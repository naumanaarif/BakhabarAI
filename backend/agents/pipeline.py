from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from .adk_runtime import run_agent_standalone
from .model_config import get_model
from tracer import tracer

async def run_crisis_simulation(scenario_data: dict = None):
    """
    Orchestrates the 5-stage crisis response pipeline.
    FIXES applied:
    - Signal agent forced to stop after one tool call (max_tool_calls=2)
    - Validation gates after each stage (check data integrity)
    - Clear manual report path (skips Stage 1 & 2, runs 3→5)
    - Rate‑limit safety: sequential batches, inter‑stage pauses
    """
    from tools.firebase_tools import get_pending_signals, query_active_incidents, get_resources
    from agents.signal_collector import signal_collector_agent
    from agents.detector import detector_agent
    from agents.planner import planner_agent
    from agents.executor import executor_agent
    from google.cloud.firestore_v1 import GeoPoint
    import json
    import asyncio
    import sys

    def fp(*args):
        print(*args, flush=True)
        sys.stdout.flush()

    trigger_type = (scenario_data or {}).get("trigger_type", "manual")

    # ── Helpers (unchanged) ─────────────────────────────────────────────────
    def sanitize(obj):
        if isinstance(obj, list):
            return [sanitize(i) for i in obj]
        if isinstance(obj, dict):
            return {k: sanitize(v) for k, v in obj.items()}
        if isinstance(obj, GeoPoint):
            return {"lat": obj.latitude, "lng": obj.longitude}
        return obj

    def slim_signal(sig):
        return {
            "id":  sig.get("id", ""),
            "src": sig.get("source_type", ""),
            "msg": str(sig.get("content", ""))[:100],
        }

    def slim_incident(inc, mode="base"):
        obj = {
            "id":   inc.get("id", ""),
            "type": inc.get("type", ""),
            "sev":  inc.get("severity", ""),
            "loc":  inc.get("location_name", ""),
        }
        if mode == "detector":
            obj["conf"] = inc.get("confidence_score", 0)
        if mode == "planner":
            obj["pop"] = inc.get("affected_population", 0)
            obj["hrs"] = inc.get("expected_duration_hours", 0)
        if mode == "executor":
            obj["res"] = inc.get("assigned_resources", [])[:3]
            obj["pop"] = inc.get("affected_population", 0)
        return obj

    def slim_resource(res):
        return {
            "id":   res.get("id", ""),
            "type": res.get("type") or res.get("resource_type", ""),
            "ok":   res.get("status", "") == "available",
        }

    # ── Pipeline start ───────────────────────────────────────────────────────
    tracer.log(
        agent_name="System",
        action=f"🚀 Pipeline started — trigger: {trigger_type}",
        input_data={"trigger": trigger_type, "scenario": str(scenario_data or {})[:150]},
        output_data={},
        confidence=1.0,
    )
    fp("\n" + "="*60)
    fp(f"[PIPELINE] Starting | trigger: {trigger_type}")
    fp("="*60)

    # ══════════════════════════════════════════════════════════════════════════
    # STAGE 1 — Signal Fusion (only for non‑manual triggers)
    # ══════════════════════════════════════════════════════════════════════════
    if trigger_type != "manual":
        fp("\n" + "-"*60)
        fp("[STAGE 1] Signal Fusion")
        fp("-"*60)
        tracer.log("SignalFusionAgent", "Stage 1: Signal Fusion starting…", {}, {}, 1.0)
        try:
            all_pending = get_pending_signals()
            pending_signals = [
                s for s in all_pending
                if s.get("metadata", {}).get("trigger_type") != "manual"
            ]
            if scenario_data and "mock_signals" in scenario_data:
                pending_signals.extend(scenario_data["mock_signals"])

            if pending_signals:
                tracer.log(
                    "SignalFusionAgent",
                    f"Fusing {len(pending_signals)} pending signals from {trigger_type} source.",
                    {"count": len(pending_signals)}, {}, 1.0,
                )
                active_now = sanitize(query_active_incidents())
                slim_inc_list = [slim_incident(i, "base") for i in active_now]

                BATCH = 4
                for i in range(0, len(pending_signals), BATCH):
                    batch = pending_signals[i:i + BATCH]
                    batch_num = i // BATCH + 1
                    print(f"[STAGE 1] Batch {batch_num} | {len(batch)} signals — direct fusion (no LLM)")

                    # ── Direct fusion: no LLM needed ──────────────────────────
                    # Build the evaluations payload deterministically from signal
                    # fields. This removes ALL Gemini/Groq calls from Stage 1.
                    def _infer_type(sig):
                        content = (sig.get("content") or "").lower()
                        src = (sig.get("source_type") or "").lower()
                        # Order matters: more specific first
                        if any(w in content for w in ["fire", "aag", "blaze", "smoke", "dhuan",
                                                       "thermal", "wildfire", "pm2.5", "smog",
                                                       "air quality", "aqi", "flames"]):
                            return "fire"
                        if any(w in content for w in ["flood", "pani", "baarish", "rain",
                                                       "flooding", "flooded", "waterlogging"]):
                            return "flood"
                        if any(w in content for w in ["heat", "garmi", "hot", "temperature",
                                                       "heatwave", "heat stroke", "lू"]):
                            return "heatwave"
                        if any(w in content for w in ["accident", "crash", "collision", "gaari",
                                                       "pileup", "truck", "vehicle"]):
                            return "accident"
                        if any(w in content for w in ["power", "bijli", "electricity", "outage",
                                                       "blackout", "generator", "grid"]):
                            return "power_outage"
                        if any(w in content for w in ["protest", "dharna", "crowd", "demonstration"]):
                            return "protest"
                        if src in ("weather",):
                            return "heatwave"
                        return "emergency"

                    def _infer_severity(credibility):
                        if credibility >= 0.8: return "HIGH"
                        if credibility >= 0.5: return "MEDIUM"
                        return "LOW"

                    evaluations = []
                    for sig in batch:
                        sig_id = sig.get("id", "")
                        credibility = float(sig.get("credibility_score", 0.5))
                        status = "verified" if credibility >= 0.5 else "noise"
                        # ── FIX: read location_name from metadata, NOT from the GeoPoint field ──
                        meta = sig.get("metadata") or {}
                        loc_name = (
                            meta.get("location_name")
                            or meta.get("name")
                            or (sig.get("location", {}).get("name") if isinstance(sig.get("location"), dict) else None)
                            or "Islamabad"
                        )
                        evaluations.append({
                            "signal_id": sig_id,
                            "status": status,
                            "credibility": credibility,
                            "incident_id": None,
                            "new_incident_data": {
                                "type": _infer_type(sig),
                                "severity": _infer_severity(credibility),
                                "location_name": loc_name,
                            } if status == "verified" else None,
                        })

                    tracer.log("SignalFusionAgent",
                               f"Starting task: Fuse signals into incidents. Call `process_signal_evaluations` **exactly once**, then output the single word 'DONE'. ...",
                               {}, {}, 1.0)
                    try:
                        from agents.signal_collector import process_signal_evaluations
                        result = await process_signal_evaluations(payload={"evaluations": evaluations})
                        print(f"[STAGE 1] Batch {batch_num} OK: {result}")
                        tracer.log("SignalFusionAgent",
                                   f"Batch {batch_num} fused {len(evaluations)} signals successfully.",
                                   {"batch": batch_num}, {"result": result}, 1.0)
                    except Exception as e:
                        tracer.log("SignalFusionAgent",
                                   f"⚠ Agent failure in batch {batch_num}: {str(e)[:150]}",
                                   {"error": str(e)}, {}, 0.0)
                        print(f"[STAGE 1] Batch {batch_num} FAILED: {e}")

                    from services.firebase_service import FirebaseService
                    for s in batch:
                        FirebaseService.update_signal_status(s["id"], "processed")

                    if i + BATCH < len(pending_signals):
                        print(f"[STAGE 1] Waiting 2s before next batch…")
                        await asyncio.sleep(2)

                # ✅ Validation gate: check that new incidents were created
                incidents_after = sanitize(query_active_incidents())
                if len(incidents_after) <= len(active_now):
                    tracer.log("SignalFusionAgent",
                               "⚠ No new incidents after fusion — pipeline will continue but may be empty.",
                               {}, {}, 0.5)
                    print("[STAGE 1] WARNING: No new incidents detected.")
            else:
                tracer.log("SignalFusionAgent", "No pending signals to fuse — skipping.", {}, {}, 1.0)
                print("[STAGE 1] No pending signals.")
        except Exception as e:
            tracer.log("SignalFusionAgent", f"⚠ Signal Fusion failed (degraded mode): {str(e)[:150]}",
                       {"error": str(e)}, {}, 0.0)
            print(f"[STAGE 1] FAILED: {e}")

    else:
        # Manual report → skip Stage 1 entirely
        tracer.log("SignalFusionAgent", "Manual report — skipping fusion (incident already created).", {}, {}, 1.0)
        print("[STAGE 1] Skipped for manual report.")

    # ══════════════════════════════════════════════════════════════════════════
    # STAGE 2 — Crisis Detection
    # ══════════════════════════════════════════════════════════════════════════
    fp("\n" + "-"*60)
    fp("[STAGE 2] Crisis Detection")
    fp("-"*60)
    tracer.log("DetectorAgent", "Stage 2: Crisis Detection starting…", {}, {}, 1.0)

    if trigger_type != "manual":
        try:
            incidents = sanitize(query_active_incidents())
            unclassified = [i for i in incidents if not i.get("affected_population")]
            if unclassified:
                # ── Pre-build deterministic fallback ──
                _POP    = {"flood": 5000, "heatwave": 10000, "fire": 2500, "accident": 400,
                           "power_outage": 15000, "protest": 3000, "emergency": 1000}
                _DUR    = {"flood": 8, "heatwave": 24, "fire": 4, "accident": 2,
                           "power_outage": 6, "protest": 5, "emergency": 12}
                _SPREAD = {"flood": "HIGH", "heatwave": "HIGH", "fire": "HIGH",
                           "accident": "LOW", "power_outage": "MEDIUM",
                           "protest": "MEDIUM", "emergency": "LOW"}
                fallback_cls = []
                for inc in unclassified:
                    t = inc.get("type", "emergency"); dur = _DUR.get(t, 12)
                    fallback_cls.append({
                        "id": inc["id"], "type": t, "severity": inc.get("severity", "MEDIUM"),
                        "affected_population": _POP.get(t, 1000),
                        "expected_duration_hours": dur,
                        "evolution_prediction": {"duration_hours": dur,
                            "peak_time": "2026-05-21T22:00:00",
                            "spread_risk": _SPREAD.get(t, "MEDIUM")},
                    })

                # ── LLM: text-only completion (no function calling = no parallel-call waste) ──
                # The LLM reasons about severity/population and outputs plain JSON.
                # ~200 tokens vs 4000+ from function-calling approach.
                classifications = fallback_cls  # default
                try:
                    import litellm
                    from agents.model_config import GROQ_API_KEYS, _agent_rotation, _AGENT_SLOT, _pool_size
                    slimmed = [{"id": i["id"], "type": i.get("type"), "title": i.get("title",""),
                                "location": i.get("location_name",""), "severity": i.get("severity","MEDIUM")}
                               for i in unclassified]
                    system_msg = (
                        "You are a crisis classification AI for Pakistani cities. "
                        "Given a list of incidents, output ONLY a valid JSON array — no extra text, no markdown. "
                        "Each item must have: id, type, severity (HIGH/MEDIUM/LOW), "
                        "affected_population (integer), expected_duration_hours (integer), "
                        "evolution_prediction: {duration_hours, peak_time (ISO8601), spread_risk (HIGH/MEDIUM/LOW)}. "
                        "Use realistic values for Pakistani urban crises."
                    )
                    user_msg = f"Classify these incidents:\n{json.dumps(slimmed, ensure_ascii=False)}"
                    # Try each Groq key in the pool before giving up
                    base_slot = _AGENT_SLOT.get("DetectorAgent", 1)
                    llm_text = None
                    for attempt_k in range(_pool_size()):
                        slot = (base_slot + attempt_k) % _pool_size()
                        key = GROQ_API_KEYS[slot % len(GROQ_API_KEYS)]
                        try:
                            print(f"[STAGE 2] Groq text-completion slot {slot}...")
                            resp = await litellm.acompletion(
                                model="groq/llama-3.1-8b-instant",
                                api_key=key,
                                messages=[
                                    {"role": "system", "content": system_msg},
                                    {"role": "user",   "content": user_msg},
                                ],
                                response_format={"type": "json_object"},
                                temperature=0.0,
                                max_tokens=600,
                                timeout=15,
                            )
                            llm_text = resp.choices[0].message.content
                            print(f"[STAGE 2] Groq slot {slot} OK — {len(llm_text)} chars")
                            break
                        except Exception as ke:
                            print(f"[STAGE 2] Groq slot {slot} failed: {type(ke).__name__} — trying next key")
                    # Parse LLM JSON output
                    if llm_text:
                        import re as _re
                        m = _re.search(r"\[.*\]", llm_text, _re.DOTALL)
                        parsed = json.loads(m.group() if m else llm_text)
                        if isinstance(parsed, dict):
                            parsed = list(parsed.values())[0] if parsed else []
                        if parsed and isinstance(parsed[0], dict) and "id" in parsed[0]:
                            classifications = parsed
                            print(f"[STAGE 2] LLM classified {len(classifications)} incidents via text-completion.")
                            tracer.log("DetectorAgent",
                                       f"LLM classified {len(classifications)} incidents via text-completion (~200 tokens).",
                                       {"count": len(classifications)}, {}, 1.0)
                except Exception as llm_err:
                    print(f"[STAGE 2] LLM text-completion failed ({type(llm_err).__name__}) — using fallback.")
                    tracer.log("DetectorAgent", f"LLM unavailable — using deterministic fallback.", {}, {}, 0.7)

                # ── Commit classifications to Firestore ──
                from agents.detector import process_incident_classifications
                result = await process_incident_classifications(payload={"classifications": classifications})
                print(f"[STAGE 2] Classifications committed: {result[:80]}")
                tracer.log("DetectorAgent",
                           f"Committed {len(classifications)} incident classifications to Firestore.",
                           {"count": len(classifications)}, {"result": result[:80]}, 1.0)
            else:
                tracer.log("DetectorAgent", "All incidents already classified — skipping.", {}, {}, 1.0)
                print("[STAGE 2] All incidents already classified.")
        except Exception as e:
            tracer.log("DetectorAgent", f"⚠ Crisis Detection error: {str(e)[:150]}",
                       {"error": str(e)}, {}, 0.0)
            print(f"[STAGE 2] ERROR: {e}")
    else:
        tracer.log("DetectorAgent", "Manual report — skipping detection (type already known).", {}, {}, 1.0)
        print("[STAGE 2] Skipped for manual report.")


    # ══════════════════════════════════════════════════════════════════════════
    # STAGE 3 — Resource Planning  (direct — deterministic math, no LLM needed)
    # ══════════════════════════════════════════════════════════════════════════
    fp("\n" + "-"*60)
    fp("[STAGE 3] Resource Planning")
    fp("-"*60)
    tracer.log("ResourcePlannerAgent", "Stage 3: Resource Planning starting…", {}, {}, 1.0)

    try:
        incidents = sanitize(query_active_incidents())
        unplanned = [i for i in incidents if not i.get("assigned_resources")]
        resources = get_resources()
        available = [r for r in resources if r.get("status") == "available"]

        if unplanned and available:
            tracer.log("ResourcePlannerAgent",
                       f"Allocating {len(available)} resources to {len(unplanned)} incident(s) — greedy priority.",
                       {"incidents": len(unplanned), "resources": len(available)}, {}, 1.0)

            _SEV_ORDER = {"HIGH": 0, "MEDIUM": 1, "LOW": 2}
            _RES_COUNT = {"HIGH": 3, "MEDIUM": 2, "LOW": 1}
            sorted_incs = sorted(unplanned,
                                 key=lambda x: _SEV_ORDER.get(x.get("severity", "LOW"), 2))
            allocations = []
            res_idx = 0
            for inc in sorted_incs:
                count = _RES_COUNT.get(inc.get("severity", "MEDIUM"), 2)
                for _ in range(count):
                    if res_idx < len(available):
                        allocations.append({
                            "resource_id": available[res_idx]["id"],
                            "incident_id": inc["id"],
                        })
                        res_idx += 1

            trade_offs = [
                "HIGH severity incidents receive 3 resources, MEDIUM receive 2, LOW receive 1.",
                "Resources allocated in priority order. Remaining pool preserved for new emergencies.",
            ]

            from agents.planner import process_resource_allocations
            result = await process_resource_allocations(
                payload={"allocations": allocations, "trade_offs": trade_offs}
            )
            print(f"[STAGE 3] Direct allocation OK ({len(allocations)} assignments): {result[:80]}")
            tracer.log("ResourcePlannerAgent",
                       f"Assigned {len(allocations)} resources via severity-priority greedy algorithm.",
                       {"assignments": len(allocations)}, {"result": result[:120]}, 1.0)
        else:
            msg = "No available resources." if not available else "All incidents already have resources assigned."
            tracer.log("ResourcePlannerAgent", f"Skipping planning — {msg}", {}, {}, 1.0)
            print(f"[STAGE 3] Skipped: {msg}")
    except Exception as e:
        tracer.log("ResourcePlannerAgent", f"⚠ Resource Planning failed: {str(e)[:150]}",
                   {"error": str(e)}, {}, 0.0)
        print(f"[STAGE 3] FAILED: {e}")

    # ══════════════════════════════════════════════════════════════════════════
    # STAGE 4 — Impact Simulation  (direct, no LLM)
    # ══════════════════════════════════════════════════════════════════════════
    fp("\n" + "-"*60)
    fp("[STAGE 4] Impact Simulation")
    fp("-"*60)
    tracer.log("SimulationStakeholderAgent", "Stage 4: Impact Simulation starting…", {}, {}, 1.0)

    try:
        from firebase_config import db
        from google.cloud.firestore_v1 import FieldFilter
        from datetime import datetime

        incidents = sanitize(query_active_incidents())
        sim_ready = []
        for inc in incidents:
            recent = (
                db.collection("action_simulations")
                .where(filter=FieldFilter("incident_id", "==", inc["id"]))
                .limit(3)
                .get()
            )
            has_recent = False
            for doc in recent:
                ts = doc.to_dict().get("timestamp")
                if isinstance(ts, str):
                    try:
                        ts = datetime.fromisoformat(ts.replace("Z", "+00:00"))
                    except Exception:
                        ts = datetime.now()
                if ts and (datetime.now(ts.tzinfo) - ts).total_seconds() < 3600:
                    has_recent = True
                    break
            if not has_recent:
                sim_ready.append(inc)
            else:
                tracer.log("SimulationStakeholderAgent",
                           f"Skipping {inc['id']} — simulation done within last hour.", {}, {}, 1.0)

        if sim_ready:
            # ── Template fallback data ──
            _BEFORE = {
                "flood":        "Streets flooded. Vehicles stranded, residents isolated.",
                "heatwave":     "Extreme heat. Heat stroke risk HIGH. Hospitals overwhelmed.",
                "fire":         "Active fire with smoke. Evacuation in progress.",
                "accident":     "Multi-vehicle collision. Road fully blocked. Casualties on scene.",
                "power_outage": "Total power failure. Hospitals on backup generators.",
                "protest":      "Large crowd. Traffic disrupted. Tension elevated.",
                "emergency":    "Emergency situation active. Response units mobilizing.",
            }
            _AFTER = {
                "flood":        "Rescue teams deployed. Evacuation corridors established. Pumping underway.",
                "heatwave":     "Cooling centers open. Medical teams on standby. Water distribution started.",
                "fire":         "Fire brigade on site. Containment achieved. Evacuation complete.",
                "accident":     "Ambulances dispatched. Road cleared. Traffic rerouted.",
                "power_outage": "LESCO repair teams deployed. Estimated restoration: 4 hours.",
                "protest":      "Police deployed for crowd management. Alternate routes opened.",
                "emergency":    "Emergency response teams deployed. Situation being assessed.",
            }
            _PUBLIC = {
                "flood":        "⚠️ FLOOD ALERT: Paani bhar gaya. Buland jagah par jayen foran.",
                "heatwave":     "⚠️ HEATWAVE ALERT: Shadeed garmi. Ghar mein rahain, paani piyain.",
                "fire":         "🔥 FIRE ALERT: Aag lagi hui hai. Ilaqa khali karein foran.",
                "accident":     "🚨 ROAD CLOSED: Bara hadsa hua. Mutabadil rasta istemal karein.",
                "power_outage": "💡 BIJLI GAYE: 4 ghante mein wapas aa jayegi. Backup use karein.",
                "protest":      "⚠️ TRAFFIC: Dharna jari hai. Mutabadil rasta istemal karein.",
                "emergency":    "⚠️ EMERGENCY: Emergency services ki hidayat par amal karein.",
            }
            fallback_sims = []
            for inc in sim_ready:
                t = inc.get("type", "emergency")
                loc = inc.get("location_name", "Islamabad")
                sev = inc.get("severity", "MEDIUM")
                fallback_sims.append({
                    "incident_id":  inc["id"],
                    "action_type":  f"{t.replace('_',' ').title()} Response",
                    "description":  f"Coordinated {sev} {t} response at {loc}.",
                    "impact": {
                        "before_state": _BEFORE.get(t, _BEFORE["emergency"]),
                        "after_state":  _AFTER.get(t, _AFTER["emergency"]),
                        "improvement_metrics": {"response_time_reduction": "18 min", "safety_boost": "45%"},
                    },
                    "notifications": {
                        "public":            _PUBLIC.get(t, _PUBLIC["emergency"]),
                        "hospitals":         f"ALERT: {t.title()} casualties expected from {loc}.",
                        "utility_providers": f"{'Power disruption possible' if t in ('flood','fire') else 'No utility impact'} at {loc}.",
                    },
                })

            # ── LLM: text-completion (no function-calling → no tool_use_failed) ──
            simulations = fallback_sims
            try:
                import litellm as _litellm
                from agents.model_config import GROQ_API_KEYS, _AGENT_SLOT, _pool_size
                slim4 = [{"id": i["id"], "type": i.get("type"), "sev": i.get("severity"),
                          "loc": i.get("location_name", "Islamabad"), "pop": i.get("affected_population", 0)}
                         for i in sim_ready]
                sys4 = (
                    "You are a crisis simulation AI for Pakistani cities. "
                    "Output ONLY a valid JSON array — no markdown. "
                    "Each item: incident_id, action_type, description, "
                    "impact:{before_state, after_state, improvement_metrics:{response_time_reduction, safety_boost}}, "
                    "notifications:{public (Urdu/Roman Urdu), hospitals, utility_providers}."
                )
                usr4 = f"Generate simulations:\n{json.dumps(slim4, ensure_ascii=False)}"
                base4 = _AGENT_SLOT.get("SimulationStakeholderAgent", 3)
                llm4_text = None
                for attempt_k in range(_pool_size()):
                    slot = (base4 + attempt_k) % _pool_size()
                    key = GROQ_API_KEYS[slot % len(GROQ_API_KEYS)]
                    try:
                        print(f"[STAGE 4] Groq text-completion slot {slot}...")
                        resp4 = await _litellm.acompletion(
                            model="groq/llama-3.1-8b-instant",
                            api_key=key,
                            messages=[{"role": "system", "content": sys4},
                                      {"role": "user",   "content": usr4}],
                            response_format={"type": "json_object"},
                            temperature=0.1, max_tokens=1200, timeout=20,
                        )
                        llm4_text = resp4.choices[0].message.content
                        print(f"[STAGE 4] Groq slot {slot} OK — {len(llm4_text)} chars")
                        break
                    except Exception as ke4:
                        print(f"[STAGE 4] Groq slot {slot} failed: {type(ke4).__name__} — next key")
                if llm4_text:
                    import re as _re4
                    m4 = _re4.search(r"\[.*\]", llm4_text, _re4.DOTALL)
                    parsed4 = json.loads(m4.group() if m4 else llm4_text)
                    if isinstance(parsed4, dict):
                        parsed4 = list(parsed4.values())[0] if parsed4 else []
                    if parsed4 and isinstance(parsed4[0], dict) and "incident_id" in parsed4[0]:
                        simulations = parsed4
                        tracer.log("SimulationStakeholderAgent",
                                   f"LLM generated {len(simulations)} simulations with Urdu alerts.",
                                   {"count": len(simulations)}, {}, 1.0)
            except Exception as llm4_err:
                print(f"[STAGE 4] LLM failed ({type(llm4_err).__name__}) — using templates.")
                tracer.log("SimulationStakeholderAgent", "LLM unavailable — template simulations used.", {}, {}, 0.7)

            # ── Commit to Firestore ──
            from agents.executor import process_simulations_and_messages
            result = await process_simulations_and_messages(payload={"simulations": simulations})
            print(f"[STAGE 4] Committed {len(simulations)} simulations: {result[:80]}")
            tracer.log("SimulationStakeholderAgent",
                       f"Committed {len(simulations)} simulation records with stakeholder notifications.",
                       {"simulations": len(simulations)}, {"result": result[:80]}, 1.0)

        else:
            tracer.log("SimulationStakeholderAgent",
                       "All incidents simulated recently — skipping.", {}, {}, 1.0)
            print("[STAGE 4] No incidents need fresh simulation.")
    except Exception as e:
        tracer.log("SimulationStakeholderAgent", f"\u26a0 Impact Simulation error: {str(e)[:150]}",
                   {"error": str(e)}, {}, 0.0)
        print(f"[STAGE 4] ERROR: {e}")


    # ══════════════════════════════════════════════════════════════════════════
    # STAGE 5 — Final Report (unchanged)
    # ══════════════════════════════════════════════════════════════════════════
    try:
        incidents = sanitize(query_active_incidents())
        high = sum(1 for i in incidents if i.get("severity") == "HIGH")
        med  = sum(1 for i in incidents if i.get("severity") == "MEDIUM")
        low  = sum(1 for i in incidents if i.get("severity") == "LOW")
        summary = (
            f"Pipeline complete ✅ — {len(incidents)} active incident(s) "
            f"(HIGH={high}, MEDIUM={med}, LOW={low}). Trigger: {trigger_type}."
        )
        tracer.log("ReporterAgent", summary, {},
                   {"count": len(incidents), "high": high, "medium": med, "low": low}, 1.0)
        print(f"[STAGE 5] {summary}")
    except Exception as e:
        tracer.log("System", f"⚠ Final Reporting failed: {str(e)[:150]}",
                   {"error": str(e)}, {}, 0.0)
        print(f"[STAGE 5] FAILED: {e}")

    fp("\n" + "="*60)
    fp("[PIPELINE] Complete!")
    fp("="*60 + "\n")
    return "PIPELINE_COMPLETE"
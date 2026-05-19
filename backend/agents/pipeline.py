from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from .adk_runtime import run_agent_standalone
from .model_config import get_model

# Import tracer at module level — same singleton used by adk_runtime
from tracer import tracer


async def run_crisis_simulation(scenario_data: dict = None):
    """
    Orchestrates the 5-stage crisis response pipeline using Google ADK agents.
    Every stage logs to the tracer so /api/logs always reflects pipeline activity.
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
        """flush_print — guaranteed immediate output in uvicorn console."""
        print(*args, flush=True)
        sys.stdout.flush()

    trigger_type = (scenario_data or {}).get("trigger_type", "manual")

    # ── Helpers ──────────────────────────────────────────────────────────────

    def sanitize(obj):
        """Recursively converts GeoPoints to plain dicts."""
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

    # ── Pipeline start ────────────────────────────────────────────────────────
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
    # STAGE 1 — Signal Fusion
    # ══════════════════════════════════════════════════════════════════════════
    fp("\n" + "-"*60)
    fp("[STAGE 1] Signal Fusion")
    fp("-"*60)
    tracer.log("SignalFusionAgent", "Stage 1: Signal Fusion starting…", {}, {}, 1.0)
    if trigger_type == "manual":
        target_id = (scenario_data or {}).get("target_signal_id")
        if target_id:
            from services.firebase_service import FirebaseService
            FirebaseService.update_signal_status(target_id, "processed")
        tracer.log("SignalFusionAgent", "Manual report — skipping fusion (incident already created).", {}, {}, 1.0)
        print("[STAGE 1] Manual mode — skipping fusion.")
        pending_signals = []
    else:
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
                    slimmed = [slim_signal(s) for s in batch]
                    prompt = (
                        "Fuse signals into incidents. Call process_signal_evaluations once.\n"
                        f"signals={json.dumps(slimmed)}\n"
                        f"active={json.dumps(slim_inc_list)}"
                    )
                    print(f"[STAGE 1] Batch {i // BATCH + 1} | {len(batch)} signals | {len(prompt)} chars")
                    await run_agent_standalone(signal_collector_agent, prompt)

                    from services.firebase_service import FirebaseService
                    for s in batch:
                        FirebaseService.update_signal_status(s["id"], "processed")

                    if i + BATCH < len(pending_signals):
                        print(f"[STAGE 1] Waiting 5s before next batch to avoid rate limits...")
                        await asyncio.sleep(5)
            else:
                tracer.log("SignalFusionAgent", "No pending signals to fuse — skipping.", {}, {}, 1.0)
                print("[STAGE 1] No pending signals.")
        except Exception as e:
            tracer.log("SignalFusionAgent", f"⚠ Signal Fusion failed (degraded mode): {str(e)[:150]}", {"error": str(e)}, {}, 0.0)
            print(f"[STAGE 1] FAILED: {e}")

    # ══════════════════════════════════════════════════════════════════════════
    # STAGE 2 — Crisis Detection
    # ══════════════════════════════════════════════════════════════════════════
    fp("\n" + "-"*60)
    fp("[STAGE 2] Crisis Detection")
    fp("-"*60)
    tracer.log("DetectorAgent", "Stage 2: Crisis Detection starting…", {}, {}, 1.0)
    await asyncio.sleep(3)  # Inter-stage pause
    if trigger_type != "manual":
        try:
            incidents = sanitize(query_active_incidents())
            unclassified = [i for i in incidents if not i.get("affected_population")]
            if unclassified:
                tracer.log(
                    "DetectorAgent",
                    f"Classifying {len(unclassified)} unclassified incident(s).",
                    {"count": len(unclassified)}, {}, 1.0,
                )
                slimmed = [slim_incident(i, "detector") for i in unclassified]
                prompt = (
                    "Classify each crisis. Call process_incident_classifications once.\n"
                    f"incidents={json.dumps(slimmed)}"
                )
                print(f"[STAGE 2] Detecting {len(unclassified)} incidents | {len(prompt)} chars")
                await run_agent_standalone(detector_agent, prompt)
                await asyncio.sleep(2)
            else:
                tracer.log("DetectorAgent", "All incidents already classified — skipping.", {}, {}, 1.0)
                print("[STAGE 2] All incidents already classified.")
        except Exception as e:
            tracer.log("DetectorAgent", f"⚠ Crisis Detection failed (degraded mode): {str(e)[:150]}", {"error": str(e)}, {}, 0.0)
            print(f"[STAGE 2] FAILED: {e}")
    else:
        tracer.log("DetectorAgent", "Manual report — skipping detection (type already known).", {}, {}, 1.0)
        print("[STAGE 2] Skipped for manual report.")

    # ══════════════════════════════════════════════════════════════════════════
    # STAGE 3 — Resource Planning
    # ══════════════════════════════════════════════════════════════════════════
    fp("\n" + "-"*60)
    fp("[STAGE 3] Resource Planning")
    fp("-"*60)
    tracer.log("ResourcePlannerAgent", "Stage 3: Resource Planning starting…", {}, {}, 1.0)
    await asyncio.sleep(3)  # Inter-stage pause
    try:
        incidents = sanitize(query_active_incidents())
        unplanned = [i for i in incidents if not i.get("assigned_resources")]
        resources = get_resources()
        available = [r for r in resources if r.get("status") == "available"]

        if unplanned and available:
            tracer.log(
                "ResourcePlannerAgent",
                f"Allocating resources: {len(available)} available → {len(unplanned)} unplanned incident(s).",
                {"incidents": len(unplanned), "resources": len(available)}, {}, 1.0,
            )
            slim_incs = [slim_incident(i, "planner") for i in unplanned]
            slim_res = [slim_resource(r) for r in available[:10]]
            prompt = (
                "Allocate resources to incidents. Call process_resource_allocations once.\n"
                f"incidents={json.dumps(slim_incs)}\n"
                f"resources={json.dumps(slim_res)}"
            )
            print(f"[STAGE 3] Planning {len(unplanned)} incidents + {len(slim_res)} resources | {len(prompt)} chars")
            await run_agent_standalone(planner_agent, prompt)
            await asyncio.sleep(2)
        else:
            msg = "No available resources." if not available else "All incidents already have resources assigned."
            tracer.log("ResourcePlannerAgent", f"Skipping planning — {msg}", {}, {}, 1.0)
            print(f"[STAGE 3] Skipped: {msg}")
    except Exception as e:
        tracer.log("ResourcePlannerAgent", f"⚠ Resource Planning failed (degraded mode): {str(e)[:150]}", {"error": str(e)}, {}, 0.0)
        print(f"[STAGE 3] FAILED: {e}")

    # ══════════════════════════════════════════════════════════════════════════
    # STAGE 4 — Impact Simulation
    # ══════════════════════════════════════════════════════════════════════════
    fp("\n" + "-"*60)
    fp("[STAGE 4] Impact Simulation")
    fp("-"*60)
    tracer.log("SimulationStakeholderAgent", "Stage 4: Impact Simulation starting…", {}, {}, 1.0)
    await asyncio.sleep(3)  # Inter-stage pause
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
                tracer.log("SimulationStakeholderAgent", f"Skipping {inc['id']} — simulation done within last hour.", {}, {}, 1.0)

        if sim_ready:
            tracer.log(
                "SimulationStakeholderAgent",
                f"Simulating impact for {len(sim_ready)} incident(s) and generating stakeholder messages.",
                {"count": len(sim_ready)}, {}, 1.0,
            )
            slimmed = [slim_incident(i, "executor") for i in sim_ready]
            prompt = (
                "Simulate response impact and generate stakeholder notifications. "
                "Call process_simulations_and_messages once.\n"
                f"incidents={json.dumps(slimmed)}"
            )
            print(f"[STAGE 4] Simulating {len(sim_ready)} incidents | {len(prompt)} chars")
            await run_agent_standalone(executor_agent, prompt)
        else:
            tracer.log("SimulationStakeholderAgent", "All incidents simulated recently — skipping.", {}, {}, 1.0)
            print("[STAGE 4] No incidents need fresh simulation.")
    except Exception as e:
        tracer.log("SimulationStakeholderAgent", f"⚠ Impact Simulation failed (degraded mode): {str(e)[:150]}", {"error": str(e)}, {}, 0.0)
        print(f"[STAGE 4] FAILED: {e}")

    # ══════════════════════════════════════════════════════════════════════════
    # STAGE 5 — Final Report (pure Python, no LLM call)
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
        tracer.log("ReporterAgent", summary, {}, {"count": len(incidents), "high": high, "medium": med, "low": low}, 1.0)
        print(f"[STAGE 5] {summary}")
    except Exception as e:
        tracer.log("System", f"⚠ Final Reporting failed: {str(e)[:150]}", {"error": str(e)}, {}, 0.0)
        print(f"[STAGE 5] FAILED: {e}")

    fp("\n" + "="*60)
    fp("[PIPELINE] Complete!")
    fp("="*60 + "\n")
    return "PIPELINE_COMPLETE"

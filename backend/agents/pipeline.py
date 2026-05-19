from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from .adk_runtime import run_agent_standalone
from .model_config import get_model

async def run_crisis_simulation(scenario_data: dict = None):
    """
    Orchestrates the crisis response pipeline using Google ADK agents.
    Provides robustness via 'Degraded Mode' fallbacks for each stage.
    """
    from tools.firebase_tools import get_pending_signals, query_active_incidents, get_resources
    from .adk_runtime import run_agent_standalone
    from agents.signal_collector import signal_collector_agent
    from agents.detector import detector_agent
    from agents.planner import planner_agent
    from agents.executor import executor_agent
    from tracer import tracer
    from google.cloud.firestore_v1 import GeoPoint
    import json

    def sanitize(obj):
        """Recursively converts GeoPoints to dicts for AI prompts."""
        if isinstance(obj, list):
            return [sanitize(i) for i in obj]
        if isinstance(obj, dict):
            return {k: sanitize(v) for k, v in obj.items()}
        if isinstance(obj, GeoPoint):
            return {"lat": obj.latitude, "lng": obj.longitude}
        return obj

    print("🚀 [PIPELINE] Starting Crisis Simulation...")

    # 1. Signal Fusion Stage
    try:
        trigger_type = scenario_data.get("trigger_type", "manual") if scenario_data else "manual"
        all_pending = get_pending_signals()
        
        # FILTER SIGNALS based on trigger mode (Strict Isolation)
        if trigger_type == "manual":
            # For manual reports, we skip the Collector/Detector agents as the user has already defined the incident.
            # We just mark the signal as processed and move to planning.
            target_id = scenario_data.get("target_signal_id") if scenario_data else None
            if target_id:
                from services.firebase_service import FirebaseService
                FirebaseService.update_signal_status(target_id, "processed")
                print(f"DEBUG: [ISOLATION] Manual mode. Marked signal {target_id} as processed. Skipping Fusion/Detection.")
            
            # Skip to step 3
            pending_signals = []
        else:
            # For stress tests, process everything tagged as mock or without a tag (legacy)
            pending_signals = [s for s in all_pending if s.get('metadata', {}).get('trigger_type') != 'manual']
            
            # INJECT additional mock signals if provided
            if scenario_data and "mock_signals" in scenario_data:
                print(f"DEBUG: Injecting {len(scenario_data['mock_signals'])} additional mock signals.")
                pending_signals.extend(scenario_data["mock_signals"])
            
            print(f"DEBUG: [ISOLATION] Mock/Stress mode. Processing {len(pending_signals)} signals.")
            
        active_incidents = query_active_incidents()
        if pending_signals:
            print(f"DEBUG: Running SignalFusionAgent for {len(pending_signals)} isolated signals...")

            # Sanitize for prompt
            clean_signals = sanitize(pending_signals)
            clean_incidents = sanitize(active_incidents)

            prompt = f"Process the following pending signals and active incidents:\nSignals: {json.dumps(clean_signals, default=str)}\nIncidents: {json.dumps(clean_incidents, default=str)}"
            await run_agent_standalone(signal_collector_agent, prompt)

            # Mark as fully processed after success
            from services.firebase_service import FirebaseService
            for s in pending_signals:
                FirebaseService.update_signal_status(s['id'], "processed")
            print("DEBUG: Marked all pending signals as processed.")

            # Small cooldown between agents to respect TPM limits
            import asyncio
            await asyncio.sleep(2)

        elif trigger_type != "manual":
            print("DEBUG: No pending signals to process.")
            tracer.log("System", "No new signals to process.", {}, {})
    except Exception as e:
        tracer.log("System", "Degraded Mode: Signal Fusion failed. Reverting to manual monitoring.", {"error": str(e)}, {}, 0.0)
        print(f"CRITICAL: Signal Fusion Failure: {e}")

    # 2. Crisis Detection Stage
    try:
        if trigger_type != "manual":
            active_incidents = query_active_incidents()
            if active_incidents:
                print(f"DEBUG: Analyzing {len(active_incidents)} active incidents. Running DetectorAgent...")
                clean_incidents = sanitize(active_incidents)
                prompt = f"Analyze and classify the following active incidents to predict severity and evolution:\n{json.dumps(clean_incidents, default=str)}"
                await run_agent_standalone(detector_agent, prompt)
                import asyncio
                await asyncio.sleep(2)
            else:
                print("DEBUG: No active incidents for DetectorAgent.")
        else:
            print("DEBUG: Skipping DetectorAgent for manual report.")
    except Exception as e:
        tracer.log("System", "Degraded Mode: Crisis Detection failed.", {"error": str(e)}, {}, 0.0)
        print(f"CRITICAL: Crisis Detection Failure: {e}")

    # 3. Resource Planning Stage
    try:
        active_incidents = query_active_incidents()
        available_resources = get_resources()
        if active_incidents:
            prompt = f"Optimize resource allocation for these incidents considering constraints:\nIncidents: {json.dumps(active_incidents, default=str)}\nResources: {json.dumps(available_resources, default=str)}"
            await run_agent_standalone(planner_agent, prompt)
            import asyncio
            await asyncio.sleep(2)
    except Exception as e:
        tracer.log("System", "Degraded Mode: Resource Planning failed.", {"error": str(e)}, {}, 0.0)
        print(f"CRITICAL: Resource Planning Failure: {e}")

    # 4. Impact Simulation Stage
    try:
        active_incidents = query_active_incidents()
        
        # DEDUPING: Only simulate incidents that haven't been simulated in the last hour
        from firebase_config import db
        from google.cloud.firestore_v1 import FieldFilter
        from datetime import datetime, timedelta
        
        sim_ready_incidents = []
        for inc in active_incidents:
            # Simple query by incident_id only to avoid needing a composite index
            recent_sims = db.collection("action_simulations")\
                .where(filter=FieldFilter("incident_id", "==", inc['id']))\
                .limit(5).get()
            
            # Filter by timestamp in Python
            has_recent = False
            for doc in recent_sims:
                sim_data = doc.to_dict()
                if "timestamp" in sim_data:
                    # Handle both datetime objects and ISO strings
                    ts = sim_data["timestamp"]
                    if isinstance(ts, str):
                        try: ts = datetime.fromisoformat(ts.replace("Z", "+00:00"))
                        except: ts = datetime.now() # Fallback
                    
                    if (datetime.now(ts.tzinfo) - ts).total_seconds() < 3600:
                        has_recent = True
                        break
            
            if not has_recent:
                sim_ready_incidents.append(inc)
            else:
                print(f"DEBUG: Skipping simulation for incident {inc['id']} (already simulated recently).")
        
        if sim_ready_incidents:
            print(f"DEBUG: Running SimulationStakeholderAgent for {len(sim_ready_incidents)} incidents...")
            prompt = f"Simulate response impact and generate stakeholder notifications for these incidents:\n{json.dumps(sanitize(sim_ready_incidents), default=str)}"
            await run_agent_standalone(executor_agent, prompt)
        else:
            print("DEBUG: No incidents require fresh simulation.")
            
    except Exception as e:
        tracer.log("System", "Degraded Mode: Impact Simulation failed.", {"error": str(e)}, {}, 0.0)
        print(f"CRITICAL: Impact Simulation Failure: {e}")

    # 5. Final Reporting Stage
    try:
        from agents.reporter import reporter_agent
        active_incidents = query_active_incidents()
        if active_incidents:
            print("DEBUG: Running ReporterAgent...")
            prompt = f"Generate a final summary report for these active incidents:\n{json.dumps(sanitize(active_incidents), default=str)}"
            await run_agent_standalone(reporter_agent, prompt)
    except Exception as e:
        tracer.log("System", "Degraded Mode: Final Reporting failed.", {"error": str(e)}, {}, 0.0)
        print(f"CRITICAL: Final Reporting Failure: {e}")

    return "PIPELINE_COMPLETE"

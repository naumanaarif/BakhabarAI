from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field

class ImprovementMetrics(BaseModel):
    response_time_reduction: str
    safety_boost: str

class ImpactState(BaseModel):
    before_state: str
    after_state: str
    improvement_metrics: ImprovementMetrics

class Notifications(BaseModel):
    public: str
    hospitals: str
    utility_providers: str

class Simulation(BaseModel):
    incident_id: str
    action_type: str
    description: str
    impact: Optional[ImpactState] = None
    notifications: Optional[Notifications] = None

class SimulationsPayload(BaseModel):
    simulations: List[Simulation]

from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from tools.firebase_tools import query_active_incidents, create_simulation_record
from tracer import tracer
from .model_config import get_model
import json

_PROCESSED_SIMULATIONS = set()

async def process_simulations_and_messages(payload: Dict[str, Any] = None, **kwargs) -> str:
    """
    Commits your response impact simulations and multi-stakeholder notifications.
    """
    from firebase_config import db
    from google.cloud.firestore_v1 import FieldFilter
    from datetime import datetime
    
    # Robust extraction
    data = payload if payload is not None else kwargs
    simulations = data.get('simulations') or data.get('payload', {}).get('simulations')

    if not simulations or not isinstance(simulations, list):
        return "ERROR: Expected 'simulations' list in payload."

    results = []
    for sim in simulations:
        if not isinstance(sim, dict): continue
        
        incident_id = sim.get('incident_id') or sim.get('id')
        if not incident_id or incident_id == "null": continue
        
        # 1. SESSION CACHE
        if incident_id in _PROCESSED_SIMULATIONS:
            continue

        # 2. DATABASE LOOP BREAKER
        recent = db.collection("action_simulations").where(filter=FieldFilter("incident_id", "==", incident_id)).limit(5).get()
        if recent:
            # Check the timestamps in Python to avoid needing a composite index
            has_recent = False
            for doc in recent:
                ts = doc.to_dict().get("timestamp")
                if isinstance(ts, str):
                    try: ts = datetime.fromisoformat(ts.replace("Z", "+00:00"))
                    except: ts = datetime.now()
                    
                if ts and (datetime.now(ts.tzinfo) - ts).total_seconds() < 600: 
                    has_recent = True
                    break
                    
            if has_recent:
                print(f"DEBUG: Simulation for {incident_id} already exists. Skipping to break loop.")
                _PROCESSED_SIMULATIONS.add(incident_id)
                continue

        # Fuzzy Impact
        impact = sim.get('impact') or {}
        if isinstance(impact, str): impact = {'before_state': 'Pending.', 'after_state': impact, 'improvement_metrics': {}}
        elif not isinstance(impact, dict): impact = {}

        metrics = impact.get('improvement_metrics') or {}
        impact_payload = {
            'before_state': impact.get('before_state') or 'Pending emergency response.',
            'after_state': impact.get('after_state') or 'Resource deployment in progress.',
            'improvement_metrics': {
                'response_time_reduction': metrics.get('response_time_reduction') or '15 min',
                'safety_boost': metrics.get('safety_boost') or '30%'
            }
        }

        notif = sim.get('notifications') or {}
        if not isinstance(notif, dict): notif = {}
        msg = notif.get('message') or notif.get('body') or "Emergency response units dispatched."
        notifications_payload = {'public': notif.get('public') or msg, 'hospitals': notif.get('hospitals') or f"Alert: {msg}", 'utility_providers': notif.get('utility_providers') or "No immediate utility impact."}

        create_simulation_record(incident_id=incident_id, action_type=sim.get('action_type') or 'Crisis Response', description=sim.get('description') or 'Simulating impact of response...', impact=impact_payload, notifications=notifications_payload)
        _PROCESSED_SIMULATIONS.add(incident_id)
        results.append(incident_id)

    return json.dumps({
        "status": "SUCCESS", 
        "terminal": True, 
        "message": "SIMULATION_LOCKED: Simulation data committed. DO NOT RETRY.",
        "simulations": len(results)
    })


executor_agent = Agent(
    name="SimulationStakeholderAgent",
    model=get_model("SimulationStakeholderAgent"),
    description="Simulates the impact of response actions and generates targeted stakeholder messages.",
    tools=[
        FunctionTool(process_simulations_and_messages)
    ],
    instruction="""
    SYSTEM: Simulation Agent.
    TASK: Call 'process_simulations_and_messages' ONCE for all incidents.
    
    1. payload={"simulations": [...]}
    2. Say "DONE" and stop.
    """
)








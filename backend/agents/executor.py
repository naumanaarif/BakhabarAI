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

async def process_simulations_and_messages(simulations: List[Dict[str, Any]] = None, **kwargs) -> str:
    """
    Commits your response impact simulations and multi-stakeholder notifications.
    """
    # Robust extraction
    data_list = simulations if simulations is not None else kwargs.get('simulations')

    if not data_list or not isinstance(data_list, list):
        print(f"DEBUG: SimulationAgent failed to provide simulations list. Got: {data_list}")
        return "ERROR: Expected a list of 'simulations'."

    results = []
    for sim in data_list:
        if not isinstance(sim, dict): continue
        
        incident_id = sim.get('incident_id') or sim.get('id')
        if not incident_id or incident_id == "null": continue
        
        # DEDUPING: Check for recent simulation (last 30 mins) to prevent duplicates
        from firebase_config import db
        from google.cloud.firestore_v1 import FieldFilter
        from datetime import datetime, timedelta
        
        recent = db.collection("action_simulations")\
            .where(filter=FieldFilter("incident_id", "==", incident_id))\
            .order_by("timestamp", direction="DESCENDING")\
            .limit(1).get()
            
        if recent:
            last_sim = recent[0].to_dict()
            ts = last_sim.get("timestamp")
            if ts and (datetime.now(ts.tzinfo) - ts).total_seconds() < 1800:
                print(f"DEBUG: Recent simulation for {incident_id} already exists. Skipping.")
                continue

        # Fuzzy Impact extraction (handle string vs object)
        impact = sim.get('impact') or {}
        if isinstance(impact, str):
            # If LLM sent a string, wrap it in a standard object
            impact = {
                'before_state': 'Unmanaged crisis state.',
                'after_state': impact,
                'improvement_metrics': {'response_time_reduction': '10 min', 'safety_boost': '20%'}
            }
        elif not isinstance(impact, dict):
            impact = {}

        # Ensure improvement metrics exist
        metrics = impact.get('improvement_metrics') or {}
        if not isinstance(metrics, dict): metrics = {}
        
        impact_payload = {
            'before_state': impact.get('before_state') or 'Pending emergency response.',
            'after_state': impact.get('after_state') or 'Resource deployment in progress.',
            'improvement_metrics': {
                'response_time_reduction': metrics.get('response_time_reduction') or '15 min',
                'safety_boost': metrics.get('safety_boost') or '30%'
            }
        }

        # Fuzzy Notifications extraction
        notif = sim.get('notifications') or {}
        if not isinstance(notif, dict): notif = {}
        
        # Handle cases where LLM uses "subject/message" instead of "public/hospitals/utility"
        msg = notif.get('message') or notif.get('body') or "Emergency response units dispatched."
        
        notifications_payload = {
            'public': notif.get('public') or msg,
            'hospitals': notif.get('hospitals') or f"Alert: {msg}",
            'utility_providers': notif.get('utility_providers') or "No immediate utility impact."
        }

        create_simulation_record(
            incident_id=incident_id,
            action_type=sim.get('action_type') or 'Crisis Response',
            description=sim.get('description') or 'Simulating impact of response...',
            impact=impact_payload,
            notifications=notifications_payload
        )
        results.append(incident_id)

    return json.dumps(results)



executor_agent = Agent(
    name="SimulationStakeholderAgent",
    model=get_model("SimulationStakeholderAgent"),
    description="Simulates the impact of response actions and generates targeted stakeholder messages.",
    tools=[
        FunctionTool(process_simulations_and_messages)
    ],
    instruction="""
    SYSTEM: Simulation Agent.
    TASK: Simulate impact. Call 'process_simulations_and_messages' IMMEDIATELY.

    RULES:
    1. Be concise. No preamble.
    2. USE JSON 'null', 'true', 'false'. NEVER Python 'None' or 'True'.
    3. 'impact' MUST be an object, NOT a string.
    4. 'notifications' MUST have: public, hospitals, utility_providers.
    5. Call tool ONCE and STOP.
    """
)





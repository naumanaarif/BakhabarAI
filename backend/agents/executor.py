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

async def process_simulations_and_messages(simulations: List[Dict[str, Any]], **kwargs) -> str:
    """
    Commits your response impact simulations and multi-stakeholder notifications.
    """
    if not simulations or not isinstance(simulations, list):
        return "ERROR: Expected a list of simulations."

    results = []
    for sim in simulations:
        incident_id = sim.get('incident_id') or sim.get('id')
        if not incident_id: continue
        
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
    You are the Simulation Agent. Analyze incidents and call 'process_simulations_and_messages'.

    EXAMPLE TOOL CALL:
    process_simulations_and_messages(simulations=[
      {
        "incident_id": "INC_123",
        "action_type": "Medical Dispatch",
        "description": "Ambulances sent via R-23 route.",
        "impact": {
          "before_state": "Traffic blocked, casualties high.",
          "after_state": "Medics on site, traffic diverted.",
          "improvement_metrics": {"response_time_reduction": "12m", "safety_boost": "40%"}
        },
        "notifications": {
          "public": "Avoid Super Highway.",
          "hospitals": "Multiple casualties incoming.",
          "utility_providers": "No power disruption."
        }
      }
    ])

    STRICT RULES:
    1. Call the tool ONCE.
    2. 'impact' MUST be an object, NOT a string.
    3. 'notifications' MUST have: public, hospitals, utility_providers.
    4. Stop after calling the tool.
    """
)



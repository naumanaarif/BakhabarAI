from typing import List, Dict, Any
from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from tools.firebase_tools import query_active_incidents, create_simulation_record
from tracer import tracer
from .model_config import get_model
import json

async def process_simulations_and_messages(simulations: list = None, **kwargs) -> str:
    """
    Commits your response impact simulations and multi-stakeholder notifications.
    """
    import re
    if simulations is None and "simulations" in kwargs:
        simulations = kwargs["simulations"]
    elif isinstance(simulations, str):
        try: simulations = json.loads(simulations).get("simulations", [])
        except: simulations = []

    if isinstance(simulations, dict) and "simulations" in simulations:
        simulations = simulations["simulations"]
    
    if not isinstance(simulations, (list, tuple)):
        return "ERROR: Expected a list of simulations."

    results = []
    for sim in simulations:
        if not isinstance(sim, dict): continue
        incident_id = sim.get('incident_id')
        if not incident_id: continue
        
        # Ensure notifications are never null for the UI
        notifs = sim.get('notifications', {})
        if not isinstance(notifs, dict): notifs = {}
        
        # UI Safety: Fill nulls with placeholder text
        if not notifs.get('public'): notifs['public'] = "Response plan activated."
        if not notifs.get('hospitals'): notifs['hospitals'] = "Normal operational status."
        if not notifs.get('utility_providers'): notifs['utility_providers'] = "No utility disruptions reported."

        create_simulation_record(
            incident_id=incident_id,
            action_type=sim.get('action_type', 'Response Optimization'),
            description=sim.get('description', 'Simulating impact...'),
            impact=sim.get('impact', {}),
            notifications=notifs
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
    You are the Simulation & Stakeholder Agent. Your ONLY job is to simulate impact and call 'process_simulations_and_messages' ONCE.

    REQUIRED JSON FORMAT:
    {
      "simulations": [
        {
          "incident_id": "INC_123",
          "action_type": "Public Alert & Medical Dispatch",
          "description": "Deployment of ambulances and traffic detours.",
          "impact": {
            "before_state": "High traffic congestion and unverified casualties.",
            "after_state": "Traffic diverted; 2 medical units on scene.",
            "improvement_metrics": { "response_time_reduction": "15 min", "safety_boost": "40%" }
          },
          "notifications": {
            "public": "AVOID Super Highway. Use alternative routes.",
            "hospitals": "Accident report: 2 units incoming. ETA 10 mins.",
            "utility_providers": "No power/water disruptions expected."
          }
        }
      ]
    }

    STRICT RULES:
    1. Call the process_simulations_and_messages tool.
    2. Pass the 'simulations' parameter exactly matching the JSON format above.
    3. Notifications MUST NEVER BE NULL. If no action is needed, write 'No specific action required' or 'Monitoring status'.
    4. Stop after calling the tool.
    """
)

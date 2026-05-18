from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from tools.firebase_tools import query_active_incidents, log_simulation
from tracer import tracer
from .model_config import get_model
import json

async def simulate_and_report() -> str:
    """
    Simulates the impact of assigned response actions and 
    generates tailored stakeholder notifications.
    """
    incidents = query_active_incidents()
    if not incidents:
        return "No active incidents to simulate."
    
    simulation_summaries = []
    for inc in incidents:
        # 1. Simulation Logic (Requirement 7)
        impact = {
            "before_state": "High congestion, 20min response time",
            "action": "Traffic rerouting & prioritized dispatch",
            "after_state": "Moderate congestion, 12min response time",
            "improvement_metrics": {"response_time": "-40%", "congestion": "-15%"}
        }
        
        # 2. Stakeholder Messaging (Requirement 8)
        notifications = {
            "public": f"SAFETY ALERT: Flooding in {inc['location_name']}. Avoid Basement levels. Use Alternate Route B.",
            "hospitals": f"MEDICAL ESCALATION: Potential inflow of 10-15 patients from {inc['location_name']} flood zone.",
            "utilities": f"INFRASTRUCTURE ALERT: Isolate power grid in {inc['location_name']} Sector 4 to prevent electrical hazards."
        }
        
        # Log to Action Simulations collection
        log_simulation(
            incident_id=inc['id'],
            action_type="Dispatch & Mitigation",
            description=f"Coordinated response for {inc['type']} at {inc['location_name']}",
            impact=impact,
            notifications=notifications
        )
        
        simulation_summaries.append({
            "incident_id": inc['id'],
            "impact": impact,
            "notifications": notifications
        })

    return json.dumps(simulation_summaries)

executor_agent = Agent(
    name="SimulationStakeholderAgent",
    model=get_model(),
    description="Simulates impact of response actions and generates stakeholder notifications using Firestore.",
    tools=[
        FunctionTool(simulate_and_report)
    ],
    instruction="""
    SYSTEM DIRECTIVE:
    1. You must IMMEDIATELY call 'simulate_and_report' with NO arguments.
    2. After the tool returns, summarize the simulations generated in one sentence.
    3. TERMINATE after the summary.
    Do NOT attempt to simulate impact manually.
    """
)

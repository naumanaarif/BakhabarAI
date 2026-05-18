from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from tools.firebase_tools import query_active_incidents, get_resources, assign_resource_to_incident
from tracer import tracer
from .model_config import get_model
import json

async def optimize_resources() -> str:
    """
    Analyzes active incidents and available resources, performs trade-offs,
    and updates Firestore allocations.
    """
    incidents = query_active_incidents()
    # Sort incidents by severity (HIGH > MEDIUM > LOW)
    incidents.sort(key=lambda x: x.get('severity', 'LOW') == 'HIGH', reverse=True)
    
    allocations = []
    trade_offs = []
    
    for inc in incidents:
        # Determine resource needs based on type/severity
        needed_type = "Medical" if inc['type'] in ["accident", "heatwave"] else "Fire"
        if inc['type'] == "urban_flooding": needed_type = "Water_Management"
        
        # Query available resources for this type
        available = get_resources(needed_type)
        
        if available:
            # Assign the first available resource
            res = available[0]
            assign_resource_to_incident(res['id'], inc['id'])
            allocations.append({
                "resource_name": res['name'],
                "incident_id": inc['id']
            })
        else:
            # Trade-off logic (Requirement 6)
            trade_offs.append(f"No {needed_type} units available for {inc['type']} at {inc['location_name']}. Prioritizing other active zones.")

    return json.dumps({"allocations": allocations, "trade_offs": trade_offs})

planner_agent = Agent(
    name="ResourcePlannerAgent",
    model=get_model(),
    description="Allocates constrained resources across detected crises and explains trade-offs using Firestore state.",
    tools=[
        FunctionTool(optimize_resources)
    ],
    instruction="""
    SYSTEM DIRECTIVE:
    1. You must IMMEDIATELY call 'optimize_resources' with NO arguments.
    2. After the tool returns, summarize the allocations and any trade-offs in one sentence.
    3. TERMINATE after the summary.
    Do NOT attempt to allocate resources manually.
    """
)

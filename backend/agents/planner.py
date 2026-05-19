from typing import List, Dict, Any
from pydantic import BaseModel

class ResourceAllocation(BaseModel):
    resource_id: str
    incident_id: str

class AllocationsPayload(BaseModel):
    allocations: List[ResourceAllocation]
    trade_offs: List[str]

from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from tools.firebase_tools import query_active_incidents, get_resources, assign_resource_to_incident
from tracer import tracer
from .model_config import get_model
import json

async def process_resource_allocations(allocations: List[Dict[str, Any]], trade_offs: List[str], **kwargs) -> str:
    """
    Commits your resource allocation decisions and trade-off rationale.
    """
    if not isinstance(allocations, list):
        return "ERROR: Expected a list of allocations."

    for c in allocations:
        # Fuzzy extraction
        resource_id = c.get('resource_id') or c.get('res_id') or c.get('resource')
        incident_id = c.get('incident_id') or c.get('inc_id') or c.get('incident')
            
        if resource_id and incident_id:
            try:
                assign_resource_to_incident(resource_id, incident_id)
            except Exception as e:
                print(f"DEBUG: Skipping invalid resource assignment {resource_id} -> {incident_id}: {e}")
    
    return json.dumps({"status": "success", "allocations_count": len(allocations), "trade_offs": trade_offs})

planner_agent = Agent(
    name="ResourcePlannerAgent",
    model=get_model("ResourcePlannerAgent"),
    description="Allocates constrained resources across detected crises and explains trade-offs.",
    tools=[
        FunctionTool(process_resource_allocations)
    ],
    instruction="""
    You are the Resource Planner Agent. Analyze crises and resources, then call 'process_resource_allocations'.

    STRICT JSON RULES:
    1. NEVER use Python literals like 'None', 'True', or 'False'.
    2. ALWAYS use JSON 'null', 'true', and 'false'.
    3. Ensure 'incident_id' matches the incident id from the input EXACTLY.
    4. Call the tool ONCE and stop.

    EXAMPLE:
    process_resource_allocations(
      allocations=[{ "resource_id": "RES_1", "incident_id": "INC_A" }],
      trade_offs=["Prioritized life safety."]
    )
    """
)




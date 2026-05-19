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

async def process_resource_allocations(allocations: List[Dict[str, Any]] = None, trade_offs: List[str] = None, **kwargs) -> str:
    """
    Commits your resource allocation decisions and trade-off rationale.
    """
    # Robust argument extraction
    data_allocs = allocations if allocations is not None else kwargs.get('allocations')
    data_trades = trade_offs if trade_offs is not None else kwargs.get('trade_offs', [])

    if not isinstance(data_allocs, list):
        print(f"DEBUG: ResourcePlannerAgent failed to provide allocations list. Got: {data_allocs}")
        return "ERROR: Expected a list of 'allocations'."

    results_count = 0
    for c in data_allocs:
        if not isinstance(c, dict): continue
        
        # Fuzzy extraction
        resource_id = c.get('resource_id') or c.get('res_id') or c.get('resource')
        incident_id = c.get('incident_id') or c.get('inc_id') or c.get('incident')
            
        if resource_id and incident_id:
            try:
                # DEDUPING: Check if this resource is already assigned to this incident
                from firebase_config import db
                inc_doc = db.collection("incidents").document(incident_id).get()
                if inc_doc.exists:
                    existing_res = inc_doc.to_dict().get("assigned_resources", [])
                    if resource_id in existing_res:
                        print(f"DEBUG: Resource {resource_id} already assigned to {incident_id}. Skipping.")
                        continue
                
                assign_resource_to_incident(resource_id, incident_id)
                results_count += 1
            except Exception as e:
                print(f"DEBUG: Skipping invalid resource assignment {resource_id} -> {incident_id}: {e}")
    
    return json.dumps({"status": "success", "allocations_count": results_count, "trade_offs": data_trades})


planner_agent = Agent(
    name="ResourcePlannerAgent",
    model=get_model("ResourcePlannerAgent"),
    description="Allocates constrained resources across detected crises and explains trade-offs.",
    tools=[
        FunctionTool(process_resource_allocations)
    ],
    instruction="""
    SYSTEM: Resource Planner Agent.
    TASK: Allocate resources. Call 'process_resource_allocations' IMMEDIATELY.

    RULES:
    1. Be concise. No preamble.
    2. USE JSON 'null', 'true', 'false'. NEVER Python 'None' or 'True'.
    3. Match resource types (Ambulance for Accident, etc).
    4. Ensure 'incident_id' matches input EXACTLY.
    5. Call tool ONCE and STOP.
    """
)





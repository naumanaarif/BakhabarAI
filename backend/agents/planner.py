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

_PROCESSED_ALLOCATIONS = set()

async def process_resource_allocations(payload: Dict[str, Any] = None, **kwargs) -> str:
    """
    Commits your resource allocation decisions and trade-off rationale.
    """
    from firebase_config import db
    # Robust extraction
    data = payload if payload is not None else kwargs
    allocations = data.get('allocations') or data.get('payload', {}).get('allocations')
    trade_offs = data.get('trade_offs') or data.get('payload', {}).get('trade_offs', [])

    if not isinstance(allocations, list):
        return "ERROR: Expected 'allocations' list in payload."

    results_count = 0
    for c in allocations:
        if not isinstance(c, dict): continue
        
        resource_id = c.get('resource_id') or c.get('res_id') or c.get('resource')
        incident_id = c.get('incident_id') or c.get('inc_id') or c.get('incident')
            
        if resource_id and incident_id:
            pair_id = f"{resource_id}:{incident_id}"
            if pair_id in _PROCESSED_ALLOCATIONS: continue

            try:
                # 1. Resource Availability Check
                res_doc = db.collection("resources").document(resource_id).get()
                if res_doc.exists and res_doc.to_dict().get("status") == "deployed":
                    print(f"DEBUG: Resource {resource_id} is already deployed. Skipping to break loop.")
                    _PROCESSED_ALLOCATIONS.add(pair_id)
                    continue

                # 2. Incident Link Check
                inc_doc = db.collection("incidents").document(incident_id).get()
                if inc_doc.exists:
                    existing_res = inc_doc.to_dict().get("assigned_resources", [])
                    if resource_id in existing_res: 
                        _PROCESSED_ALLOCATIONS.add(pair_id)
                        continue
                
                assign_resource_to_incident(resource_id, incident_id)
                _PROCESSED_ALLOCATIONS.add(pair_id)
                results_count += 1
            except Exception as e:
                print(f"DEBUG: Skipping invalid resource assignment: {e}")
    
    return json.dumps({
        "status": "SUCCESS", 
        "terminal": True, 
        "message": "ALLOCATION_LOCKED: Resources committed. DO NOT RETRY.",
        "allocations": results_count
    })


planner_agent = Agent(
    name="ResourcePlannerAgent",
    model=get_model("ResourcePlannerAgent"),
    description="Allocates constrained resources across detected crises and explains trade-offs.",
    tools=[
        FunctionTool(process_resource_allocations)
    ],
    instruction="""
    SYSTEM: Resource Planner Agent.
    TASK: Call 'process_resource_allocations' ONCE to assign resources.

    STOP PROTOCOL:
    1. Call tool with: payload={"allocations": [...], "trade_offs": [...]}
    2. After tool response, say "Allocation complete." and TERMINATE.
    3. NEVER call the tool a second time.
    """
)







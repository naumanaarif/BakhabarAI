from typing import List
from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from tools.firebase_tools import query_active_incidents, get_resources, assign_resource_to_incident
from tracer import tracer
from .model_config import get_model
import json

async def process_resource_allocations(payload: dict = None, **kwargs) -> str:
    """
    Commits your resource allocation decisions and trade-off rationale.
    """
    import re
    # Strip fictional tags
    def clean_arg(val):
        if isinstance(val, str):
            val = re.sub(r'<function=.*?>', '', val)
            val = re.sub(r'</function>', '', val)
        return val

    if payload is None:
        payload = kwargs
    elif isinstance(payload, str):
        try: payload = json.loads(payload)
        except: payload = {}

    allocations = payload.get("allocations", [])
    if isinstance(allocations, dict) and "allocations" in allocations:
        allocations = allocations["allocations"]

    trade_offs = payload.get("trade_offs", [])
    if isinstance(trade_offs, dict) and "trade_offs" in trade_offs:
        trade_offs = trade_offs["trade_offs"]
    
    if not isinstance(allocations, (list, tuple)):
        return "ERROR: Expected a list of allocations."

    for alloc in allocations:
        if not isinstance(alloc, dict): continue
        assign_resource_to_incident(clean_arg(alloc.get('resource_id')), clean_arg(alloc.get('incident_id')))
    
    return json.dumps({"status": "success", "allocations_count": len(allocations), "trade_offs": trade_offs})

planner_agent = Agent(
    name="ResourcePlannerAgent",
    model=get_model("ResourcePlannerAgent"),
    description="Allocates constrained resources across detected crises and explains trade-offs.",
    tools=[
        FunctionTool(process_resource_allocations)
    ],
    instruction="""
    You are the Resource Planner Agent. Your ONLY job is to allocate resources and call 'process_resource_allocations' ONCE.

    REQUIRED JSON FORMAT:
    {
      "payload": {
        "allocations": [
          { "resource_id": "RES_123", "incident_id": "INC_456" }
        ],
        "trade_offs": [
          "Prioritized the high-severity incident over the minor one."
        ]
      }
    }

    STRICT RULES:
    1. Call the process_resource_allocations tool.
    2. ONLY reason about the incidents provided in the current prompt. Do NOT mention 'floods' unless a flood is actually present.
    3. Match resources (e.g. Medical for accidents, Fire for wildfires).
    4. Pass the 'payload' parameter exactly matching the JSON format above.
    5. Stop after calling the tool.
    """
)

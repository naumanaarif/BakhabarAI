from typing import List
import json
from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from tools.firebase_tools import query_active_incidents, update_incident_details
from tracer import tracer
from .model_config import get_model

async def process_incident_classifications(payload: dict = None, **kwargs) -> str:
    """
    Commits your detailed crisis classification.
    """
    import re
    # DANGEROUS HALLUCINATION FIX: Strip any <function=...> tags if the AI nested them
    if payload is None:
        payload = kwargs
    elif isinstance(payload, str):
        try: payload = json.loads(payload)
        except: payload = {}

    classifications = payload.get("classifications", [])
    if isinstance(classifications, dict) and "classifications" in classifications:
        classifications = classifications["classifications"]
    
    if not isinstance(classifications, (list, tuple)):
        return "ERROR: Expected a list of classifications."

    results = []
    processed_ids = set()
    
    for cl in classifications:
        if not isinstance(cl, dict): continue
        incident_id = cl.pop('incident_id', cl.pop('id', None))
        if not incident_id or incident_id == "null" or incident_id in processed_ids:
            continue

        processed_ids.add(incident_id)
        
        # CLEANUP: Remove any nulls or "analyzing" strings
        clean_cl = {k: v for k, v in cl.items() if v is not None and v != "null" and v != "unknown"}
        
        # Ensure numeric values
        for k in ['affected_population', 'expected_duration_hours']:
            if k in clean_cl:
                try: clean_cl[k] = int(float(str(clean_cl[k])))
                except: del clean_cl[k]

        if clean_cl:
            update_incident_details(incident_id, clean_cl)
            results.append(incident_id)

    return json.dumps(results)

detector_agent = Agent(
    name="DetectorAgent",
    model=get_model("DetectorAgent"),
    description="Classifies crisis type and predicts severity and evolution.",
    tools=[
        FunctionTool(process_incident_classifications)
    ],
    instruction="""
    You are the Crisis Detector Agent. Your ONLY job is to analyze 'active_incidents' and call 'process_incident_classifications' ONCE.

    REQUIRED JSON FORMAT:
    {
      "payload": {
        "classifications": [
          {
            "id": "INCIDENT_ID_HERE",
            "type": "accident",
            "severity": "HIGH",
            "affected_population": 1500,
            "expected_duration_hours": 12,
            "evolution_prediction": {
              "duration_hours": 12,
              "peak_time": "2026-05-19T20:00:00",
              "spread_risk": "LOW"
            }
          }
        ]
      }
    }

    STRICT RULES:
    1. Call the process_incident_classifications tool.
    2. Pass the 'payload' parameter as an object exactly matching the format above.
    3. 'affected_population' MUST be a realistic estimate. NEVER use 0. If population is unknown, estimate at least 800 for urban areas.
    4. Stop after calling the tool.
    """
)

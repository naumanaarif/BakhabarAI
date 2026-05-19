from typing import List, Dict, Any, Optional
import json
from pydantic import BaseModel

class EvolutionPrediction(BaseModel):
    duration_hours: int
    peak_time: str
    spread_risk: str

class Classification(BaseModel):
    id: str
    type: str
    severity: str
    affected_population: int
    expected_duration_hours: int
    evolution_prediction: Optional[EvolutionPrediction] = None

class ClassificationsPayload(BaseModel):
    classifications: List[Classification]
from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from tools.firebase_tools import query_active_incidents, update_incident_details
from tracer import tracer
from .model_config import get_model

_PROCESSED_INCIDENTS = set()

async def process_incident_classifications(payload: Dict[str, Any] = None, **kwargs) -> str:
    """
    Commits your detailed crisis classification.
    """
    from firebase_config import db
    # Robust extraction
    data = payload if payload is not None else kwargs
    classifications = data.get('classifications') or data.get('payload', {}).get('classifications')
    
    if not classifications or not isinstance(classifications, list):
        return "ERROR: Expected 'classifications' list in payload."

    results = []
    
    for cl in classifications:
        if not isinstance(cl, dict): continue
        
        incident_id = cl.get('id') or cl.get('incident_id')
        if not incident_id or incident_id == "null": continue
        
        # 1. SESSION CACHE
        if incident_id in _PROCESSED_INCIDENTS:
            print(f"DEBUG: Detector: Incident {incident_id} already processed in session.")
            continue

        # 2. DATABASE LOOP BREAKER
        doc = db.collection("incidents").document(incident_id).get()
        if doc.exists:
            inc_data = doc.to_dict()
            # If affected_population is already > 0, it means it was already classified
            if inc_data.get("affected_population", 0) > 0:
                print(f"DEBUG: Detector: Incident {incident_id} already has classification. Skipping to break loop.")
                _PROCESSED_INCIDENTS.add(incident_id)
                continue

        inc_type = cl.get('type') or cl.get('incident_type') or 'emergency'
        severity = cl.get('severity') or 'MEDIUM'
        pop = cl.get('affected_population') or cl.get('population') or 800
        duration = cl.get('expected_duration_hours') or cl.get('duration') or 12

        evo = cl.get('evolution_prediction') or {}
        if not isinstance(evo, dict): evo = {}
        
        peak_time = evo.get('peak_time') or cl.get('peak_time') or "2026-05-19T20:00:00"
        spread = evo.get('spread_risk') or cl.get('spread_risk') or "LOW"
        evo_duration = evo.get('duration_hours') or cl.get('duration_hours') or duration

        clean_cl = {
            'type': str(inc_type).lower(),
            'severity': str(severity).upper(),
            'affected_population': int(float(str(pop))),
            'expected_duration_hours': int(float(str(duration))),
            'evolution_prediction': {
                'duration_hours': int(float(str(evo_duration))),
                'peak_time': str(peak_time),
                'spread_risk': str(spread).upper()
            }
        }

        update_incident_details(incident_id, clean_cl)
        _PROCESSED_INCIDENTS.add(incident_id)
        results.append(incident_id)

    return json.dumps({
        "status": "SUCCESS", 
        "terminal": True, 
        "message": "CLASSIFICATION_LOCKED: Data committed. DO NOT RETRY.",
        "classified_ids": results
    })


detector_agent = Agent(
    name="DetectorAgent",
    model=get_model("DetectorAgent"),
    description="Classifies crisis type and predicts severity and evolution.",
    tools=[
        FunctionTool(process_incident_classifications)
    ],
    instruction="""
    SYSTEM: Crisis Detector Agent.
    TASK: Call 'process_incident_classifications' ONCE for ALL active incidents.

    STOP PROTOCOL:
    1. Call tool with: payload={"classifications": [...]}
    2. After tool response, say "Classification complete." and TERMINATE.
    3. NEVER call the tool a second time.
    """
)







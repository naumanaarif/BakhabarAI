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

async def process_incident_classifications(classifications: List[Dict[str, Any]], **kwargs) -> str:
    """
    Commits your detailed crisis classification.
    """
    if not classifications or not isinstance(classifications, list):
        return "ERROR: Expected a list of classifications."

    results = []
    processed_ids = set()
    
    for cl in classifications:
        # Fuzzy extraction: handle different key names the LLM might hallucinate
        incident_id = cl.get('id') or cl.get('incident_id')
        if not incident_id or incident_id == "null" or incident_id in processed_ids:
            continue
        processed_ids.add(incident_id)

        # Extract type, severity, population
        inc_type = cl.get('type') or cl.get('incident_type') or 'emergency'
        severity = cl.get('severity') or 'MEDIUM'
        pop = cl.get('affected_population') or cl.get('population') or 800
        duration = cl.get('expected_duration_hours') or cl.get('duration') or 12

        # Extract evolution prediction (nested or flat)
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
    You are the Crisis Detector Agent. Analyze 'active_incidents' and call 'process_incident_classifications'.

    EXAMPLE TOOL CALL:
    process_incident_classifications(classifications=[
      {
        "id": "INC_123",
        "type": "flood",
        "severity": "HIGH",
        "affected_population": 1500,
        "expected_duration_hours": 24,
        "evolution_prediction": {
          "duration_hours": 24,
          "peak_time": "2026-05-19T20:00:00",
          "spread_risk": "MEDIUM"
        }
      }
    ])

    STRICT RULES:
    1. Call the tool ONCE.
    2. 'affected_population' MUST be > 500 for urban areas.
    3. Stop after calling the tool.
    """
)



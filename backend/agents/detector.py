from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from tools.firebase_tools import query_active_incidents, update_incident_details
from tracer import tracer
from .model_config import get_model
import json

async def classify_and_predict() -> str:
    """
    Fetches active incidents from Firestore, classifies them, 
    and predicts their evolution and impact.
    """
    incidents = query_active_incidents()
    if not incidents:
        return "No active incidents to classify."
    
    classification_results = []
    for inc in incidents:
        # Get current confidence or default to 0.5
        current_confidence = inc.get('confidence_score', 0.5)
        
        # Simulation logic: Detector verification adds to confidence
        # but doesn't necessarily jump to 100% instantly
        verified_confidence = min(0.98, current_confidence + 0.15)
        
        # Intelligent classification based on location or existing data
        loc_name = inc.get('location_name', '').lower()
        if 'margalla' in loc_name:
            predicted_type = 'wildfire'
            severity = 'HIGH'
            population = 5000
        elif 'i-8' in loc_name or 'heat' in inc.get('type', '').lower():
            predicted_type = 'heatwave'
            severity = 'MEDIUM'
            population = 25000
        else:
            predicted_type = "urban_flooding" if inc.get('type') == 'unknown' else inc['type']
            severity = "HIGH"
            population = 15000
        
        evolution = {
            "expected_duration_hours": 12 if predicted_type == 'wildfire' else 8,
            "peak_impact_time": "2024-01-15T20:00:00Z",
            "spread_risk": "HIGH" if predicted_type == 'wildfire' else "MEDIUM",
            "uncertainty_range": "+/- 2 hours"
        }
        
        update_data = {
            "type": predicted_type,
            "severity": severity,
            "affected_population": population,
            "evolution_prediction": evolution,
            "confidence_score": verified_confidence
        }
        
        update_incident_details(inc['id'], update_data)
        classification_results.append({
            "incident_id": inc['id'],
            "type": predicted_type,
            "severity": severity
        })

    return json.dumps(classification_results)

detector_agent = Agent(
    name="DetectorAgent",
    model=get_model(),
    description="Classifies crisis type and predicts severity and evolution using Firestore state.",
    tools=[
        FunctionTool(classify_and_predict)
    ],
    instruction="""
    SYSTEM DIRECTIVE:
    1. You must IMMEDIATELY call 'classify_and_predict' with NO arguments.
    2. After the tool returns, summarize the number of incidents classified in one sentence.
    3. TERMINATE after the summary.
    Do NOT attempt to classify incidents without using the tool.
    """
)

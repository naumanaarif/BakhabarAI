import json
from pydantic import BaseModel, Field
from typing import List, Optional

class NewIncidentData(BaseModel):
    type: str = Field(description="Type of the incident (e.g. accident, flood)")
    severity: str = Field(description="Severity (LOW, MEDIUM, HIGH)")
    location_name: str = Field(description="Name of the location")

class SignalEvaluation(BaseModel):
    signal_id: str
    status: str
    credibility: float
    incident_id: Optional[str] = None
    new_incident_data: Optional[NewIncidentData] = None

class EvaluationsPayload(BaseModel):
    evaluations: List[SignalEvaluation]

from typing import List, Dict, Any
from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from tools.firebase_tools import (
    get_pending_signals, 
    verify_signal, 
    query_active_incidents, 
    create_incident,
    update_incident_details
)
from tracer import tracer
from .model_config import get_model


async def process_signal_evaluations(evaluations: List[SignalEvaluation], **kwargs) -> str:
    """
    Commits analysis of emergency signals. 
    """
    from services.firebase_service import FirebaseService
    from firebase_config import db
    import google.cloud.firestore as firestore

    results = []
    processed_signal_ids = set()

    # Robust handling for different input formats (Pydantic models or raw dicts)
    data_list = evaluations if isinstance(evaluations, (list, tuple)) else []
    
    for ev in data_list:
        signal_id = None
        incident_id = None
        status = 'noise'
        credibility = 0.5
        new_data = None
        
        if hasattr(ev, 'signal_id'):
            signal_id = ev.signal_id
            incident_id = getattr(ev, 'incident_id', None)
            status = getattr(ev, 'status', 'noise')
            credibility = float(getattr(ev, 'credibility', 0.5))
            new_data = getattr(ev, 'new_incident_data', None)
        elif isinstance(ev, dict):
            signal_id = ev.get('signal_id')
            incident_id = ev.get('incident_id')
            status = ev.get('status', 'noise')
            credibility = float(ev.get('credibility', 0.5))
            new_data = ev.get('new_incident_data')

        if not signal_id or signal_id in processed_signal_ids:
            continue
        processed_signal_ids.add(signal_id)
        
        print(f"DEBUG: Processing evaluation for signal {signal_id} with status {status}")
        
        # If signal is verified
        if status == 'verified':
            # 1. CONFIDENCE BOOST: If incident exists, increment confidence
            if incident_id and incident_id != "null" and incident_id != "None":
                print(f"DEBUG: Boosting confidence for existing incident {incident_id}")
                inc_ref = db.collection("incidents").document(incident_id)
                inc_doc = inc_ref.get()
                if inc_doc.exists:
                    current_conf = float(inc_doc.to_dict().get("confidence_score", 0.3))
                    # Boost confidence: new_conf = current + (1 - current) * 0.4
                    new_conf = round(min(0.99, current_conf + (1.0 - current_conf) * 0.4), 2)
                    inc_ref.update({"confidence_score": new_conf, "last_updated": firestore.SERVER_TIMESTAMP})
                    print(f"DEBUG: New confidence for {incident_id}: {new_conf}")
            
            # 2. CREATE NEW: If no incident_id, create new one
            else:
                if not new_data: 
                    # Attempt recovery
                    signal = FirebaseService.get_signal_by_id(signal_id)
                    source = signal.get("source_type", "social") if signal else "social"
                    if source == "social": source = "Citizen Report"
                    
                    incident_id = create_incident(
                        incident_type="emergency",
                        severity="MEDIUM",
                        confidence=credibility,
                        location_name="Unknown",
                        lat=33.6844,
                        lng=73.0479,
                        signal_source=source
                    )
                else:
                    # Robust extraction from new_data
                    if hasattr(new_data, 'type'):
                        inc_type = new_data.type
                        inc_sev = new_data.severity
                        inc_loc = new_data.location_name
                    elif isinstance(new_data, dict):
                        inc_type = new_data.get('type', 'emergency')
                        inc_sev = new_data.get('severity', 'MEDIUM')
                        inc_loc = new_data.get('location_name', 'Unknown')
                    else:
                        inc_type, inc_sev, inc_loc = 'emergency', 'MEDIUM', 'Unknown'
                    
                    incident_id = create_incident(
                        incident_type=inc_type,
                        severity=inc_sev,
                        confidence=credibility,
                        location_name=inc_loc,
                        lat=33.6844,
                        lng=73.0479,
                        signal_source="Citizen Report"
                    )
                print(f"DEBUG: Created NEW incident {incident_id} for signal {signal_id}")
        
        verify_signal(signal_id, credibility, status, incident_id)
        results.append({"signal_id": signal_id, "incident_id": incident_id})
    
    return json.dumps(results)

signal_collector_agent = Agent(
    name="SignalFusionAgent",
    model=get_model("SignalFusionAgent"),
    description="Fuses multi-source signals and manages incident initialization.",
    tools=[
        FunctionTool(process_signal_evaluations)
    ],
    instruction="""
    You are the Signal Fusion Agent. Analyze 'pending_signals' and call 'process_signal_evaluations'.

    STRICT JSON RULES:
    1. NEVER use Python literals like 'None', 'True', or 'False'.
    2. ALWAYS use JSON 'null', 'true', and 'false'.
    3. Ensure 'signal_id' matches the input EXACTLY.
    4. Call the tool ONCE and stop.

    EXAMPLE:
    process_signal_evaluations(evaluations=[
      {
        "signal_id": "SIG_123",
        "status": "verified",
        "credibility": 0.85,
        "incident_id": "INC_456",
        "new_incident_data": null
      }
    ])
    """
)



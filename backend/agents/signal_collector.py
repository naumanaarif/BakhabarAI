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


# Module-level cache to prevent re-processing in a single execution flow
_ALREADY_PROCESSED_SIGNALS = set()

async def process_signal_evaluations(payload: Dict[str, Any] = None, **kwargs) -> str:
    """
    Commits analysis of emergency signals. 
    """
    from services.firebase_service import FirebaseService
    from firebase_config import db
    import google.cloud.firestore as firestore

    results = []
    
    # Robust extraction
    data = payload if payload is not None else kwargs
    evaluations = data.get('evaluations') or data.get('payload', {}).get('evaluations')
    if not isinstance(evaluations, (list, tuple)): evaluations = []
    
    for ev in evaluations:
        if not isinstance(ev, dict): continue
        
        signal_id = ev.get('signal_id')
        if not signal_id: continue
        
        # 1. SESSION LEVEL DEDUPLICATION
        if signal_id in _ALREADY_PROCESSED_SIGNALS:
            print(f"DEBUG: Signal {signal_id} already processed in this session. Skipping.")
            continue
        
        # 2. DATABASE LEVEL DEDUPLICATION (The ultimate loop breaker)
        signal_doc = db.collection("signals").document(signal_id).get()
        if signal_doc.exists:
            current_status = signal_doc.to_dict().get("status")
            if current_status in ["verified", "noise", "processed"]:
                print(f"DEBUG: Signal {signal_id} is already '{current_status}'. Skipping to break loop.")
                _ALREADY_PROCESSED_SIGNALS.add(signal_id)
                continue

        # Process the evaluation
        incident_id = ev.get('incident_id')
        status = ev.get('status', 'noise')
        if status not in ['verified', 'noise']:
            status = 'verified' if status in ['matched', 'active', 'linked', 'evaluated'] else 'noise'
            
        credibility = float(ev.get('credibility', 0.5))
        new_data = ev.get('new_incident_data')

        print(f"!!! [LOOP_BREAKER] Committing Signal Evaluation: {signal_id} -> {status} !!!")
        
        if status == 'verified':
            # --- Read signal location + metadata from Firestore ---
            _sig_lat, _sig_lng = 33.6844, 73.0479  # fallback: Islamabad
            _sig_meta = {}
            try:
                _sig_doc = db.collection("signals").document(signal_id).get()
                if _sig_doc.exists:
                    _geo = _sig_doc.to_dict().get("location")
                    if hasattr(_geo, 'latitude'):
                        _sig_lat, _sig_lng = _geo.latitude, _geo.longitude
                    _sig_meta = _sig_doc.to_dict().get("metadata") or {}
            except Exception as _e:
                print(f"DEBUG: Could not read signal location for {signal_id}: {_e}")

            if incident_id and incident_id not in ("null", "None", ""):
                # PATH A: Signal is linked to an existing incident → boost confidence
                inc_ref = db.collection("incidents").document(incident_id)
                inc_doc = inc_ref.get()
                if inc_doc.exists:
                    current_conf = float(inc_doc.to_dict().get("confidence_score", 0.3))
                    new_conf = round(min(0.99, current_conf + (1.0 - current_conf) * 0.4), 2)
                    inc_ref.update({"confidence_score": new_conf, "last_updated": firestore.SERVER_TIMESTAMP})
                    print(f"DEBUG: Boosted confidence of incident {incident_id} to {new_conf}")

            elif new_data and isinstance(new_data, dict):
                # PATH B: New signal with type/severity/location → create incident
                inc_type = str(new_data.get('type') or 'emergency').lower()
                inc_sev  = str(new_data.get('severity') or 'MEDIUM').upper()
                inc_loc  = (
                    str(new_data.get('location_name') or '')
                    or _sig_meta.get('location_name')
                    or 'Islamabad'
                )
                incident_id = create_incident(
                    incident_type=inc_type,
                    severity=inc_sev,
                    confidence=credibility,
                    location_name=inc_loc,
                    lat=_sig_lat,
                    lng=_sig_lng,
                    signal_source=_sig_meta.get('source_type', 'Signal Feed'),
                )
                print(f"DEBUG: Created incident {incident_id} ({inc_type}/{inc_sev}) at {inc_loc}")

            else:
                # PATH C: Verified but no actionable data → log and mark noise
                print(f"DEBUG: Signal {signal_id} verified but no incident mapping or data provided. Skipping incident creation.")
                status = 'noise'
        
        verify_signal(signal_id, credibility, status, incident_id)
        _ALREADY_PROCESSED_SIGNALS.add(signal_id)
        results.append({"signal_id": signal_id, "incident_id": incident_id})
    
    return json.dumps({
        "status": "SUCCESS", 
        "terminal": True, 
        "message": "DATA_LOCKED_PERMANENTLY: ALL signals committed. DO NOT CALL AGAIN.",
        "processed": len(results)
    })


signal_collector_agent = Agent(
    name="SignalFusionAgent",
    model=get_model("SignalFusionAgent"),
    description="Fuses multi-source signals and manages incident initialization.",
    tools=[
        FunctionTool(process_signal_evaluations)
    ],
    instruction="""
    SYSTEM: Signal Fusion Agent.
    TASK: Call 'process_signal_evaluations' ONCE for ALL signals.
    
    1. payload={"evaluations": [...]}
    2. After calling, say "DONE" and stop.
    """
)







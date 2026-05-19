import json
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


async def process_signal_evaluations(evaluations: list = None, **kwargs) -> str:
    """
    Commits analysis of emergency signals. 
    """
    from services.firebase_service import FirebaseService
    from firebase_config import db
    import google.cloud.firestore as firestore

    results = []
    processed_signal_ids = set()

    if evaluations is None and "evaluations" in kwargs:
        evaluations = kwargs["evaluations"]
    elif isinstance(evaluations, str):
        try: evaluations = json.loads(evaluations).get("evaluations", [])
        except: evaluations = []

    data_list = evaluations
    if isinstance(data_list, dict) and "evaluations" in data_list:
        data_list = data_list["evaluations"]
    
    if not isinstance(data_list, (list, tuple)):
        return "ERROR: Expected a list of evaluations."

    for ev in data_list:
        if not isinstance(ev, dict): continue
        signal_id = ev.get('signal_id') or ev.get('id')
        if not signal_id or signal_id in processed_signal_ids:
            continue
            
        processed_signal_ids.add(signal_id)
        incident_id = ev.get('incident_id')
        status = ev.get('status', 'noise')
        credibility = float(ev.get('credibility', 0.5))
        
        print(f"DEBUG: Processing evaluation for signal {signal_id} with status {status}")
        
        # If signal is verified
        if status == 'verified':
            # 1. CONFIDENCE BOOST: If incident exists, increment confidence
            if incident_id and incident_id != "null":
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
                inc_data = ev.get('new_incident_data')
                if not inc_data or not isinstance(inc_data, dict): 
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
                    incident_id = create_incident(
                        incident_type=inc_data.get('type', 'emergency'),
                        severity=inc_data.get('severity', 'MEDIUM'),
                        confidence=credibility,
                        location_name=inc_data.get('location_name', 'Unknown'),
                        lat=inc_data.get('lat', 33.6844),
                        lng=inc_data.get('lng', 73.0479),
                        signal_source=inc_data.get('source_type', 'Citizen Report')
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
    You are the Signal Fusion Agent. Your ONLY job is to analyze 'pending_signals' and call 'process_signal_evaluations' ONCE.

    REQUIRED JSON FORMAT:
    {
      "evaluations": [
        {
          "signal_id": "SIGNAL_ID_HERE",
          "status": "verified",
          "credibility": 0.85,
          "incident_id": "EXISTING_INCIDENT_ID_OR_NULL",
          "new_incident_data": {
            "type": "accident",
            "severity": "HIGH",
            "location_name": "Karachi"
          }
        }
      ]
    }

    STRICT RULES:
    1. Call the process_signal_evaluations tool.
    2. Pass the 'evaluations' parameter as a list of objects exactly matching the format above.
    3. Use JSON 'null' for missing values. NEVER use Python 'None'.
    4. Stop after calling the tool.
    """
)

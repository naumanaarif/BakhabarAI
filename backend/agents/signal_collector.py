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
import json

async def fuse_and_verify_signals() -> str:
    """
    Ingests pending signals from Firestore, evaluates credibility, 
    handles contradictions, and creates/updates incidents.
    """
    signals = get_pending_signals()
    if not signals:
        return "No new signals to process."

    active_incidents = query_active_incidents()
    
    results = []
    for signal in signals:
        # Evaluate signal (This would normally be an LLM-driven internal step, 
        # but we expose it via the tool's reasoning trace)
        credibility = 0.8  # Default baseline
        status = "verified"
        
        # Check for contradictions (Requirement 5/10)
        # Example: If a sensor contradicts social media
        if signal['source_type'] == 'sensor' and signal['content'].lower().find('normal') != -1:
            # If we already have an active incident nearby based on social reports
            # this sensor might be the 'truth' that marks it as a false alarm
            status = "contradicted"
            credibility = 1.0

        location_name = signal.get('location_name') or signal.get('metadata', {}).get('location_name') or 'Unknown'
        
        # Create/Update Incident logic
        incident_id = None
        # Simple spatial grouping for prototype (approximate same location)
        for inc in active_incidents:
            if inc.get('location_name') == location_name:
                incident_id = inc['id']
                break
        
        if not incident_id and status == "verified":
            incident_id = create_incident(
                incident_type="unknown", # To be refined by DetectorAgent
                severity="MEDIUM",
                confidence=0.5,
                location_name=location_name,
                lat=signal['location'].latitude,
                lng=signal['location'].longitude,
                signal_source=signal['source_type']
            )
        elif incident_id and status == "verified":
            # If incident exists, update its confidence and sources via create_incident logic
            create_incident(
                incident_type="unknown",
                severity="MEDIUM",
                confidence=0.5,
                location_name=location_name,
                lat=signal['location'].latitude,
                lng=signal['location'].longitude,
                signal_source=signal['source_type']
            )
        
        # Update the signal in Firestore
        verify_signal(signal['id'], credibility, status, incident_id)
        
        results.append({
            "signal_id": signal['id'],
            "status": status,
            "incident_id": incident_id
        })

    return json.dumps(results)

signal_collector_agent = Agent(
    name="SignalFusionAgent",
    model=get_model(),
    description="Fuses multi-source signals, evaluates credibility, and manages incident initialization.",
    tools=[
        FunctionTool(fuse_and_verify_signals)
    ],
    instruction="""
    SYSTEM DIRECTIVE: 
    1. You must IMMEDIATELY call 'fuse_and_verify_signals' with NO arguments.
    2. After the tool returns, summarize the 'processed' count from the output in one sentence.
    3. TERMINATE after the summary. 
    Do NOT search for more signals. Do NOT attempt to verify signals manually.
    """
)

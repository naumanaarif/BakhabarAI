from fastapi import APIRouter
from typing import List
from agents.pipeline import run_crisis_simulation
from tracer import tracer
from services.firebase_service import FirebaseService
import asyncio

router = APIRouter(prefix="/api")

@router.get("/incidents")
async def get_incidents():
    """Fetches active incidents from Firestore."""
    incidents = FirebaseService.get_active_incidents()
    # Normalize GeoPoint to lat/lng for JSON serialization
    for inc in incidents:
        if 'location' in inc:
            inc['location'] = {
                "lat": inc['location'].latitude,
                "lng": inc['location'].longitude
            }
    return {"incidents": incidents}

@router.get("/incidents/{id}")
async def get_incident_detail(id: str):
    """Fetches a specific incident from Firestore."""
    # We can add a get_incident_by_id to FirebaseService if needed
    # For now, let's just filter the active ones
    incidents = FirebaseService.get_active_incidents()
    for inc in incidents:
        if inc['id'] == id:
            if 'location' in inc:
                inc['location'] = {
                    "lat": inc['location'].latitude,
                    "lng": inc['location'].longitude
                }
            return inc
    return {"error": "Incident not found"}

@router.post("/report")
async def submit_report(report: dict):
    """Adds a new signal to Firestore."""
    FirebaseService.add_signal(
        source_type="social",
        content=report.get("message", "User Report"),
        lat=report.get("lat", 33.6844),
        lng=report.get("lng", 73.0479),
        metadata={"user_report": True}
    )
    return {"status": "success", "message": "Incident report submitted to Firestore signals."}

@router.post("/run-scenario")
async def run_scenario(scenario: dict = None):
    """Triggers the agent pipeline to process Firestore state."""
    tracer.clear()
    
    try:
        # Run the agent pipeline
        result = await run_crisis_simulation(scenario)
        
        return {
            "status": "success",
            "result": result,
            "traces": tracer.get_traces()
        }
    except Exception as e:
        import traceback
        error_msg = str(e)
        stack_trace = traceback.format_exc()
        
        tracer.log(
            agent_name="System",
            action="simulation_error",
            input_data={"scenario": scenario},
            output_data={"error": error_msg, "traceback": stack_trace},
            confidence=0.0
        )
        return {
            "status": "error",
            "message": error_msg
        }

@router.get("/logs")
async def get_logs():
    """Fetches recent agent traces from the tracer instance."""
    return {
        "traces": tracer.get_traces()
    }

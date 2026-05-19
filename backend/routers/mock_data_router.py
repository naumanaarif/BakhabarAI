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
    """Adds a new signal to Firestore and triggers the agent pipeline."""
    from tools.maps_tool import geocode
    
    message = report.get("message", "User Report")
    req_lat = report.get("lat")
    req_lng = report.get("lng")
    
    print(f"🚀 [BACKEND] Received report: {message}")
    print(f"DEBUG: Request coordinates: {req_lat}, {req_lng}")
    
    # Extract location name (everything before the first colon, or try to find keywords)
    location_name = "Islamabad"
    if ":" in message:
        location_name = message.split(":", 1)[0].strip()
    elif " in " in message.lower():
        # "Flood in G-10" -> "G-10"
        location_name = message.lower().split(" in ", 1)[1].strip()
        # Clean up common suffixes
        location_name = location_name.split("!")[0].split(".")[0].strip()
    elif " at " in message.lower():
        location_name = message.lower().split(" at ", 1)[1].strip()
        location_name = location_name.split("!")[0].split(".")[0].strip()
        
    print(f"DEBUG: Extracted potential location: {location_name}")
    
    # Geocode the location name to get coordinates
    coords = await geocode(location_name)
    lat = coords.get("lat")
    lng = coords.get("lng")
    
    # If geocoding failed or returned default, but request has non-default coordinates, use request ones
    # (Islamabad default is 33.6844, 73.0479)
    is_default = (req_lat == 33.6844 and req_lng == 73.0479)
    if (not lat or not lng or lat == 33.6844) and not is_default:
        lat = req_lat
        lng = req_lng
        print(f"DEBUG: Using request coordinates as fallback: {lat}, {lng}")
    
    # Final fallback if everything is missing
    lat = lat or 33.6844
    lng = lng or 73.0479
    
    print(f"DEBUG: Final signal coordinates: {lat}, {lng}")
    
    metadata = {"user_report": True, "location_name": location_name}
    if "media_url" in report:
        metadata["media_url"] = report["media_url"]

    # Extract incident type from message (format: "Location: Type - Description")
    inc_type = "emergency"
    if ":" in message and " - " in message:
        try:
            inc_type = message.split(":")[1].split("-")[0].strip().lower()
        except:
            pass
    elif "accident" in message.lower(): inc_type = "accident"
    elif "flood" in message.lower(): inc_type = "flood"
    elif "fire" in message.lower(): inc_type = "fire"

    # 1. Create a "Preliminary" Incident immediately so it shows on the Dashboard
    from tools.firebase_tools import create_incident
    
    preliminary_incident_id = create_incident(
        incident_type=inc_type,
        severity="MEDIUM", # Default
        confidence=0.3,    # Low initial confidence for single report
        location_name=location_name,
        lat=lat,
        lng=lng,
        signal_source="Citizen Report"
    )
    print(f"DEBUG: Created preliminary incident {preliminary_incident_id} for immediate dashboard display.")

    # 2. Save signal in Firestore and associate with the new incident
    signal_id = FirebaseService.add_signal(
        source_type="social",
        content=message,
        lat=lat,
        lng=lng,
        metadata={**metadata, "trigger_type": "manual", "incident_id": preliminary_incident_id}
    )
    
    # 3. Run pipeline to refine the incident
    asyncio.create_task(run_crisis_simulation(scenario_data={
        "trigger_type": "manual", 
        "target_signal_id": signal_id,
        "existing_incident_id": preliminary_incident_id
    }))
    
    return {"status": "success", "message": "Incident report submitted and agent pipeline started."}


@router.post("/run-scenario")
async def run_scenario(scenario: dict = None):
    """
    Triggers the agent pipeline for a stress test scenario.
    Ensures it only processes mock/scenario data.
    """
    print(f"🚀 [BACKEND] Received request to run scenario: {scenario}")
    tracer.clear()
    
    # Force the trigger type to 'mock' for isolation
    scenario = scenario or {}
    scenario["trigger_type"] = "mock"
    
    try:
        # Run the agent pipeline in mock isolation mode
        result = await run_crisis_simulation(scenario_data=scenario)
        
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

@router.get("/places/autocomplete")
async def places_autocomplete(q: str):
    """Fetches location suggestions using Google Places API."""
    from tools.maps_tool import get_places_autocomplete
    result = await get_places_autocomplete(q)
    return result

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

    # Write media_url directly to the incident if provided — don't wait for pipeline propagation
    report_media_url = report.get("media_url") or metadata.get("media_url")
    if report_media_url and preliminary_incident_id:
        try:
            from firebase_config import db
            db.collection("incidents").document(preliminary_incident_id).update({"media_url": report_media_url})
            print(f"DEBUG: Attached media_url to incident {preliminary_incident_id}")
        except Exception as e:
            print(f"WARN: Could not attach media_url: {e}")

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
    Seeds mock Islamabad incidents directly into Firestore so all pipeline
    stages have real data to process.
    """
    from tools.firebase_tools import create_incident, query_active_incidents
    import json

    print("="*60)
    print("[SCENARIO] /api/run-scenario called")
    print(f"[SCENARIO] Payload: {json.dumps(scenario or {})[:200]}")
    print("="*60, flush=True)

    tracer.clear()
    scenario = scenario or {}
    scenario["trigger_type"] = "mock"

    # ── Seed incidents into Firestore so the pipeline has data ──────────
    # These are hardcoded demo incidents for Islamabad.
    # The pipeline Stages 2-5 will then classify, plan, simulate them.
    SEED_INCIDENTS = [
        {
            "type": "flood",
            "severity": "HIGH",
            "confidence": 0.5,
            "location_name": "G-10, Islamabad",
            "lat": 33.6938,
            "lng": 73.0213,
            "signal_source": "Stress Test",
        },
        {
            "type": "heatwave",
            "severity": "MEDIUM",
            "confidence": 0.5,
            "location_name": "I-8, Islamabad",
            "lat": 33.6761,
            "lng": 73.0651,
            "signal_source": "Stress Test",
        },
    ]

    seeded_ids = []
    for inc in SEED_INCIDENTS:
        try:
            inc_id = create_incident(**inc)
            seeded_ids.append(inc_id)
            print(f"[SCENARIO] Seeded incident {inc_id} — {inc['type']} @ {inc['location_name']}")
            tracer.log(
                agent_name="System",
                action=f"Seeded mock incident: {inc['type'].upper()} at {inc['location_name']}",
                input_data={"type": inc["type"], "severity": inc["severity"]},
                output_data={"id": inc_id},
                confidence=1.0,
            )
        except Exception as e:
            print(f"[SCENARIO] Failed to seed incident: {e}")

    # Verify seeds are visible
    active = query_active_incidents()
    print(f"[SCENARIO] Active incidents after seeding: {len(active)}")

    # ── Launch pipeline in background (non-blocking) ──
    # Return 202 immediately so the app doesn't freeze.
    # The pipeline runs async; results appear live in Firestore / agent logs.
    import asyncio

    async def _run_pipeline_bg():
        try:
            await run_crisis_simulation(scenario_data=scenario)
        except Exception as bg_err:
            print(f"[SCENARIO] Background pipeline error: {bg_err}")

    asyncio.create_task(_run_pipeline_bg())

    return {
        "status": "started",
        "message": f"Stress test pipeline launched in background. {len(seeded_ids)} incidents seeded.",
        "incidents_seeded": len(seeded_ids),
        "incidents_seeded_ids": seeded_ids,
    }

@router.get("/logs")
async def get_logs():
    """Fetches recent agent traces from the tracer instance."""
    traces = tracer.get_traces()
    print(f"[API] /api/logs — returning {len(traces)} trace entries")
    return {
        "count": len(traces),
        "traces": traces
    }

@router.get("/debug/ping")
async def debug_ping():
    """Health check + tracer state. Use this to verify server is alive."""
    traces = tracer.get_traces()
    return {
        "status": "ok",
        "tracer_entries": len(traces),
        "last_trace": traces[-1] if traces else None
    }

@router.delete("/debug/logs")
async def clear_logs():
    """Clears in-memory tracer logs. Use before a fresh scenario run."""
    tracer.clear()
    return {"status": "cleared"}

@router.get("/debug/incidents")
async def debug_incidents():
    """Returns ALL incidents from Firestore (any status) for debugging.
    Use to check if incidents exist but aren't showing on frontend."""
    from firebase_config import db
    from google.cloud.firestore_v1 import GeoPoint
    docs = list(db.collection("incidents").stream())
    result = []
    for doc in docs:
        d = doc.to_dict()
        loc = d.get("location")
        result.append({
            "id": doc.id,
            "type": d.get("type"),
            "status": d.get("status"),
            "severity": d.get("severity"),
            "location_name": d.get("location_name"),
            "lat": loc.latitude if isinstance(loc, GeoPoint) else None,
            "lng": loc.longitude if isinstance(loc, GeoPoint) else None,
            "confidence_score": d.get("confidence_score"),
            "expected_duration_hours": d.get("expected_duration_hours"),
            "media_url": d.get("media_url"),
            "has_location": isinstance(loc, GeoPoint),
        })
    return {"total": len(result), "incidents": result}

@router.get("/places/autocomplete")
async def places_autocomplete(q: str):
    """Fetches location suggestions using Google Places API."""
    from tools.maps_tool import get_places_autocomplete
    result = await get_places_autocomplete(q)
    return result

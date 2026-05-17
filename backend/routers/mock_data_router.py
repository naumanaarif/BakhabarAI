from fastapi import APIRouter
from typing import List
from agents.pipeline import run_crisis_simulation
from tracer import tracer

router = APIRouter(prefix="/api")

@router.get("/incidents")
async def get_incidents():
    # Placeholder for returning mock incidents
    return {
        "incidents": [
            {
                "crisis_id": "c_001",
                "type": "flood",
                "location": {
                    "name": "G-10, Islamabad",
                    "lat": 33.6844,
                    "lng": 73.0479
                },
                "severity": "HIGH",
                "confidence": 0.92,
                "affected_population": 12000,
                "status": "active"
            },
            {
                "crisis_id": "c_002",
                "type": "heatwave",
                "location": {
                    "name": "I-8, Islamabad",
                    "lat": 33.6682,
                    "lng": 73.0768
                },
                "severity": "MEDIUM",
                "confidence": 0.85,
                "affected_population": 8500,
                "status": "active"
            }
        ]
    }

@router.get("/incidents/{id}")
async def get_incident_detail(id: str):
    return {
        "crisis_id": id,
        "type": "flood",
        "location": {
            "name": "G-10, Islamabad",
            "lat": 33.6844,
            "lng": 73.0479
        },
        "severity": "HIGH",
        "confidence": 0.92,
        "affected_population": 12000,
        "expected_duration_hours": 6,
        "peak_impact_time": "2024-01-15T18:00:00Z",
        "signal_sources": ["Google Weather API", "Social"],
        "conflicting_signals": [],
        "status": "active"
    }

@router.post("/report")
async def submit_report(report: dict):
    # Simulated agent processing delay happens on frontend, or we can sleep here
    return {"status": "success", "message": "Incident report submitted and verified."}

@router.post("/run-scenario")
async def run_scenario(scenario: dict = None):
    # Clear previous traces for a fresh run
    tracer.clear()
    
    # Run the agent pipeline
    result = await run_crisis_simulation(scenario)
    
    return {
        "status": "success",
        "result": result,
        "traces": tracer.get_traces()
    }

@router.get("/logs")
async def get_logs():
    return {
        "traces": tracer.get_traces() if tracer.get_traces() else [
            {
                "timestamp": "2024-01-15T14:30:00Z",
                "agent": "DetectorAgent",
                "action": "classified_crisis",
                "input": {"signals": 4, "location": "G-10"},
                "output": {"type": "flood", "severity": "HIGH"},
                "confidence": 0.92
            }
        ]
    }

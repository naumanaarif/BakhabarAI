import sys
import os
import asyncio

# Add backend to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.firebase_service import FirebaseService
from firebase_config import db

async def setup_stress_test():
    print("🚀 Setting up Multi-Crisis Stress Test Scenario...")
    
    # 1. Clear existing pending signals
    signals = db.collection("signals").where("status", "==", "pending").stream()
    for s in signals:
        s.reference.delete()
    
    # 2. Add conflicting signals for Zone A (G-10)
    # Social media reports flooding
    FirebaseService.add_signal(
        source_type="social",
        content="G-10 Markaz is completely flooded! Cars are submerged. Stay away!",
        lat=33.6844,
        lng=73.0479,
        metadata={"location_name": "G-10 Markaz"}
    )
    
    # Official sensor says normal (Conflict/False Alarm candidate)
    FirebaseService.add_signal(
        source_type="sensor",
        content="Water level at G-10 drainage point: 0.2m (Normal Range). No blockage detected.",
        lat=33.6850,
        lng=73.0485,
        metadata={"location_name": "G-10 Markaz"}
    )
    
    # 3. Add a clear HIGH severity signal for Zone B (Margalla Hills)
    FirebaseService.add_signal(
        source_type="field_report",
        content="WILD FIRE DETECTED. Large smoke plume rising from Margalla Trail 3. Spreading fast due to wind.",
        lat=33.7483,
        lng=73.0784,
        metadata={"location_name": "Margalla Hills Trail 3"}
    )
    
    # 4. Add a third simultaneous crisis (Power Outage in Sector F-7)
    FirebaseService.add_signal(
        source_type="social",
        content="Complete blackout in F-7/2. Multiple transformers exploded. Dark and unsafe.",
        lat=33.7215,
        lng=73.0567,
        metadata={"location_name": "Sector F-7/2"}
    )
    
    # 5. Reset all resources to available
    resources = db.collection("resources").stream()
    for res in resources:
        res.reference.update({"status": "available", "current_incident_id": None})
    
    print("✅ Stress test signals and resources initialized.")
    print("👉 Conflicting signals in G-10 (Social vs Sensor).")
    print("👉 High priority Wildfire in Margalla.")
    print("👉 Concurrent Power Outage in F-7.")
    print("\nTrigger the pipeline via the App or /api/run-scenario to see agentic trade-offs and retractions.")

if __name__ == "__main__":
    asyncio.run(setup_stress_test())

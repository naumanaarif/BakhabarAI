import asyncio
import sys
import os
import time

# Add backend root to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from firebase_config import db
from services.firebase_service import FirebaseService
from agents.pipeline import run_crisis_simulation
from google.cloud.firestore_v1 import FieldFilter

async def reproduce():
    print("--- Reproduction Script ---")
    
    # 1. Clear existing incidents and signals for clean state
    print("Clearing signals and incidents...")
    for coll in ["signals", "incidents"]:
        docs = db.collection(coll).get()
        for doc in docs:
            doc.reference.delete()

    # 2. Add a user report
    location_name = "G-10 Markaz"
    report_message = f"{location_name}: Severe flooding in the main square!"
    print(f"Adding user report: {report_message}")
    
    FirebaseService.add_signal(
        source_type="social",
        content=report_message,
        lat=33.6844,
        lng=73.0479,
        metadata={"user_report": True}
    )

    # 3. Run the pipeline
    print("Running pipeline...")
    await run_crisis_simulation()
    
    # 4. Check if incident was created
    incidents = FirebaseService.get_active_incidents()
    print(f"Active incidents count: {len(incidents)}")
    for inc in incidents:
        print(f"Incident: {inc['type']} at {inc['location_name']}, Confidence: {inc['confidence_score']}")

    if len(incidents) == 0:
        print("FAILED: No incident created from user report.")
    else:
        # 5. Add another report at the same location
        print(f"Adding another report for {location_name}...")
        FirebaseService.add_signal(
            source_type="social",
            content=f"{location_name}: Water level is rising fast!",
            lat=33.6844,
            lng=73.0479,
            metadata={"user_report": True}
        )
        
        # 6. Run pipeline again
        print("Running pipeline again...")
        await run_crisis_simulation()
        
        # 7. Check confidence
        incidents = FirebaseService.get_active_incidents()
        for inc in incidents:
            if inc['location_name'] == location_name:
                print(f"Updated Incident: {inc['type']} at {inc['location_name']}, Confidence: {inc['confidence_score']}")
                # Expect confidence to increase

if __name__ == "__main__":
    asyncio.run(reproduce())

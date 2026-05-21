import sys
import os
import time
import asyncio
# Add the parent directory (backend root) to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from firebase_config import db
from services.firebase_service import FirebaseService

def clear_db():
    print("Clearing signals, incidents, and logs for a clean demo...")
    for coll in ["signals", "incidents", "agent_logs", "action_simulations"]:
        docs = db.collection(coll).stream()
        for doc in docs:
            doc.reference.delete()
    
    # Reset resources to available
    resources = db.collection("resources").stream()
    for res in resources:
        res.reference.update({"status": "available", "current_incident_id": None})
    print("Cleanup complete.")

def inject_signals():
    # Diverse Scenarios for a realistic demo
    scenarios = [
        # 1. Urban Flooding in G-10
        {
            "source": "social",
            "content": "G-10/4 streets are completely flooded after the rain! Cars are stuck. #IslamabadRain",
            "lat": 33.6844, "lng": 73.0479, "loc_name": "G-10, Islamabad",
            "delay": 1
        },
        # 2. Wildfire/Smoke Detection in Margalla Hills
        {
            "source": "sensor",
            "content": "PM2.5 levels spike at Station 4. Thermal anomaly detected in sector 5.",
            "lat": 33.7483, "lng": 73.0400, "loc_name": "Margalla Hills, Islamabad",
            "delay": 1
        },
        # 3. Heatwave Alert in I-8
        {
            "source": "weather",
            "content": "Extreme Heatwave Warning: Temp expected to hit 47C. Stay indoors.",
            "lat": 33.6682, "lng": 73.0768, "loc_name": "I-8, Islamabad",
            "delay": 1
        },
        # 4. False Alarm (Will be contradicted by logic)
        {
            "source": "social",
            "content": "Wait, I see smoke near E-7! Is there a fire?",
            "lat": 33.7199, "lng": 73.0372, "loc_name": "E-7, Islamabad",
            "delay": 1
        },
        {
            "source": "sensor",
            "content": "Status: NORMAL. No smoke detected in E-7 sector.",
            "lat": 33.7199, "lng": 73.0372, "loc_name": "E-7, Islamabad",
            "delay": 1
        }
    ]

    print("Starting Live Feed Simulation...")
    for s in scenarios:
        print(f"Injecting {s['source']} signal for {s['loc_name']}...")
        FirebaseService.add_signal(
            source_type=s['source'],
            content=s['content'],
            lat=s['lat'],
            lng=s['lng'],
            metadata={"location_name": s['loc_name']}
        )
        time.sleep(s['delay'])
    
    print("All signals injected.")

if __name__ == "__main__":
    clear_db()
    inject_signals()
    print("\nDEMO READY: Now trigger the Agent Pipeline from the App or by running 'python backend/main.py'")

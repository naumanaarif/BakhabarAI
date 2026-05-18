import sys
import os
# Add the parent directory (backend root) to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from firebase_config import db

def init_resources():
    resources = [
        {"name": "Ambulance 01", "type": "Medical", "status": "available", "current_incident_id": None},
        {"name": "Ambulance 02", "type": "Medical", "status": "available", "current_incident_id": None},
        {"name": "Rescue Team Alpha", "type": "Fire", "status": "available", "current_incident_id": None},
        {"name": "Rescue Team Beta", "type": "Fire", "status": "available", "current_incident_id": None},
        {"name": "Police Unit 101", "type": "Police", "status": "available", "current_incident_id": None},
        {"name": "Police Unit 102", "type": "Police", "status": "available", "current_incident_id": None},
        {"name": "Heavy Water Pump 01", "type": "Water_Management", "status": "available", "current_incident_id": None},
        {"name": "Drone Team 1", "type": "Recon", "status": "available", "current_incident_id": None},
    ]

    print("Initializing resources in Firestore...")
    collection_ref = db.collection("resources")
    
    # Optional: Clear existing resources to avoid duplicates
    # docs = collection_ref.stream()
    # for doc in docs:
    #     doc.reference.delete()

    for r in resources:
        collection_ref.add(r)
        print(f"Added {r['name']} ({r['type']})")

    print("Resource initialization complete.")

if __name__ == "__main__":
    init_resources()

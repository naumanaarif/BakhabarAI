import sys
import os
# Add the parent directory (backend root) to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from firebase_config import db

def init_resources():
    resources = [
        # Medical
        {"name": "Ambulance 01", "type": "Medical", "status": "available", "current_incident_id": None},
        {"name": "Ambulance 02", "type": "Medical", "status": "available", "current_incident_id": None},
        {"name": "Mobile Clinic Alpha", "type": "Medical", "status": "available", "current_incident_id": None},
        
        # Fire & Rescue
        {"name": "Fire Engine 10", "type": "Fire", "status": "available", "current_incident_id": None},
        {"name": "Rescue Team Alpha", "type": "Fire", "status": "available", "current_incident_id": None},
        {"name": "Rescue Team Beta", "type": "Fire", "status": "available", "current_incident_id": None},
        
        # Police & Security
        {"name": "Police Unit 101", "type": "Police", "status": "available", "current_incident_id": None},
        {"name": "Police Unit 102", "type": "Police", "status": "available", "current_incident_id": None},
        
        # Water Management (Critical for Floods)
        {"name": "Heavy Water Pump 01", "type": "Water_Management", "status": "available", "current_incident_id": None},
        {"name": "Heavy Water Pump 02", "type": "Water_Management", "status": "available", "current_incident_id": None},
        {"name": "Industrial Dewatering Unit", "type": "Water_Management", "status": "available", "current_incident_id": None},
        
        # Recon & Aerial (Drones)
        {"name": "Drone Team 1 (Thermal)", "type": "Recon", "status": "available", "current_incident_id": None},
        {"name": "Drone Team 2 (Visual)", "type": "Recon", "status": "available", "current_incident_id": None},
        {"name": "Rapid Recon Unit", "type": "Recon", "status": "available", "current_incident_id": None},
        
        # Logistics & Transport
        {"name": "High-Clearance Truck 01", "type": "Logistics", "status": "available", "current_incident_id": None},
        {"name": "Emergency Food Supply Truck", "type": "Logistics", "status": "available", "current_incident_id": None},
    ]

    print("Clearing existing resources to prevent duplicates...")
    collection_ref = db.collection("resources")
    docs = collection_ref.stream()
    for doc in docs:
        doc.reference.delete()

    print("Initializing expanded resources in Firestore...")
    for r in resources:
        collection_ref.add(r)
        print(f"Added {r['name']} ({r['type']})")

    print("Resource initialization complete.")

if __name__ == "__main__":
    init_resources()

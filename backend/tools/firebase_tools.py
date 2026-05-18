from services.firebase_service import FirebaseService
from typing import List, Dict, Any, Optional

def get_pending_signals() -> List[Dict[str, Any]]:
    """
    Fetches all signals from Firestore that have not been processed yet (status='pending').
    """
    return FirebaseService.get_pending_signals()

def verify_signal(signal_id: str, credibility_score: float, status: str, incident_id: str = None):
    """
    Updates a signal's status and credibility score in Firestore.
    """
    FirebaseService.update_signal_status(signal_id, status, credibility_score, incident_id)
    print(f"DEBUG: Verified signal {signal_id} with status {status}")
    return {"status": "success", "signal_id": signal_id}

def query_active_incidents() -> List[Dict[str, Any]]:
    """
    Retrieves all currently active incidents from Firestore.
    """
    incidents = FirebaseService.get_active_incidents()
    print(f"DEBUG: Queried {len(incidents)} active incidents")
    return incidents

def create_incident(incident_type: str, severity: str, confidence: float, location_name: str, lat: float, lng: float, population: int = 0, signal_source: str = None) -> str:
    """
    Creates a new incident record in Firestore and returns its ID.
    If an incident already exists at the same location, it updates confidence and sources.
    """
    incident_id = FirebaseService.create_incident(
        incident_type=incident_type,
        severity=severity,
        confidence=confidence,
        location_name=location_name,
        lat=lat,
        lng=lng,
        population=population,
        signal_source=signal_source
    )
    print(f"DEBUG: Processed incident {incident_id} of type {incident_type} from {signal_source}")
    return incident_id

def update_incident_details(incident_id: str, updates: Dict[str, Any]):
    """
    Updates an existing incident with new data (e.g., evolution prediction, status).
    """
    FirebaseService.update_incident(incident_id, updates)
    print(f"DEBUG: Updated incident {incident_id} with data: {updates}")
    return {"status": "success", "incident_id": incident_id}

def get_resources(resource_type: str = None) -> List[Dict[str, Any]]:
    """
    Queries Firestore for available resources, optionally filtered by type.
    """
    return FirebaseService.get_available_resources(resource_type)

def assign_resource_to_incident(resource_id: str, incident_id: str):
    """
    Allocates a specific resource to an incident in Firestore.
    """
    FirebaseService.allocate_resource(resource_id, incident_id)

def log_simulation(incident_id: str, action_type: str, description: str, impact: Dict[str, Any], notifications: Dict[str, str]):
    """
    Logs a response simulation and stakeholder messages to Firestore.
    """
    FirebaseService.log_action_simulation(incident_id, action_type, description, impact, notifications)

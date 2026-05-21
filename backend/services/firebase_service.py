from firebase_config import db
from google.cloud.firestore_v1 import GeoPoint, FieldFilter
from datetime import datetime
from typing import List, Dict, Any, Optional

class FirebaseService:
    # Default credibility scores by source type
    _SOURCE_CREDIBILITY = {
        "sensor":         0.85,
        "field_report":   0.85,
        "weather":        0.90,
        "emergency_call": 0.80,
        "social":         0.60,
        "whatsapp":       0.60,
    }

    @staticmethod
    def add_signal(source_type: str, content: str, lat: float, lng: float,
                   metadata: Dict[str, Any] = None, credibility_score: float = None):
        """Adds a raw signal to the signals collection.
        
        credibility_score defaults to a source-type-based value if not provided.
        All defaults are >= 0.5 so signals pass the pipeline's verification threshold.
        """
        if credibility_score is None:
            credibility_score = FirebaseService._SOURCE_CREDIBILITY.get(source_type, 0.65)

        signal_data = {
            "source_type": source_type,
            "content": content,
            "location": GeoPoint(lat, lng),
            "timestamp": datetime.now(),
            "credibility_score": credibility_score,
            "status": "pending",
            "metadata": metadata or {},
            "incident_id": None
        }
        _, doc_ref = db.collection("signals").add(signal_data)
        return doc_ref.id

    @staticmethod
    def get_pending_signals() -> List[Dict[str, Any]]:
        """Retrieves all signals that are pending processing."""
        docs = db.collection("signals").where(filter=FieldFilter("status", "==", "pending")).stream()
        return [{**doc.to_dict(), "id": doc.id} for doc in docs]

    @staticmethod
    def get_signal_by_id(signal_id: str) -> Optional[Dict[str, Any]]:
        """Retrieves a specific signal by ID."""
        doc = db.collection("signals").document(signal_id).get()
        if doc.exists:
            return {**doc.to_dict(), "id": doc.id}
        return None

    @staticmethod
    def update_signal_status(signal_id: str, status: str, credibility_score: float = None, incident_id: str = None):
        """Updates the status and metadata of a signal."""
        update_data = {"status": status}
        if credibility_score is not None:
            update_data["credibility_score"] = credibility_score
        if incident_id is not None:
            update_data["incident_id"] = incident_id
        
        # Propagate media_url from signal to incident
        if incident_id:
            try:
                signal_doc = db.collection("signals").document(signal_id).get()
                if signal_doc.exists:
                    media_url = signal_doc.to_dict().get("metadata", {}).get("media_url")
                    if media_url:
                        incident_doc = db.collection("incidents").document(incident_id).get()
                        if incident_doc.exists and not incident_doc.to_dict().get("media_url"):
                            db.collection("incidents").document(incident_id).update({"media_url": media_url})
            except Exception as e:
                print(f"Error propagating media_url: {e}")

        db.collection("signals").document(signal_id).update(update_data)

    @staticmethod
    def get_incident_by_id(incident_id: str) -> Optional[Dict[str, Any]]:
        """Retrieves a specific incident by ID."""
        doc = db.collection("incidents").document(incident_id).get()
        if doc.exists:
            return {**doc.to_dict(), "id": doc.id}
        return None

    @staticmethod
    def create_incident(incident_type: str, severity: str, confidence: float, location_name: str, lat: float, lng: float, population: int = 0, signal_source: str = None, media_url: str = None):
        """Creates a new incident record or updates existing one if nearby."""
        # Check for existing incident at the same location name
        existing = db.collection("incidents").where(filter=FieldFilter("location_name", "==", location_name)).where(filter=FieldFilter("status", "==", "active")).limit(1).get()
        
        if existing:
            doc = existing[0]
            data = doc.to_dict()
            
            # If the incident type is different, it's a correction/reclassification
            # If the new signal source is highly reliable (sensor/field), we adopt its type
            new_type = data.get("type")
            if signal_source in ["sensor", "field_report"] and incident_type != new_type:
                new_type = incident_type
                
            # Confidence logic: 
            # - If it's a verification of the same type, increase confidence.
            # - If it's a contradiction/correction, the confidence might change based on the new signal.
            if incident_type == data.get("type"):
                new_confidence = min(1.0, data.get("confidence_score", 0.0) + 0.1)
            else:
                # If a field report corrects a social report, we might lower confidence of the "incident" 
                # or just switch to the new type with the new signal's confidence
                new_confidence = confidence

            sources = data.get("signal_sources", [])
            if signal_source and signal_source not in sources:
                sources.append(signal_source)
            
            update_payload = {
                "type": new_type,
                "confidence_score": new_confidence,
                "signal_sources": sources,
                "last_updated": datetime.now()
            }
            if media_url and not data.get("media_url"):
                update_payload["media_url"] = media_url

            db.collection("incidents").document(doc.id).update(update_payload)
            return doc.id

        incident_data = {
            "type": incident_type,
            "severity": severity,
            "confidence_score": confidence,
            "status": "active",
            "location_name": location_name,
            "location": GeoPoint(lat, lng),
            "affected_population": population,
            "evolution_prediction": {},
            "assigned_resources": [],
            "signal_sources": [signal_source] if signal_source else [],
            "timestamp": datetime.now(),
            "last_updated": datetime.now()
        }
        if media_url:
            incident_data["media_url"] = media_url
            
        _, doc_ref = db.collection("incidents").add(incident_data)
        return doc_ref.id

    @staticmethod
    def update_incident(incident_id: str, data: Dict[str, Any]):
        """Updates an existing incident."""
        db.collection("incidents").document(incident_id).update(data)

    @staticmethod
    def get_active_incidents() -> List[Dict[str, Any]]:
        """Retrieves all active crises."""
        docs = db.collection("incidents").where(filter=FieldFilter("status", "==", "active")).stream()
        return [{**doc.to_dict(), "id": doc.id} for doc in docs]

    @staticmethod
    def add_agent_log(agent_name: str, action: str, input_data: Any, output_data: Any, confidence: float = 1.0):
        """Logs an agent's reasoning chain for the mobile app."""
        log_data = {
            "agent_name": agent_name,
            "action": action,
            "input_data": input_data,
            "output_data": output_data,
            "confidence": confidence,
            "timestamp": datetime.now()
        }
        db.collection("agent_logs").add(log_data)

    @staticmethod
    def get_available_resources(resource_type: str = None) -> List[Dict[str, Any]]:
        """Queries for available resources."""
        query = db.collection("resources").where(filter=FieldFilter("status", "==", "available"))
        if resource_type:
            query = query.where(filter=FieldFilter("type", "==", resource_type))
        
        docs = query.stream()
        return [{**doc.to_dict(), "id": doc.id} for doc in docs]

    @staticmethod
    def allocate_resource(resource_id: str, incident_id: str):
        """Atomic transaction-like update to allocate a resource to an incident."""
        resource_ref = db.collection("resources").document(resource_id)
        incident_ref = db.collection("incidents").document(incident_id)
        
        # In a real scenario, we'd use a transaction here
        resource_ref.update({
            "status": "deployed",
            "current_incident_id": incident_id
        })
        
        incident_doc = incident_ref.get()
        if incident_doc.exists:
            resources = incident_doc.to_dict().get("assigned_resources", [])
            if resource_id not in resources:
                resources.append(resource_id)
                incident_ref.update({"assigned_resources": resources})

    @staticmethod
    def log_action_simulation(incident_id: str, action_type: str, description: str, impact: Dict[str, Any], notifications: Dict[str, str]):
        """Logs a simulation outcome and stakeholder messages."""
        sim_data = {
            "incident_id": incident_id,
            "action_type": action_type,
            "description": description,
            "impact_prediction": impact,
            "stakeholder_notifications": notifications,
            "timestamp": datetime.now()
        }
        db.collection("action_simulations").add(sim_data)

# Contracts: core-incident-tracking

## REST API (FastAPI)

### 1. Get All Active Incidents
- **Endpoint**: `GET /api/incidents`
- **Description**: Returns all currently active crisis incidents for rendering on the map and list.
- **Response**:
  ```json
  [
    {
      "crisis_id": "uuid",
      "type": "flood",
      "location": { "name": "G-10, Islamabad", "lat": 33.6844, "lng": 73.0479 },
      "severity": "HIGH",
      "confidence": 0.92,
      "status": "active"
    }
  ]
  ```

### 2. Get Incident Details (Includes Expert View Data)
- **Endpoint**: `GET /api/incidents/{crisis_id}`
- **Description**: Returns full details for an incident, including agent traces for the Expert View.
- **Response**:
  ```json
  {
    "crisis_id": "uuid",
    "type": "flood",
    "severity": "HIGH",
    "confidence": 0.92,
    "affected_population": 12000,
    "expected_duration_hours": 6,
    "agent_traces": [
      {
        "agent": "CrisisDetector",
        "action": "classified_crisis",
        "timestamp": "2024-01-15T14:35:00Z"
      }
    ]
  }
  ```

### 3. Submit Citizen Report
- **Endpoint**: `POST /api/report`
- **Description**: Submits a new signal (citizen report) to the SignalHarvester agent.
- **Payload**:
  ```json
  {
    "source_type": "field_report",
    "location": { "name": "G-10", "lat": 33.6844, "lng": 73.0479 },
    "content": "Water is entering shops on the main street."
  }
  ```
- **Response**: `201 Created` with the generated `signal_id`.

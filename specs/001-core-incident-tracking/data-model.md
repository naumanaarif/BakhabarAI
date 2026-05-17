# Data Model: core-incident-tracking

## Entities

### `Location`
Represents geographic coordinates and a human-readable name.
- `lat` (double): Latitude.
- `lng` (double): Longitude.
- `name` (string): Sector or area name (e.g., "G-10, Islamabad").

### `Signal` (Citizen Report)
Represents a raw input from a user or mocked API.
- `signal_id` (string): UUID.
- `source_type` (string): Enum (`social`, `sensor`, `emergency_call`, `weather`, `traffic`, `field_report`).
- `source_name` (string): Human-readable source name.
- `timestamp` (datetime): ISO8601 string.
- `location` (Location): Where the signal originated.
- `content` (string): Text content or raw data description.
- `credibility_score` (double): 0.0 to 1.0 (Assigned by Agent 1).
- `is_mock` (boolean): Flag indicating if data is real or mock.

### `Incident` (Crisis Object)
Represents a verified crisis classified by the `CrisisDetector` agent.
- `crisis_id` (string): UUID.
- `type` (string): Enum (`flood`, `heatwave`, `accident`, `power_outage`, `protest`, `disease`).
- `location` (Location): Center of the crisis.
- `severity` (string): Enum (`HIGH`, `MEDIUM`, `LOW`).
- `confidence` (double): 0.0 to 1.0.
- `affected_population` (integer): Estimated count.
- `expected_duration_hours` (integer): Estimated duration.
- `peak_impact_time` (datetime): ISO8601 string.
- `signal_sources` (list of strings): IDs of signals contributing to this crisis.
- `conflicting_signals` (list of strings): IDs of signals contradicting this crisis.
- `status` (string): Enum (`active`, `resolved`, `false_alarm`).

### `AgentTrace`
Represents the reasoning log for hackathon judging ("Expert View").
- `trace_id` (string): UUID.
- `crisis_id` (string): Reference to the Incident.
- `agent_name` (string): e.g., "CrisisDetector".
- `timestamp` (datetime): ISO8601 string.
- `action` (string): The reasoning step or tool call.
- `input_data` (map): Raw input received by the agent.
- `output_data` (map): Result of the agent's action.
- `confidence` (double): Optional confidence level for this specific step.

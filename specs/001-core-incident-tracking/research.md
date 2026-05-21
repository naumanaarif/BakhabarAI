# Research & Decisions: core-incident-tracking

## Context
The technical context and architecture for BakhabarAI are strictly defined by the project constitution (`AGENTS.md` and `constitution.md`). The primary focus of this feature is the `home_screen`, `map_screen`, `incident_detail_screen`, and `report_screen`.

## Decisions

### 1. Framework & Language
- **Decision**: Flutter (Dart) for Mobile App, FastAPI (Python 3.11+) for Backend.
- **Rationale**: Mandated by the hackathon constitution. Flutter allows for rapid mobile UI development and FastAPI handles Python-based Antigravity agent execution perfectly.
- **Alternatives considered**: None (Strictly mandated).

### 2. State Management (Flutter)
- **Decision**: Provider or Riverpod (will use Provider for simplicity if not already initialized).
- **Rationale**: The constitution states "State Mgmt: Provider or Riverpod". Provider is lightweight and ideal for the MVP scope of syncing incidents and map state.
- **Alternatives considered**: BLoC, GetX (Rejected: Not approved by constitution).

### 3. Maps Integration
- **Decision**: `google_maps_flutter` package.
- **Rationale**: Constitution explicitly requires Google Maps Platform.
- **Alternatives considered**: Mapbox, Leaflet (Rejected: Must use Google Maps API).

### 4. Icons & Styling
- **Decision**: `lucide_icons` exclusively. Strict adherence to `AppColors` defined in constitution.
- **Rationale**: The constitution explicitly bans Material or Cupertino icons. Only Lucide Icons are permitted.
- **Alternatives considered**: Material Icons (Rejected: Explicitly banned).

### 5. Backend Agent Orchestration
- **Decision**: Google ADK `SequentialAgent` for orchestrating SignalHarvester and CrisisDetector.
- **Rationale**: Antigravity/ADK orchestration is the primary judging criterion. The backend must structure the agents exactly as defined.
- **Alternatives considered**: Raw Gemini API calls (Rejected: Must use ADK).

## Resolved Clarifications
There are no unresolved clarifications. All technical choices adhere to the project constitution.

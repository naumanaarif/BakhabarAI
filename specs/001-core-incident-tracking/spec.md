# Feature Specification: core-incident-tracking

**Feature Branch**: `001-core-incident-tracking`

**Created**: 2026-05-17

**Status**: Draft

**Input**: User description: "as you already know about the project, we are building a mobile app that keeps people informed about crisis and incidents. the homepage should show the users live incidents update, shows a live map with incident markers on it, it also shows a list of few incidents below the map window. The users should also be able to Report An Incident, also, there are some other screens for the requirements of the hackathon we are building this app for, as you can already see in the project files."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Real-Time Dashboard (Priority: P1)

As a citizen, I want to open the app and instantly see a map with active crisis markers and a list of nearby incidents, so that I can make informed decisions about my safety and travel plans.

**Why this priority**: Immediate situational awareness is the core value proposition of the app. Without this, users have no reason to rely on the application during a crisis.

**Independent Test**: Can be fully tested by launching the app, verifying the map renders with mock incident data, and confirming the list below the map matches the displayed markers.

**Acceptance Scenarios**:

1. **Given** the user launches the app, **When** the home screen successfully loads, **Then** a live map is displayed at the top half of the screen with clear markers indicating active crises.
2. **Given** the home screen is visible, **When** the user views the area below the map, **Then** a list of at least 3 active incidents is shown with summary details (type, location, severity).
3. **Given** a new incident is processed by the backend, **When** the app polls for updates, **Then** the map and list update seamlessly without requiring a manual refresh.

---

### User Story 2 - Citizen Incident Reporting (Priority: P1)

As a citizen, I want to report a crisis or incident I observe, so that the system can process it and alert others.

**Why this priority**: Citizen reports (crowdsourcing) are a mandatory input for the SignalHarvester agent to function and detect crises.

**Independent Test**: Can be fully tested by navigating to the report screen, filling out the form, submitting it, and verifying the backend successfully receives the payload.

**Acceptance Scenarios**:

1. **Given** the user is on the home screen, **When** they tap the "Report" button, **Then** the Incident Report form is presented.
2. **Given** the user has filled in the incident type, location, and a brief description, **When** they tap submit, **Then** the report is transmitted to the backend and a success confirmation is displayed.

---

### User Story 3 - Incident Details & Expert Analysis View (Priority: P2)

As a citizen, I want to see detailed safety instructions for an incident, and as a hackathon judge/expert, I want to toggle an "Expert View" to examine the underlying AI agent trace logs and confidence scores.

**Why this priority**: Crucial for demonstrating the Google Antigravity multi-agent orchestration for the hackathon judging criteria.

**Independent Test**: Can be fully tested by opening an incident's details, reviewing the citizen-friendly info, toggling the Expert View, and verifying the technical logs are displayed correctly.

**Acceptance Scenarios**:

1. **Given** the user is viewing the incident list or map, **When** they tap on a specific incident, **Then** a detailed view opens showing basic info, safety instructions, and a simplified trust badge (e.g., "AI Verified").
2. **Given** the incident details view, **When** the user switches the "Expert View" toggle to ON, **Then** the UI updates to show raw confidence scores, agent reasoning logs, and simulation actions.

### Edge Cases

- What happens if the device loses internet connectivity while attempting to submit an incident report?
- How does the system display overlapping map markers when multiple distinct incidents occur in the exact same location or very close proximity?
- How is the UI handled if the backend returns a malformed or empty response for the incident list?
- What if the user denies the location permission request on the splash/home screen?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST render a map component on the home screen to visualize incident locations.
- **FR-002**: The system MUST render a summarized list of active incidents directly below the map on the home screen.
- **FR-003**: The system MUST provide an incident reporting form capturing incident type, location, and text description.
- **FR-004**: The system MUST successfully transmit citizen incident reports to the backend (SignalHarvester agent).
- **FR-005**: The system MUST provide an Incident Details screen accessible from both the map markers and the incident list.
- **FR-006**: The Incident Details screen MUST include an "Expert View" toggle.
- **FR-007**: When "Expert View" is OFF, the system MUST NOT display raw confidence scores or agent trace logs (use simplified terminology like "AI Verified").
- **FR-008**: When "Expert View" is ON, the system MUST display the raw confidence scores, agent reasoning, and simulation data.
- **FR-009**: The UI MUST use Skeleton Loading Placeholders across the app for fetching data.
- **FR-010**: The UI MUST show a loading circle with the agent name when an agent is processing a response.
- **FR-011**: The app MUST present a Location Access popup on the main home/overview splash screen.
- **FR-012**: Map Incident Markers MUST be color-coded based on severity: RED (High), ORANGE (Medium), PURPLE (Assessed/Other).
- **FR-013**: The main navigation MUST be a bottom bar containing exactly 4 tabs: HOME, MAP, AI ASSISTANT CHAT, and Agent Logs (old runs).
- **FR-014**: Every screen MUST feature a Back Button on the top left corner.
- **FR-015**: No mock data shall be hardcoded on the UI; all mock UI data MUST be fetched via backend API endpoints.

### Key Entities

- **Incident**: Represents a verified crisis event, including attributes like Type, Location, Severity, Status, and Confidence Score.
- **Signal**: A user-submitted observation or API-harvested data point, including Source, Location, and Description.
- **AgentTrace**: The historical log of decisions, reasoning, and actions taken by the Antigravity agents regarding an incident.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can view the fully populated home dashboard (map and list) within 3 seconds of opening the app.
- **SC-002**: Users can complete and submit an incident report in under 60 seconds.
- **SC-003**: The app correctly maps 100% of the structured JSON data returned by the backend agents to the UI without crashing or silent failures.
- **SC-004**: Toggling Expert View reveals the underlying data instantly, requiring no additional network requests.

## Assumptions

- Users have stable internet connectivity (offline support is out of scope for the MVP).
- User authentication (OTP) is completed prior to accessing the home dashboard.
- The backend API, powered by Google Antigravity, is operational and can serve mock data for the canonical demo scenarios.
- Location services are enabled on the device for accurate reporting and map centering.

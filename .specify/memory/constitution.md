# BakhabarAI Constitution

## Core Principles

### I. Google Antigravity is the core orchestrator
- ALL agent workflows must be orchestrated through Google Antigravity
- No agent may run outside Antigravity's orchestration layer
- Every agent interaction must produce a traceable Antigravity log entry
- Use of external LLMs (Gemini, etc.) is allowed only as tools called from within Antigravity — not as standalone orchestrators

### II. Multi-agent architecture is mandatory
- The system must implement exactly 5 named agents (see Agent definitions)
- Each agent must be distinctly named and identifiable in logs
- Agent logs must show: agent name, input received, reasoning steps, tool calls made, output produced, confidence score, timestamp
- No agent may be collapsed into another — judges will verify separation

### III. Mobile app is the primary deliverable
- Flutter mobile app is mandatory for submission
- All citizen-facing features live in the Flutter app
- The app must be buildable to APK for submission
- Web app/dashboard is optional — do not prioritise over Flutter

### IV. Data privacy
- No real personal data may be stored or transmitted
- All citizen reports use anonymised/mock identifiers
- Phone numbers stored only as hashed tokens after OTP verification
- Mock datasets must be clearly labelled as mock in documentation

### V. Simulation is not optional
- At least one action must be fully simulated end-to-end
- Simulation must show visible before-state → action → after-state
- The false alarm / alert retraction scenario must be demonstrable
- Baseline comparison (rule-based vs agentic) must be implemented

### VI. Robustness evidence is required for submission
- At least one of these must be demonstrable in the app:
  - False alarm detected and alert retracted
  - API failure with fallback to cached data
  - Conflicting signals resolved with reasoning
  - Missing location data handled gracefully

## Tech Stack - Approved Technologies

| Layer | Technology | Notes |
|---|---|---|
| Agent orchestration | Google Antigravity | Mandatory — core requirement |
| Agent framework | Google ADK (Agent Development Kit) | Primary agent framework |
| LLM | Gemini 2.0 Flash / Gemini 2.5 Pro | Via Vertex AI |
| Mobile app | Flutter (Dart) | Mandatory deliverable |
| Backend API | Python (FastAPI or Flask) | Serves Flutter app |
| Database | Firestore | Mock data storage |
| Auth | Firebase Phone OTP | +92 Pakistan numbers |
| Maps | Google Maps Flutter SDK | Crisis zone overlays |
| Notifications | Firebase Cloud Messaging (FCM) | Agent 5 push alerts |
| Additional tools | n8n, LangGraph, CrewAI, Vertex AI | Allowed as supporting tools |
| Version control | Git + GitHub | Required for submission |

**Not approved (do not use):**
- Any orchestration framework as a replacement for Antigravity
- Real emergency APIs (1122, PSCA) — use mock data only

## Application Architecture

```text
Flutter Mobile App (citizen-facing)
        │
        │  HTTP / FCM
        ▼
Python Backend API (FastAPI)
        │
        │  Antigravity SDK calls
        ▼
Google Antigravity Orchestration Layer
        │
        ├── Agent 1: SignalHarvester
        ├── Agent 2: CrisisDetector
        ├── Agent 3: SituationReasoner
        ├── Agent 4: ResourcePlanner
        └── Agent 5: ResponseExecutor
                │
                ▼
        Firestore (mock data)
        FCM (push alerts to Flutter)
        Mock APIs (weather, maps, 1122)
```

## Agent Definitions — Immutable

These agent names, responsibilities, and output contracts must not change. All specs and implementations must reference agents by these exact names.

### Agent 1 — SignalHarvester
**Responsibility:** Ingest and normalise multi-source signals  
**Inputs:** Citizen reports, Mock weather API, Mock Maps/traffic, Mock 1122/PSCA, Mock social media posts.
**Outputs:** Normalised signal bundle (JSON), Credibility score per signal (0.0–1.0), Noise flag for irrelevant signals (boolean), Source type label per signal.
**Rules:** Must handle Roman Urdu text, deduplicate signals within 5-min window, label at least 1 signal as noise in every demo scenario, log confidence score.

### Agent 2 — CrisisDetector
**Responsibility:** Classify crisis type, severity, and confidence  
**Inputs:** Normalised signal bundle from SignalHarvester
**Outputs:** Crisis type, Severity level, Confidence score, Affected radius (km), Affected population estimate, Expected duration (hours), Conflicting signal flag.
**Rules:** Support simultaneous detection of 2+ crises, produce false alarm output in retraction demo, confidence <0.5 triggers verification, structured JSON only.

### Agent 3 — SituationReasoner
**Responsibility:** Cross-link crises, predict cascades, produce compound risk score  
**Inputs:** Crisis objects from CrisisDetector + resource availability from Firestore
**Outputs:** Compound risk score (0–100), Cascade prediction, Impact analysis narrative, Priority ranking, Recommended action brief.
**Rules:** Explicitly reason about relationship between simultaneous crises, cascade prediction is key differentiator, plain English narrative for Expert View, handle single crisis gracefully.

### Agent 4 — ResourcePlanner
**Responsibility:** Allocate constrained resources, generate action plan  
**Inputs:** Recommended action brief from SituationReasoner + resource pool from Firestore
**Outputs:** Prioritised action list, Resource allocation per action, Trade-off explanation, Stakeholder notification drafts.
**Rules:** Show resource trade-offs, attach constraints to each action, audience-specific stakeholder messages, baseline comparison output.

### Agent 5 — ResponseExecutor
**Responsibility:** Simulate execution of actions, push results to Flutter app  
**Inputs:** Action plan from ResourcePlanner
**Simulated executions:** Traffic rerouting, Rescue dispatch, Shelter activation, SMS/push alert, NDMA escalation, Alert retraction.
**Outputs:** Execution log per action, Before-state snapshot, After-state snapshot, Overall response progress %, Risk score after intervention.
**Rules:** Visible state change to Firestore for every action, alert retraction demonstrable, risk scores in Flutter Simulation screen, execution logs match Antigravity trace logs.

## UI / UX Rules
- **Skeleton Loading:** Entire app must use skeleton loading placeholders for fetching state.
- **Premium Look:** Maintain a clean, high-end, glassmorphic visual style.
- **Agent Loading:** When agents are processing, show a loading circle accompanied by the agent's name.
- **Top App Bar:** Every screen must have a Back Button on the top left corner.
- **Screen Transitions:** All screen changes must have smooth animations/transitions.
- **Location Request:** The main Home/Overview splash screen popup must ask the user for Location access.
- **Map Markers:** Incidents must be color-coded by category: RED (high severity), ORANGE (medium), PURPLE (other/assessed).
- **Mock Data via API:** No mock or sample data should be hardcoded on the UI. The app must fetch this data by calling functional API endpoints.

## Flutter App — Screen Inventory

| Priority | Screen | Agent connection |
|---|---|---|
| P0 | Splash screen + Location Request Popup | None |
| P0 | Home dashboard (mini map + incidents) | Agent 2 + 3 output |
| P0 | Full map page (RED/ORANGE/PURPLE markers) | Agent 2 + 4 output |
| P0 | AI Assistant Chat Screen | Agent 1 input / incident reporting |
| P0 | Incident detail page (citizen + expert view toggle) | Agent 2 + 3 + 4 + 5 |
| P1 | Simulation outcome page | Agent 5 output |
| P1 | Agent logs page (old runs) | All agents |
| P2 | Resource allocation screen | Agent 4 output |

### Navigation Structure
Bottom Navigation Bar includes exactly 4 tabs:
1. HOME
2. MAP
3. AI ASSISTANT CHAT
4. Agent Logs (old runs)

### Expert View Toggle & Citizen-facing Rules
- Toggle on Incident Detail screen.
- OFF state: shelter location, safe route, emergency number, AI Verified badge.
- ON state: agent trace, simulation actions, resource allocation, raw confidence scores.
- Replace raw scores with: "AI Verified" (≥0.75), "AI Monitoring" (0.5–0.75), "Unverified" (<0.5) in citizen view.
- Crisis types: flood / heatwave / traffic gridlock / power outage / infrastructure failure.

## Demo Scenario — Canonical (Karachi monsoon compound crisis)

**Input signals:** Twitter reports, Weather API, Maps API, 1122 calls, irrelevant signals, conflicting signals.
**Expected outputs:** SignalHarvester ingestion, CrisisDetector (Flood & Heatwave), SituationReasoner compound risk, ResourcePlanner resource allocation, ResponseExecutor simulation and false alarm retraction (Saddar flood).

## Submission Checklist & Additional Notes

No feature is "done" until all items are true: Antigravity agent trace log exists, Flutter UI reflects agent output, Expert view toggle works, Mock data used, canonical demo scenario works, Firestore state change visible.

**Cost and scalability:** Gemini 2.0 Flash for all agent calls, < $0.01 per run, parallelisation via Antigravity at scale.

## Governance

- This constitution is the single source of truth for all Antigravity planning, specification, and implementation decisions.
- Every plan generated by `/speckit.plan` and every implementation by `/speckit.implement` must be validated against these principles before proceeding.
- These rules can never be overridden by any spec, plan, or implementation.

**Version**: 1.0 | **Ratified**: 2026-05-17 | **Last Amended**: 2026-05-17

# BakhabarAI — Technical Documentation

> **Shehar ka Nigehban** — Guardian of the City  
> CIRO Challenge: Crisis Intelligence & Response Orchestrator

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Solution Design Philosophy](#2-solution-design-philosophy)
3. [System Architecture](#3-system-architecture)
4. [Backend: FastAPI](#4-backend-fastapi)
5. [Agent Orchestration: Google ADK](#5-agent-orchestration-google-adk)
6. [API Integrations](#6-api-integrations)
7. [Data Strategy: Real vs. Mock](#7-data-strategy-real-vs-mock)
8. [Firebase Integration](#8-firebase-integration)
9. [Flutter Mobile Application](#9-flutter-mobile-application)
10. [Design System](#10-design-system)
11. [Screens & Navigation](#11-screens--navigation)
12. [Data Models](#12-data-models)
13. [Demo Scenarios](#13-demo-scenarios)
14. [Configuration & Environment](#14-configuration--environment)
15. [Running the Project](#15-running-the-project)
16. [Folder Structure](#16-folder-structure)

---

## 1. Project Overview

**BakhabarAI** is a full-stack, multi-agent crisis intelligence system built specifically for Pakistani urban environments. Its purpose is to solve the core challenge faced by municipal emergency management: fragmented, noisy, and slow information that prevents timely, coordinated disaster response.

The system ingests heterogeneous signals (live weather data, citizen reports, sensor telemetry, emergency calls), runs them through a 5-stage AI agent pipeline orchestrated with **Google Antigravity (ADK)**, and delivers structured crisis intelligence — severity classifications, resource allocation plans, impact simulations, and stakeholder notifications — directly to a premium Flutter mobile dashboard in real-time via **Firebase Firestore**.

**Key Capabilities:**
- Real-time urban crisis detection with confidence scoring
- Multi-crisis resource allocation with trade-off reasoning
- Before/after impact simulation per incident
- AI-generated bilingual stakeholder notifications (English + Roman Urdu)
- Live agent trace logs visible to end users
- Citizen incident reporting with immediate map visibility
- False alarm detection via signal conflict resolution

---

## 2. Solution Design Philosophy

### Why Agentic AI?

Traditional rule-based emergency systems cannot handle the ambiguity, scale, and noise of real-world crisis data. BakhabarAI takes an agentic approach where each specialized AI agent handles one responsibility and passes a structured, enriched context to the next. This mirrors how a real emergency operations center works — with distinct roles for signal intake, analysis, planning, execution, and reporting.

### Hybrid Intelligence Model

The system deliberately combines:
- **Deterministic logic** for time-critical, structured operations (resource greedy allocation, signal credibility scoring, database writes)
- **LLM reasoning** for ambiguous judgment tasks (crisis type classification, impact narrative generation, Urdu alert drafting)
- **Real-time streaming** from Firestore to the Flutter client, so no polling is needed

### Graceful Degradation

Every LLM-dependent stage has a hardcoded deterministic fallback. If the Groq or Gemini API is unavailable, the pipeline continues with template-based outputs. This ensures the system never fails silently during a live demo or production incident.

---

## 3. System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     BakhabarAI System                               │
│                                                                     │
│  ┌──────────────────────┐          ┌─────────────────────────────┐ │
│  │  Flutter Mobile App  │◄────────►│     FastAPI Backend         │ │
│  │  (Android APK)       │  HTTP/   │     (Python 3.11+)          │ │
│  │                      │  REST    │                             │ │
│  │  • 4-tab navigation  │          │  • /api/incidents           │ │
│  │  • Real-time streams │          │  • /api/run-scenario        │ │
│  │  • Google Maps SDK   │          │  • /api/logs                │ │
│  │  • Glassmorphic UI   │          │  • /api/report              │ │
│  │  • Dio HTTP client   │          │  • /api/places/autocomplete │ │
│  └──────────┬───────────┘          └──────────────┬──────────────┘ │
│             │                                     │                │
│             │ Real-time                           │ Triggers       │
│             │ Firestore                           │                │
│             ▼ streams                             ▼                │
│  ┌──────────────────────┐     ┌─────────────────────────────────┐ │
│  │  Firebase Firestore  │◄────│   Google ADK Agent Pipeline     │ │
│  │                      │     │                                 │ │
│  │  Collections:        │     │  Stage 1: SignalFusionAgent     │ │
│  │  • incidents         │     │  Stage 2: DetectorAgent         │ │
│  │  • signals           │     │  Stage 3: ResourcePlannerAgent  │ │
│  │  • resources         │     │  Stage 4: SimulationAgent       │ │
│  │  • agent_logs        │     │  Stage 5: ReporterAgent         │ │
│  │  • action_sims       │     │                                 │ │
│  └──────────────────────┘     │  LLM: Gemini 2.0 Flash          │ │
│                               │  LLM: Groq (llama-3.1-8b)       │ │
│                               └────────────┬────────────────────┘ │
│                                            │                       │
│                                            ▼                       │
│                          ┌─────────────────────────────┐          │
│                          │   Google Maps Platform APIs  │          │
│                          │                             │          │
│                          │  • Geocoding API             │          │
│                          │  • Distance Matrix API       │          │
│                          │  • Directions API            │          │
│                          │  • Places API (New)          │          │
│                          │  • Weather API               │          │
│                          └─────────────────────────────┘          │
└─────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Technology | Responsibility |
|:---|:---|:---|
| Mobile Client | Flutter (Dart) | Dashboard, maps, reports, real-time streaming |
| HTTP Layer | Dio | REST calls to FastAPI for actions |
| Real-time Layer | Firebase Firestore SDK | Live incident, log, resource, simulation streams |
| API Server | FastAPI (uvicorn) | Route handling, pipeline triggering, CORS |
| Agent Pipeline | Google ADK | Orchestrated 5-stage crisis processing |
| Primary LLM | Gemini 2.0 Flash via ADK | Classification, simulation generation |
| Secondary LLM | Groq llama-3.1-8b-instant (via litellm) | Text completions, rate-limit fallback pool |
| Persistence | Firebase Firestore | All structured data |
| Trace Logger | Custom `AgentTracer` | In-memory + Firestore persistence of agent logs |
| Maps | Google Maps Platform | Geocoding, routing, places autocomplete |

---

## 4. Backend: FastAPI

### Entry Point: `backend/main.py`

The FastAPI application starts with a CORS-open configuration (permitting mobile app requests from any origin), includes the main router, and prints a startup banner listing all active endpoints.

```python
app = FastAPI(title="BakhabarAI Backend", version="1.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], ...)
app.include_router(mock_data_router.router)
```

### API Endpoints: `backend/routers/mock_data_router.py`

All routes are prefixed with `/api`.

| Method | Endpoint | Description |
|:---|:---|:---|
| `GET` | `/api/incidents` | Fetches all **active** incidents from Firestore. Normalizes Firestore `GeoPoint` to `{lat, lng}` JSON. |
| `GET` | `/api/incidents/{id}` | Fetches a single incident by document ID. |
| `POST` | `/api/report` | Accepts a citizen report. Geocodes the location, creates a preliminary incident in Firestore immediately, saves the signal, then triggers the pipeline async. |
| `POST` | `/api/run-scenario` | Seeds two hardcoded Islamabad demo incidents (flood in G-10, heatwave in I-8) into Firestore, then launches the full pipeline in the background. Returns `202 Accepted` immediately. |
| `GET` | `/api/logs` | Returns all agent trace entries from the in-memory `AgentTracer`. |
| `GET` | `/api/places/autocomplete` | Proxies Google Places Autocomplete (New API first, classic fallback). |
| `GET` | `/api/debug/ping` | Health check. Returns server status and trace count. |
| `DELETE` | `/api/debug/logs` | Clears the in-memory trace buffer before a fresh scenario run. |
| `GET` | `/api/debug/incidents` | Returns ALL Firestore incidents regardless of status (for debugging). |

### Citizen Report Flow (`POST /api/report`)

1. Extract location name from message text (looks for `"in"`, `"at"`, or `:` patterns)
2. Geocode the extracted location via Google Geocoding API
3. **Immediately create a `MEDIUM` confidence preliminary incident** in Firestore (so it appears on the map without delay)
4. If a `media_url` was submitted, attach it directly to the incident document
5. Save the raw signal to Firestore with `trigger_type: "manual"`
6. Launch the crisis pipeline as an async background task to refine the incident
7. Return `{"status": "success"}` immediately (non-blocking)

### Agent Trace Logger: `backend/tracer.py`

`AgentTracer` is a singleton used across all pipeline stages. Every call to `tracer.log(...)` does two things:

1. **In-memory append**: Adds the trace entry to `self.traces[]` (served by `/api/logs`)
2. **Background Firestore write**: Uses a daemon thread to persist the log to the `agent_logs` Firestore collection (consumed by the Flutter app's real-time stream)

```python
class AgentTracer:
    def log(self, agent_name, action, input_data, output_data, confidence):
        # 1. Append to in-memory list
        self.traces.append({...})
        # 2. Write to Firestore in background thread (non-blocking)
        threading.Thread(target=FirebaseService.add_agent_log, ...).start()
```

---

## 5. Agent Orchestration: Google ADK

### Framework

BakhabarAI uses **Google Antigravity Agent Development Kit (ADK)** with `google.adk.agents.Agent` and `google.adk.tools.FunctionTool`. The pipeline is implemented in `backend/agents/pipeline.py` as an async orchestrator function `run_crisis_simulation()`.

### Model Strategy: `backend/agents/model_config.py`

The system uses a **dual-LLM pool strategy** to maximize throughput and handle rate limits:

- **Gemini 2.0 Flash** (via `google.adk.models.google_llm.Gemini`) — primary ADK-native model. Used when Groq is unavailable.
- **Groq llama-3.1-8b-instant** (via `google.adk.models.lite_llm.LiteLlm`) — faster, higher-throughput model. Multiple Groq API keys (from separate accounts) form a pool, with each pipeline stage assigned its own dedicated key to avoid TPM conflicts.

Each agent is assigned a fixed pool slot. On a 429 rate-limit error, the agent rotates through all pool slots before falling back to Gemini.

```python
_AGENT_SLOT = {
    "SignalFusionAgent":          0,  # Groq key 1
    "DetectorAgent":              1,  # Groq key 2
    "ResourcePlannerAgent":       2,  # Groq key 3
    "SimulationStakeholderAgent": 3,  # Groq key 4
    "ReporterAgent":              4,  # Groq key 5
}
```

---

### Stage 1 — Signal Fusion (`SignalFusionAgent`)

**File**: `backend/agents/signal_collector.py`  
**Triggered by**: All non-manual pipeline runs (scenario triggers, weather signals)

**What it does:**
- Fetches all `pending` signals from the `signals` Firestore collection
- Augments with any `mock_signals` passed in the scenario payload
- Processes signals in batches of 4
- **Deterministically** infers crisis type from signal content keywords (no LLM needed):
  - `"pani"`, `"flood"`, `"baarish"` → `flood`
  - `"garmi"`, `"heat"`, `"temperature"` → `heatwave`
  - `"aag"`, `"fire"`, `"pm2.5"`, `"smog"` → `fire`
  - `"bijli"`, `"blackout"`, `"outage"` → `power_outage`
- Assigns credibility-based severity: ≥0.8 → HIGH, ≥0.5 → MEDIUM, else LOW
- Calls `process_signal_evaluations()` to commit results to Firestore
- Marks processed signals to prevent reprocessing (session cache + DB status check)

**Deduplication logic:** Two-layer guard — session-level `set()` and Firestore document status check (`"verified"` / `"processed"` / `"noise"`).

---

### Stage 2 — Crisis Detection (`DetectorAgent`)

**File**: `backend/agents/detector.py`  
**Triggered by**: All non-manual pipeline runs

**What it does:**
- Queries active incidents that have no `affected_population` (i.e., unclassified)
- Builds a deterministic fallback classification for each incident (population estimates, duration, spread risk by crisis type)
- Attempts **Groq text-completion** (JSON mode, ~200 tokens) to classify severity, affected population, expected duration, and evolution prediction
- If Groq fails, uses the deterministic fallback
- Calls `process_incident_classifications()` to write enriched data back to Firestore

**Fallback type→population mapping:**
```
flood → 5,000 people  |  heatwave → 10,000  |  fire → 2,500
accident → 400        |  power_outage → 15,000  |  protest → 3,000
```

**Manual reports skip Stage 2** — the incident type is already known from the citizen's message.

---

### Stage 3 — Resource Planning (`ResourcePlannerAgent`)

**File**: `backend/agents/planner.py`  
**Always runs** (including manual reports)

**What it does:**
- Fetches all active incidents without `assigned_resources`
- Fetches all resources with `status: "available"` from Firestore
- Applies a **greedy priority algorithm** — no LLM needed, fully deterministic:
  - Sorts incidents by severity (HIGH → MEDIUM → LOW)
  - Allocates resources: HIGH gets 3, MEDIUM gets 2, LOW gets 1
- Calls `process_resource_allocations()` to write assignments to Firestore
- Logs a trade-off explanation string for visibility on the dashboard

---

### Stage 4 — Impact Simulation (`SimulationStakeholderAgent`)

**File**: `backend/agents/executor.py`  
**Always runs**

**What it does:**
- Checks each active incident for recent simulations (< 1 hour old) to avoid re-generating
- Builds **template-based fallback simulations** per crisis type:
  - `before_state`: English description of the pre-response situation
  - `after_state`: English description of the coordinated response outcome
  - `improvement_metrics`: `response_time_reduction`, `safety_boost`
  - `notifications`: Four stakeholder messages — `public` (Roman Urdu), `hospitals`, `utility_providers`, `law_enforcement`
- Attempts **Groq text-completion** to generate richer, LLM-authored simulations with proper Urdu alerts
- Commits results to the `action_simulations` Firestore collection via `process_simulations_and_messages()`

**Example public notification (Urdu):**
```
⚠️ FLOOD ALERT: Paani bhar gaya. Buland jagah par jayen foran.
```

---

### Stage 5 — Final Report (`ReporterAgent`)

**File**: `backend/agents/reporter.py`  
**Always runs as final stage**

**What it does:**
- Counts all active incidents grouped by severity
- Generates a summary string: `"Pipeline complete ✅ — 3 active incident(s) (HIGH=1, MEDIUM=2, LOW=0). Trigger: mock."`
- Logs the summary via `tracer.log()` for both the in-memory API and Firestore persistence
- No Firestore writes — purely a bookkeeping and observability stage

---

### Pipeline Trigger Modes

| Trigger Type | Stage 1 | Stage 2 | Stage 3 | Stage 4 | Stage 5 |
|:---|:---:|:---:|:---:|:---:|:---:|
| `mock` (scenario run) | ✅ | ✅ | ✅ | ✅ | ✅ |
| `manual` (citizen report) | ⏭ skipped | ⏭ skipped | ✅ | ✅ | ✅ |

---

## 6. API Integrations

### Google Maps Platform

All Google Maps integrations are wrapped in `backend/tools/maps_tool.py` using `httpx` async HTTP calls.

#### Geocoding API
Converts text addresses to `{lat, lng}` coordinates. Used when a citizen report is submitted to resolve the location name (e.g., `"G-10, Islamabad"`) into precise coordinates for the Firestore `GeoPoint`.

```python
GET https://maps.googleapis.com/maps/api/geocode/json
  ?address=G-10, Islamabad
  &key={GOOGLE_MAPS_API_KEY}
```

**Fallback**: If the API key is missing or the call fails, hardcoded coordinate maps for common Islamabad sectors are used (G-10 → `33.6844, 73.0479`; I-8 → `33.6811, 73.0805`).

#### Distance Matrix API
Calculates travel times and distances between origin/destination pairs. Used by the Planner agent to determine which resources are closest to each incident.

```python
GET https://maps.googleapis.com/maps/api/distancematrix/json
  ?origins=G-10, Islamabad
  &destinations=I-8, Islamabad
  &key={GOOGLE_MAPS_API_KEY}
```

#### Directions API
Returns route geometry (polyline, steps) for dispatch simulations. Used by the Executor agent to generate realistic routing data.

```python
GET https://maps.googleapis.com/maps/api/directions/json
  ?origin=Rescue HQ, Islamabad
  &destination=G-10, Islamabad
  &key={GOOGLE_MAPS_API_KEY}
```

#### Places API (New) + Classic Fallback
Powers the live location autocomplete in the Report Incident screen. The backend proxies the request to preserve the API key server-side.

```python
# New Places API (tried first)
POST https://places.googleapis.com/v1/places:autocomplete
  Headers: X-Goog-Api-Key: {key}
  Body: {"input": "G-10", "includedRegionCodes": ["pk"]}

# Classic fallback
GET https://maps.googleapis.com/maps/api/place/autocomplete/json
  ?input=G-10&components=country:pk&key={key}
```

#### Reverse Geocode
Converts `{lat, lng}` back to a human-readable address. Used for displaying location names from raw GPS coordinates.

#### Google Maps Flutter SDK (Mobile)
The Flutter app uses `google_maps_flutter` to render the interactive crisis map. Custom `Marker` widgets are placed at each incident's coordinates with color-coded severity. Map type is `normal` with custom padding to account for the bottom navigation bar.

---

### Google Weather API

Used via the Google Maps Platform Weather endpoint (`backend/tools/weather_tool.py`) to fetch current temperature, precipitation, wind speed, and storm risk for a given location. Weather data is fed into Stage 1 as a real-world signal source to validate or contradict social/sensor signals.

**Base URL**: `https://weather.googleapis.com/v1`

---

## 7. Data Strategy: Real vs. Mock

A core design decision is the strict separation between real API data and simulated signal data. **The Flutter UI never has hardcoded data** — it fetches everything from either Firestore streams or FastAPI endpoints.

### Real Data (Live APIs)

| Data Type | Source | Used For |
|:---|:---|:---|
| Map tiles & rendering | Google Maps Flutter SDK | Interactive crisis map |
| Incident coordinates | Google Geocoding API | Resolving citizen report locations |
| Travel times & distances | Google Distance Matrix API | Resource proximity in Stage 3 |
| Routing polylines | Google Directions API | Dispatch routing in Stage 4 |
| Place suggestions | Google Places API (New) | Report screen autocomplete |
| Weather conditions | Google Weather API | Signal validation in Stage 1 |

### Mock Data (Simulated Signals)

All mock data lives in `backend/data/` and represents signal types that cannot be provided by real APIs in a hackathon context.

#### `mock_social_posts.json`
Roman Urdu and English posts replicating citizen WhatsApp/Twitter reports:
```json
{
  "source_type": "social",
  "content": "G-10 mein pani bhar gaya hai, gaariyan phans gayi hain",
  "credibility_score": 0.7,
  "is_mock": true
}
```

#### `mock_emergency_calls.json`
Transcripts of 15 (Rescue) service calls with locations and severity indicators.

#### `mock_field_reports.json`
Structured inputs from traffic wardens or first responders — high credibility (`0.85-0.95`).

#### `mock_sensors.json`
Telemetry from storm-water sensors, heat monitors, and grid power sensors with numeric readings.

#### `backend/data/scenarios/`

Three pre-configured scenario JSON files define the signal mix for each demo:

| Scenario | File | Crisis | Key Feature |
|:---|:---|:---|:---|
| 1 | `scenario_1_flood.json` | Urban flood, G-10 | Single-crisis detection |
| 2 | `scenario_2_multi_crisis.json` | Flood G-10 + Heatwave I-8 | Resource trade-off allocation |
| 3 | `scenario_3_false_alarm.json` | Flood F-11 (false alarm) | Conflict detection & retraction |

---

## 8. Firebase Integration

Firebase Firestore acts as the real-time data layer between the FastAPI backend and the Flutter mobile app.

### Collections

| Collection | Documents | Purpose |
|:---|:---|:---|
| `incidents` | One per active crisis | Core incident data with type, severity, location (GeoPoint), confidence, population, resources |
| `signals` | One per ingested signal | Raw signal data with status lifecycle: `pending` → `verified`/`noise` → `processed` |
| `resources` | One per emergency unit | Resource pool with type, status (`available`/`deployed`), assigned incident |
| `action_simulations` | One per incident simulation | Before/after state, improvement metrics, stakeholder notifications |
| `agent_logs` | One per tracer entry | Agent name, action description, confidence, timestamp |

### Incident Lifecycle

```
Citizen submits report (POST /api/report)
        ↓
Preliminary incident created immediately → status: "active", confidence: 0.3
        ↓
Pipeline runs in background
        ↓
Stage 1: Signal verified → confidence boosted to ~0.58
Stage 2: Classification → affected_population, expected_duration_hours added
Stage 3: Resources assigned → assigned_resources[] populated
Stage 4: Simulation created → action_simulations document created
Stage 5: Summary logged → agent_logs entry
        ↓
Flutter Firestore stream fires → incident appears on map & dashboard instantly
```

### Flutter ↔ Firestore Real-time Streams (`api_service.dart`)

The `ApiService` class in Flutter maintains active Firestore listeners:

```dart
// Incidents stream — filtered to active only
Stream<List<Incident>> getIncidentsStream()         // active incidents only
Stream<List<Incident>> getIncidentHistoryStream()   // last 20, any status
Stream<Incident?> getIncidentStream(String id)      // single incident

// Other collections
Stream<List<AgentTrace>> getAgentLogsStream()       // sorted latest-first
Stream<List<Resource>> getResourcesStream()          // full pool
Stream<List<ActionSimulation>> getSimulationsStream() // sorted latest-first
```

All streams handle Firestore `GeoPoint`, `Timestamp`, and nested map deserialization defensively, with `debugPrint` on parse errors.

### Firebase Authentication

User authentication uses Firebase Auth with a simulated phone + OTP flow. Auth is **only required to submit reports** — all incident viewing is public. The `AuthProvider` in `mobile/lib/core/auth_provider.dart` manages auth state and exposes it via Flutter's `Provider`.

---

## 9. Flutter Mobile Application

### Technology

- **Framework**: Flutter (Dart), targeting Android APK
- **State Management**: `Provider` + `StatefulWidget` (per screen)
- **HTTP Client**: `Dio` with `LogInterceptor` in debug mode
- **Real-time Data**: Firebase Firestore SDK (`cloud_firestore`)
- **Maps**: `google_maps_flutter`
- **Icons**: `lucide_icons` exclusively — no Material or Cupertino icons
- **Fonts**: `google_fonts` (Poppins, Inter, JetBrains Mono)

### `ApiService` (`mobile/lib/services/api_service.dart`)

Central service class with two types of data access:

1. **Firestore streams** — for real-time data (incidents, logs, resources, simulations). No polling needed.
2. **Dio REST calls** — for actions (submit report, run scenario, places autocomplete).

The `baseUrl` is configured to the local network IP of the machine running FastAPI (`http://192.168.x.x:8000/api`), enabling a physical Android device on the same Wi-Fi to connect.

### `LocationService` (`mobile/lib/services/location_service.dart`)

Requests device location permission and retrieves current GPS coordinates. Used on `HomeScreen` to display the user's position on the map and pre-fill coordinates in the report form.

### `NotificationService` (`mobile/lib/services/notification_service.dart`)

Handles local push notification setup for incident alerts dispatched by the backend pipeline.

---

## 10. Design System

The design system is enforced strictly via `mobile/lib/core/theme.dart`. No screen or widget uses hardcoded colors or font declarations directly.

### Color Palette (`AppColors`)

| Token | Hex | Usage |
|:---|:---|:---|
| `primary` | `#f4f1e9` | Warm off-white scaffold background |
| `accent` | `#ff6036` | Coral orange — CTAs, active states, borders |
| `textPrimary` | `#1a1a1a` | Near-black body and heading text |
| `textMuted` | `#6b6b6b` | Secondary labels, timestamps |
| `cardBg` | `#ffffff` | Card and input field backgrounds |
| `severityHigh` | `#ef4444` | Red — HIGH severity indicators |
| `severityMedium` | `#f59e0b` | Amber — MEDIUM severity indicators |
| `severityLow` | `#22c55e` | Green — LOW severity + success states |

### Typography (`AppTextStyles`)

| Style | Font | Weight | Size |
|:---|:---|:---|:---|
| `h1` | Poppins | Bold (700) | 24px |
| `h2` | Poppins | SemiBold (600) | 18px |
| `body` | Inter | Regular (400) | 14px |
| `bodyMuted` | Inter | Regular (400) | 14px + muted color |
| `label` | Inter | Medium (500) | 12px |
| `mono` | JetBrains Mono | Regular | 12px — agent logs only |

### Component Rules

- **Buttons**: 52px height, 16px border radius, coral fill + white text
- **Cards**: white background, 16px radius, `0 4px 12px rgba(0,0,0,0.08)` shadow
- **Severity card borders**: 4px left border (red for HIGH, amber for MEDIUM)
- **Input fields**: 52px height, 12px radius, 2px coral focus border
- **Severity badges**: 6px radius pill, colored background, white text
- **Glassmorphism**: `rgba(255,255,255,0.85)` + `12px` backdrop blur — used **only** on map popup cards

### Loading States

Every screen that fetches data displays a `SkeletonLoader` widget (`mobile/lib/widgets/skeleton_loader.dart`) using a shimmer animation while the Firestore stream or API call is pending. No screen ever shows blank content during loading.

---

## 11. Screens & Navigation

### Navigation Structure

```
Stack Navigator:
  └── SplashScreen → AuthWrapper
        ├── SignupScreen → OtpScreen → MainShell
        └── (if logged in) → MainShell

Bottom Tab Navigator (MainShell) — 4 tabs:
  ├── Tab 0: HomeScreen           (overview + mini map + incident previews)
  ├── Tab 1: MapScreen            (full map + crisis markers)
  ├── Tab 2: AIAssistantChatScreen (AI chat for incident queries)
  └── Tab 3: AgentLogsScreen      (real-time agent trace timeline)

Push Navigation:
  HomeScreen → IncidentsScreen
  IncidentsScreen → IncidentDetailScreen
  IncidentDetailScreen → ResourceAllocationScreen
  IncidentDetailScreen → SimulationScreen
  IncidentsScreen → ResourceAllocationScreen (all crises)
  IncidentsScreen → SimulationScreen (all crises)
  SimulationScreen → AgentLogsScreen
  HomeScreen → ReportScreen (auth required)
```

### Screen Descriptions

| Screen | File | Key Features |
|:---|:---|:---|
| `SplashScreen` | `splash_screen.dart` | App logo + loading animation |
| `HomeScreen` | `home_screen.dart` | Mini map, incident summary cards, location permission popup, "Run Scenario" button |
| `MapScreen` | `map_screen.dart` | Full Google Maps with severity-colored markers, crisis popup cards (glassmorphic) |
| `AIAssistantChatScreen` | `ai_assistant_chat_screen.dart` | Chat interface for querying incidents and getting AI responses |
| `AgentLogsScreen` | `agent_logs_screen.dart` | Scrollable chronological agent trace log in JetBrains Mono |
| `IncidentsScreen` | `incidents_screen.dart` | Filterable list of all active incidents with severity badges |
| `IncidentDetailScreen` | `incident_detail_screen.dart` | Full incident profile — map, signals, media, population, duration, confidence bar |
| `ResourceAllocationScreen` | `resource_allocation_screen.dart` | Resource pool visualization, assignment list, trade-off explanation |
| `SimulationScreen` | `simulation_screen.dart` | Before/After tabs, stakeholder notifications per audience |
| `ReportScreen` | `report_screen.dart` | Form with location autocomplete, incident type, photo upload, text description |

---

## 12. Data Models

### Incident (`mobile/lib/models/incident.dart`)

```dart
class Incident {
  final String crisisId;
  final String type;           // flood | heatwave | accident | fire | power_outage | protest
  final String severity;       // HIGH | MEDIUM | LOW
  final double confidence;     // 0.0 – 1.0
  final String status;         // active | resolved | false_alarm
  final int? affectedPopulation;
  final int? expectedDurationHours;
  final String? peakImpactTime;
  final Map<String, dynamic> location;  // {name, lat, lng}
  final List<String> signalSources;
  final String? mediaUrl;
  final DateTime? timestamp;
}
```

### Resource (`mobile/lib/models/resource.dart`)

```dart
class Resource {
  final String id;
  final String type;       // ambulance | police | rescue | drone
  final String status;     // available | deployed
  final String? assignedIncidentId;
}
```

### AgentTrace (`mobile/lib/models/agent_log.dart`)

```dart
class AgentTrace {
  final String id;
  final String agentName;
  final String action;
  final double confidence;
  final DateTime timestamp;
}
```

### ActionSimulation (`mobile/lib/models/simulation.dart`)

```dart
class ActionSimulation {
  final String id;
  final String incidentId;
  final String actionType;
  final String description;
  final Map<String, dynamic> impactPrediction;         // before_state, after_state, improvement_metrics
  final Map<String, String> stakeholderNotifications;  // public, hospitals, utility_providers, law_enforcement
  final DateTime timestamp;
}
```

---

## 13. Demo Scenarios

### Scenario 1: Urban Flood — G-10, Islamabad

**Trigger**: `POST /api/run-scenario` with default payload  
**Seeds**: HIGH severity flood at `33.6938, 73.0213` (G-10)  
**Pipeline Flow**:
1. Signal Fusion skips (no pending social signals unless pre-seeded)
2. Detector classifies: `flood` → population 5,000 → 8 hrs duration
3. Planner assigns 3 resources (HIGH priority)
4. Simulator generates flood response template + Urdu public alert
5. Reporter logs summary

**Expected UI**: RED marker on G-10 on the map; incident card shows HIGH badge; simulation shows rescue boat dispatch and evacuation corridors.

---

### Scenario 2: Multi-Crisis — G-10 Flood + I-8 Heatwave

**Trigger**: `POST /api/run-scenario`  
**Seeds**: HIGH flood (G-10) + MEDIUM heatwave (I-8)  
**Pipeline Flow**:
- Planner must allocate from a shared resource pool
- HIGH flood gets 3 resources allocated first
- MEDIUM heatwave gets 2 from remaining pool
- Trade-off log explains priority reasoning

**Expected UI**: Two markers (RED + AMBER) on map; Resource Allocation screen shows split assignments with trade-off explanation; Simulation screen shows two separate before/after panels.

---

### Scenario 3: False Alarm — F-11

**Design**: A flood signal is submitted via `/api/report` for F-11. A conflicting field report with high credibility contradicts it. The system's signal credibility comparison logic identifies the conflict, marks the original signal as `noise`, and the incident confidence drops. The simulation generates a utility-check notification instead of a full emergency alert.

**Expected UI**: Incident briefly appears on dashboard with LOW confidence badge, then transitions to `false_alarm` status with a retraction notification visible in the Simulation screen.

---

## 14. Configuration & Environment

### `.env` File (root directory — never committed)

```bash
# Google APIs
GOOGLE_MAPS_API_KEY=your_google_cloud_api_key
GEMINI_API_KEY=your_gemini_api_key

# Groq (optional — multiple keys for pool)
GROQ_API_KEY=gsk_...
GROQ_API_KEYS=gsk_key1,gsk_key2,gsk_key3   # comma-separated pool

# Behaviour flags
PREFER_GROQ=True   # True = use Groq first, False = use Gemini only
DEBUG=True

# Flutter
BACKEND_URL=http://192.168.x.x:8000
FLUTTER_MAPS_KEY=your_google_android_maps_key
```

### Firebase Configuration

- **`backend/firebase_config.py`**: Loads the Firebase Admin SDK service account JSON from environment or file. Initializes `firebase_admin` and returns `db = firestore.client()`.
- **`backend/.firebaserc`**: Firebase project reference.
- **`mobile/`**: Contains `google-services.json` (Android) for Flutter Firebase SDK initialization.
- **Custom Firestore database**: The app uses a named database (`bakhabarai-db`) instead of the default — configured in `ApiService._firestore`.

### Flutter Android Manifest

The Google Maps Android SDK API key is injected via the `AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${MAPS_API_KEY}"/>
```

---

## 15. Running the Project

### Prerequisites

- Python 3.11+
- Flutter SDK 3.x + Android Studio + Android SDK (API level 21+)
- A Google Cloud project with these APIs enabled:
  - Maps SDK for Android
  - Geocoding API
  - Distance Matrix API
  - Directions API
  - Places API (New)
  - Google Weather API (if available in your region)
- Firebase project with Firestore enabled (named database: `bakhabarai-db`)
- A physical Android device or emulator with Google Play Services

### Backend Setup

```bash
cd backend

# Create and activate virtual environment
python -m venv .venv
.venv\Scripts\activate           # Windows
# or: source .venv/bin/activate  # macOS/Linux

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp ../.env.example ../.env
# Edit .env with your API keys

# Start the server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The server will print a banner with all active endpoints. The `--host 0.0.0.0` flag allows physical Android devices on the same network to connect.

### Flutter Setup

```bash
cd mobile

# Get dependencies
flutter pub get

# Connect an Android device or start an emulator
# Update api_service.dart baseUrl to your machine's local IP:
# static const String baseUrl = 'http://YOUR_MACHINE_IP:8000/api';

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### View Agent Traces (ADK Web UI)

```bash
cd backend
adk web
# Opens at http://localhost:8000/adk — shows structured trace viewer
```

---

## 16. Folder Structure

```
bakhabarai/
├── mobile/                          # Flutter Android app
│   ├── lib/
│   │   ├── main.dart                # App entry + Firebase init + theme setup
│   │   ├── core/
│   │   │   ├── theme.dart           # AppColors, AppTextStyles, AppTheme
│   │   │   ├── router.dart          # Named routes + GoRouter
│   │   │   ├── auth_provider.dart   # Firebase Auth state
│   │   │   └── utils.dart           # Shared utility functions
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── auth/
│   │   │   │   ├── signup_screen.dart
│   │   │   │   └── otp_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── map_screen.dart
│   │   │   ├── incidents_screen.dart
│   │   │   ├── incident_detail_screen.dart
│   │   │   ├── resource_allocation_screen.dart
│   │   │   ├── simulation_screen.dart
│   │   │   ├── agent_logs_screen.dart
│   │   │   ├── ai_assistant_chat_screen.dart
│   │   │   └── report_screen.dart
│   │   ├── widgets/
│   │   │   ├── bottom_nav_bar.dart
│   │   │   ├── skeleton_loader.dart
│   │   │   └── top_app_bar.dart
│   │   ├── models/
│   │   │   ├── incident.dart
│   │   │   ├── resource.dart
│   │   │   ├── agent_log.dart
│   │   │   └── simulation.dart
│   │   └── services/
│   │       ├── api_service.dart     # Dio REST + Firestore real-time streams
│   │       ├── location_service.dart
│   │       └── notification_service.dart
│   ├── android/
│   │   └── app/src/main/
│   │       └── AndroidManifest.xml
│   └── pubspec.yaml
│
├── backend/                         # FastAPI + Google ADK
│   ├── main.py                      # FastAPI app, CORS, startup banner
│   ├── config.py                    # .env loading, API key parsing
│   ├── tracer.py                    # AgentTracer — in-memory + Firestore logging
│   ├── firebase_config.py           # Firebase Admin SDK initialization
│   ├── data_model.py                # Shared Pydantic models
│   ├── agents/
│   │   ├── __init__.py
│   │   ├── pipeline.py              # Main 5-stage async orchestrator
│   │   ├── signal_collector.py      # Stage 1: SignalFusionAgent
│   │   ├── detector.py              # Stage 2: DetectorAgent
│   │   ├── planner.py               # Stage 3: ResourcePlannerAgent
│   │   ├── executor.py              # Stage 4: SimulationStakeholderAgent
│   │   ├── reporter.py              # Stage 5: ReporterAgent
│   │   ├── model_config.py          # Gemini + Groq pool initialization
│   │   └── adk_runtime.py           # ADK agent runner utilities
│   ├── routers/
│   │   └── mock_data_router.py      # All /api/* endpoints
│   ├── tools/
│   │   ├── maps_tool.py             # Geocoding, Directions, Distance Matrix, Places
│   │   ├── weather_tool.py          # Google Weather API wrapper
│   │   ├── firebase_tools.py        # Firestore CRUD helpers
│   │   └── mock_tools.py            # Mock data loader utilities
│   ├── services/
│   │   └── firebase_service.py      # High-level Firebase service layer
│   ├── data/
│   │   ├── mock_social_posts.json
│   │   ├── mock_emergency_calls.json
│   │   ├── mock_field_reports.json
│   │   ├── mock_sensors.json
│   │   └── scenarios/
│   │       ├── scenario_1_flood.json
│   │       ├── scenario_2_multi_crisis.json
│   │       └── scenario_3_false_alarm.json
│   └── requirements.txt
│
├── traces/                          # Auto-exported agent trace JSONs
├── specs/                           # Feature specifications
├── .env                             # API keys — never commit
├── .env.example                     # Safe template
├── .gitignore
├── AGENTS.md                        # Project constitution
├── README.md                        # Quick start
└── DOCUMENTATION.md                 # This file
```

---

*BakhabarAI — Built for the CIRO Challenge using Google Antigravity (ADK), Gemini 2.0 Flash, Firebase, and Flutter.*

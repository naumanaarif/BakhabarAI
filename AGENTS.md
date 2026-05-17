<!-- SPECKIT START -->

# BakhabarAI — Agent Constitution & Spec Guide
> Read this file FIRST before writing any code, creating any file, or making any decision.
> This is the single source of truth for the entire project.

---

## 1. Project Overview

**App Name:** BakhabarAI  
**Tagline:** Shehar ka Nigehban (Guardian of the City)  
**Type:** Mobile App (Flutter) + AI Backend (Python + Google ADK)  
**Purpose:** Agentic AI system that detects urban crises (floods, heatwaves, accidents), allocates resources, simulates coordinated responses, and shows outcomes — built for Pakistani cities.  
**Hackathon:** CIRO Challenge — Crisis Intelligence & Response Orchestrator  
**Mandatory Requirement:** Google Antigravity (ADK) must orchestrate ALL agent workflows  

---

## 2. Tech Stack — Never Deviate From This

### Frontend
```
Framework:     Flutter (Dart)
Target:        Android (APK) — primary
Maps:          google_maps_flutter
Icons:         lucide_icons ONLY — never use Material or Cupertino icons
State Mgmt:    Provider or Riverpod
HTTP Client:   dio
Local Storage: shared_preferences (minimal use)
long screens in Screen folder will use scrollbar
```

### Backend
```
Language:      Python 3.11+
Framework:     FastAPI
Agent System:  Google ADK (google-adk)
LLM:           Gemini 2.0 Flash via ADK
WSGI:          uvicorn
```

### APIs & Services
```
Maps/Routing:  Google Maps Platform (single API key)
Weather:       Google Weather API (via Maps Platform)
Air Quality:   Google Air Quality API
Directions:    Google Directions API
Geocoding:     Google Geocoding API
Places:        Google Places API (New)
Routes:        Google Routes API
Distance:      Google Distance Matrix API
Roads:         Google Roads API
Database:      Firebase Firestore (optional, for persistence)
```

### Data Strategy
```
REAL APIs:     Weather, Maps, Air Quality, Routes, Geocoding
MOCK DATA:     Social media posts, Emergency calls, Field reports, Sensors
FORMAT:        All signals normalized to same JSON schema before agents see them
```

---

## 3. Project Folder Structure — Always Follow This

```
bakhabarai/
├── mobile/                          # Flutter app
│   ├── lib/
│   │   ├── main.dart                # App entry point + theme
│   │   ├── core/
│   │   │   ├── theme.dart           # Colors, typography, component styles
│   │   │   ├── constants.dart       # API endpoints, keys references
│   │   │   └── router.dart          # All named routes
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
│   │   │   └── report_screen.dart
│   │   ├── widgets/
│   │   │   ├── incident_card.dart
│   │   │   ├── severity_badge.dart
│   │   │   ├── confidence_bar.dart
│   │   │   ├── resource_row.dart
│   │   │   ├── agent_log_tile.dart
│   │   │   ├── crisis_marker.dart
│   │   │   ├── bottom_nav_bar.dart
│   │   │   └── simulation_outcome_card.dart
│   │   ├── models/
│   │   │   ├── incident.dart
│   │   │   ├── resource.dart
│   │   │   ├── agent_log.dart
│   │   │   └── simulation_result.dart
│   │   └── services/
│   │       ├── api_service.dart     # All FastAPI calls
│   │       └── location_service.dart
│   ├── android/
│   │   └── app/src/main/
│   │       └── AndroidManifest.xml  # API key + permissions
│   └── pubspec.yaml
│
├── backend/                         # FastAPI + ADK
│   ├── main.py                      # FastAPI routes
│   ├── agents/
│   │   ├── signal_collector.py      # Agent 1
│   │   ├── detector.py              # Agent 2
│   │   ├── planner.py               # Agent 3
│   │   ├── executor.py              # Agent 4
│   │   └── reporter.py              # Agent 5
│   ├── tools/
│   │   ├── weather_tool.py          # Google Weather API wrapper
│   │   ├── maps_tool.py             # Maps/Routes/Directions wrapper
│   │   ├── geocoding_tool.py        # Geocoding wrapper
│   │   └── mock_tools.py            # Social posts, sensors, calls
│   ├── data/
│   │   ├── mock_social_posts.json
│   │   ├── mock_emergency_calls.json
│   │   ├── mock_field_reports.json
│   │   ├── mock_sensors.json
│   │   └── scenarios/
│   │       ├── scenario_1_flood.json
│   │       ├── scenario_2_multi_crisis.json
│   │       └── scenario_3_false_alarm.json
│   ├── tracer.py                    # Agent trace logger
│   ├── config.py                    # All env var loading
│   └── requirements.txt
│
├── traces/                          # Auto-generated agent logs (submission)
│   └── .gitkeep
│
├── .env                             # API keys — never commit this
├── .env.example                     # Safe template to commit
├── .gitignore
├── AGENT.md                         # This file
└── README.md
```

---

## 4. Design System — Never Break These Rules

### Colors
```dart
// ALWAYS use these exact values — no approximations
static const Color primary     = Color(0xFFf4f1e9);  // warm off-white background
static const Color accent      = Color(0xFFff6036);  // coral orange — CTAs, active states
static const Color textPrimary = Color(0xFF1a1a1a);  // near black
static const Color textMuted   = Color(0xFF6b6b6b);  // gray secondary text
static const Color cardBg      = Color(0xFFffffff);  // white cards
static const Color severityHigh   = Color(0xFFef4444); // red
static const Color severityMedium = Color(0xFFf59e0b); // amber
static const Color severityLow    = Color(0xFF22c55e); // green
static const Color successGreen   = Color(0xFF22c55e);
static const Color dangerRed      = Color(0xFFef4444);
```

### Typography
```dart
// Headings:     Poppins Bold    24px
// Subheadings:  Poppins SemiBold 18px
// Body:         Inter Regular   14px
// Labels:       Inter Medium    12px
// Monospace:    JetBrains Mono  12px (agent logs only)
```

### Component Rules
```
Buttons:
  - Height: 52px
  - Border radius: 16px
  - Primary: accent fill (#ff6036), white text
  - Secondary: 2px accent border, accent text, transparent fill

Cards:
  - Background: white
  - Border radius: 16px
  - Shadow: 0 4px 12px rgba(0,0,0,0.08)
  - HIGH severity: left border 4px #ef4444
  - MEDIUM severity: left border 4px #f59e0b

Input Fields:
  - Height: 52px
  - Border radius: 12px
  - Background: white
  - Border focus: 2px #ff6036

Badges (Severity):
  - Border radius: 6px (pill)
  - Padding: 4px 10px
  - HIGH   → red bg   + white text
  - MEDIUM → amber bg + white text
  - LOW    → green bg + white text

Glassmorphism (MAP OVERLAY ONLY):
  - Background: rgba(255,255,255,0.85)
  - Backdrop blur: 12px
  - Border: 1px rgba(255,255,255,0.3)
  - Use ONLY on map popup cards — nowhere else
```

### Icons — LUCIDE ONLY
```dart
// RULE: Never import or use MaterialIcons or CupertinoIcons
// ALWAYS use: import 'package:lucide_icons/lucide_icons.dart'
// Standard size: 22px
// Active color:  #ff6036 (coral)
// Inactive color: #6b6b6b (gray)

// Navigation icons
home          → LucideIcons.home
map           → LucideIcons.map
incidents     → LucideIcons.alertTriangle
report        → LucideIcons.plusCircle
logs          → LucideIcons.scrollText

// Crisis type icons
flood         → LucideIcons.waves
heatwave      → LucideIcons.thermometerSun
accident      → LucideIcons.car
power outage  → LucideIcons.zap
protest       → LucideIcons.megaphone
disease       → LucideIcons.virus
default       → LucideIcons.alertTriangle

// Resource icons
ambulance     → LucideIcons.ambulance
police        → LucideIcons.shield
rescue        → LucideIcons.hardHat
drone         → LucideIcons.radio

// UI icons
location      → LucideIcons.mapPin
confidence    → LucideIcons.barChart2
population    → LucideIcons.users
time/duration → LucideIcons.clock
confirmed     → LucideIcons.checkCircle
conflicting   → LucideIcons.alertCircle
notification  → LucideIcons.bell
search        → LucideIcons.search
back arrow    → LucideIcons.arrowLeft
settings      → LucideIcons.settings
agent/AI      → LucideIcons.cpu
signal        → LucideIcons.radio
detection     → LucideIcons.scanSearch
planning      → LucideIcons.brainCircuit
execution     → LucideIcons.play
before state  → LucideIcons.xCircle
after state   → LucideIcons.checkCircle
```

---

## 5. Screen List & Navigation Flow

```
Stack Navigator:
  └── SplashScreen → AuthWrapper
        ├── SignupScreen → OtpScreen → MainShell
        └── (if logged in) → MainShell

Bottom Tab Navigator (MainShell):
  ├── Tab 0: HomeScreen
  ├── Tab 1: MapScreen
  ├── Tab 2: AIAssistantChatScreen
  └── Tab 3: AgentLogsScreen

Push Navigation (from screens above):
  IncidentsScreen → IncidentDetailScreen
  IncidentDetailScreen → ResourceAllocationScreen (specific crisis)
  IncidentDetailScreen → SimulationScreen (specific crisis)
  IncidentsScreen → ResourceAllocationScreen (overall — all crises)
  IncidentsScreen → SimulationScreen (overall — all crises)
  ResourceAllocationScreen → SimulationScreen
  SimulationScreen → AgentLogsScreen
```

### Screen Purpose Summary
```
SplashScreen          → App logo + loading
HomeScreen            → Mini map + incident previews + Location Access Popup
MapScreen             → Full map + RED/ORANGE/PURPLE markers + reroute overlay
AIAssistantChatScreen → AI Assistant chat for incidents/reporting
AgentLogsScreen       → Scrollable agent reasoning timeline
IncidentDetailScreen  → Single crisis full info + media + sources
ResourceAllocation    → Pool + assignments + trade-offs (overall OR specific)
SimulationScreen      → Before/Actions/After tabs (overall OR specific)
AgentLogsScreen       → Scrollable agent reasoning timeline
ReportScreen          → Form to submit new incident (auth required)
```

---

## 6. Agent Architecture — ADK Rules

### The 5 Agents (Build in This Order)
```
Agent 1: SignalCollectorAgent
  Role:    Ingests all signal sources and normalizes them
  Inputs:  Weather API, Maps API, Mock JSON files
  Outputs: Normalized signal list with credibility scores
  Tools:   weather_tool, maps_tool, mock_tools

Agent 2: DetectorAgent
  Role:    Classifies crisis type, location, severity, confidence
  Inputs:  Normalized signals from Agent 1
  Outputs: Crisis objects with type/severity/confidence/location
  Tools:   geocoding_tool, Gemini reasoning

Agent 3: PlannerAgent
  Role:    Allocates constrained resources across crises
  Inputs:  Detected crises + resource pool
  Outputs: Resource assignments + trade-off explanations
  Tools:   distance_matrix_tool, Gemini reasoning

Agent 4: ExecutorAgent
  Role:    Simulates response actions
  Inputs:  Resource plan from Agent 3
  Outputs: Simulation results (reroutes, alerts, tickets, notifications)
  Tools:   directions_tool, maps_tool, Gemini for message generation

Agent 5: ReporterAgent
  Role:    Generates before/after comparison + stakeholder messages
  Inputs:  All outputs from Agents 1-4
  Outputs: Final simulation outcome + stakeholder notifications
  Tools:   Gemini reasoning
```

### ADK Orchestration Rules
```python
# ALWAYS use ADK SequentialAgent for the main pipeline
# NEVER call agents directly without ADK orchestration
# ALWAYS pass full context between agents
# ALWAYS use ADK tools — never raw API calls inside agents
# Antigravity MUST be visible in agent traces for submission

from google.adk.agents import SequentialAgent, Agent
from google.adk.tools import FunctionTool

# Main pipeline
crisis_pipeline = SequentialAgent(
    name="BakhabarAI_Pipeline",
    agents=[
        signal_collector_agent,
        detector_agent,
        planner_agent,
        executor_agent,
        reporter_agent
    ]
)
```

### Signal Schema — All Sources Must Match This
```json
{
  "signal_id": "uuid",
  "source_type": "weather|social|traffic|sensor|emergency_call|field_report",
  "source_name": "Google Weather API",
  "timestamp": "ISO8601",
  "location": {
    "name": "G-10, Islamabad",
    "lat": 33.6844,
    "lng": 73.0479
  },
  "content": "heavy rainfall 23mm detected",
  "credibility_score": 0.95,
  "is_mock": false,
  "raw_data": {}
}
```

### Crisis Object Schema
```json
{
  "crisis_id": "uuid",
  "type": "flood|heatwave|accident|power_outage|protest|disease",
  "location": { "name": "", "lat": 0, "lng": 0 },
  "severity": "HIGH|MEDIUM|LOW",
  "confidence": 0.82,
  "affected_population": 12000,
  "expected_duration_hours": 6,
  "peak_impact_time": "ISO8601",
  "signal_sources": [],
  "conflicting_signals": [],
  "status": "active|resolved|false_alarm"
}
```

---

## 7. API Integration Rules

### Environment Variables — Always Load From .env
```python
# config.py — always use this pattern
from dotenv import load_dotenv
import os

load_dotenv()

GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY")
GEMINI_API_KEY      = os.getenv("GEMINI_API_KEY")
WEATHER_BASE_URL    = "https://weather.googleapis.com/v1"
MAPS_BASE_URL       = "https://maps.googleapis.com/maps/api"
```

### .env File Structure
```bash
# .env (never commit — add to .gitignore)
GOOGLE_MAPS_API_KEY=your_key_here
GEMINI_API_KEY=your_key_here
BACKEND_URL=http://localhost:8000
FLUTTER_MAPS_KEY=your_android_key_here
```

### Flutter API Key Rule
```xml
<!-- AndroidManifest.xml — Maps key goes here -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${MAPS_API_KEY}"/>
```

### FastAPI Endpoint Structure
```
POST /api/run-scenario          → triggers full agent pipeline
GET  /api/incidents             → returns all detected crises
GET  /api/incidents/{id}        → single crisis detail
GET  /api/resources             → resource allocation results
GET  /api/simulation/{id}       → simulation outcomes
GET  /api/logs                  → agent trace logs
POST /api/report                → submit new incident
```

---

## 8. Mock Data Rules

### When to Use Mock vs Real
```
REAL:  Weather, Maps rendering, Routes, Air Quality, Geocoding
MOCK:  Social media posts, Emergency calls, Field reports, Sensors

RULE: Mock data must be realistic Pakistani context
  - Use Urdu/Roman Urdu text in social posts
  - Use real Islamabad sector names (G-10, I-8, F-11 etc)
  - Use real Pakistani phone number format
  - Use realistic timestamps
```

### Mock Social Post Example
```json
{
  "signal_id": "sp_001",
  "source_type": "social",
  "source_name": "WhatsApp Report",
  "timestamp": "2024-01-15T14:30:00Z",
  "location": { "name": "G-10, Islamabad", "lat": 33.6844, "lng": 73.0479 },
  "content": "G-10 mein pani bhar gaya hai, gaariyan phans gayi hain",
  "credibility_score": 0.7,
  "is_mock": true
}
```

### 3 Mandatory Demo Scenarios
```
scenario_1_flood.json
  → Single crisis: Urban flood in G-10
  → Sources: Weather (real) + Social posts (mock) + Traffic (real)
  → Expected output: HIGH severity flood detected

scenario_2_multi_crisis.json
  → Two simultaneous: G-10 Flood + I-8 Heatwave
  → Shows resource trade-off between two crises
  → Expected output: Resource allocation with trade-off explanation

scenario_3_false_alarm.json
  → Starts as flood signal, field report contradicts it
  → System detects conflicting signal, retracts alert
  → Expected output: False alarm recovery + retraction message
```

---

## 9. Flutter Development Rules

### Never Do These
```
❌ Never use MaterialIcons — use lucide_icons only
❌ Never hardcode colors — always reference AppColors class
❌ Never hardcode strings — use constants or l10n
❌ Never make API calls directly from screens — use services/api_service.dart
❌ Never use setState for complex state — use Provider/Riverpod
❌ Never use localStorage/browser storage
❌ Never skip loading states — every API call needs a Skeleton Loading placeholder
❌ Never skip error states — every API call needs an error handler
❌ Never hardcode mock data on the UI. Create an API endpoint to fetch mockup data.
```

### Always Do These
```
✅ Always use AppColors.accent for coral color references
✅ Always use AppTextStyles for typography
✅ Always show Skeleton Loading placeholders while fetching data
✅ Always handle empty states (no incidents found etc)
✅ Always use named routes for navigation with screen transitions
✅ Always show a Back Button on the top left corner of each screen
✅ Always show a loading circle with the agent name when Agent is processing a response
✅ Always ask user for Location via popup on the main home/overview splash screen
✅ Always extract repeated UI into widgets/
```

### Screen Template Pattern
```dart
// Every screen follows this structure
class ExampleScreen extends StatefulWidget {
  @override
  _ExampleScreenState createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  bool _isLoading = false;
  String? _error;
  // data variables

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // fetch data
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return LoadingWidget();
    if (_error != null) return ErrorWidget(message: _error!);
    return Scaffold(
      backgroundColor: AppColors.primary,
      // screen content
    );
  }
}
```

---

## 10. Agent Trace Logging — Add After App Works

```python
# tracer.py — import this in every agent file
import json
from datetime import datetime

class AgentTracer:
    def __init__(self):
        self.traces = []

    def log(self, agent: str, action: str, 
            input_data: dict, output_data: dict, 
            confidence: float = None):
        self.traces.append({
            "timestamp": datetime.now().isoformat(),
            "agent": agent,
            "action": action,
            "input": input_data,
            "output": output_data,
            "confidence": confidence
        })

    def export(self, path: str = "traces/agent_trace.json"):
        with open(path, "w") as f:
            json.dump(self.traces, f, indent=2)

# Global instance — import this everywhere
tracer = AgentTracer()

# Usage in any agent:
tracer.log(
    agent="DetectorAgent",
    action="classified_crisis",
    input_data={"signals": 4, "location": "G-10"},
    output_data={"type": "flood", "severity": "HIGH"},
    confidence=0.82
)
```

---

## 11. Git & File Rules

```
.gitignore must include:
  .env
  *.pyc
  __pycache__/
  .dart_tool/
  build/
  traces/*.json    # don't commit traces to git

Branch naming:
  main             → stable working code only
  feature/screen-name  → per screen
  feature/agent-name   → per agent

Commit message format:
  feat: add incident detail screen
  feat: signal collector agent
  fix: map markers not rendering
  style: update severity badge colors
```

---

## 12. Build & Run Commands

### Backend
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### Flutter
```bash
cd mobile
flutter pub get
flutter run                    # run on emulator
flutter build apk --release   # build final APK
```

### ADK Web UI (for traces)
```bash
cd backend
adk web                        # opens localhost:8000/adk
```

---

## 13. Submission Checklist

```
APK:
  [ ] flutter build apk --release
  [ ] Test APK installs and runs on physical device
  [ ] All 3 demo scenarios work end to end

Agent Traces:
  [ ] Run all 3 scenarios
  [ ] traces/scenario_1_flood.json exported
  [ ] traces/scenario_2_multi_crisis.json exported
  [ ] traces/scenario_3_false_alarm.json exported
  [ ] Screenshot of ADK web UI trace tab

Demo Video (3-5 mins):
  [ ] Shows Gather Crisis News triggering agents
  [ ] Shows crisis detection with confidence score
  [ ] Shows resource allocation with trade-off
  [ ] Shows simulation before/after
  [ ] Shows false alarm recovery scenario
  [ ] Shows agent logs screen

README.md:
  [ ] System architecture diagram
  [ ] ADK/Antigravity usage explanation
  [ ] All APIs listed
  [ ] Mock vs real data explained
  [ ] How to run locally
  [ ] Assumptions and limitations
```

---

## 14. Key Decisions & Assumptions

```
1. App targets Android only (APK) — iOS not required
2. Login is phone + OTP — no email/password
3. Signup required ONLY for submitting reports — viewing is public
4. All 3 demo scenarios use Islamabad geography specifically
5. Resource pool is fixed mock data (not fetched from real system)
6. Rerouting shows simulated routes — not live Google Navigation
7. Stakeholder notifications are simulated cards — no real SMS/email sent
8. Weather and Maps use real APIs — social/sensor data is always mock
9. Multi-crisis scenario always has exactly 2 simultaneous crises
10. False alarm scenario always ends with alert retraction + utility notification
```

---

*Last updated: BakhabarAI v1.0 — Hackathon Build*
*Agent: Read this file on every new session before writing any code.*

<!-- SPECKIT END -->

# BakhabarAI — Shehar ka Nigehban (Guardian of the City)

An agentic AI system that detects urban crises (floods, heatwaves, accidents), allocates resources, simulates coordinated responses, and shows outcomes — built specifically for Pakistani cities.

**Hackathon**: CIRO Challenge — Crisis Intelligence & Response Orchestrator

---

## 🏗️ System Architecture

BakhabarAI is built on a decoupled architecture prioritizing performance, real-time feedback, and visible AI reasoning.

- **Frontend**: Flutter (Mobile-First Android APK) featuring a premium Glassmorphic UI, smooth transitions, and a 4-tab navigation architecture.
- **Backend**: FastAPI (Python) driving the data layer and serving APIs.
- **Agent Orchestration**: **Google Antigravity (ADK)** utilizing Gemini 2.0 Flash to power 5 distinct agents in a sequential pipeline.

---

## 🤖 The 5 Agent Pipeline (ADK)

1. **SignalCollectorAgent**: Ingests weather, maps, social media, and sensor data to normalize into standard signal schema.
2. **DetectorAgent**: Classifies crisis type, location, severity, and assigns a confidence score.
3. **PlannerAgent**: Evaluates constraints and optimally allocates emergency resources (Ambulance, Fire, Drone).
4. **ExecutorAgent**: Simulates response actions, maps out reroutes, and dispatches notifications.
5. **ReporterAgent**: Generates the final before/after comparison and publishes the trace logs.

*Note: You can view real-time operations of these agents via the **Expert View** toggle on the Incident Details screen, or globally in the **Agent Traces** tab.*

---

## 📡 API Endpoints (FastAPI)

- `POST /api/run-scenario`: Triggers full agent pipeline
- `GET /api/incidents`: Returns all detected active crises
- `GET /api/incidents/{id}`: Returns single crisis details
- `GET /api/resources`: Fetches resource allocation outcomes
- `GET /api/simulation/{id}`: Fetches simulation outcomes
- `GET /api/logs`: Retrieves raw agent reasoning traces
- `POST /api/report`: Submits a new user incident to the DetectorAgent

---

## 💾 Mock vs. Real Data Strategy

- **Real Data APIs**: Google Maps rendering, Routes API, Weather API, Geocoding API.
- **Simulated (Mock) Data**: Social media posts, Emergency calls, Field reports, Local sensors.
- **Constraint**: *No hardcoded mock data exists in the Flutter UI.* The Flutter UI strictly fetches simulated payloads from the FastAPI backend to demonstrate real network latency, skeleton loaders, and error states.

---

## 🚀 How to Run Locally

### 1. Backend (FastAPI)
```bash
cd backend
python -m venv venv
source venv/bin/activate  # (or venv\Scripts\activate on Windows)
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```
*(Ensure you have configured your `.env` file with `GOOGLE_MAPS_API_KEY` and `GEMINI_API_KEY`)*

### 2. Frontend (Flutter)
```bash
cd mobile
flutter pub get
flutter run
```
*(To build the APK: `flutter build apk --release`)*

---

## 📋 Assumptions and Limitations
- The application is currently optimized exclusively for Android.
- Simulated Scenarios (Flood, Multi-Crisis, False Alarm) are geographically locked to Islamabad sectors (e.g., G-10, I-8) for demonstration purposes.
- Resource constraints (Ambulances, Police) are mocked as fixed-pool resources rather than live dispatch connections.
- User authentication uses a simulated OTP flow.

---
*Built with ❤️ for the CIRO Challenge using Google Antigravity.*

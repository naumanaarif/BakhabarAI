# Tasks: Core Incident Tracking

**Input**: Design documents from `/specs/001-core-incident-tracking/`

**Prerequisites**: plan.md, spec.md, data-model.md, contracts/, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Initialize Flutter project `mobile/` if not exists
- [ ] T002 Initialize FastAPI project `backend/` if not exists
- [ ] T003 Create `backend/requirements.txt` and install FastAPI, uvicorn, and `google-adk`
- [ ] T004 Create project structure for Flutter per `plan.md` in `mobile/lib/`
- [ ] T005 [P] Create project structure for Backend per `plan.md` in `backend/`
- [ ] T006 Configure basic theme constants in `mobile/lib/core/theme.dart` (colors, typography)
- [ ] T007 Configure `mobile/pubspec.yaml` with required packages (`lucide_icons`, `dio`, `provider`/`riverpod`, `google_maps_flutter`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T008 Setup `backend/config.py` to load environment variables from `.env`
- [ ] T009 Create base FastAPI application in `backend/main.py`
- [ ] T010 Setup `mobile/lib/services/api_service.dart` with `dio` for backend communication
- [ ] T011 Create base data models in Flutter (`mobile/lib/models/incident.dart`, `mobile/lib/models/resource.dart`)
- [ ] T012 Create base data models in Python (`backend/data_model.py` or equivalent based on `data-model.md`)
- [ ] T013 Implement `SkeletonLoader` widget in `mobile/lib/widgets/skeleton_loader.dart`
- [ ] T014 Implement `TopAppBar` with Back Button in `mobile/lib/widgets/top_app_bar.dart`
- [ ] T015 Implement `BottomNavBar` with 4 tabs in `mobile/lib/widgets/bottom_nav_bar.dart`
- [ ] T016 Setup routing/navigation structure in `mobile/lib/core/router.dart`
- [ ] T017 Implement basic Agent orchestration setup in `backend/agents/` (SignalCollector, Detector)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Live Dashboard (Priority: P1) 🎯 MVP

**Goal**: Users can view live incident updates, an interactive map with colored markers, and a list of incidents below the map.

**Independent Test**: Can the app launch, request location, show a skeleton loader, and then render mock incidents on the map and in a list?

### Implementation for User Story 1

- [ ] T018 [P] [US1] Implement `backend/routers/mock_data_router.py` to serve mock incidents via API
- [ ] T019 [US1] Add GET endpoint `/api/incidents` in `backend/main.py` using `mock_data_router`
- [ ] T020 [P] [US1] Create `Location Access` popup flow for splash/home screen in `mobile/lib/screens/splash_screen.dart`
- [ ] T021 [US1] Implement `mobile/lib/screens/home_screen.dart` to fetch and display incidents list
- [ ] T022 [US1] Implement `CrisisMarker` widget in `mobile/lib/widgets/crisis_marker.dart` (RED, ORANGE, PURPLE)
- [ ] T023 [US1] Implement `mobile/lib/screens/map_screen.dart` to display Google Map with `CrisisMarker`s
- [ ] T024 [US1] Add state management logic in `mobile/lib/screens/home_screen.dart` to use `SkeletonLoader` while fetching data
- [ ] T025 [US1] Link `home_screen.dart` and `map_screen.dart` into `BottomNavBar` navigation

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Incident Reporting (Priority: P2)

**Goal**: Users can report an incident through the app, interacting with the AI Assistant Chat for guidance.

**Independent Test**: Can a user open the AI Assistant Chat, submit a report, see the agent processing indicator, and get a confirmed submission?

### Implementation for User Story 2

- [ ] T026 [P] [US2] Implement POST endpoint `/api/report` in `backend/main.py`
- [ ] T027 [US2] Create basic Agent interaction logic in `backend/agents/reporter.py` for handling reports
- [ ] T028 [US2] Implement `mobile/lib/screens/auth/otp_screen.dart` to simulate OTP requirement for reporting
- [ ] T029 [US2] Implement AI Assistant Chat UI in `mobile/lib/screens/report_screen.dart` (or `ai_assistant_chat_screen.dart` if combined)
- [ ] T030 [US2] Implement Agent Processing indicator (loading circle with agent name) in the Chat UI
- [ ] T031 [US2] Connect report submission to `api_service.dart` and handle response
- [ ] T032 [US2] Handle UI transition and success state after report is submitted

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Expert Analysis View (Priority: P3)

**Goal**: Users can view deep details of an incident, including an Expert View toggle that reveals raw agent traces and confidence scores.

**Independent Test**: Can a user click an incident, toggle "Expert View", and instantly see raw logs and confidence scores?

### Implementation for User Story 3

- [ ] T033 [P] [US3] Add GET endpoint `/api/incidents/{id}` in `backend/main.py`
- [ ] T034 [P] [US3] Implement GET endpoint `/api/logs` in `backend/main.py` to fetch AgentTrace data
- [ ] T035 [US3] Create `AgentTrace` model in `mobile/lib/models/agent_log.dart`
- [ ] T036 [US3] Implement `mobile/lib/screens/incident_detail_screen.dart`
- [ ] T037 [US3] Implement the "Expert View" toggle inside `incident_detail_screen.dart`
- [ ] T038 [US3] Create UI for raw confidence scores and agent traces when "Expert View" is ON
- [ ] T039 [US3] Ensure simplified terminology ("AI Verified") is shown when "Expert View" is OFF
- [ ] T040 [US3] Implement `mobile/lib/screens/agent_logs_screen.dart` for the 4th tab in `BottomNavBar`

**Checkpoint**: All user stories should now be independently functional

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T041 [P] Ensure smooth screen transitions are applied across all routes in `router.dart`
- [ ] T042 Verify all UI mock data is completely removed and fetched via backend APIs
- [ ] T043 Refine "Glassmorphism" aesthetic and premium look across all cards and widgets
- [ ] T044 Run end-to-end user journeys for the 3 demo scenarios
- [ ] T045 Final cleanup of `README.md` and export of agent traces to `traces/` folder

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User Story 1 (P1)
  - User Story 2 (P2)
  - User Story 3 (P3)
- **Polish (Final Phase)**: Depends on all user stories being complete

### Parallel Opportunities

- All Setup and Foundational tasks marked [P] can run in parallel
- Frontend and Backend model definitions (T011, T012) can run in parallel
- The backend mock API endpoints and frontend widgets can be developed in parallel once the foundation is set.

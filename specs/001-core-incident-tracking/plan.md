# Implementation Plan: core-incident-tracking

**Branch**: `001-core-incident-tracking` | **Date**: 2026-05-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-core-incident-tracking/spec.md`

## Summary

The app delivers immediate situational awareness via a Flutter-based map and incident list, backed by a FastAPI system orchestrated by Google Antigravity. Citizens can view active crises, report incidents, and use an "Expert View" to examine underlying AI agent logs.

## Technical Context

**Language/Version**: Dart (Flutter) / Python 3.11+

**Primary Dependencies**: Flutter, FastAPI, Google Maps Flutter SDK, Google ADK, Firebase Phone Auth, Lucide Icons

**Storage**: Firestore (mock data)

**Testing**: Flutter test, Pytest

**Target Platform**: Android (APK)

**Project Type**: Mobile App + Python API Backend

**Performance Goals**: Instant map rendering (<3 seconds app load)

**Constraints**: Must use Google ADK for all agent workflows, Lucide Icons only, strictly no Material/Cupertino icons, strictly follow defined AppColors.

**Scale/Scope**: Canonical demo scenarios with mock data for judging.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] Uses Google Antigravity for orchestration (Pass)
- [x] Multi-agent architecture (5 agents) (Pass)
- [x] Mobile app is the primary deliverable (Pass)
- [x] Uses mock data to protect privacy (Pass)
- [x] Includes "Expert View" for hackathon judging (Pass)
- [x] Uses Lucide Icons exclusively (Pass)

## Project Structure

### Documentation (this feature)

```text
specs/001-core-incident-tracking/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (future)
```

### Source Code (repository root)

```text
mobile/                          # Flutter app
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── theme.dart           # AppColors, AppTextStyles
│   │   ├── constants.dart
│   │   └── router.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── map_screen.dart
│   │   ├── incident_detail_screen.dart
│   │   └── report_screen.dart
│   ├── widgets/
│   ├── models/
│   └── services/
│       └── api_service.dart

backend/                         # FastAPI + ADK
├── main.py
├── agents/
│   ├── signal_collector.py
│   └── detector.py
├── tools/
├── data/
└── config.py
```

**Structure Decision**: Selected the Mobile + API backend structure as explicitly mandated by the project constitution and `AGENTS.md`. Flutter will handle the mobile frontend and FastAPI will handle the Google Antigravity backend.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations. Architecture strictly follows the constitution.

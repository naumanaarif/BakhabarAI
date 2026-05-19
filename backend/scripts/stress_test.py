import sys
import os
import asyncio

# Add backend to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.firebase_service import FirebaseService
from firebase_config import db


async def setup_stress_test():
    print("🚀 Setting up Multi-City Stress Test Scenario...")

    # ── Clear existing pending signals ────────────────────────────────────────
    signals = db.collection("signals").where("status", "==", "pending").stream()
    for s in signals:
        s.reference.delete()

    # ── Reset all resources to available ─────────────────────────────────────
    resources = db.collection("resources").stream()
    for res in resources:
        res.reference.update({"status": "available", "current_incident_id": None})

    # ══════════════════════════════════════════════════════════════════════════
    # CITY 1 — ISLAMABAD
    # ══════════════════════════════════════════════════════════════════════════

    # Scenario A: Conflicting flood signals in G-10 (False Alarm candidate)
    FirebaseService.add_signal(
        source_type="social",
        content="G-10 Markaz bilkul doob gaya hai! Gaariyan pani mein ghum hain. Logon ko door rehna chahiye!",
        lat=33.6844,
        lng=73.0479,
        metadata={"location_name": "G-10 Markaz, Islamabad"}
    )
    FirebaseService.add_signal(
        source_type="sensor",
        content="Water level at G-10 drainage point: 0.2m (Normal Range). No blockage detected.",
        lat=33.6850,
        lng=73.0485,
        metadata={"location_name": "G-10 Markaz, Islamabad"}
    )

    # Scenario B: Wildfire on Margalla Hills (HIGH severity, clear signal)
    FirebaseService.add_signal(
        source_type="field_report",
        content="WILD FIRE on Margalla Trail 3. Large smoke column visible from F-6. Wind spreading flames rapidly.",
        lat=33.7483,
        lng=73.0784,
        metadata={"location_name": "Margalla Hills Trail 3, Islamabad"}
    )
    FirebaseService.add_signal(
        source_type="social",
        content="Margalla mein aag lag gayi! Trail 3 ke paas dhuan bohot zyada hai. CDA ko call karo!",
        lat=33.7490,
        lng=73.0790,
        metadata={"location_name": "Margalla Hills, Islamabad"}
    )

    # ══════════════════════════════════════════════════════════════════════════
    # CITY 2 — KARACHI
    # ══════════════════════════════════════════════════════════════════════════

    # Scenario A: Urban flooding in Korangi after heavy rain
    FirebaseService.add_signal(
        source_type="social",
        content="Korangi Industrial Area mein 4 feet pani aa gaya. Factories band ho gayi hain. Mazdoor phanse hain!",
        lat=24.8267,
        lng=67.1239,
        metadata={"location_name": "Korangi Industrial Area, Karachi"}
    )
    FirebaseService.add_signal(
        source_type="sensor",
        content="Stormwater drain overflow detected. Flow rate: 380 cumecs (Critical: 300). Back-pressure alert.",
        lat=24.8280,
        lng=67.1250,
        metadata={"location_name": "Korangi Drain, Karachi"}
    )

    # Scenario B: Heatwave emergency in Lyari
    FirebaseService.add_signal(
        source_type="emergency_call",
        content="Multiple heat stroke cases in Lyari. EDHI receiving 10+ patients/hour. Temperature feels above 50C.",
        lat=24.8608,
        lng=67.0104,
        metadata={"location_name": "Lyari, Karachi"}
    )
    FirebaseService.add_signal(
        source_type="field_report",
        content="Lyari General Hospital overwhelmed. Outdoor workers collapsing. No electricity = no cooling.",
        lat=24.8600,
        lng=67.0110,
        metadata={"location_name": "Lyari, Karachi"}
    )

    # ══════════════════════════════════════════════════════════════════════════
    # CITY 3 — LAHORE
    # ══════════════════════════════════════════════════════════════════════════

    # Scenario A: Road accident with traffic collapse on GT Road
    FirebaseService.add_signal(
        source_type="emergency_call",
        content="Serious multi-vehicle pileup on GT Road near Shahdara. 3 trucks involved. Road completely blocked.",
        lat=31.6340,
        lng=74.3540,
        metadata={"location_name": "GT Road Shahdara, Lahore"}
    )
    FirebaseService.add_signal(
        source_type="social",
        content="GT Road pe badi accident ho gayi! Ambulance aa rahi hai magar traffic jam ki wajah se phans gayi.",
        lat=31.6335,
        lng=74.3535,
        metadata={"location_name": "Shahdara, Lahore"}
    )

    # Scenario B: Mass power outage in Gulberg
    FirebaseService.add_signal(
        source_type="social",
        content="Gulberg 3 mein 6 ghante se bijli nahi. Hospitals ke generators bhi band hone wale hain. Emergency!",
        lat=31.5204,
        lng=74.3587,
        metadata={"location_name": "Gulberg III, Lahore"}
    )
    FirebaseService.add_signal(
        source_type="sensor",
        content="LESCO Grid Station 11-B: Main feeder tripped. Estimated 40,000 consumers affected. ETA restore: unknown.",
        lat=31.5210,
        lng=74.3595,
        metadata={"location_name": "Gulberg Grid Station, Lahore"}
    )

    # ══════════════════════════════════════════════════════════════════════════
    # CITY 4 — PESHAWAR
    # ══════════════════════════════════════════════════════════════════════════

    # Scenario A: Flash flood in Hayatabad
    FirebaseService.add_signal(
        source_type="field_report",
        content="Flash flood warning in Hayatabad Phase 6. Nullah burst. Residential streets underwater within minutes.",
        lat=33.9983,
        lng=71.4687,
        metadata={"location_name": "Hayatabad Phase 6, Peshawar"}
    )
    FirebaseService.add_signal(
        source_type="sensor",
        content="River Kabul tributary gauge: 4.1m rising (Danger: 3.5m). Flow expected to peak in 2 hours.",
        lat=34.0010,
        lng=71.4700,
        metadata={"location_name": "Hayatabad Nullah, Peshawar"}
    )

    # Scenario B: Smog & air quality crisis in Saddar
    FirebaseService.add_signal(
        source_type="social",
        content="Peshawar Saddar mein saans lena mushkil ho gaya. Aankhon mein jalan, visibility sirf 50 meter!",
        lat=34.0151,
        lng=71.5249,
        metadata={"location_name": "Saddar, Peshawar"}
    )
    FirebaseService.add_signal(
        source_type="sensor",
        content="Air Quality Index (AQI): 312 — Hazardous. PM2.5: 278 µg/m³. Major health risk for all groups.",
        lat=34.0155,
        lng=71.5255,
        metadata={"location_name": "Saddar AQI Station, Peshawar"}
    )

    # ── Summary ───────────────────────────────────────────────────────────────
    print("✅ Stress test signals initialized across 4 cities (8 scenarios).")
    print()
    print("📍 ISLAMABAD")
    print("   ↳ Scenario A: Conflicting flood signals in G-10 (False alarm candidate)")
    print("   ↳ Scenario B: Wildfire on Margalla Hills Trail 3 (HIGH severity)")
    print()
    print("📍 KARACHI")
    print("   ↳ Scenario A: Urban flooding in Korangi Industrial Area")
    print("   ↳ Scenario B: Heatwave emergency in Lyari")
    print()
    print("📍 LAHORE")
    print("   ↳ Scenario A: Multi-vehicle accident + traffic collapse on GT Road Shahdara")
    print("   ↳ Scenario B: Mass power outage in Gulberg III")
    print()
    print("📍 PESHAWAR")
    print("   ↳ Scenario A: Flash flood in Hayatabad Phase 6")
    print("   ↳ Scenario B: Hazardous smog/AQI crisis in Saddar")
    print()
    print("👉 Trigger the pipeline via the App or POST /api/run-scenario to see agentic trade-offs.")


if __name__ == "__main__":
    asyncio.run(setup_stress_test())

"""
reset_and_seed.py — BakhabarAI Stress Test Reset
=================================================
Run this ONCE before recording your stress test demo.

What it does:
  1. Wipes:  signals, incidents, agent_logs, action_simulations
  2. Resets: all resources → available
  3. Seeds:  8 multi-city scenarios across Islamabad, Karachi, Lahore, Peshawar

Usage:
  cd backend
  venv\\Scripts\\python.exe scripts\\reset_and_seed.py

Then trigger the pipeline from the App (Run Stress Test button) or:
  venv\\Scripts\\python.exe scripts\\trigger_pipeline.py
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from firebase_config import db
from services.firebase_service import FirebaseService

COLLECTIONS_TO_CLEAR = [
    "signals",
    "incidents",
    "agent_logs",
    "action_simulations",
]

def _wipe_collection(name: str):
    docs = list(db.collection(name).stream())
    for doc in docs:
        doc.reference.delete()
    print(f"  ✓ Cleared {len(docs):>3} docs from '{name}'")

def reset_db():
    print("\n🗑️  Wiping Firestore collections...")
    for col in COLLECTIONS_TO_CLEAR:
        _wipe_collection(col)

    print("\n♻️  Resetting resources → available...")
    resources = list(db.collection("resources").stream())
    for res in resources:
        res.reference.update({"status": "available", "current_incident_id": None})
    print(f"  ✓ Reset {len(resources)} resources")

def seed_signals():
    print("\n🌱 Seeding stress test signals (4 cities, 8 scenarios)...")

    signals = [
        # ── ISLAMABAD ────────────────────────────────────────────────────────
        {   # Conflicting flood signals → false alarm candidate
            "source": "social",
            "content": "G-10 Markaz bilkul doob gaya hai! Gaariyan pani mein ghum hain. Logon ko door rehna chahiye!",
            "lat": 33.6844, "lng": 73.0479,
            "metadata": {"location_name": "G-10 Markaz, Islamabad"},
        },
        {   # Sensor contradicts social → false alarm
            "source": "sensor",
            "content": "Water level at G-10 drainage point: 0.2m (Normal Range). No blockage detected. Sensor readings nominal.",
            "lat": 33.6850, "lng": 73.0485,
            "metadata": {"location_name": "G-10 Markaz, Islamabad"},
        },
        {   # Wildfire — HIGH severity
            "source": "field_report",
            "content": "WILD FIRE on Margalla Trail 3. Large smoke column visible from F-6. Wind spreading flames rapidly toward residential areas. CDA rangers on scene.",
            "lat": 33.7483, "lng": 73.0784,
            "metadata": {"location_name": "Margalla Hills Trail 3, Islamabad"},
        },
        {   # Confirming wildfire
            "source": "social",
            "content": "Margalla mein aag lag gayi! Trail 3 ke paas dhuan bohot zyada hai. Ghar khali karo E-7 waale!",
            "lat": 33.7490, "lng": 73.0790,
            "metadata": {"location_name": "Margalla Hills, Islamabad"},
        },

        # ── KARACHI ──────────────────────────────────────────────────────────
        {   # Urban flooding
            "source": "social",
            "content": "Korangi Industrial Area mein 4 feet pani aa gaya. Factories band ho gayi hain. Mazdoor phanse hain highway pe!",
            "lat": 24.8267, "lng": 67.1239,
            "metadata": {"location_name": "Korangi Industrial Area, Karachi"},
        },
        {   # Sensor confirms flooding
            "source": "sensor",
            "content": "Stormwater drain overflow detected at Korangi Nullah. Flow rate: 380 cumecs (Critical threshold: 300). Back-pressure alert issued.",
            "lat": 24.8280, "lng": 67.1250,
            "metadata": {"location_name": "Korangi Drain, Karachi"},
        },
        {   # Heatwave emergency
            "source": "emergency_call",
            "content": "Multiple heat stroke cases in Lyari. EDHI receiving 10+ patients/hour. Temperature feels above 50C. Electricity gone since morning.",
            "lat": 24.8608, "lng": 67.0104,
            "metadata": {"location_name": "Lyari, Karachi"},
        },
        {   # Hospital confirms heatwave
            "source": "field_report",
            "content": "Lyari General Hospital overwhelmed. Outdoor workers collapsing on street. No electricity = no cooling. Requesting emergency ORS supplies.",
            "lat": 24.8600, "lng": 67.0110,
            "metadata": {"location_name": "Lyari, Karachi"},
        },

        # ── LAHORE ───────────────────────────────────────────────────────────
        {   # Road accident
            "source": "emergency_call",
            "content": "Serious multi-vehicle pileup on GT Road near Shahdara. 3 trucks involved, 2 overturned. Road completely blocked. Ambulance stuck in traffic.",
            "lat": 31.6340, "lng": 74.3540,
            "metadata": {"location_name": "GT Road Shahdara, Lahore"},
        },
        {   # Confirming accident
            "source": "social",
            "content": "GT Road pe badi accident ho gayi! Shahdara flyover ke paas 3 trucks phanse. Ambulance aa rahi hai magar traffic jam mein phans gayi.",
            "lat": 31.6335, "lng": 74.3535,
            "metadata": {"location_name": "Shahdara, Lahore"},
        },
        {   # Power outage
            "source": "social",
            "content": "Gulberg 3 mein 6 ghante se bijli nahi. Hospitals ke generators bhi band hone wale hain. Babies wards mein AC band!",
            "lat": 31.5204, "lng": 74.3587,
            "metadata": {"location_name": "Gulberg III, Lahore"},
        },
        {   # Grid sensor confirms outage
            "source": "sensor",
            "content": "LESCO Grid Station 11-B: Main feeder tripped at 09:14. Estimated 40,000 consumers affected across Gulberg I-V. ETA restore: unknown.",
            "lat": 31.5210, "lng": 74.3595,
            "metadata": {"location_name": "Gulberg Grid Station, Lahore"},
        },

        # ── PESHAWAR ─────────────────────────────────────────────────────────
        {   # Flash flood
            "source": "field_report",
            "content": "Flash flood warning in Hayatabad Phase 6. Nullah burst near Phase 6 park. Residential streets underwater within minutes. 3 children rescued.",
            "lat": 33.9983, "lng": 71.4687,
            "metadata": {"location_name": "Hayatabad Phase 6, Peshawar"},
        },
        {   # River gauge confirms flash flood
            "source": "sensor",
            "content": "River Kabul tributary gauge at Hayatabad Bridge: 4.1m rising (Danger level: 3.5m). Flow expected to peak in 90 minutes.",
            "lat": 34.0010, "lng": 71.4700,
            "metadata": {"location_name": "Hayatabad Nullah, Peshawar"},
        },
        {   # Smog/AQI crisis
            "source": "social",
            "content": "Peshawar Saddar mein saans lena mushkil ho gaya. Aankhon mein jalan, visibility sirf 50 meter. School band karo foran!",
            "lat": 34.0151, "lng": 71.5249,
            "metadata": {"location_name": "Saddar, Peshawar"},
        },
        {   # AQI sensor confirms smog
            "source": "sensor",
            "content": "Saddar AQI Monitor: PM2.5 = 278 µg/m³. AQI index: 312 — Hazardous. Visibility: 50m. Major health risk for ALL population groups.",
            "lat": 34.0155, "lng": 71.5255,
            "metadata": {"location_name": "Saddar AQI Station, Peshawar"},
        },
    ]

    count = 0
    for s in signals:
        try:
            FirebaseService.add_signal(
                source_type=s["source"],
                content=s["content"],
                lat=s["lat"],
                lng=s["lng"],
                metadata=s["metadata"],
            )
            count += 1
        except Exception as e:
            print(f"  ✗ Failed to seed signal: {e}")

    print(f"  ✓ Seeded {count}/{len(signals)} signals")

def print_summary():
    print("\n" + "="*58)
    print("  ✅  RESET COMPLETE — Ready for Stress Test")
    print("="*58)
    print()
    print("  📍 ISLAMABAD  → G-10 False Alarm + Margalla Wildfire")
    print("  📍 KARACHI    → Korangi Flood + Lyari Heatwave")
    print("  📍 LAHORE     → GT Road Accident + Gulberg Power Outage")
    print("  📍 PESHAWAR   → Hayatabad Flash Flood + Saddar Smog")
    print()
    print("  ▶  Next step: Tap 'Run Stress Test' in the App")
    print("     OR run: python scripts/trigger_pipeline.py")
    print()


if __name__ == "__main__":
    reset_db()
    seed_signals()
    print_summary()

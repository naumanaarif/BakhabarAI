from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field

class ImprovementMetrics(BaseModel):
    response_time_reduction: str
    safety_boost: str

class ImpactState(BaseModel):
    before_state: str
    after_state: str
    improvement_metrics: ImprovementMetrics

class Notifications(BaseModel):
    public: str
    hospitals: str
    utility_providers: str
    law_enforcement: str

class Simulation(BaseModel):
    incident_id: str
    action_type: str
    description: str
    impact: Optional[ImpactState] = None
    notifications: Optional[Notifications] = None

class SimulationsPayload(BaseModel):
    simulations: List[Simulation]

from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from tools.firebase_tools import query_active_incidents, create_simulation_record
from tracer import tracer
from .model_config import get_model
import json

_PROCESSED_SIMULATIONS = set()

async def process_simulations_and_messages(payload: Dict[str, Any] = None, **kwargs) -> str:
    """
    Commits your response impact simulations and multi-stakeholder notifications.
    """
    from firebase_config import db
    from google.cloud.firestore_v1 import FieldFilter
    from datetime import datetime
    
    # Robust extraction
    data = payload if payload is not None else kwargs
    simulations = data.get('simulations') or data.get('payload', {}).get('simulations')

    if not simulations or not isinstance(simulations, list):
        return "ERROR: Expected 'simulations' list in payload."

    results = []
    for sim in simulations:
        if not isinstance(sim, dict): continue
        
        incident_id = sim.get('incident_id') or sim.get('id')
        if not incident_id or incident_id == "null": continue
        
        # 1. SESSION CACHE
        if incident_id in _PROCESSED_SIMULATIONS:
            continue

        # 2. DATABASE LOOP BREAKER
        recent = db.collection("action_simulations").where(filter=FieldFilter("incident_id", "==", incident_id)).limit(5).get()
        if recent:
            # Check the timestamps in Python to avoid needing a composite index
            has_recent = False
            for doc in recent:
                ts = doc.to_dict().get("timestamp")
                if isinstance(ts, str):
                    try: ts = datetime.fromisoformat(ts.replace("Z", "+00:00"))
                    except: ts = datetime.now()
                    
                if ts and (datetime.now(ts.tzinfo) - ts).total_seconds() < 600: 
                    has_recent = True
                    break
                    
            if has_recent:
                print(f"DEBUG: Simulation for {incident_id} already exists. Skipping to break loop.")
                _PROCESSED_SIMULATIONS.add(incident_id)
                continue

        # Fuzzy Impact
        impact = sim.get('impact') or {}
        if isinstance(impact, str): impact = {'before_state': 'Pending.', 'after_state': impact, 'improvement_metrics': {}}
        elif not isinstance(impact, dict): impact = {}

        metrics = impact.get('improvement_metrics') or {}
        impact_payload = {
            'before_state': impact.get('before_state') or 'Pending emergency response.',
            'after_state': impact.get('after_state') or 'Resource deployment in progress.',
            'improvement_metrics': {
                'response_time_reduction': metrics.get('response_time_reduction') or '15 min',
                'safety_boost': metrics.get('safety_boost') or '30%'
            }
        }

        notif = sim.get('notifications') or {}
        if not isinstance(notif, dict): notif = {}
        msg = notif.get('message') or notif.get('body') or "Emergency response units dispatched."

        # ── Fetch the real incident from Firestore to get accurate location + type ──
        _inc_type = 'emergency'
        loc = ''
        try:
            _inc_doc = db.collection("incidents").document(incident_id).get()
            if _inc_doc.exists:
                _inc_data = _inc_doc.to_dict()
                loc = _inc_data.get("location_name", "") or ""
                _inc_type = (_inc_data.get("type") or "emergency").lower().replace("_", " ")
        except Exception as _e:
            print(f"DEBUG: Could not fetch incident {incident_id} for notifications: {_e}")
        # Fallback: try the sim payload fields
        if not loc:
            loc = sim.get('location_name', '') or sim.get('loc', '')
        if _inc_type == 'emergency':
            _inc_type = (sim.get('type') or sim.get('incident_type') or 'emergency').lower().replace("_", " ")

        # City detection from the real incident location
        _city = 'islamabad'
        _loc_lower = loc.lower()
        if any(k in _loc_lower for k in ['karachi', 'korangi', 'lyari', 'clifton', 'orangi', 'gulshan', 'defence khi']): _city = 'karachi'
        elif any(k in _loc_lower for k in ['lahore', 'gulberg', 'shahdara', 'dha lhr', 'model town', 'johar town']): _city = 'lahore'
        elif any(k in _loc_lower for k in ['peshawar', 'hayatabad', 'saddar pesh', 'cantt pesh']): _city = 'peshawar'


        _HOSPITALS = {
            'islamabad': {'flood': 'PIMS Emergency (33-9261170): Pre-position 4 trauma teams. Expect water-related injuries and hypothermia cases. Activate flood-response protocol.',
                          'heatwave': 'Polyclinic Hospital (33-9218300) & PIMS: Open heat stroke bays. Prepare IV fluids for 50+ patients. Alert nephrology for rhabdomyolysis cases.',
                          'fire': 'PIMS Burns Unit (33-9261170): Activate 6-bed burn ICU. Request additional skin grafting supplies. Coordinate with CDA ambulance fleet.',
                          'accident': 'Trauma Centre Islamabad (33-9261170): Dispatch 3 ambulances to scene. Pre-alert surgery OT. Blood bank: O-ve on standby.',
                          'power_outage': 'PIMS & Polyclinic: Switch to backup generators immediately. Reschedule elective surgeries. ICU and life-support systems verified.',
                          'protest': 'PIMS Emergency: Keep 2 trauma bays on standby for crowd-control injuries. Stock rubber-bullet wound kits.',
                          'emergency': 'PIMS Emergency (33-9261170): Full emergency activation. All senior consultants on call.'},
            'karachi': {'flood': 'Jinnah Postgraduate Medical Centre (021-99201300): Activate flood protocol. 6 resuscitation bays ready. Karachi Water Board on standby.',
                        'heatwave': 'Civil Hospital Karachi & JPMC: Open 20-bed heat emergency ward. Deploy mobile ORS units to Lyari and Korangi.',
                        'fire': 'Burns Centre JPMC (021-99201300): Alert burn unit — 8 beds available. Request Aga Khan Hospital mutual aid.',
                        'accident': 'Aga Khan Hospital (021-111911911): Dispatch trauma team to GT Road. Pre-alert JPMC for overflow.',
                        'power_outage': 'JPMC, Civil Hospital: Activate generator protocols. KESC liaison contacted for priority restoration.',
                        'protest': 'Civil Hospital Karachi: Crowd-control injury protocol active. 3 trauma bays on standby.',
                        'emergency': 'JPMC Emergency (021-99201300): Full emergency activation.'},
            'lahore': {'flood': 'Services Hospital Lahore (042-99203550): 5 flood trauma bays activated. Coordinate with Rescue 1122 for stretcher transport.',
                       'heatwave': 'Mayo Hospital Lahore & Services Hospital: Heat emergency OPD open 24h. 500 ORS sachets distributed. Cooling tents deployed.',
                       'fire': 'Services Hospital Burns Unit (042-99203550): Alert burn team — 4 ICU beds. Request Punjab Emergency Service aerial support.',
                       'accident': 'General Hospital Lahore (042-99200300): 2 surgery OTs on standby. Rescue 1122 coordinating extraction from GT Road pileup.',
                       'power_outage': 'Mayo Hospital, Services Hospital: Generator fuel reserves checked. LESCO priority helpline: 042-111000118 activated.',
                       'protest': 'Services Hospital Lahore: Crowd injury protocol. 2 trauma teams on 30-minute standby.',
                       'emergency': 'Services Hospital Lahore (042-99203550): Emergency activation in progress.'},
            'peshawar': {'flood': 'Hayatabad Medical Complex (091-9217480): Flash flood trauma protocol. 4 resuscitation bays cleared. KP Rescue 1122 coordinating.',
                         'heatwave': 'Lady Reading Hospital Peshawar (091-9211360): Heat stroke unit activated. 30 IV drip stations ready. Outdoor worker outreach launched.',
                         'fire': 'MTI Peshawar / HMC (091-9217480): Burns team on standby. 3 ICU beds reserved. CDA fire liaison activated.',
                         'accident': 'Hayatabad Medical Complex (091-9217480): Trauma team dispatched to Peshawar-Nowshera bypass. 2 surgery theatres on alert.',
                         'power_outage': 'HMC & Lady Reading: Generator protocols active. PESCO KP contacted for priority grid restoration.',
                         'protest': 'Lady Reading Hospital: 2 trauma bays on standby for crowd-related injuries.',
                         'emergency': 'Hayatabad Medical Complex (091-9217480): Full emergency response activated.'},
        }
        _POLICE = {
            'islamabad': {'flood': 'Islamabad Traffic Police (051-9261661): Close Srinagar Highway inbound. Divert via IJP Road. Deploy 6 constables for G-10 sector evacuation assistance.',
                          'heatwave': 'ICT Police: Set up 4 shaded rest points at D-Chowk, Faizabad, G-9 Markaz, F-8 Kachehri. Patrol vulnerable katchi abadis every 2 hours.',
                          'fire': 'ICT Police SSP Operations: Establish 500m cordon around Margalla fire zone. Close Trail 3, 4, 5 access points. Evacuate Sector E-7 residences immediately.',
                          'accident': 'Islamabad Traffic Police (051-9261661): Road closed at Murree Road/Faizabad intersection. 8 officers deployed. Alternate via Express Highway.',
                          'power_outage': 'ICT Police: Heightened patrol in blacked-out sectors G-10, G-11. Anti-looting mobile units deployed every 45 minutes.',
                          'protest': 'ICT Police SSP (051-9261770): 3 platoons deployed at D-Chowk. Riot gear on standby. Red Zone entrance sealed.',
                          'emergency': 'ICT Police Emergency (15): All available units dispatched. DSP on scene coordinating.'},
            'karachi': {'flood': 'Karachi Police (021-9221100): Traffic diverted away from Korangi Industrial Area. SSP East coordinating boat rescue with Rangers.',
                        'heatwave': 'Karachi Police & Rangers: Enforce water distribution points at Lyari, Orangi. 4 cooling stations guarded 24h.',
                        'fire': 'Karachi Police SSP Central: Cordon established around fire site. Evacuated 3-block radius. Karachi Fire Brigade (021-32219701) on scene.',
                        'accident': 'Karachi Traffic Police (021-9221328): Super Highway closed at Scheme 33. Alternate via Northern Bypass. 10 officers managing diversion.',
                        'power_outage': 'Karachi Police: Looting prevention patrols in KESC blackout zones. Rangers called for critical installations.',
                        'protest': 'Karachi Police & Rangers: MA Jinnah Road sealed. Traffic diverted via Shahrae Faisal.',
                        'emergency': 'Karachi Police Emergency (15): SSP Operations contacted. All units mobilised.'},
            'lahore': {'flood': 'Lahore Traffic Police (042-99202020): Ravi Road and Canal Bank closures active. Punjab Rescue 1122 boats deployed in Shahdara.',
                       'heatwave': 'Punjab Police: Water distribution vans deployed in Gulberg, Model Town. Anti-hoarding teams monitoring utility stores.',
                       'fire': 'Lahore Police SSP Operations: 1km cordon active. Evacuated 200 residents from adjacent Model Town blocks.',
                       'accident': 'Lahore Traffic Police (042-99202020): GT Road closed both directions at Shahdara flyover. 12 officers on scene. Alternate via Canal Road.',
                       'power_outage': 'Lahore Police: High-visibility patrol in blackout zones Gulberg III, IV. LESCO emergency line (042-111000118) being shared with public.',
                       'protest': 'Lahore Police SSP: Mall Road blocked. Traffic diverted via Jail Road and Ferozpur Road.',
                       'emergency': 'Lahore Police Emergency (15): Rapid Response Force units dispatched.'},
            'peshawar': {'flood': 'KP Police (091-9210405): Ring Road closed near Hayatabad nullah. Rescue 1122 KP coordinating with police for boat deployment.',
                         'heatwave': 'Peshawar Police: Water tankers escorted to Saddar and Hayatabad markets. Outdoor gathering restricted 12pm-4pm.',
                         'fire': 'Peshawar Police SSP: 200m cordon at Margalla fire zone. Residents of Phase 6 Hayatabad evacuated via police buses.',
                         'accident': 'KP Traffic Police (091-9210405): Peshawar-Nowshera M-1 closed. Alternate via Warsak Road. 8 officers managing pileup site.',
                         'power_outage': 'Peshawar Police: Night patrols doubled in PESCO blackout areas. Emergency helpline 1122 being publicised.',
                         'protest': 'Peshawar Police: Cantt area sealed. City Saddar traffic diverted via University Road.',
                         'emergency': 'KP Police Emergency (15): Elite Force units responding. SP Operations on scene.'},
        }

        # Normalize type to match dict keys (underscores, not spaces)
        _inc_type_key = _inc_type.replace(' ', '_')
        _hosp_msg = notif.get('hospitals') or _HOSPITALS.get(_city, _HOSPITALS['islamabad']).get(_inc_type_key, _HOSPITALS['islamabad']['emergency'])
        _law_msg  = notif.get('law_enforcement') or notif.get('police') or _POLICE.get(_city, _POLICE['islamabad']).get(_inc_type_key, _POLICE['islamabad']['emergency'])
        notifications_payload = {
            'public':            notif.get('public') or msg,
            'hospitals':         _hosp_msg,
            'utility_providers': notif.get('utility_providers') or "Utility teams on standby. No immediate infrastructure impact reported.",
            'law_enforcement':   _law_msg,
        }

        create_simulation_record(incident_id=incident_id, action_type=sim.get('action_type') or 'Crisis Response', description=sim.get('description') or 'Simulating impact of response...', impact=impact_payload, notifications=notifications_payload)
        _PROCESSED_SIMULATIONS.add(incident_id)
        results.append(incident_id)

    return json.dumps({
        "status": "SUCCESS", 
        "terminal": True, 
        "message": "SIMULATION_LOCKED: Simulation data committed. DO NOT RETRY.",
        "simulations": len(results)
    })


executor_agent = Agent(
    name="SimulationStakeholderAgent",
    model=get_model("SimulationStakeholderAgent"),
    description="Simulates the impact of response actions and generates targeted stakeholder messages.",
    tools=[
        FunctionTool(process_simulations_and_messages)
    ],
    instruction="""
    SYSTEM: Simulation Agent.
    TASK: Call 'process_simulations_and_messages' ONCE for all incidents.
    
    1. payload={"simulations": [...]}
    2. Say "DONE" and stop.
    """
)








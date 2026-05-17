from pydantic import BaseModel, Field
from typing import List, Optional

class Location(BaseModel):
    name: str
    lat: float
    lng: float

class Incident(BaseModel):
    crisis_id: str
    type: str
    location: Location
    severity: str
    confidence: float
    affected_population: int
    status: str
    expected_duration_hours: Optional[int] = None
    peak_impact_time: Optional[str] = None
    signal_sources: Optional[List[str]] = None
    conflicting_signals: Optional[List[str]] = None

class Signal(BaseModel):
    signal_id: str
    source_type: str
    source_name: str
    timestamp: str
    location: Location
    content: str
    credibility_score: float
    is_mock: bool

class AgentTrace(BaseModel):
    timestamp: str
    agent: str
    action: str
    input: dict
    output: dict
    confidence: float

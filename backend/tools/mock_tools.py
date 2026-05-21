import json
import os
from typing import List

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")

def get_mock_signals(source_type: str) -> List[dict]:
    """
    Reads mock signals from JSON files based on the source type.
    """
    file_map = {
        "social": "mock_social_posts.json",
        "emergency_call": "mock_emergency_calls.json",
        "field_report": "mock_field_reports.json",
        "sensor": "mock_sensors.json"
    }
    
    file_name = file_map.get(source_type)
    if not file_name:
        return []
    
    file_path = os.path.join(DATA_DIR, file_name)
    if not os.path.exists(file_path):
        return []
    
    with open(file_path, "r", encoding="utf-8") as f:
        return json.load(f)

def get_all_mock_signals() -> List[dict]:
    """
    Combines mock signals from all available mock sources.
    """
    all_signals = []
    for source in ["social", "emergency_call", "field_report", "sensor"]:
        all_signals.extend(get_mock_signals(source))
    return all_signals

from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from tools.maps_tool import reverse_geocode
import json

async def analyze_signals(signals_json: str) -> str:
    """
    Analyzes normalized signals and identifies potential crises.
    Classifies crisis type, location, severity, and confidence.
    """
    # This function is a placeholder for the logic that would normally be done by the LLM
    # However, since this is part of the agent's toolset, it can perform some pre-processing.
    return signals_json # Passing through for the LLM to process

detector_agent = Agent(
    name="DetectorAgent",
    description="Classifies crisis type, location, severity, and confidence based on collected signals.",
    tools=[
        FunctionTool(reverse_geocode)
    ],
    instruction="""
    You are the DetectorAgent. You receive a list of normalized signals.
    Your goal is to identify active crises.
    1. Group signals by location and content similarity.
    2. For each cluster, determine:
        - Crisis Type: flood, heatwave, accident, power_outage, protest, disease.
        - Location: name, lat, lng.
        - Severity: HIGH, MEDIUM, LOW.
        - Confidence: 0.0 to 1.0.
    3. If signals are conflicting (e.g., one report says flood, another says road clear), note this in the 'conflicting_signals' field.
    4. Output a list of Crisis objects as a JSON string.
    """
)

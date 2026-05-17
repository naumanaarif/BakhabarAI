from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from tools.weather_tool import get_weather_data
from tools.mock_tools import get_all_mock_signals
from tracer import tracer
import json
from datetime import datetime

async def collect_signals(location_name: str = "Islamabad") -> str:
    """
    Collects signals from multiple sources: Weather API and Mock JSON sources.
    Returns a normalized JSON list of signals.
    """
    signals = []
    
    # 1. Collect from Weather API (Real/Mock fallback)
    # Defaulting to Islamabad coordinates for now
    weather = await get_weather_data(33.6844, 73.0479)
    if "condition" in weather:
        signals.append({
            "signal_id": f"weather_{int(datetime.now().timestamp())}",
            "source_type": "weather",
            "source_name": "Google Weather API",
            "timestamp": datetime.now().isoformat(),
            "location": {"name": "Islamabad", "lat": 33.6844, "lng": 73.0479},
            "content": f"Weather condition: {weather['condition']}, Temp: {weather['temperature']}C, Precip: {weather['precipitation']}",
            "credibility_score": 1.0,
            "is_mock": False,
            "raw_data": weather
        })
    
    # 2. Collect from Mock Sources
    mock_signals = get_all_mock_signals()
    signals.extend(mock_signals)
    
    # Log the action
    tracer.log(
        agent="SignalCollectorAgent",
        action="collected_signals",
        input_data={"location": location_name},
        output_data={"signal_count": len(signals)},
        confidence=1.0
    )
    
    return json.dumps(signals)

signal_collector_agent = Agent(
    name="SignalCollectorAgent",
    description="Ingests all signal sources and normalizes them for the crisis detection pipeline.",
    tools=[
        FunctionTool(collect_signals)
    ],
    instruction="""
    You are the SignalCollectorAgent. Your job is to gather all possible signals related to urban crises in Islamabad.
    1. Call the 'collect_signals' tool to get a list of raw signals.
    2. Review the signals and ensure they are formatted correctly according to the schema.
    3. Output the final list of normalized signals as a JSON string.
    """
)

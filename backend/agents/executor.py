from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from tools.maps_tool import get_directions
import json

executor_agent = Agent(
    name="ExecutorAgent",
    description="Simulates response actions based on the resource plan.",
    tools=[
        FunctionTool(get_directions)
    ],
    instruction="""
    You are the ExecutorAgent. You receive a resource plan.
    Your goal is to simulate the execution of the response.
    1. For each assigned resource, get directions from their current location (assume mock bases) to the crisis site.
    2. Generate simulated action logs:
        - "Ambulance A-1 dispatched to G-10 via Service Road South."
        - "Rerouting traffic at Junction X due to flooding."
    3. Generate alert messages for stakeholders.
    4. Output the simulation results as a JSON string.
    """
)

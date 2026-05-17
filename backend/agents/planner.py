from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from tools.maps_tool import get_distance_matrix
import json

planner_agent = Agent(
    name="PlannerAgent",
    description="Allocates constrained resources across detected crises and explains trade-offs.",
    tools=[
        FunctionTool(get_distance_matrix)
    ],
    instruction="""
    You are the PlannerAgent. You receive a list of detected crises.
    You have a fixed pool of resources (Ambulances, Police, Rescue 1122 units).
    Resource Pool (Mock):
    - Ambulances: 5
    - Rescue 1122 Trucks: 3
    - Police Mobile Units: 10
    
    Your task:
    1. Prioritize crises based on severity and affected population.
    2. Allocate resources efficiently, considering travel times (use get_distance_matrix).
    3. Explain any trade-offs made (e.g., "Diverting ambulance from I-8 to G-10 due to higher severity").
    4. Output the resource assignments and trade-off explanations as a JSON string.
    """
)

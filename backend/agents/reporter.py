from google.adk.agents import Agent
from .model_config import get_model
import json

reporter_agent = Agent(
    name="ReporterAgent",
    model=get_model(),
    description="Generates final simulation outcome reports and stakeholder messages.",
    instruction="""
    You are the ReporterAgent. You receive all the data from previous agents.
    Your goal is to summarize everything for the end user and stakeholders.
    1. Generate a "Before vs After" comparison of the crisis situation.
    2. Create final messages for:
        - Citizens (Safety instructions).
        - Emergency Responders (Mission summary).
        - Government Officials (Impact assessment).
    3. Provide a final status for each crisis (e.g., "Mitigation in progress").
    4. Output the final report as a JSON string.
    """
)

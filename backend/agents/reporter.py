from google.adk.agents import Agent
from .model_config import get_model
import json

reporter_agent = Agent(
    name="ReporterAgent",
    model=get_model("ReporterAgent"),
    description="Generates final simulation outcome reports and stakeholder messages.",
    instruction="""
    SYSTEM: Reporter Agent.
    TASK: Generate a final summary report JSON.

    STOP PROTOCOL:
    1. Output a valid JSON report.
    2. Format: {"summary": "...", "stakeholders": {...}, "status": "..."}
    3. Say "Final Report Complete." and TERMINATE.
    4. NEVER repeat the report or add commentary.
    """
)


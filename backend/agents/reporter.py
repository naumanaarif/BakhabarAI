"""
ReporterAgent — lightweight final-stage summarizer.
This agent does NOT make an LLM call — it is a stub that the pipeline
calls directly via run_agent_standalone for tracer logging only.
The actual summary is composed in pipeline.py Stage 5 without any LLM
to conserve quota.  This file is retained so future ADK submission traces
show a ReporterAgent entry.
"""
from google.adk.agents import Agent
from .model_config import get_model
import json


async def generate_final_report(payload: dict = None, **kwargs) -> str:
    """
    Generates a brief final report string from incident summary data.
    Called with a pre-built summary dict so no extra LLM reasoning is needed.
    """
    data = payload or kwargs
    incidents = data.get("incidents", [])
    high  = sum(1 for i in incidents if i.get("sev") == "HIGH")
    med   = sum(1 for i in incidents if i.get("sev") == "MEDIUM")
    low   = sum(1 for i in incidents if i.get("sev") == "LOW")
    return json.dumps({
        "status":  "complete",
        "summary": f"Pipeline complete. {len(incidents)} active incidents: HIGH={high}, MEDIUM={med}, LOW={low}.",
        "terminal": True,
    })


reporter_agent = Agent(
    name="ReporterAgent",
    model=get_model("ReporterAgent"),
    description="Generates final simulation summary and stakeholder status.",
    instruction=(
        "SYSTEM: Reporter. TASK: Call generate_final_report once with the "
        "incident summary. Output the JSON and say DONE. Do not add commentary."
    ),
)

from google.adk.agents import SequentialAgent
from agents.signal_collector import signal_collector_agent
from agents.detector import detector_agent
from agents.planner import planner_agent
from agents.executor import executor_agent
from agents.reporter import reporter_agent
from .adk_runtime import run_agent_standalone

# Main pipeline orchestration
crisis_pipeline = SequentialAgent(
    name="BakhabarAI_Pipeline",
    sub_agents=[
        signal_collector_agent,
        detector_agent,
        planner_agent,
        executor_agent,
        reporter_agent
    ]
)

async def run_crisis_simulation(scenario_data: dict = None):
    """
    Triggers the full agent pipeline.
    If scenario_data is provided, it can be used to seed the pipeline.
    """
    # The initial input to the pipeline
    initial_input = "Identify and respond to any urban crises in Islamabad."
    if scenario_data:
        initial_input += f" Use this scenario data: {scenario_data}"
    
    # Run the pipeline using the standalone runner
    result = await run_agent_standalone(crisis_pipeline, initial_input)
    return result

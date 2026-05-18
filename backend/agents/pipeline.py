from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from .adk_runtime import run_agent_standalone
from agents.signal_collector import fuse_and_verify_signals
from agents.detector import classify_and_predict
from agents.planner import optimize_resources
from agents.executor import simulate_and_report
from .model_config import get_model

# Orchestrator (Python-based Sequence for Stability)
async def run_crisis_simulation(scenario_data: dict = None):
    """
    Manually executes the crisis response pipeline in a fixed order.
    This replaces the Agent-based orchestrator to ensure 100% stability
    and zero infinite loops during the demo.
    """
    from tracer import tracer
    
    # 1. Verification Step
    tracer.log("System", "Verifying incoming emergency signals...", {}, {})
    await fuse_and_verify_signals()
    tracer.log("System", "Signals verified and merged into active incidents.", {}, {})
    
    # 2. Analysis Step
    tracer.log("System", "Analyzing crisis severity and predicting evolution...", {}, {})
    await classify_and_predict()
    tracer.log("System", "Incident analysis and impact predictions complete.", {}, {})
    
    # 3. Planning Step
    tracer.log("System", "Optimizing resource allocation across active zones...", {}, {})
    await optimize_resources()
    tracer.log("System", "Response units dispatched and deployment plan ready.", {}, {})
    
    # 4. Simulation Step
    tracer.log("System", "Calculating predicted outcomes and notifying stakeholders...", {}, {})
    await simulate_and_report()
    tracer.log("System", "Impact simulation ready and stakeholders notified.", {}, {})
    
    return "PIPELINE_COMPLETE"

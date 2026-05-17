import json
from datetime import datetime
import os

class AgentTracer:
    def __init__(self):
        self.traces = []

    def log(self, agent: str, action: str, 
            input_data: dict, output_data: dict, 
            confidence: float = None):
        self.traces.append({
            "timestamp": datetime.now().isoformat(),
            "agent": agent,
            "action": action,
            "input": input_data,
            "output": output_data,
            "confidence": confidence
        })

    def export(self, path: str = "traces/agent_trace.json"):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            json.dump(self.traces, f, indent=2)

    def get_traces(self):
        return self.traces

    def clear(self):
        self.traces = []

# Global instance — import this everywhere
tracer = AgentTracer()

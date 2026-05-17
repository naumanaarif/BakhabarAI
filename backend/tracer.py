import json
from datetime import datetime
import os

class AgentTracer:
    def __init__(self):
        self.traces = []

    def log(self, agent_name: str, action: str, 
            input_data: dict, output_data: dict, 
            confidence: float = 1.0):
        self.traces.append({
            "id": f"trace_{len(self.traces) + 1}",
            "agent_name": agent_name,
            "action": action,
            "input_data": input_data,
            "output_data": output_data,
            "confidence": confidence,
            "timestamp": datetime.now().isoformat()
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

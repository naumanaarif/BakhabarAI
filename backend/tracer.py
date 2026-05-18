import json
from datetime import datetime
import os
from services.firebase_service import FirebaseService

class AgentTracer:
    def __init__(self):
        self.traces = []

    def log(self, agent_name: str, action: str, 
            input_data: dict, output_data: dict, 
            confidence: float = 1.0):
        # Humanize the log entry
        trace_data = {
            "id": f"trace_{len(self.traces) + 1}",
            "agent_name": agent_name,
            "action": action,
            "confidence": confidence,
            "timestamp": datetime.now().isoformat()
        }
        
        # Only include data if it's meaningful/populated to save space
        if input_data: trace_data["input_summary"] = str(input_data)[:200]
        if output_data: trace_data["output_summary"] = str(output_data)[:200]

        self.traces.append(trace_data)

        # PERSIST TO FIREBASE for Mobile App
        try:
            FirebaseService.add_agent_log(
                agent_name=agent_name,
                action=action,
                input_data={}, # Keep empty to avoid JSON clutter in UI
                output_data={}, # Keep empty to avoid JSON clutter in UI
                confidence=confidence
            )
        except Exception as e:
            print(f"Error persisting log to Firebase: {e}")

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

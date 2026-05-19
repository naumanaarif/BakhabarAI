from google.adk.models.google_llm import Gemini
from google.adk.models.lite_llm import LiteLlm
from config import GEMINI_API_KEY, GROQ_API_KEY, GROQ_API_KEYS
import os

# Set base API keys
os.environ["GOOGLE_API_KEY"] = GEMINI_API_KEY

# Initialize Gemini once
gemini_model = Gemini(model="models/gemini-2.0-flash-lite")

# Pre-initialize a pool of Groq models, one for each key
groq_model_pool = []
if GROQ_API_KEYS:
    print(f"DEBUG: Initializing Groq model pool with {len(GROQ_API_KEYS)} keys...")
    for i, key in enumerate(GROQ_API_KEYS):
        if not key or len(key) < 10: # Basic validation
            print(f"DEBUG: Skipping invalid/empty key at index {i}")
            continue
            
        try:
            # Pass the key directly to the model instance to ensure it's "locked in"
            model_instance = LiteLlm(
                model="groq/llama-3.1-8b-instant",
                api_key=key
            )
            groq_model_pool.append(model_instance)
            print(f"DEBUG: Successfully added model for key {i+1} to pool.")
        except Exception as e:
            print(f"DEBUG: Failed to initialize Groq model with key {i}: {e}")

# If no Groq keys were valid, ensure we have at least one fallback or log warning
if not groq_model_pool and os.getenv("PREFER_GROQ", "False").lower() == "true":
    print("CRITICAL: No valid Groq API keys available in pool. Falling back to Gemini.")

# Restore default key
if GROQ_API_KEY:
    os.environ["GROQ_API_KEY"] = GROQ_API_KEY

def get_model(agent_name: str = None):
    """
    Returns the appropriate model for the agent.
    If multiple Groq keys are available, it partitions them by agent.
    """
    if os.getenv("PREFER_GROQ", "False").lower() == "true" and groq_model_pool:
        if not agent_name:
            return groq_model_pool[0]
            
        # Map agents to specific model instances in the pool
        mapping = {
            "SignalFusionAgent": 0,
            "DetectorAgent": 1,
            "ResourcePlannerAgent": 2,
            "SimulationStakeholderAgent": 3,
            "ReporterAgent": 4
        }
        
        idx = mapping.get(agent_name, 0) % len(groq_model_pool)
        print(f"DEBUG: Agent '{agent_name}' mapped to Groq key index {idx}")
        return groq_model_pool[idx]
        
    return gemini_model

def rotate_groq_key():
    """Fallback for reactive rotation if needed."""
    pass # No longer needed with the pool, but kept for compatibility

def set_key_for_agent(agent_name: str):
    """Sets the environment variable for the agent's mapped key."""
    if os.getenv("PREFER_GROQ", "False").lower() == "true" and groq_model_pool:
        mapping = {
            "SignalFusionAgent": 0,
            "DetectorAgent": 1,
            "ResourcePlannerAgent": 2,
            "SimulationStakeholderAgent": 3,
            "ReporterAgent": 4
        }
        idx = mapping.get(agent_name, 0) % len(groq_model_pool)
        # Get the actual key from our pool's model instance if possible, or re-parse from config
        # For simplicity, we'll re-parse from GROQ_API_KEYS
        if idx < len(GROQ_API_KEYS):
            key = GROQ_API_KEYS[idx]
            os.environ["GROQ_API_KEY"] = key
            # Also set GROQ_API_KEY for LiteLLM
            os.environ["GROQ_API_KEY"] = key
            print(f"DEBUG: Set GROQ_API_KEY for {agent_name} to key at index {idx}")

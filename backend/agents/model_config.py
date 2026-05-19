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
                model="groq/llama-3.3-70b-versatile",
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

# Global index to track current key rotation
current_key_index = 0

def rotate_groq_key():
    """Reactive rotation to move to the next key in the pool when 429 occurs."""
    global current_key_index
    if groq_model_pool:
        current_key_index = (current_key_index + 1) % len(groq_model_pool)
        key = GROQ_API_KEYS[current_key_index % len(GROQ_API_KEYS)]
        os.environ["GROQ_API_KEY"] = key
        print(f"DEBUG: Rotated GROQ_API_KEY to pool index {current_key_index}")

def get_model(agent_name: str = None):
    """
    Returns the appropriate model for the agent.
    If multiple Groq keys are available, it partitions them by agent.
    """
    if os.getenv("PREFER_GROQ", "False").lower() == "true" and groq_model_pool:
        # If we just rotated, we might want to prioritize the rotated key
        # But usually partitioned mapping is better for parallelism.
        
        if not agent_name:
            return groq_model_pool[current_key_index % len(groq_model_pool)]
            
        # Map agents to specific model instances in the pool
        mapping = {
            "SignalFusionAgent": 0,
            "DetectorAgent": 1,
            "ResourcePlannerAgent": 2,
            "SimulationStakeholderAgent": 3,
            "ReporterAgent": 4
        }
        
        # Add current_key_index as an offset for the base mapping to help recovery
        base_idx = mapping.get(agent_name, 0)
        idx = (base_idx + current_key_index) % len(groq_model_pool)
        print(f"DEBUG: Agent '{agent_name}' mapped to Groq key at pool index {idx}")
        return groq_model_pool[idx]
        
    return gemini_model

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
        # First, find which key in the original list we SHOULD use
        # (This is tricky because the pool might be smaller than the raw list)
        # For simplicity, we'll just set it to the key of the model instance we mapped to
        pool_idx = mapping.get(agent_name, 0) % len(groq_model_pool)
        
        # Find the actual key used for this pool item
        # We'll just rotate through the available ones
        if pool_idx < len(GROQ_API_KEYS):
            key = GROQ_API_KEYS[pool_idx]
            os.environ["GROQ_API_KEY"] = key
            print(f"DEBUG: Set GROQ_API_KEY for {agent_name} to key at pool index {pool_idx}")

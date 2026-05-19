from google.adk.models.google_llm import Gemini
from google.adk.models.lite_llm import LiteLlm
from config import GEMINI_API_KEY, GROQ_API_KEY, GROQ_API_KEYS
import os

# Gemini (fallback / when PREFER_GROQ=False)
os.environ["GOOGLE_API_KEY"] = GEMINI_API_KEY
try:
    gemini_primary = Gemini(model="gemini-2.0-flash")
    gemini_lite    = Gemini(model="gemini-2.0-flash-lite")
    print("DEBUG: Gemini 2.0 Flash models initialized.")
except Exception as e:
    print(f"WARN: Gemini 2.0 Flash unavailable, using 1.5 Flash: {e}")
    gemini_primary = Gemini(model="gemini-1.5-flash")
    gemini_lite    = gemini_primary

# Groq pool
# Each key is from a DIFFERENT Groq account -> independent 6K TPM budget per key.
# Strategy: assign one dedicated key per agent for maximum parallelism.
groq_model_pool: list = []
if GROQ_API_KEYS:
    print(f"DEBUG: Initializing Groq pool with {len(GROQ_API_KEYS)} independent-account keys...")
    for i, key in enumerate(GROQ_API_KEYS):
        if not key or len(key) < 10:
            print(f"DEBUG: Skipping invalid key at index {i}")
            continue
        try:
            model_instance = LiteLlm(
                model="groq/llama-3.1-8b-instant",
                api_key=key,
                temperature=0.0,
            )
            groq_model_pool.append(model_instance)
            print(f"DEBUG: Added Groq model for account {i + 1} to pool (key ...{key[-6:]})")
        except Exception as e:
            print(f"DEBUG: Failed to init Groq model key {i}: {e}")

if not groq_model_pool:
    print("WARN: No valid Groq keys -- Gemini will be used exclusively.")

# Set default env var (first key)
if GROQ_API_KEY:
    os.environ["GROQ_API_KEY"] = GROQ_API_KEY

# Agent -> pool slot mapping
# Each agent gets its OWN dedicated slot so they never share TPM.
# With 6 keys and 5 agents, slot 5 (index 5) is a spare for rotation.
_AGENT_SLOT = {
    "SignalFusionAgent":          0,  # key 1
    "DetectorAgent":              1,  # key 2
    "ResourcePlannerAgent":       2,  # key 3
    "SimulationStakeholderAgent": 3,  # key 4
    "ReporterAgent":              4,  # key 5
    # key 6 (index 5) is the rotation spare
}
_SPARE_SLOT = 5  # index of the spare key used on rate-limit rotation

# Per-agent rotation offset (starts at 0, increments to spare on 429)
_agent_rotation: dict = {}

# Global fallback rotation index (used when agent name is unknown)
current_key_index = 0


def _pool_size() -> int:
    return len(groq_model_pool)


def rotate_groq_key(agent_name: str = None):
    """
    On a 429 for a specific agent, rotate that agent's slot to the spare key.
    If the spare is also exhausted, cycles through remaining slots.
    """
    global current_key_index
    if not groq_model_pool:
        return

    if agent_name and agent_name in _AGENT_SLOT:
        current = _agent_rotation.get(agent_name, _AGENT_SLOT[agent_name])
        spare = _SPARE_SLOT % _pool_size()
        if current != spare:
            _agent_rotation[agent_name] = spare
            print(f"DEBUG: Agent '{agent_name}' rotated to spare slot {spare}")
        else:
            next_slot = (current + 1) % _pool_size()
            _agent_rotation[agent_name] = next_slot
            print(f"DEBUG: Agent '{agent_name}' spare exhausted, cycling to slot {next_slot}")

        key_idx = _agent_rotation[agent_name] % len(GROQ_API_KEYS)
        os.environ["GROQ_API_KEY"] = GROQ_API_KEYS[key_idx]
    else:
        current_key_index = (current_key_index + 1) % _pool_size()
        key_idx = current_key_index % len(GROQ_API_KEYS)
        os.environ["GROQ_API_KEY"] = GROQ_API_KEYS[key_idx]
        print(f"DEBUG: Global key rotated to index {current_key_index}")


def get_model(agent_name: str = None, force_gemini: bool = False):
    """
    Returns the best model for the given agent.

    Priority:
      1. Gemini  -- if force_gemini=True (rate-limit fallback)
      2. Groq    -- if PREFER_GROQ=True AND pool is available
      3. Gemini  -- default fallback
    """
    prefer_groq = os.getenv("PREFER_GROQ", "False").lower() == "true"

    if force_gemini or not prefer_groq or not groq_model_pool:
        if force_gemini:
            print(f"DEBUG: Force Gemini for '{agent_name}'")
        _LITE_AGENTS = {"SignalFusionAgent", "DetectorAgent", "ReporterAgent"}
        return gemini_lite if agent_name in _LITE_AGENTS else gemini_primary

    # Groq: use the agent's dedicated slot (with any active rotation applied)
    base_slot = _AGENT_SLOT.get(agent_name, current_key_index % _pool_size())
    slot = _agent_rotation.get(agent_name, base_slot) % _pool_size()
    key_suffix = GROQ_API_KEYS[slot % len(GROQ_API_KEYS)][-6:]
    print(f"DEBUG: Agent '{agent_name}' -> Groq slot {slot} (key ...{key_suffix})")
    return groq_model_pool[slot]


def set_key_for_agent(agent_name: str):
    """Sets GROQ_API_KEY env var to this agent's currently assigned key."""
    prefer_groq = os.getenv("PREFER_GROQ", "False").lower() == "true"
    if prefer_groq and groq_model_pool and GROQ_API_KEYS:
        base_slot = _AGENT_SLOT.get(agent_name, 0)
        slot = _agent_rotation.get(agent_name, base_slot) % _pool_size()
        key_idx = slot % len(GROQ_API_KEYS)
        os.environ["GROQ_API_KEY"] = GROQ_API_KEYS[key_idx]
        key_suffix = GROQ_API_KEYS[key_idx][-6:]
        print(f"DEBUG: Set GROQ_API_KEY for '{agent_name}' to slot {slot} (...{key_suffix})")

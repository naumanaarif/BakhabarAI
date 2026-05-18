from google.adk.models.google_llm import Gemini
from google.adk.models.lite_llm import LiteLlm
from config import GEMINI_API_KEY, GROQ_API_KEY
import os

# Set API keys for the environment
os.environ["GOOGLE_API_KEY"] = GEMINI_API_KEY
os.environ["GROQ_API_KEY"] = GROQ_API_KEY

# Initialize models
# Primary: Gemini
gemini_model = Gemini(model="models/gemini-2.0-flash-lite")

# Backup: Groq (using Llama 3.1 8B for maximum TPD quota and speed)
groq_model = None
if GROQ_API_KEY:
    groq_model = LiteLlm(model="groq/llama-3.1-8b-instant")

def get_model():
    # Prefer Gemini Flash Lite for stability and quota
    if os.getenv("PREFER_GROQ", "False").lower() == "true":
        return groq_model
    return gemini_model

def get_backup_model():
    return groq_model if groq_model else gemini_model

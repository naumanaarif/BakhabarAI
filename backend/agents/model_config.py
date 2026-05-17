from google.adk.models.google_llm import Gemini
from config import GEMINI_API_KEY
import os

# Set API key for Google Generative AI if needed by the environment
os.environ["GOOGLE_API_KEY"] = GEMINI_API_KEY

# Initialize the Gemini model
# Note: google-adk usually uses the Gemini 2.0 Flash model by default or as specified
adk_model = Gemini(model="gemini-3.1-flash-lite")

def get_model():
    return adk_model

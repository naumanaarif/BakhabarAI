import os
from dotenv import load_dotenv

load_dotenv(override=True)

GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY") or os.getenv("Google_MAPS_API_KEY") or ""
# If multiple keys are provided in a comma-separated list, take the first one
if "," in GOOGLE_MAPS_API_KEY:
    GOOGLE_MAPS_API_KEY = GOOGLE_MAPS_API_KEY.split(",")[0].strip()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
# Robust multi-key parsing
raw_keys = os.getenv("GROQ_API_KEYS", GROQ_API_KEY)
# Clean and split: handles commas, newlines, and carriage returns
GROQ_API_KEYS = [k.strip() for k in raw_keys.replace("\n", ",").replace("\r", ",").split(",") if k.strip()]
print(f"DEBUG: Config loaded {len(GROQ_API_KEYS)} Groq API keys.")

WEATHER_BASE_URL = "https://weather.googleapis.com/v1"
MAPS_BASE_URL = "https://maps.googleapis.com/maps/api"

# Default configuration settings
DEBUG = os.getenv("DEBUG", "True").lower() == "true"

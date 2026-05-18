import os
from dotenv import load_dotenv

load_dotenv()

GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY", "")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")

WEATHER_BASE_URL = "https://weather.googleapis.com/v1"
MAPS_BASE_URL = "https://maps.googleapis.com/maps/api"

# Default configuration settings
DEBUG = os.getenv("DEBUG", "True").lower() == "true"

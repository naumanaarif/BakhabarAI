import httpx
from config import GOOGLE_MAPS_API_KEY, WEATHER_BASE_URL
from typing import Dict, Any

async def get_weather_data(lat: float, lng: float) -> Dict[str, Any]:
    """
    Fetches weather data from Google Weather API.
    If API key is missing, returns a mock response.
    """
    if not GOOGLE_MAPS_API_KEY:
        # Mock weather data for Islamabad
        return {
            "source": "Mock Google Weather API",
            "condition": "Heavy Rain",
            "temperature": 22,
            "precipitation": "23mm",
            "wind_speed": "15km/h",
            "humidity": "85%",
            "location": {"lat": lat, "lng": lng}
        }

    # Note: In a real scenario, we would use the correct endpoint and params for Google Weather API.
    # For now, we'll use a placeholder structure.
    try:
        async with httpx.AsyncClient() as client:
            # Example endpoint structure (hypothetical)
            response = await client.get(
                f"{WEATHER_BASE_URL}/current",
                params={
                    "location": f"{lat},{lng}",
                    "key": GOOGLE_MAPS_API_KEY
                }
            )
            if response.status_code == 200:
                return response.json()
            else:
                return {"error": f"API returned status {response.status_code}", "fallback": "mock"}
    except Exception as e:
        return {"error": str(e), "fallback": "mock"}

import httpx
from config import GOOGLE_MAPS_API_KEY, MAPS_BASE_URL
from typing import Dict, Any, List

async def get_distance_matrix(origins: List[str], destinations: List[str]) -> Dict[str, Any]:
    """
    Fetches distance and duration between origins and destinations using Google Distance Matrix API.
    """
    if not GOOGLE_MAPS_API_KEY:
        return {
            "status": "OK",
            "rows": [
                {
                    "elements": [
                        {"distance": {"text": "5 km", "value": 5000}, "duration": {"text": "10 mins", "value": 600}, "status": "OK"}
                    ]
                }
            ]
        }

    url = f"{MAPS_BASE_URL}/distancematrix/json"
    params = {
        "origins": "|".join(origins),
        "destinations": "|".join(destinations),
        "key": GOOGLE_MAPS_API_KEY
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.get(url, params=params)
        return response.json()

async def get_directions(origin: str, destination: str) -> Dict[str, Any]:
    """
    Fetches directions using Google Directions API.
    """
    if not GOOGLE_MAPS_API_KEY:
        return {"status": "OK", "routes": [{"summary": "Via Mock Road", "legs": [{"steps": []}]}]}

    url = f"{MAPS_BASE_URL}/directions/json"
    params = {
        "origin": origin,
        "destination": destination,
        "key": GOOGLE_MAPS_API_KEY
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.get(url, params=params)
        return response.json()

async def reverse_geocode(lat: float, lng: float) -> Dict[str, Any]:
    """
    Converts coordinates to a human-readable address.
    """
    if not GOOGLE_MAPS_API_KEY:
        return {"status": "OK", "results": [{"formatted_address": "Mock Address, Islamabad"}]}

    url = f"{MAPS_BASE_URL}/geocode/json"
    params = {
        "latlng": f"{lat},{lng}",
        "key": GOOGLE_MAPS_API_KEY
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.get(url, params=params)
        return response.json()

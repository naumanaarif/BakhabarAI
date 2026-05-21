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

async def get_places_autocomplete(query: str) -> Dict[str, Any]:
    """
    Fetches location autocomplete suggestions.
    Tries the New Places API first, falls back to Classic if needed.
    """
    if not GOOGLE_MAPS_API_KEY:
        print("DEBUG: No Google Maps API Key found.")
        return {"predictions": [{"description": f"{query} (Mock)"}]}

    print(f"DEBUG: Using Google Maps API Key ending in ...{GOOGLE_MAPS_API_KEY[-4:]}")

    # 1. Try New Places API
    url_new = "https://places.googleapis.com/v1/places:autocomplete"
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": GOOGLE_MAPS_API_KEY
    }
    payload = {
        "input": query,
        "includedRegionCodes": ["pk"]
    }
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(url_new, headers=headers, json=payload, timeout=5.0)
            print(f"DEBUG: New Places API Response Status: {response.status_code}")
            if response.status_code == 200:
                data = response.json()
                predictions = []
                if "suggestions" in data:
                    for item in data["suggestions"]:
                        pred = item.get("placePrediction", {})
                        text_obj = pred.get("text", {})
                        desc = text_obj.get("text")
                        if desc:
                            predictions.append({"description": desc})
                    if predictions:
                        return {"predictions": predictions}
            else:
                print(f"DEBUG: New Places API Error: {response.text}")
    except Exception as e:
        print(f"DEBUG: New Places API Exception: {e}")

    # 2. Fallback to Classic Places API
    url_classic = f"{MAPS_BASE_URL}/place/autocomplete/json"
    params = {
        "input": query,
        "components": "country:pk",
        "key": GOOGLE_MAPS_API_KEY
    }
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(url_classic, params=params, timeout=5.0)
            print(f"DEBUG: Classic Places API Response Status: {response.status_code}")
            data = response.json()
            if data.get("status") == "OK":
                return {"predictions": data.get("predictions", [])}
            else:
                print(f"DEBUG: Classic Places API Error: {data.get('status')} - {data.get('error_message')}")
    except Exception as e:
        print(f"DEBUG: Classic Places API Exception: {e}")
                    
    return {"predictions": [
        {"description": f"{query}, Islamabad"},
        {"description": f"{query}, Rawalpindi"},
        {"description": f"{query} Sector, Islamabad"}
    ]}

async def geocode(address: str) -> Dict[str, Any]:
    """
    Converts address to coordinates.
    """
    if not GOOGLE_MAPS_API_KEY:
        # Default mock coordinates in Karachi/Islamabad based on address
        addr_lower = address.lower()
        if "scheme 33" in addr_lower or "karachi" in addr_lower:
            return {"lat": 24.9462, "lng": 67.1238}
        elif "i-8" in addr_lower:
            return {"lat": 33.6811, "lng": 73.0805}
        elif "g-10" in addr_lower:
            return {"lat": 33.6844, "lng": 73.0479}
        return {"lat": 33.6844, "lng": 73.0479}

    url = f"{MAPS_BASE_URL}/geocode/json"
    params = {
        "address": address,
        "key": GOOGLE_MAPS_API_KEY
    }
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(url, params=params)
            data = response.json()
            if data.get("status") == "OK" and data.get("results"):
                loc = data["results"][0]["geometry"]["location"]
                return {"lat": loc["lat"], "lng": loc["lng"]}
    except Exception as e:
        print(f"Error geocoding address '{address}': {e}")
        
    return {"lat": 33.6844, "lng": 73.0479}


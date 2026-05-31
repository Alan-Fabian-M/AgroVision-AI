from fastapi import APIRouter, Depends, Query
from app.services.weather_service import WeatherService, get_weather_service

router = APIRouter(prefix="/weather", tags=["Weather"])

@router.get("/")
async def get_current_weather(
    lat: float = Query(..., description="Latitude"),
    lon: float = Query(..., description="Longitude"),
    weather_service: WeatherService = Depends(get_weather_service),
):
    """
    Get the current weather for a specific location.
    """
    return await weather_service.get_weather(lat, lon)

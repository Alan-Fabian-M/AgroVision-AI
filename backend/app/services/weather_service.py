import os
import logging
from app.core.config import get_settings
import httpx
from fastapi import HTTPException, status

logger = logging.getLogger(__name__)

class WeatherService:
    def __init__(self):
        settings = get_settings()
        self.api_key = settings.OPENWEATHER_API_KEY
        self.base_url = "https://api.openweathermap.org/data/2.5/weather"

    async def get_weather(self, lat: float, lon: float) -> dict:
        if not self.api_key:
            logger.warning("OPENWEATHER_API_KEY is not set. Returning mock weather data.")
            return {
                "temperature": 25.0,
                "humidity": 60,
                "condition": "Mocked Clear (No API Key)",
                "icon": "01d"
            }

        params = {
            "lat": lat,
            "lon": lon,
            "appid": self.api_key,
            "units": "metric",
            "lang": "es"
        }

        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(self.base_url, params=params, timeout=10.0)
                response.raise_for_status()
                data = response.json()
                
                return {
                    "temperature": data["main"]["temp"],
                    "humidity": data["main"]["humidity"],
                    "condition": data["weather"][0]["description"].title(),
                    "icon": data["weather"][0]["icon"]
                }
            except httpx.HTTPStatusError as e:
                logger.error(f"HTTP error from OpenWeatherMap: {e}")
                raise HTTPException(
                    status_code=status.HTTP_502_BAD_GATEWAY,
                    detail="Error conectando al servicio del clima."
                )
            except httpx.RequestError as e:
                logger.error(f"Request error to OpenWeatherMap: {e}")
                raise HTTPException(
                    status_code=status.HTTP_504_GATEWAY_TIMEOUT,
                    detail="Tiempo de espera agotado al consultar el clima."
                )
            except Exception as e:
                logger.error(f"Unexpected error in WeatherService: {e}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Error inesperado al obtener el contexto climático."
                )

def get_weather_service() -> WeatherService:
    return WeatherService()

"""
Interfaz: WeatherService
Define el contrato para obtener datos climáticos.
Implementaciones: MockWeatherService (MVP), OpenWeatherMapService (futuro).
"""
from abc import ABC, abstractmethod
from typing import Any


class WeatherService(ABC):
    """Contrato para servicios de datos climáticos."""

    @abstractmethod
    async def get_weather(
        self,
        latitude: float,
        longitude: float,
    ) -> dict[str, Any]:
        """
        Obtiene datos climáticos actuales para una coordenada geográfica.

        Args:
            latitude: Latitud en grados decimales (-90 a 90).
            longitude: Longitud en grados decimales (-180 a 180).

        Returns:
            Diccionario con al menos:
            {
                "temp_celsius": float,
                "humidity_pct": float,
                "pressure_hpa": float,
                "description": str,
                "wind_speed_ms": float,
                "source": str,
            }
        """
        ...

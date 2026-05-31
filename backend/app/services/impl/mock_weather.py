"""
Implementación: MockWeatherService
Simula una respuesta de OpenWeatherMap para el MVP.
Genera datos climáticos realistas basados en la latitud/longitud.
"""
import hashlib
import math
from typing import Any

from app.services.interfaces.weather import WeatherService


class MockWeatherService(WeatherService):
    """
    Servicio de clima simulado para el MVP.
    Genera datos determinísticos pero realistas basados en coordenadas.
    Preparado para ser reemplazado por OpenWeatherMapService real.
    """

    async def get_weather(
        self,
        latitude: float,
        longitude: float,
    ) -> dict[str, Any]:
        """
        Genera datos climáticos simulados.

        Usa un hash de las coordenadas para generar valores determinísticos
        (misma ubicación = mismo clima simulado), con ajustes por zona
        geográfica para mayor realismo.
        """
        # Seed determinístico basado en coordenadas (redondeadas a 2 decimales)
        seed_str = f"{round(latitude, 2)}:{round(longitude, 2)}"
        seed = int(hashlib.md5(seed_str.encode()).hexdigest()[:8], 16)

        # Temperatura base según latitud (trópico más cálido)
        lat_factor = abs(latitude) / 90.0  # 0 en el ecuador, 1 en los polos
        base_temp = 30.0 - (lat_factor * 35.0)  # ~30°C en ecuador, ~-5°C en polos
        temp_variation = (seed % 15) - 7  # ±7°C de variación
        temp = round(base_temp + temp_variation, 1)

        # Humedad (mayor en zonas tropicales)
        base_humidity = 80.0 - (lat_factor * 40.0)
        humidity_variation = (seed % 20) - 10
        humidity = round(
            max(15.0, min(98.0, base_humidity + humidity_variation)), 1
        )

        # Presión atmosférica
        pressure = round(1013.25 + ((seed % 30) - 15), 1)

        # Velocidad del viento
        wind_speed = round(1.0 + (seed % 15) * 0.8, 1)

        # Descripción del clima
        descriptions = [
            "Cielo despejado",
            "Parcialmente nublado",
            "Nublado",
            "Lluvia ligera",
            "Lluvia moderada",
            "Tormenta eléctrica",
            "Neblina",
            "Cálido y soleado",
        ]
        description = descriptions[seed % len(descriptions)]

        # Condición climática simplificada para el análisis de plagas
        if humidity > 75:
            climate_condition = "Alta Humedad"
        elif temp > 35:
            climate_condition = "Calor Extremo"
        elif temp < 10:
            climate_condition = "Frío"
        elif humidity < 30:
            climate_condition = "Sequía"
        else:
            climate_condition = "Templado"

        return {
            "temp_celsius": temp,
            "humidity_pct": humidity,
            "pressure_hpa": pressure,
            "description": description,
            "wind_speed_ms": wind_speed,
            "climate_condition": climate_condition,
            "source": "mock_openweathermap",
            "coordinates": {
                "latitude": latitude,
                "longitude": longitude,
            },
        }

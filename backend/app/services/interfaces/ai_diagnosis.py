"""
Interfaz: AIDiagnosisService
Define el contrato para servicios de diagnóstico basado en IA.
Implementaciones: GeminiDiagnosisService (MVP).
"""
from abc import ABC, abstractmethod
from typing import Any


class AIDiagnosisService(ABC):
    """Contrato para análisis multimodal de cultivos mediante IA."""

    @abstractmethod
    async def analyze(
        self,
        image_paths: list[str],
        audio_path: str | None,
        text_notes: str | None,
        weather_data: dict[str, Any],
    ) -> dict[str, Any]:
        """
        Ejecuta un análisis multimodal de un cultivo.

        Args:
            image_paths: Lista de rutas locales a las imágenes del cultivo.
            audio_path: Ruta local al archivo de audio (opcional).
            text_notes: Notas de texto del agricultor (opcional).
            weather_data: Datos climáticos obtenidos del WeatherService.

        Returns:
            Diccionario con los campos requeridos por la tabla Diagnosis:
            {
                "risk_level": str,
                "estimated_loss_usd": float,
                "action_plan": str,
                "pest_detected": str,
                "pest_type": str,
                "defoliation_pct": float,
                "beneficial_controllers": str | None,
                "confidence": float,
                "productos_sugeridos": list[str],
                "recomendaciones_tratamiento": str,
            }
        """
        ...

"""
Interfaz: TreatmentRecommendationService
Define el contrato para generar recomendaciones de tratamiento.
Implementaciones:
  - LLMRecommendationService (MVP): usa Gemini para generar tratamiento.
  - GraphRecommendationService (futuro): consultas Cypher a Neo4j.
"""
from abc import ABC, abstractmethod
from typing import Any


class TreatmentRecommendationService(ABC):
    """Contrato para servicios de recomendación de tratamientos."""

    @abstractmethod
    async def recommend(
        self,
        diagnosis_data: dict[str, Any],
    ) -> str:
        """
        Genera un plan de tratamiento basado en los datos del diagnóstico.

        Args:
            diagnosis_data: Diccionario con los campos del diagnóstico IA
                            (pest_detected, pest_type, defoliation_pct, etc.).

        Returns:
            Texto con el plan de tratamiento detallado.
        """
        ...

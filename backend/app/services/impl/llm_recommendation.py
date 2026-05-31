"""
Implementación: LLMRecommendationService (MVP)
Genera recomendaciones de tratamiento usando Gemini.
"""
import json
import logging
from typing import Any

import google.generativeai as genai

from app.core.config import get_settings
from app.services.interfaces.treatment import TreatmentRecommendationService

logger = logging.getLogger(__name__)


class LLMRecommendationService(TreatmentRecommendationService):
    """
    Genera un plan de tratamiento usando Gemini como motor de recomendación.
    MVP: basado en el diagnóstico previo del cultivo.
    Futuro: será reemplazado por GraphRecommendationService (Neo4j).
    """

    def __init__(self) -> None:
        settings = get_settings()
        api_key = settings.GEMINI_API_KEY
        if not api_key:
            raise ValueError("GEMINI_API_KEY no configurada.")

        genai.configure(api_key=api_key)

        self._model = genai.GenerativeModel(
            "gemini-2.0-flash",
            generation_config={"response_mime_type": "text/plain"},
        )

    async def recommend(
        self,
        diagnosis_data: dict[str, Any],
    ) -> str:
        """
        Genera recomendaciones de tratamiento basadas en el diagnóstico.
        """
        prompt = f"""
Eres un ingeniero agrónomo experto en tratamientos fitosanitarios.
Basándote en el siguiente diagnóstico de un cultivo, genera un plan
de tratamiento detallado y práctico.

DIAGNÓSTICO PREVIO:
  • Plaga detectada: {diagnosis_data.get("pest_detected", "Desconocida")}
  • Tipo de plaga: {diagnosis_data.get("pest_type", "OTRO")}
  • % Defoliación: {diagnosis_data.get("defoliation_pct", 0)}%
  • Nivel de riesgo: {diagnosis_data.get("risk_level", "MODERADO")}
  • Controladores benéficos: {diagnosis_data.get("beneficial_controllers", "No identificados")}
  • Productos sugeridos por IA: {diagnosis_data.get("productos_sugeridos", [])}

INSTRUCCIONES:
1. Redacta un plan de tratamiento con pasos concretos y cronograma.
2. Incluye dosis recomendadas de productos (genéricas).
3. Menciona prácticas de manejo integrado de plagas (MIP).
4. Considera la preservación de controladores benéficos si fueron identificados.
5. Incluye medidas preventivas para evitar reinfestación.
6. Sé conciso pero técnicamente preciso.

Escribe en español, formato texto plano, máximo 500 palabras.
"""

        try:
            response = self._model.generate_content(prompt)
            plan = response.text.strip()
            logger.info(f"Plan de tratamiento generado ({len(plan)} chars)")
            return plan
        except Exception as e:
            logger.error(f"Error generando plan de tratamiento: {e}")
            return (
                f"Plan de tratamiento automático no disponible. "
                f"Error: {str(e)}. "
                f"Consulte con un ingeniero agrónomo para el tratamiento de "
                f"'{diagnosis_data.get('pest_detected', 'la plaga detectada')}'."
            )

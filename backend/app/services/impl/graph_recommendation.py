"""
Placeholder: GraphRecommendationService
Preparado para migración a Neo4j con consultas Cypher.
"""
from typing import Any

from app.services.interfaces.treatment import TreatmentRecommendationService


class GraphRecommendationService(TreatmentRecommendationService):
    """
    Implementación futura de recomendaciones basadas en grafo de conocimiento.

    TODO: Implementar cuando Neo4j esté poblado con datos suficientes.
    Usará consultas Cypher para:
      - Encontrar tratamientos óptimos según plaga y condiciones climáticas.
      - Recomendar rotación de productos para evitar resistencia.
      - Sugerir controladores biológicos basados en relaciones predador-presa.
      - Considerar historial de tratamientos previos del agricultor.

    Ejemplo de query Cypher futura:
    ```cypher
    MATCH (plaga:Plaga {nombre: $pest_detected})<-[:COMBATE]-(t:Tratamiento)
    MATCH (plaga)-[:PROLIFERA_CON]->(clima:Clima {tipo: $climate_condition})
    WHERE t.efectividad > 0.7
    RETURN t.nombre, t.dosis_recomendada, t.periodo_carencia
    ORDER BY t.efectividad DESC
    LIMIT 5
    ```
    """

    def __init__(self) -> None:
        # TODO: Inyectar driver Neo4j
        pass

    async def recommend(
        self,
        diagnosis_data: dict[str, Any],
    ) -> str:
        """Generará recomendaciones basadas en el grafo de conocimiento."""
        raise NotImplementedError(
            "GraphRecommendationService no está implementado. "
            "Requiere Neo4j poblado con el grafo de conocimiento agrícola. "
            "Usa LLMRecommendationService como alternativa (MVP)."
        )

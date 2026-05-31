"""
neo4j_service.py — Servicio de recomendaciones basado en el grafo de conocimiento.
Consulta Neo4j para obtener tratamientos y productos agroquímicos
en función de la plaga detectada y las condiciones climáticas actuales.
"""
import logging
from typing import Any, Optional
from app.services.neo4j_database import get_session, verify_connectivity

logger = logging.getLogger(__name__)


class Neo4jRecommendationService:
    """
    Motor de recomendaciones AgroVision AI.
    Ejecuta consultas Cypher contra el grafo de conocimiento para:
      - Buscar plagas por nombre.
      - Verificar si las condiciones climáticas favorecen a la plaga (THRIVES_IN).
      - Retornar tratamientos y productos agroquímicos asociados (TREATED_WITH → USES).
    """

    async def get_treatment_recommendation(
        self,
        pest_name: str,
        current_temp: float,
        current_humidity: float,
    ) -> dict[str, Any]:
        """
        Busca recomendaciones de tratamiento para una plaga detectada,
        considerando el contexto climático actual.
        
        Args:
            pest_name: Nombre de la plaga detectada por Gemini (ej: 'Roya Asiática').
            current_temp: Temperatura actual en °C (de OpenWeatherMap).
            current_humidity: Humedad actual en % (de OpenWeatherMap).
        
        Returns:
            Dict con la plaga, clima, tratamientos y productos encontrados.
        """
        # Verificar conectividad primero
        is_connected = await verify_connectivity()
        if not is_connected:
            logger.warning("Neo4j no disponible. Retornando recomendación vacía.")
            return self._empty_recommendation(pest_name, current_temp, current_humidity)

        try:
            async with get_session() as session:
                # ── Consulta Cypher principal ────────────────────────
                result = await session.run(
                    """
                    // 1. Buscar la plaga por nombre (case-insensitive)
                    MATCH (pest:Pest)
                    WHERE toLower(pest.name) CONTAINS toLower($pest_name)
                    
                    // 2. Verificar si el clima actual favorece a la plaga
                    OPTIONAL MATCH (pest)-[:THRIVES_IN]->(climate:ClimateCondition)
                    WHERE climate.temp_min <= $temp AND $temp <= climate.temp_max
                      AND climate.humidity_min <= $humidity AND $humidity <= climate.humidity_max
                    
                    // 3. Obtener tratamientos y productos agroquímicos
                    OPTIONAL MATCH (pest)-[:TREATED_WITH]->(treatment:Treatment)
                    OPTIONAL MATCH (treatment)-[:USES]->(product:Agrochemical)
                    
                    // 4. Obtener cultivos afectados
                    OPTIONAL MATCH (crop:Crop)-[:AFFECTED_BY]->(pest)
                    
                    RETURN pest.name AS pest_name,
                           pest.scientific_name AS scientific_name,
                           pest.type AS pest_type,
                           pest.description AS pest_description,
                           climate IS NOT NULL AS climate_favorable,
                           climate.description AS climate_description,
                           collect(DISTINCT {
                               name: treatment.name,
                               type: treatment.type,
                               description: treatment.description,
                               application_method: treatment.application_method
                           }) AS treatments,
                           collect(DISTINCT {
                               name: product.name,
                               active_ingredient: product.active_ingredient,
                               dosage: product.dosage,
                               safety_period: product.safety_period,
                               treatment_type: treatment.type
                           }) AS products,
                           collect(DISTINCT crop.name) AS affected_crops
                    """,
                    pest_name=pest_name,
                    temp=current_temp,
                    humidity=current_humidity,
                )

                records = await result.data()

                if not records or records[0].get("pest_name") is None:
                    logger.info(f"No se encontró la plaga '{pest_name}' en el grafo.")
                    return self._empty_recommendation(pest_name, current_temp, current_humidity)

                record = records[0]

                # Filtrar tratamientos y productos que no sean None
                treatments = [
                    t for t in record.get("treatments", [])
                    if t.get("name") is not None
                ]
                products = [
                    p for p in record.get("products", [])
                    if p.get("name") is not None
                ]

                natural_products = []
                chemical_products = []
                for p in products:
                    if p.get("treatment_type") == "Control Biológico" or p.get("treatment_type") == "Control Orgánico":
                        natural_products.append(p)
                    else:
                        chemical_products.append(p)

                return {
                    "pest": {
                        "name": record["pest_name"],
                        "scientific_name": record.get("scientific_name"),
                        "type": record.get("pest_type"),
                        "description": record.get("pest_description"),
                    },
                    "climate_context": {
                        "current_temp": current_temp,
                        "current_humidity": current_humidity,
                        "climate_favorable": record.get("climate_favorable", False),
                        "climate_description": record.get("climate_description"),
                    },
                    "treatments": treatments,
                    "natural_products": natural_products,
                    "chemical_products": chemical_products,
                    "affected_crops": [
                        c for c in record.get("affected_crops", []) if c is not None
                    ],
                    "source": "neo4j_knowledge_graph",
                }

        except Exception as e:
            logger.error(f"Error consultando Neo4j para plaga '{pest_name}': {e}")
            return self._empty_recommendation(pest_name, current_temp, current_humidity)

    def _empty_recommendation(
        self,
        pest_name: str,
        temp: float,
        humidity: float,
    ) -> dict[str, Any]:
        """Retorna una estructura vacía cuando no hay datos disponibles."""
        return {
            "pest": {
                "name": pest_name,
                "scientific_name": None,
                "type": None,
                "description": None,
            },
            "climate_context": {
                "current_temp": temp,
                "current_humidity": humidity,
                "climate_favorable": False,
                "climate_description": None,
            },
            "treatments": [],
            "natural_products": [],
            "chemical_products": [],
            "affected_crops": [],
            "source": "no_data_available",
        }


def get_recommendation_service() -> Neo4jRecommendationService:
    """Factory function para inyección de dependencias en FastAPI."""
    return Neo4jRecommendationService()

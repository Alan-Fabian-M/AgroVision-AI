"""
knowledge_graph.py — Funciones de consulta al Knowledge Graph de AgroVision AI.
Usa labels duales (inglés/español) y el context manager de neo4j_database.py.
Mantiene compatibilidad con el router knowledge.py existente.
"""
from typing import Any
from neo4j.exceptions import ServiceUnavailable, AuthError
from app.services.neo4j_database import get_session, verify_connectivity
from app.core.exceptions import DatabaseException


async def get_risks_by_crop_and_climate(cultivo: str, clima: str) -> dict[str, Any]:
    """
    Busca plagas que afectan un cultivo y proliferan bajo un clima dado.
    Compatible con los labels en español (Cultivo, Plaga, Clima, Tratamiento).
    """
    query = """
    MATCH (climaNode:ClimateCondition)<-[:THRIVES_IN]-(plaga:Pest)-[:TREATED_WITH]->(t:Treatment)
    WHERE toLower(plaga.nombre) CONTAINS toLower($clima)
       OR toLower(climaNode.tipo) CONTAINS toLower($clima)

    OPTIONAL MATCH (crop:Crop)-[:AFFECTED_BY]->(plaga)
    WHERE toLower(crop.nombre) CONTAINS toLower($cultivo)
       OR toLower(crop.name) CONTAINS toLower($cultivo)
    
    OPTIONAL MATCH (t)-[:USES]->(a:Agrochemical)

    RETURN plaga.name AS nombre,
           plaga.type AS tipo,
           collect(DISTINCT t.name) AS tratamientos,
           collect(DISTINCT a.name) AS productos
    """

    try:
        is_connected = await verify_connectivity()
        if not is_connected:
            return {
                "cultivo": cultivo,
                "clima": clima,
                "plagas": [],
                "message": "Neo4j no disponible"
            }

        async with get_session() as session:
            result = await session.run(query, cultivo=cultivo, clima=clima)
            records = await result.data()

            if not records or records[0].get("nombre") is None:
                return {
                    "cultivo": cultivo,
                    "clima": clima,
                    "plagas": [],
                    "message": f"No se encontraron riesgos para '{cultivo}' con clima '{clima}'"
                }

            plagas = []
            for record in records:
                tratamientos = [t for t in record.get("tratamientos", []) if t is not None]
                productos = [p for p in record.get("productos", []) if p is not None]
                plagas.append({
                    "nombre": record["nombre"],
                    "tipo": record.get("tipo"),
                    "tratamientos": tratamientos,
                    "productos": productos,
                })

            return {
                "cultivo": cultivo,
                "clima": clima,
                "plagas": plagas
            }

    except (ServiceUnavailable, AuthError) as e:
        raise DatabaseException(detail=f"Neo4j connection error: {e}")
    except Exception as e:
        raise DatabaseException(detail=f"Error querying knowledge graph: {e}")


async def get_all_crops() -> list[dict[str, Any]]:
    """Retorna todos los cultivos del grafo."""
    try:
        is_connected = await verify_connectivity()
        if not is_connected:
            return []

        async with get_session() as session:
            result = await session.run(
                "MATCH (c:Crop) RETURN c.name AS nombre, c.region AS region"
            )
            records = await result.data()
            return [{"nombre": r["nombre"], "region": r.get("region")} for r in records]

    except (ServiceUnavailable, AuthError) as e:
        raise DatabaseException(detail=f"Neo4j connection error: {e}")


async def get_treatments_by_pest(plaga: str) -> dict[str, Any]:
    """Devuelve todos los tratamientos que combaten una plaga específica."""
    query = """
    MATCH (t:Tratamiento)-[:COMBATE]->(p:Plaga)
    WHERE toLower(p.nombre) CONTAINS toLower($plaga) OR toLower($plaga) CONTAINS toLower(p.nombre)
    OPTIONAL MATCH (p)-[:AFECTA_A]->(c:Cultivo)
    RETURN t.nombre AS nombre,
           t.ingrediente_activo AS ingrediente_activo,
           t.aplicacion AS aplicacion,
           p.nombre AS plaga_nombre,
           p.tipo AS plaga_tipo,
           collect(DISTINCT c.nombre) AS cultivos_afectados
    """
    try:
        async with get_neo4j_session() as session:
            result = await session.run(query, plaga=plaga)
            records = await result.data()

            if not records:
                # Búsqueda fuzzy: si no hay match exacto, devuelve todos los tratamientos
                fallback = """
                MATCH (t:Tratamiento)-[:COMBATE]->(p:Plaga)
                RETURN t.nombre AS nombre,
                       t.ingrediente_activo AS ingrediente_activo,
                       t.aplicacion AS aplicacion,
                       p.nombre AS plaga_nombre,
                       p.tipo AS plaga_tipo
                LIMIT 4
                """
                result2 = await session.run(fallback)
                records = await result2.data()

            tratamientos = [
                {
                    "nombre": r["nombre"],
                    "ingrediente_activo": r.get("ingrediente_activo", ""),
                    "aplicacion": r.get("aplicacion", "Foliar"),
                    "plaga": r.get("plaga_nombre", plaga),
                    "tipo_plaga": r.get("plaga_tipo", ""),
                    "cultivos": r.get("cultivos_afectados", []),
                }
                for r in records
            ]
            return {"plaga": plaga, "tratamientos": tratamientos}

    except (ServiceUnavailable, AuthError) as e:
        raise DatabaseException(detail=f"Neo4j connection error: {e}")
    except Exception as e:
        raise DatabaseException(detail=f"Error: {e}")


async def get_all_pests() -> list[dict[str, Any]]:
    """Retorna todas las plagas del grafo con sus detalles."""
    try:
        is_connected = await verify_connectivity()
        if not is_connected:
            return []

        async with get_session() as session:
            result = await session.run(
                """
                MATCH (p:Pest)
                RETURN p.name AS nombre, 
                       p.type AS tipo,
                       p.scientific_name AS nombre_cientifico,
                       p.description AS descripcion
                """
            )
            records = await result.data()
            return [
                {
                    "nombre": r["nombre"],
                    "tipo": r.get("tipo"),
                    "nombre_cientifico": r.get("nombre_cientifico"),
                    "descripcion": r.get("descripcion"),
                }
                for r in records
            ]

    except (ServiceUnavailable, AuthError) as e:
        raise DatabaseException(detail=f"Neo4j connection error: {e}")

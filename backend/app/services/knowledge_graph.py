from typing import Any
from neo4j.exceptions import ServiceUnavailable, AuthError
from app.core.neo4j import get_neo4j_session
from app.core.exceptions import DatabaseException


async def get_risks_by_crop_and_climate(cultivo: str, clima: str) -> dict[str, Any]:
    query = """
    MATCH (climaNode:Clima)<-[:PROLIFERA_CON]-(plaga:Plaga)-[:AFECTA_A]->(cultivoNode:Cultivo)
    WHERE cultivoNode.nombre = $cultivo AND climaNode.tipo = $clima
    OPTIONAL MATCH (tratamiento:Tratamiento)-[:COMBATE]->(plaga)
    RETURN plaga.nombre AS nombre,
 plaga.tipo AS tipo,
           collect(DISTINCT tratamiento.nombre) AS tratamientos
    """

    try:
        async with get_neo4j_session() as session:
            result = await session.run(query, cultivo=cultivo, clima=clima)
            records = await result.data()

            if not records:
                return {
                    "cultivo": cultivo,
                    "clima": clima,
                    "plagas": [],
                    "message": f"No risks found for cultivo '{cultivo}' with clima '{clima}'"
                }

            plagas = []
            for record in records:
                tratamientos = [t for t in record["tratamientos"] if t is not None]
                plagas.append({
                    "nombre": record["nombre"],
                    "tipo": record["tipo"],
                    "tratamientos": tratamientos
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
    query = "MATCH (c:Cultivo) RETURN c.nombre AS nombre"

    try:
        async with get_neo4j_session() as session:
            result = await session.run(query)
            records = await result.data()
            return [{"nombre": record["nombre"]} for record in records]
    except (ServiceUnavailable, AuthError) as e:
        raise DatabaseException(detail=f"Neo4j connection error: {e}")


async def get_all_pests() -> list[dict[str, Any]]:
    query = "MATCH (p:Plaga) RETURN p.nombre AS nombre, p.tipo AS tipo"

    try:
        async with get_neo4j_session() as session:
            result = await session.run(query)
            records = await result.data()
            return [{"nombre": record["nombre"], "tipo": record["tipo"]} for record in records]
    except (ServiceUnavailable, AuthError) as e:
        raise DatabaseException(detail=f"Neo4j connection error: {e}")

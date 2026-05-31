"""
neo4j_database.py — Manejador de conexión a Neo4j para AgroVision AI.
Usa el driver async oficial y extrae credenciales del .env.
"""
import logging
from neo4j import AsyncGraphDatabase
from neo4j.exceptions import ServiceUnavailable, AuthError
from contextlib import asynccontextmanager
from app.core.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

# ── Singleton del driver ─────────────────────────────────────────────────────
_driver = None


def get_driver():
    """Obtiene (o crea) una instancia singleton del driver async de Neo4j."""
    global _driver
    if _driver is None:
        _driver = AsyncGraphDatabase.driver(
            settings.NEO4J_URI,
            auth=(settings.NEO4J_USER, settings.NEO4J_PASSWORD),
            max_connection_lifetime=300,
            max_connection_pool_size=50,
        )
        logger.info(f"Neo4j driver creado → {settings.NEO4J_URI}")
    return _driver


async def close_driver():
    """Cierra el driver de Neo4j limpiamente (llamar en el shutdown de FastAPI)."""
    global _driver
    if _driver is not None:
        await _driver.close()
        _driver = None
        logger.info("Neo4j driver cerrado.")


async def verify_connectivity():
    """Verifica que Neo4j esté disponible. Retorna True/False."""
    driver = get_driver()
    try:
        await driver.verify_connectivity()
        logger.info("✓ Neo4j: conectividad verificada.")
        return True
    except (ServiceUnavailable, AuthError) as e:
        logger.warning(f"✗ Neo4j no disponible: {e}")
        return False


@asynccontextmanager
async def get_session():
    """Context manager async para obtener una sesión de Neo4j."""
    driver = get_driver()
    session = driver.session()
    try:
        yield session
    finally:
        await session.close()

from neo4j import AsyncGraphDatabase
from neo4j.exceptions import ServiceUnavailable, AuthError
from contextlib import asynccontextmanager
from app.core.config import get_settings

settings = get_settings()

driver = None


def get_driver() -> AsyncGraphDatabase:
    global driver
    if driver is None:
        driver = AsyncGraphDatabase.driver(
            settings.NEO4J_URI,
            auth=(settings.NEO4J_USER, settings.NEO4J_PASSWORD)
        )
    return driver


async def close_driver():
    global driver
    if driver is not None:
        await driver.close()
        driver = None


@asynccontextmanager
async def get_neo4j_session():
    neo4j_driver = get_driver()
    try:
        await neo4j_driver.verify_connectivity()
    except (ServiceUnavailable, AuthError) as e:
        raise ConnectionError(f"Cannot connect to Neo4j: {e}")
    session = neo4j_driver.session()
    try:
        yield session
    finally:
        await session.close()

"""
Seed script for Neo4j Knowledge Graph - AgroVision AI
Santa Cruz, Bolivia agricultural model

Usage:
    python -m scripts.seed_neo4j

Cypher queries to test directly in Neo4j Browser:
==================================================

// --- CREATE NODES ---
// Cultivos (Crops)
CREATE (c:Cultivo {nombre: "Soya"})
CREATE (c:Cultivo {nombre: "Sorgo"})
CREATE (c:Cultivo {nombre: "Maíz"})
CREATE (c:Cultivo {nombre: "Caña de Azúcar"})

// Plagas/Enfermedades (Pests/Diseases)
CREATE (p:Plaga {nombre: "Roya de la Soya", tipo: "Hongo"})
CREATE (p:Plaga {nombre: "Gusano Cogollero", tipo: "Insecto"})
CREATE (p:Plaga {nombre: "Pulgón Amarillo", tipo: "Insecto"})
CREATE (p:Plaga {nombre: "Cochinilla", tipo: "Insecto"})

// Condiciones Climáticas (Climate Conditions)
CREATE (cl:Clima {tipo: "Alta Humedad"})
CREATE (cl:Clima {tipo: "Sequía"})
CREATE (cl:Clima {tipo: "Temperatura Alta"})
CREATE (cl:Clima {tipo: "Lluvia Excessiva"})

// Tratamientos (Treatments)
CREATE (t:Tratamiento {nombre: "Fungicida Mancozeb", ingrediente_activo: "Mancozeb", aplicacion: "Foliar"})
CREATE (t:Tratamiento {nombre: "Insecticida Clorpirifos", ingrediente_activo: "Clorpirifos", aplicacion: "Foliar"})
CREATE (t:Tratamiento {nombre: "Agroquímico Metomil", ingrediente_activo: "Metomil", aplicacion: "Foliar"})
CREATE (t:Tratamiento {nombre: "Fungicida Tebuconazol", ingrediente_activo: "Tebuconazol", aplicacion: "Foliar"})

// --- CREATE RELATIONSHIPS ---
// Plaga AFECTA_A Cultivo
MATCH (p:Plaga {nombre: "Roya de la Soya"}), (c:Cultivo {nombre: "Soya"})
CREATE (p)-[:AFECTA_A]->(c)
MATCH (p:Plaga {nombre: "Gusano Cogollero"}), (c:Cultivo {nombre: "Maíz"})
CREATE (p)-[:AFECTA_A]->(c)
MATCH (p:Plaga {nombre: "Gusano Cogollero"}), (c:Cultivo {nombre: "Sorgo"})
CREATE (p)-[:AFECTA_A]->(c)
MATCH (p:Plaga {nombre: "Pulgón Amarillo"}), (c:Cultivo {nombre: "Sorgo"})
CREATE (p)-[:AFECTA_A]->(c)
MATCH (p:Plaga {nombre: "Cochinilla"}), (c:Cultivo {nombre: "Caña de Azúcar"})
CREATE (p)-[:AFECTA_A]->(c)

// Plaga PROLIFERA_CON Clima
MATCH (p:Plaga {nombre: "Roya de la Soya"}), (cl:Clima {tipo: "Alta Humedad"})
CREATE (p)-[:PROLIFERA_CON]->(cl)
MATCH (p:Plaga {nombre: "Gusano Cogollero"}), (cl:Clima {tipo: "Temperatura Alta"})
CREATE (p)-[:PROLIFERA_CON]->(cl)
MATCH (p:Plaga {nombre: "Gusano Cogollero"}), (cl:Clima {tipo: "Sequía"})
CREATE (p)-[:PROLIFERA_CON]->(cl)
MATCH (p:Plaga {nombre: "Pulgón Amarillo"}), (cl:Clima {tipo: "Temperatura Alta"})
CREATE (p)-[:PROLIFERA_CON]->(cl)
MATCH (p:Plaga {nombre: "Cochinilla"}), (cl:Clima {tipo: "Alta Humedad"})
CREATE (p)-[:PROLIFERA_CON]->(cl)

// Tratamiento COMBATE Plaga
MATCH (t:Tratamiento {nombre: "Fungicida Mancozeb"}), (p:Plaga {nombre: "Roya de la Soya"})
CREATE (t)-[:COMBATE]->(p)
MATCH (t:Tratamiento {nombre: "Fungicida Tebuconazol"}), (p:Plaga {nombre: "Roya de la Soya"})
CREATE (t)-[:COMBATE]->(p)
MATCH (t:Tratamiento {nombre: "Insecticida Clorpirifos"}), (p:Plaga {nombre: "Gusano Cogollero"})
CREATE (t)-[:COMBATE]->(p)
MATCH (t:Tratamiento {nombre: "Agroquímico Metomil"}), (p:Plaga {nombre: "Gusano Cogollero"})
CREATE (t)-[:COMBATE]->(p)
MATCH (t:Tratamiento {nombre: "Insecticida Clorpirifos"}), (p:Plaga {nombre: "Pulgón Amarillo"})
CREATE (t)-[:COMBATE]->(p)
MATCH (t:Tratamiento {nombre: "Insecticida Clorpirifos"}), (p:Plaga {nombre: "Cochinilla"})
CREATE (t)-[:COMBATE]->(p)

// --- TEST QUERY (main use case) ---
MATCH (clima:Clima)<-[:PROLIFERA_CON]-(plaga:Plaga)-[:AFECTA_A]->(cultivo:Cultivo)
WHERE cultivo.nombre = "Soya" AND clima.tipo = "Alta Humedad"
OPTIONAL MATCH (tratamiento:Tratamiento)-[:COMBATE]->(plaga)
RETURN plaga.nombre AS plaga, plaga.tipo AS tipo, collect(DISTINCT tratamiento.nombre) AS tratamientos

// --- VERIFY DATA ---
MATCH (n) RETURN n
MATCH ()-[r]->() RETURN type(r), count(*) as count
"""

import asyncio
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from neo4j import AsyncGraphDatabase
from app.core.config import get_settings

settings = get_settings()

CULTIVOS = [
    {"nombre": "Soya"},
    {"nombre": "Sorgo"},
    {"nombre": "Maíz"},
    {"nombre": "Caña de Azúcar"},
]

PLAGAS = [
    {"nombre": "Roya de la Soya", "tipo": "Hongo"},
    {"nombre": "Gusano Cogollero", "tipo": "Insecto"},
    {"nombre": "Pulgón Amarillo", "tipo": "Insecto"},
    {"nombre": "Cochinilla", "tipo": "Insecto"},
]

CLIMAS = [
    {"tipo": "Alta Humedad"},
    {"tipo": "Sequía"},
    {"tipo": "Temperatura Alta"},
    {"tipo": "Lluvia Excessiva"},
]

TRATAMIENTOS = [
    {"nombre": "Fungicida Mancozeb", "ingrediente_activo": "Mancozeb", "aplicacion": "Foliar"},
    {"nombre": "Insecticida Clorpirifos", "ingrediente_activo": "Clorpirifos", "aplicacion": "Foliar"},
    {"nombre": "Agroquímico Metomil", "ingrediente_activo": "Metomil", "aplicacion": "Foliar"},
    {"nombre": "Fungicida Tebuconazol", "ingrediente_activo": "Tebuconazol", "aplicacion": "Foliar"},
]

RELACIONES_AFECTA_A = [
    ("Roya de la Soya", "Soya"),
    ("Gusano Cogollero", "Maíz"),
    ("Gusano Cogollero", "Sorgo"),
    ("Pulgón Amarillo", "Sorgo"),
    ("Cochinilla", "Caña de Azúcar"),
]

RELACIONES_PROLIFERA_CON = [
    ("Roya de la Soya", "Alta Humedad"),
    ("Gusano Cogollero", "Temperatura Alta"),
    ("Gusano Cogollero", "Sequía"),
    ("Pulgón Amarillo", "Temperatura Alta"),
    ("Cochinilla", "Alta Humedad"),
]

RELACIONES_COMBATE = [
    ("Fungicida Mancozeb", "Roya de la Soya"),
    ("Fungicida Tebuconazol", "Roya de la Soya"),
    ("Insecticida Clorpirifos", "Gusano Cogollero"),
    ("Agroquímico Metomil", "Gusano Cogollero"),
    ("Insecticida Clorpirifos", "Pulgón Amarillo"),
    ("Insecticida Clorpirifos", "Cochinilla"),
]


async def seed():
    driver = AsyncGraphDatabase.driver(
        settings.NEO4J_URI,
        auth=(settings.NEO4J_USER, settings.NEO4J_PASSWORD)
    )

    try:
        await driver.verify_connectivity()
        print("Connected to Neo4j")
    except Exception as e:
        print(f"Cannot connect to Neo4j: {e}")
        return

    session = driver.session()

    try:
        print("Clearing existing data...")
        await session.run("MATCH (n) DETACH DELETE n")

        print("Creating Cultivos...")
        for c in CULTIVOS:
            await session.run(
                "CREATE (c:Cultivo $data)",
                data=c
            )
        print(f"  Created {len(CULTIVOS)} cultivos")

        print("Creating Plagas...")
        for p in PLAGAS:
            await session.run(
                "CREATE (p:Plaga $data)",
                data=p
            )
        print(f"  Created {len(PLAGAS)} plagas")

        print("Creating Climas...")
        for cl in CLIMAS:
            await session.run(
                "CREATE (cl:Clima $data)",
                data=cl
            )
        print(f"  Created {len(CLIMAS)} climas")

        print("Creating Tratamientos...")
        for t in TRATAMIENTOS:
            await session.run(
                "CREATE (t:Tratamiento $data)",
                data=t
            )
        print(f"  Created {len(TRATAMIENTOS)} tratamientos")

        print("Creating AFECTA_A relationships...")
        for plaga, cultivo in RELACIONES_AFECTA_A:
            await session.run(
                """
                MATCH (p:Plaga {nombre: $plaga}), (c:Cultivo {nombre: $cultivo})
                CREATE (p)-[:AFECTA_A]->(c)
                """,
                plaga=plaga, cultivo=cultivo
            )
        print(f"  Created {len(RELACIONES_AFECTA_A)} relationships")

        print("Creating PROLIFERA_CON relationships...")
        for plaga, clima in RELACIONES_PROLIFERA_CON:
            await session.run(
                """
                MATCH (p:Plaga {nombre: $plaga}), (cl:Clima {tipo: $clima})
                CREATE (p)-[:PROLIFERA_CON]->(cl)
                """,
                plaga=plaga, clima=clima
            )
        print(f"  Created {len(RELACIONES_PROLIFERA_CON)} relationships")

        print("Creating COMBATE relationships...")
        for tratamiento, plaga in RELACIONES_COMBATE:
            await session.run(
                """
                MATCH (t:Tratamiento {nombre: $tratamiento}), (p:Plaga {nombre: $plaga})
                CREATE (t)-[:COMBATE]->(p)
                """,
                tratamiento=tratamiento, plaga=plaga
            )
        print(f"  Created {len(RELACIONES_COMBATE)} relationships")

        print("\nSeed completed successfully!")
        print("\nTest queries for Neo4j Browser:")
        print("=" * 50)
        print("MATCH (clima:Clima)<-[:PROLIFERA_CON]-(plaga:Plaga)-[:AFECTA_A]->(cultivo:Cultivo)")
        print("WHERE cultivo.nombre = 'Soya' AND clima.tipo = 'Alta Humedad'")
        print("OPTIONAL MATCH (tratamiento:Tratamiento)-[:COMBATE]->(plaga)")
        print("RETURN plaga.nombre AS plaga, plaga.tipo AS tipo, collect(DISTINCT tratamiento.nombre) AS tratamientos")

    finally:
        await session.close()
        await driver.close()


if __name__ == "__main__":
    asyncio.run(seed())

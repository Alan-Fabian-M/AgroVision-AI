"""
Seed script para Neo4j Knowledge Graph — AgroVision AI
Santa Cruz, Bolivia — Modelo agrícola.

Crea nodos con labels duales (español e inglés) para mantener compatibilidad
con knowledge_graph.py existente y el nuevo neo4j_service.py.

Estructura del Grafo:
  (Crop)-[:AFFECTED_BY]->(Pest)-[:THRIVES_IN]->(ClimateCondition)
  (Pest)-[:TREATED_WITH]->(Treatment)-[:USES]->(Agrochemical)

Uso:
    cd backend
    python -m scripts.seed_neo4j
"""
import asyncio
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from neo4j import AsyncGraphDatabase
from app.core.config import get_settings

settings = get_settings()

# ══════════════════════════════════════════════════════════════════════════════
# DATOS DE SEED
# ══════════════════════════════════════════════════════════════════════════════

CROPS = [
    {"name": "Soya",            "nombre": "Soya",            "region": "Santa Cruz"},
    {"name": "Maíz",            "nombre": "Maíz",            "region": "Santa Cruz"},
    {"name": "Sorgo",           "nombre": "Sorgo",           "region": "Santa Cruz"},
    {"name": "Caña de Azúcar",  "nombre": "Caña de Azúcar",  "region": "Santa Cruz"},
    {"name": "Arroz",           "nombre": "Arroz",           "region": "Santa Cruz"},
    {"name": "Trigo",           "nombre": "Trigo",           "region": "Santa Cruz"},
    {"name": "Girasol",         "nombre": "Girasol",         "region": "Santa Cruz"},
]

PESTS = [
    {
        "name": "Roya Asiática",
        "nombre": "Roya de la Soya",
        "scientific_name": "Phakopsora pachyrhizi",
        "type": "Hongo",
        "tipo": "Hongo",
        "description": "Enfermedad fúngica devastadora que produce pústulas en las hojas de la soya. Puede causar pérdidas del 10% al 80%.",
    },
    {
        "name": "Gusano Cogollero",
        "nombre": "Gusano Cogollero",
        "scientific_name": "Spodoptera frugiperda",
        "type": "Insecto",
        "tipo": "Insecto",
        "description": "Larva que se alimenta del cogollo del maíz y sorgo, destruyendo las hojas centrales de la planta.",
    },
    {
        "name": "Pulgón Amarillo",
        "nombre": "Pulgón Amarillo",
        "scientific_name": "Melanaphis sacchari",
        "type": "Insecto",
        "tipo": "Insecto",
        "description": "Insecto chupador que se alimenta del floema del sorgo, debilitando la planta y transmitiendo virus.",
    },
    {
        "name": "Cochinilla",
        "nombre": "Cochinilla",
        "scientific_name": "Saccharicoccus sacchari",
        "type": "Insecto",
        "tipo": "Insecto",
        "description": "Insecto escamoso que se adhiere a tallos de caña de azúcar, succionando savia y reduciendo el rendimiento.",
    },
    {
        "name": "Mancha Anillada",
        "nombre": "Mancha Anillada",
        "scientific_name": "Corynespora cassiicola",
        "type": "Hongo",
        "tipo": "Hongo",
        "description": "Hongo que produce manchas circulares con anillos concéntricos en hojas de soya, reduce la fotosíntesis.",
    },
    {
        "name": "Piricularia",
        "nombre": "Piricularia",
        "scientific_name": "Magnaporthe oryzae",
        "type": "Hongo",
        "tipo": "Hongo",
        "description": "Enfermedad fúngica del arroz que afecta hojas, cuello de panoja y granos. Condiciones húmedas la favorecen.",
    },
    {
        "name": "Roya del Trigo",
        "nombre": "Roya del Trigo",
        "scientific_name": "Puccinia triticina",
        "type": "Hongo",
        "tipo": "Hongo",
        "description": "Produce pústulas anaranjadas en hojas de trigo, reduciendo el rendimiento si no se controla.",
    },
]

CLIMATE_CONDITIONS = [
    {
        "name": "Alta Humedad Cálida",
        "description": "Temperatura 22-35°C con humedad >70%. Ideal para proliferación de hongos.",
        "tipo": "Alta Humedad",
        "temp_min": 22.0,
        "temp_max": 35.0,
        "humidity_min": 70.0,
        "humidity_max": 100.0,
    },
    {
        "name": "Calor Seco",
        "description": "Temperatura >30°C con humedad <50%. Favorece insectos como cogollero y pulgón.",
        "tipo": "Sequía",
        "temp_min": 30.0,
        "temp_max": 45.0,
        "humidity_min": 0.0,
        "humidity_max": 50.0,
    },
    {
        "name": "Templado Húmedo",
        "description": "Temperatura 15-25°C con humedad 60-85%. Favorece roya del trigo.",
        "tipo": "Temperatura Alta",
        "temp_min": 15.0,
        "temp_max": 25.0,
        "humidity_min": 60.0,
        "humidity_max": 85.0,
    },
    {
        "name": "Lluvias Intensas",
        "description": "Periodos prolongados de lluvia con humedad >80%. Favorece todo tipo de hongos.",
        "tipo": "Lluvia Excesiva",
        "temp_min": 20.0,
        "temp_max": 32.0,
        "humidity_min": 80.0,
        "humidity_max": 100.0,
    },
]

TREATMENTS = [
    {
        "name": "Aplicación de Azoxistrobina + Ciproconazol",
        "nombre": "Fungicida Azoxistrobina",
        "type": "Fungicida Sistémico",
        "description": "Mezcla de estrobilurina + triazol para control preventivo y curativo de roya.",
        "application_method": "Pulverización foliar con 150-200 L/ha de caldo.",
    },
    {
        "name": "Aplicación de Mancozeb",
        "nombre": "Fungicida Mancozeb",
        "type": "Fungicida de Contacto",
        "description": "Fungicida protectante de amplio espectro para control preventivo.",
        "application_method": "Pulverización foliar cada 10-14 días.",
    },
    {
        "name": "Aplicación de Clorpirifos",
        "nombre": "Insecticida Clorpirifos",
        "type": "Insecticida Organofosforado",
        "description": "Control de larvas y adultos de insectos masticadores y chupadores.",
        "application_method": "Pulverización foliar o aplicación al suelo.",
    },
    {
        "name": "Control Biológico con Bacillus thuringiensis",
        "nombre": "Bacillus thuringiensis",
        "type": "Control Biológico",
        "description": "Bacteria entomopatógena que produce cristales tóxicos para larvas de lepidópteros.",
        "application_method": "Pulverización foliar al atardecer, cuando las larvas son jóvenes.",
    },
    {
        "name": "Aplicación de Tebuconazol",
        "nombre": "Fungicida Tebuconazol",
        "type": "Fungicida Triazol",
        "description": "Fungicida sistémico del grupo triazol para control de royas y manchas foliares.",
        "application_method": "Pulverización foliar con 200 L/ha de caldo.",
    },
    {
        "name": "Aplicación de Metomil",
        "nombre": "Agroquímico Metomil",
        "type": "Insecticida Carbamato",
        "description": "Insecticida de acción rápida para control de orugas y larvas.",
        "application_method": "Pulverización foliar con equipo calibrado.",
    },
]

AGROCHEMICALS = [
    {
        "name": "Azoxistrobina 200 SC",
        "active_ingredient": "Azoxistrobina",
        "dosage": "300-400 mL/ha",
        "safety_period": "30 días antes de cosecha",
        "toxicity_class": "III - Ligeramente Tóxico",
    },
    {
        "name": "Ciproconazol 80 WG",
        "active_ingredient": "Ciproconazol",
        "dosage": "25-35 g/ha",
        "safety_period": "30 días antes de cosecha",
        "toxicity_class": "II - Moderadamente Tóxico",
    },
    {
        "name": "Mancozeb 800 WP",
        "active_ingredient": "Mancozeb",
        "dosage": "2-3 kg/ha",
        "safety_period": "14 días antes de cosecha",
        "toxicity_class": "IV - Normalmente no ofrece peligro",
    },
    {
        "name": "Clorpirifos 480 EC",
        "active_ingredient": "Clorpirifos",
        "dosage": "0.8-1.2 L/ha",
        "safety_period": "21 días antes de cosecha",
        "toxicity_class": "II - Moderadamente Tóxico",
    },
    {
        "name": "Bacillus thuringiensis var. kurstaki",
        "active_ingredient": "Bt kurstaki",
        "dosage": "0.5-1.0 L/ha",
        "safety_period": "Sin restricción",
        "toxicity_class": "IV - Normalmente no ofrece peligro",
    },
    {
        "name": "Tebuconazol 250 EW",
        "active_ingredient": "Tebuconazol",
        "dosage": "0.5-0.75 L/ha",
        "safety_period": "35 días antes de cosecha",
        "toxicity_class": "III - Ligeramente Tóxico",
    },
    {
        "name": "Metomil 215 SL",
        "active_ingredient": "Metomil",
        "dosage": "0.3-0.5 L/ha",
        "safety_period": "14 días antes de cosecha",
        "toxicity_class": "I - Extremadamente Tóxico",
    },
]

# ── Relaciones ────────────────────────────────────────────────────────────────

# (Crop)-[:AFFECTED_BY]->(Pest)
AFFECTED_BY = [
    ("Soya",           "Roya Asiática"),
    ("Soya",           "Mancha Anillada"),
    ("Maíz",           "Gusano Cogollero"),
    ("Sorgo",          "Gusano Cogollero"),
    ("Sorgo",          "Pulgón Amarillo"),
    ("Caña de Azúcar", "Cochinilla"),
    ("Arroz",          "Piricularia"),
    ("Trigo",          "Roya del Trigo"),
    ("Girasol",        "Mancha Anillada"),
]

# (Pest)-[:THRIVES_IN]->(ClimateCondition)
THRIVES_IN = [
    ("Roya Asiática",    "Alta Humedad Cálida"),
    ("Roya Asiática",    "Lluvias Intensas"),
    ("Mancha Anillada",  "Alta Humedad Cálida"),
    ("Gusano Cogollero", "Calor Seco"),
    ("Pulgón Amarillo",  "Calor Seco"),
    ("Cochinilla",       "Alta Humedad Cálida"),
    ("Piricularia",      "Lluvias Intensas"),
    ("Piricularia",      "Alta Humedad Cálida"),
    ("Roya del Trigo",   "Templado Húmedo"),
]

# (Pest)-[:TREATED_WITH]->(Treatment)
TREATED_WITH = [
    ("Roya Asiática",    "Aplicación de Azoxistrobina + Ciproconazol"),
    ("Roya Asiática",    "Aplicación de Mancozeb"),
    ("Roya Asiática",    "Aplicación de Tebuconazol"),
    ("Mancha Anillada",  "Aplicación de Azoxistrobina + Ciproconazol"),
    ("Mancha Anillada",  "Aplicación de Mancozeb"),
    ("Gusano Cogollero", "Aplicación de Clorpirifos"),
    ("Gusano Cogollero", "Control Biológico con Bacillus thuringiensis"),
    ("Gusano Cogollero", "Aplicación de Metomil"),
    ("Pulgón Amarillo",  "Aplicación de Clorpirifos"),
    ("Cochinilla",       "Aplicación de Clorpirifos"),
    ("Piricularia",      "Aplicación de Azoxistrobina + Ciproconazol"),
    ("Piricularia",      "Aplicación de Tebuconazol"),
    ("Roya del Trigo",   "Aplicación de Tebuconazol"),
    ("Roya del Trigo",   "Aplicación de Mancozeb"),
]

# (Treatment)-[:USES]->(Agrochemical)
USES = [
    ("Aplicación de Azoxistrobina + Ciproconazol", "Azoxistrobina 200 SC"),
    ("Aplicación de Azoxistrobina + Ciproconazol", "Ciproconazol 80 WG"),
    ("Aplicación de Mancozeb",                     "Mancozeb 800 WP"),
    ("Aplicación de Clorpirifos",                  "Clorpirifos 480 EC"),
    ("Control Biológico con Bacillus thuringiensis", "Bacillus thuringiensis var. kurstaki"),
    ("Aplicación de Tebuconazol",                  "Tebuconazol 250 EW"),
    ("Aplicación de Metomil",                      "Metomil 215 SL"),
]


# ══════════════════════════════════════════════════════════════════════════════
# SEED FUNCTION
# ══════════════════════════════════════════════════════════════════════════════

async def seed():
    print("=" * 60)
    print("  AgroVision AI — Neo4j Knowledge Graph Seed")
    print("=" * 60)
    print(f"\nConectando a: {settings.NEO4J_URI}")

    driver = AsyncGraphDatabase.driver(
        settings.NEO4J_URI,
        auth=(settings.NEO4J_USER, settings.NEO4J_PASSWORD),
    )

    try:
        await driver.verify_connectivity()
        print("✓ Conectado a Neo4j exitosamente.\n")
    except Exception as e:
        print(f"✗ Error conectando a Neo4j: {e}")
        print("  Verifica que Neo4j esté corriendo y las credenciales en .env sean correctas.")
        return

    session = driver.session()

    try:
        # ── Limpiar datos existentes ─────────────────────────
        print("🗑  Limpiando base de datos...")
        result = await session.run("MATCH (n) DETACH DELETE n")
        summary = await result.consume()
        print(f"   Nodos eliminados: {summary.counters.nodes_deleted}")
        print(f"   Relaciones eliminadas: {summary.counters.relationships_deleted}")

        # ── Crear constraints para unicidad ──────────────────
        print("\n📐 Creando constraints...")
        constraints = [
            "CREATE CONSTRAINT IF NOT EXISTS FOR (c:Crop) REQUIRE c.name IS UNIQUE",
            "CREATE CONSTRAINT IF NOT EXISTS FOR (p:Pest) REQUIRE p.name IS UNIQUE",
            "CREATE CONSTRAINT IF NOT EXISTS FOR (cc:ClimateCondition) REQUIRE cc.name IS UNIQUE",
            "CREATE CONSTRAINT IF NOT EXISTS FOR (t:Treatment) REQUIRE t.name IS UNIQUE",
            "CREATE CONSTRAINT IF NOT EXISTS FOR (a:Agrochemical) REQUIRE a.name IS UNIQUE",
        ]
        for c in constraints:
            await session.run(c)
        print("   ✓ Constraints creados.")

        # ── Crear nodos: Crops ───────────────────────────────
        print(f"\n🌾 Creando {len(CROPS)} Cultivos (Crop)...")
        for crop in CROPS:
            await session.run(
                "CREATE (c:Crop:Cultivo $data)",
                data=crop,
            )
        print("   ✓ Cultivos creados.")

        # ── Crear nodos: Pests ───────────────────────────────
        print(f"🐛 Creando {len(PESTS)} Plagas (Pest)...")
        for pest in PESTS:
            await session.run(
                "CREATE (p:Pest:Plaga $data)",
                data=pest,
            )
        print("   ✓ Plagas creadas.")

        # ── Crear nodos: ClimateConditions ───────────────────
        print(f"🌤  Creando {len(CLIMATE_CONDITIONS)} Condiciones Climáticas...")
        for climate in CLIMATE_CONDITIONS:
            await session.run(
                "CREATE (cc:ClimateCondition:Clima $data)",
                data=climate,
            )
        print("   ✓ Condiciones climáticas creadas.")

        # ── Crear nodos: Treatments ──────────────────────────
        print(f"💊 Creando {len(TREATMENTS)} Tratamientos...")
        for treatment in TREATMENTS:
            await session.run(
                "CREATE (t:Treatment:Tratamiento $data)",
                data=treatment,
            )
        print("   ✓ Tratamientos creados.")

        # ── Crear nodos: Agrochemicals ───────────────────────
        print(f"🧪 Creando {len(AGROCHEMICALS)} Productos Agroquímicos...")
        for agro in AGROCHEMICALS:
            await session.run(
                "CREATE (a:Agrochemical $data)",
                data=agro,
            )
        print("   ✓ Productos agroquímicos creados.")

        # ── Crear relaciones: AFFECTED_BY ────────────────────
        print(f"\n🔗 Creando {len(AFFECTED_BY)} relaciones AFFECTED_BY...")
        for crop_name, pest_name in AFFECTED_BY:
            await session.run(
                """
                MATCH (c:Crop {name: $crop_name}), (p:Pest {name: $pest_name})
                CREATE (c)-[:AFFECTED_BY]->(p)
                """,
                crop_name=crop_name,
                pest_name=pest_name,
            )
        print("   ✓ Relaciones AFFECTED_BY creadas.")

        # ── Crear relaciones: THRIVES_IN ─────────────────────
        print(f"🔗 Creando {len(THRIVES_IN)} relaciones THRIVES_IN...")
        for pest_name, climate_name in THRIVES_IN:
            await session.run(
                """
                MATCH (p:Pest {name: $pest_name}), (cc:ClimateCondition {name: $climate_name})
                CREATE (p)-[:THRIVES_IN]->(cc)
                """,
                pest_name=pest_name,
                climate_name=climate_name,
            )
        print("   ✓ Relaciones THRIVES_IN creadas.")

        # ── Crear relaciones: TREATED_WITH ───────────────────
        print(f"🔗 Creando {len(TREATED_WITH)} relaciones TREATED_WITH...")
        for pest_name, treatment_name in TREATED_WITH:
            await session.run(
                """
                MATCH (p:Pest {name: $pest_name}), (t:Treatment {name: $treatment_name})
                CREATE (p)-[:TREATED_WITH]->(t)
                """,
                pest_name=pest_name,
                treatment_name=treatment_name,
            )
        print("   ✓ Relaciones TREATED_WITH creadas.")

        # ── Crear relaciones: USES ───────────────────────────
        print(f"🔗 Creando {len(USES)} relaciones USES...")
        for treatment_name, agro_name in USES:
            await session.run(
                """
                MATCH (t:Treatment {name: $treatment_name}), (a:Agrochemical {name: $agro_name})
                CREATE (t)-[:USES]->(a)
                """,
                treatment_name=treatment_name,
                agro_name=agro_name,
            )
        print("   ✓ Relaciones USES creadas.")

        # ── Verificar totales ────────────────────────────────
        count_result = await session.run(
            "MATCH (n) RETURN labels(n)[0] AS label, count(n) AS total ORDER BY label"
        )
        records = await count_result.data()

        rel_result = await session.run(
            "MATCH ()-[r]->() RETURN type(r) AS relacion, count(r) AS total ORDER BY relacion"
        )
        rel_records = await rel_result.data()

        print("\n" + "=" * 60)
        print("  ✅ SEED COMPLETADO EXITOSAMENTE")
        print("=" * 60)
        print("\n📊 Resumen de nodos:")
        for r in records:
            print(f"   {r['label']:20s} → {r['total']}")
        print("\n📊 Resumen de relaciones:")
        for r in rel_records:
            print(f"   {r['relacion']:20s} → {r['total']}")

        # ── Query de prueba ──────────────────────────────────
        print("\n" + "-" * 60)
        print("🧪 Query de prueba: Roya Asiática en Soya con clima 28°C / 75% humedad")
        print("-" * 60)
        test_result = await session.run(
            """
            MATCH (pest:Pest)
            WHERE toLower(pest.name) CONTAINS toLower('Roya Asiática')
            
            OPTIONAL MATCH (pest)-[:THRIVES_IN]->(climate:ClimateCondition)
            WHERE climate.temp_min <= 28.0 AND 28.0 <= climate.temp_max
              AND climate.humidity_min <= 75.0 AND 75.0 <= climate.humidity_max
            
            OPTIONAL MATCH (pest)-[:TREATED_WITH]->(treatment:Treatment)
            OPTIONAL MATCH (treatment)-[:USES]->(product:Agrochemical)
            OPTIONAL MATCH (crop:Crop)-[:AFFECTED_BY]->(pest)
            
            RETURN pest.name AS plaga,
                   climate IS NOT NULL AS clima_favorable,
                   climate.description AS clima_desc,
                   collect(DISTINCT treatment.name) AS tratamientos,
                   collect(DISTINCT product.name) AS productos,
                   collect(DISTINCT crop.name) AS cultivos_afectados
            """
        )
        test_records = await test_result.data()
        for r in test_records:
            print(f"   Plaga:              {r['plaga']}")
            print(f"   Clima favorable:    {r['clima_favorable']}")
            print(f"   Descripción clima:  {r['clima_desc']}")
            print(f"   Tratamientos:       {r['tratamientos']}")
            print(f"   Productos:          {r['productos']}")
            print(f"   Cultivos afectados: {r['cultivos_afectados']}")

    except Exception as e:
        print(f"\n✗ Error durante el seed: {e}")
        import traceback
        traceback.print_exc()

    finally:
        await session.close()
        await driver.close()
        print("\n🔌 Conexión a Neo4j cerrada.")


if __name__ == "__main__":
    asyncio.run(seed())

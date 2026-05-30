# AgroVision AI - Backend

Backend FastAPI para la plataforma de detección de riesgos agrícolas AgroVision AI.

## Requisitos

- Python 3.10+
- PostgreSQL 14+
- Neo4j 5.x (via Docker)
- Docker (para Neo4j)

## Estructura del Proyecto

```
backend/
├── app/
│   ├── core/               # Configuración central
│   │   ├── config.py      # Settings (pydantic-settings)
│   │   ├── database.py    # SQLAlchemy engine
│   │   ├── neo4j.py       # Neo4j driver async
│   │   └── exceptions.py  # Custom exceptions
│   ├── models/            # Modelos SQLAlchemy
│   │   └── diagnostico.py
│   ├── schemas/           # Schemas Pydantic
│   │   └── diagnostico.py
│   ├── routers/           # Endpoints FastAPI
│   │   ├── diagnostics.py
│   │   └── knowledge.py
│   ├── services/         # Lógica de negocio
│   │   ├── diagnostico.py
│   │   └── knowledge_graph.py
│   └── main.py           # App FastAPI
├── scripts/
│   └── seed_neo4j.py     # Seed data para Neo4j
├── requirements.txt
└── .env
```

## Setup

### 1. Clonar y crear entorno virtual

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate # Windows
```

### 2. Instalar dependencias

```bash
pip install -r requirements.txt
```

### 3. Configurar variables de entorno

```bash
cp .env.example .env
# Editar .env con tus credenciales si es necesario
```

Variables por defecto:
```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/agrovison_ai
NEO4J_URI=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=password
```

### 4. Iniciar PostgreSQL

```bash
# Con Docker
docker run -d --name postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=agrovison_ai \
  -p 5432:5432 \
  postgres:14

# O usar PostgreSQL local
```

### 5. Iniciar Neo4j

```bash
docker run -d --name neo4j \
  -p 7474:7474 \
  -p 7687:7687 \
  -e NEO4J_AUTH=neo4j/password \
  neo4j:latest
```

Acceso a Neo4j Browser: http://localhost:7474
Credenciales: `neo4j` / `password`

### 6. Seed data para Neo4j

```bash
python -m scripts.seed_neo4j
```

Esto creará:
- **Cultivos:** Soya, Sorgo, Maíz, Caña de Azúcar
- **Plagas:** Roya de la Soya, Gusano Cogollero, Pulgón Amarillo, Cochinilla
- **Climas:** Alta Humedad, Sequía, Temperatura Alta, Lluvia Excessiva
- **Tratamientos:** Fungicida Mancozeb, Insecticida Clorpirifos, Agroquímico Metomil, Fungicida Tebuconazol
- **Relaciones:** AFECTA_A, PROLIFERA_CON, COMBATE

###7. Crear base de datos PostgreSQL

```bash
# Conectarse a PostgreSQL y crear la base de datos
psql -h localhost -U postgres -c "CREATE DATABASE agrovison_ai;"
```

###8. Ejecutar el servidor

```bash
uvicorn app.main:app --reload
```

API disponible en: http://localhost:8000
Swagger UI: http://localhost:8000/docs

## Endpoints

### Diagnostics

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/v1/diagnostics/` | Crear diagnóstico |
| GET | `/api/v1/diagnostics/{id}` | Obtener diagnóstico por ID |

#### POST /api/v1/diagnostics/

```json
{
  "user_id": "user123",
  "latitud": -17.784,
  "longitud": -63.182,
  "imagen_url": "https://storage.example.com/img.jpg",
  "clima_temp": 28.5,
  "clima_humedad": 85.0,
  "severidad_riesgo": 3,
  "diagnostico_ia": "Roya de la Soya detectada con severidad media"
}
```

### Knowledge Graph

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/v1/knowledge-graph/risks` | Consultar riesgos por cultivo y clima |
| GET | `/api/v1/knowledge-graph/crops` | Listar todos los cultivos |
| GET | `/api/v1/knowledge-graph/pests` | Listar todas las plagas |

#### GET /api/v1/knowledge-graph/risks

Parámetros:
- `cultivo`: Nombre del cultivo (ej. "Soya", "Maíz")
- `clima`: Condición climática (ej. "Alta Humedad", "Sequía")

Ejemplo:
```
GET /api/v1/knowledge-graph/risks?cultivo=Soya&clima=Alta%20Humedad
```

Response:
```json
{
  "cultivo": "Soya",
  "clima": "Alta Humedad",
  "plagas": [
    {
      "nombre": "Roya de la Soya",
      "tipo": "Hongo",
      "tratamientos": ["Fungicida Mancozeb", "Fungicida Tebuconazol"]
    }
  ]
}
```

### Health Check

```
GET /health
```

## Consultas Cypher para Neo4j Browser

### Ver todos los nodos y relaciones

```cypher
MATCH (n) RETURN n
MATCH ()-[r]->() RETURN type(r), count(*) as count
```

### Consultar riesgos por cultivo y clima

```cypher
MATCH (clima:Clima)<-[:PROLIFERA_CON]-(plaga:Plaga)-[:AFECTA_A]->(cultivo:Cultivo)
WHERE cultivo.nombre = "Soya" AND clima.tipo = "Alta Humedad"
OPTIONAL MATCH (tratamiento:Tratamiento)-[:COMBATE]->(plaga)
RETURN plaga.nombre AS plaga, plaga.tipo AS tipo, collect(DISTINCT tratamiento.nombre) AS tratamientos
```

### Ver todas las plagas y sus tratamientos

```cypher
MATCH (p:Plaga)-[:AFECTA_A]->(c:Cultivo)
OPTIONAL MATCH (t:Tratamiento)-[:COMBATE]->(p)
RETURN p.nombre AS plaga, p.tipo AS tipo, c.nombre AS cultivo, collect(DISTINCT t.nombre) AS tratamientos
```

## Troubleshooting

### Neo4j no se conecta

```bash
# Verificar que el contenedor está corriendo
docker ps | grep neo4j

# Reiniciar si es necesario
docker restart neo4j

# Ver logs
docker logs neo4j
```

### PostgreSQL no se conecta

```bash
# Verificar que el contenedor está corriendo
docker ps | grep postgres

# Probar conexión
psql -h localhost -U postgres -d agrovison_ai
```

### Error de CORS

Si tienes problemas de CORS con el frontend Flutter, agregar:

```python
# En app/main.py
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción, especificar orígenes
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## Environment Variables

| Variable | Default | Descripción |
|----------|---------|-------------|
| `DATABASE_URL` | `postgresql://postgres:postgres@localhost:5432/agrovison_ai` | URL de PostgreSQL |
| `NEO4J_URI` | `bolt://localhost:7687` | URI de Neo4j |
| `NEO4J_USER` | `neo4j` | Usuario de Neo4j |
| `NEO4J_PASSWORD` | `password` | Contraseña de Neo4j |
| `API_V1_PREFIX` | `/api/v1` | Prefijo para endpoints |
| `PROJECT_NAME` | `AgroVision AI` | Nombre del proyecto |

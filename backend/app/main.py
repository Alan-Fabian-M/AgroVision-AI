import logging
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.exc import SQLAlchemyError

from app.core.config import get_settings
from app.core.database import engine, Base
from app.services.neo4j_database import close_driver as close_neo4j, verify_connectivity
from app.core.exceptions import (
    DatabaseException,
    NotFoundException,
    database_exception_handler,
    not_found_exception_handler,
    sqlalchemy_exception_handler,
)

# Importar TODOS los modelos para que Base.metadata los conozca
import app.models  # noqa: F401

from app.routers.diagnostics import router as diagnostics_router
from app.routers.knowledge import router as knowledge_router

settings = get_settings()
logger = logging.getLogger(__name__)


# ── Lifespan ─────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info(f"Iniciando {settings.PROJECT_NAME}...")

    # Crear directorio de uploads si no existe
    uploads_dir = Path(settings.UPLOAD_DIR)
    uploads_dir.mkdir(parents=True, exist_ok=True)
    (uploads_dir / "images").mkdir(exist_ok=True)
    (uploads_dir / "audio").mkdir(exist_ok=True)
    logger.info(f"Directorio de uploads: {uploads_dir.resolve()}")

    # Crear tablas en la base de datos
    Base.metadata.create_all(bind=engine)
    logger.info("Tablas de base de datos sincronizadas.")

    # Verificar conectividad con Neo4j (no-bloqueante)
    await verify_connectivity()

    yield

    # Shutdown
    await close_neo4j()
    logger.info(f"{settings.PROJECT_NAME} detenido.")


# ── App ──────────────────────────────────────────────────
app = FastAPI(
    title=settings.PROJECT_NAME,
    description=(
        "Plataforma de agricultura de precisión. "
        "Diagnóstico multimodal de plagas con IA (Gemini)."
    ),
    version="1.0.0-mvp",
    lifespan=lifespan,
)

# ── CORS ─────────────────────────────────────────────────
if settings.CORS_ALLOWED_ORIGINS:
    origins = [
        origin.strip() 
        for origin in settings.CORS_ALLOWED_ORIGINS.split(",") 
        if origin.strip()
    ]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# ── Exception handlers ───────────────────────────────────
app.add_exception_handler(DatabaseException, database_exception_handler)
app.add_exception_handler(NotFoundException, not_found_exception_handler)
app.add_exception_handler(SQLAlchemyError, sqlalchemy_exception_handler)

# ── Archivos estáticos (uploads) ─────────────────────────
uploads_path = Path(settings.UPLOAD_DIR)
uploads_path.mkdir(parents=True, exist_ok=True)
app.mount(
    settings.STATIC_URL_PREFIX,
    StaticFiles(directory=str(uploads_path)),
    name="uploads",
)

# ── Routers ──────────────────────────────────────────────
app.include_router(diagnostics_router, prefix=settings.API_V1_PREFIX)
app.include_router(knowledge_router, prefix=settings.API_V1_PREFIX)

# ── Health check ─────────────────────────────────────────
@app.get("/health", tags=["System"])
def health_check():
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "version": "1.0.0-mvp",
    }

from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # ── Entorno y Seguridad ──────────────────────────────
    ENV: str = "development"
    DEBUG: bool = True
    SECRET_KEY: str = "secret"
    CORS_ALLOWED_ORIGINS: str = ""

    # ── Base de datos ────────────────────────────────────
    DATABASE_URL: str = "postgresql://postgres:password123@localhost:5433/agrovision_db"

    # ── API ──────────────────────────────────────────────
    API_V1_PREFIX: str = "/api/v1"
    PROJECT_NAME: str = "AgroVision AI"

    # ── Neo4j (futuro) ───────────────────────────────────
    NEO4J_URI: str = "bolt://localhost:7687"
    NEO4J_USER: str = "neo4j"
    NEO4J_PASSWORD: str = "password"

    # ── APIs externas ────────────────────────────────────
    GEMINI_API_KEY: str = ""
    OPENWEATHERMAP_API_KEY: str = ""

    # ── Almacenamiento de archivos ───────────────────────
    UPLOAD_DIR: str = "uploads"
    STATIC_URL_PREFIX: str = "/static/uploads"

    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "ignore"


@lru_cache()
def get_settings() -> Settings:
    return Settings()

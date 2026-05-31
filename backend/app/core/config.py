from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    # ── Entorno y Seguridad ──────────────────────────────
    ENV: str = "development"
    DEBUG: bool = True
    SECRET_KEY: str = "supersecretkey"  # change in production
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days for mobile app session
    CORS_ALLOWED_ORIGINS: str = "http://localhost:3000"

    # ── Base de datos ────────────────────────────────────
    DATABASE_URL: str = "postgresql://postgres:password123@localhost:5433/agrovision_db"

    # ── API ──────────────────────────────────────────────
    API_V1_PREFIX: str = "/api/v1"
    PROJECT_NAME: str = "AgroVision AI"
    HOST: str = "127.0.0.1"
    PORT: int = 8000
    ALLOWED_HOSTS: str = "localhost,127.0.0.1"

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

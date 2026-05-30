from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/agrovison_ai"
    API_V1_PREFIX: str = "/api/v1"
    PROJECT_NAME: str = "AgroGuardian AI"
    NEO4J_URI: str = "bolt://localhost:7687"
    NEO4J_USER: str = "neo4j"
    NEO4J_PASSWORD: str = "password"
    GEMINI_API_KEY: str = ""
    OPENWEATHERMAP_API_KEY: str = ""
    SECRET_KEY: str = ""
    HOST: str = "127.0.0.1"
    PORT: int = 8000
    ALLOWED_HOSTS: str = "localhost,127.0.0.1"
    CORS_ALLOWED_ORIGINS: str = "http://localhost:3000"

    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "ignore"


@lru_cache()
def get_settings() -> Settings:
    return Settings()

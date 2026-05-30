"""
app.dependencies — Inyección de dependencias para FastAPI.
Factory functions usadas con Depends() para inyectar las implementaciones
concretas de cada interfaz. Para cambiar de proveedor (ej. Local → S3),
solo se modifica este archivo.
"""
from functools import lru_cache

from app.services.interfaces.file_storage import FileStorageService
from app.services.interfaces.weather import WeatherService
from app.services.interfaces.ai_diagnosis import AIDiagnosisService
from app.services.interfaces.treatment import TreatmentRecommendationService

from app.services.impl.local_storage import LocalFileStorageService
from app.services.impl.mock_weather import MockWeatherService
from app.services.impl.gemini_diagnosis import GeminiDiagnosisService
from app.services.impl.llm_recommendation import LLMRecommendationService

from app.services.diagnosis_orchestrator import DiagnosisOrchestrator


# ── Singletons (se crean una sola vez) ───────────────────

@lru_cache()
def get_file_storage() -> FileStorageService:
    """
    MVP: almacenamiento local.
    Migración futura: cambiar a AWSS3StorageService().
    """
    return LocalFileStorageService()


@lru_cache()
def get_weather_service() -> WeatherService:
    """
    MVP: datos climáticos simulados.
    Migración futura: cambiar a OpenWeatherMapService().
    """
    return MockWeatherService()


@lru_cache()
def get_ai_service() -> AIDiagnosisService:
    """
    MVP: Google Gemini 1.5 Flash + Whisper local.
    """
    return GeminiDiagnosisService()


@lru_cache()
def get_treatment_service() -> TreatmentRecommendationService:
    """
    MVP: recomendaciones vía LLM (Gemini).
    Migración futura: cambiar a GraphRecommendationService() (Neo4j).
    """
    return LLMRecommendationService()


def get_orchestrator(
    file_storage: FileStorageService = None,
    weather: WeatherService = None,
    ai: AIDiagnosisService = None,
    treatment: TreatmentRecommendationService = None,
) -> DiagnosisOrchestrator:
    """
    Construye el orquestador con todas las dependencias inyectadas.
    Usa los singletons por defecto, pero permite override para testing.
    """
    return DiagnosisOrchestrator(
        file_storage=file_storage or get_file_storage(),
        weather_service=weather or get_weather_service(),
        ai_service=ai or get_ai_service(),
        treatment_service=treatment or get_treatment_service(),
    )

"""
app.services.interfaces — Contratos abstractos (puertos) del sistema.
"""
from app.services.interfaces.file_storage import FileStorageService  # noqa: F401
from app.services.interfaces.weather import WeatherService  # noqa: F401
from app.services.interfaces.ai_diagnosis import AIDiagnosisService  # noqa: F401
from app.services.interfaces.treatment import TreatmentRecommendationService  # noqa: F401

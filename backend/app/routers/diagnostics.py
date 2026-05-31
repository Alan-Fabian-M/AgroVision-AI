"""
Router: /api/v1/diagnostics
Endpoints para el flujo de diagnóstico multimodal de AgroVision AI.
"""
import uuid
import logging
from typing import Optional
from fastapi import (
    APIRouter, Depends, File, Form, HTTPException, UploadFile, status,
)
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.exceptions import DatabaseException
from app.dependencies import get_orchestrator
from app.models.diagnosis import Diagnosis
from app.schemas.diagnosis import DiagnosisResponse
from app.services.diagnosis_orchestrator import DiagnosisOrchestrator
from app.services.weather_service import WeatherService, get_weather_service

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/diagnostics", tags=["Diagnostics"])

# ── Extensiones permitidas ───────────────────────────────
ALLOWED_IMAGE_TYPES = {
    "image/jpeg", "image/png", "image/webp", "image/gif", "image/bmp"
}
ALLOWED_AUDIO_TYPES = {
    "audio/mpeg", "audio/wav", "audio/ogg", "audio/webm",
    "audio/mp4", "audio/x-m4a", "audio/aac",
}
MAX_FILE_SIZE_MB = 10


# ── POST /analyze — Endpoint principal ───────────────────
@router.post(
    "/analyze",
    status_code=status.HTTP_201_CREATED,
    summary="Análisis multimodal de cultivo (Validación Temporal)",
    description=(
        "Recibe datos multimodales (imágenes, audio, texto) junto con "
        "coordenadas geográficas. Temporalmente solo valida imágenes "
        "y retorna el contexto climático obtenido de OpenWeatherMap."
    ),
)
async def analyze_crop(
    latitude: float = Form(
        ..., ge=-90, le=90,
        description="Latitud en grados decimales"
    ),
    longitude: float = Form(
        ..., ge=-180, le=180,
        description="Longitud en grados decimales"
    ),
    user_id: str = Form(
        ..., min_length=1,
        description="UUID del usuario registrado"
    ),
    text_notes: Optional[str] = Form(
        None,
        description="Notas de texto del agricultor (opcional)"
    ),
    audio: Optional[UploadFile] = File(
        None,
        description="Archivo de audio con descripción del problema (opcional)"
    ),
    images: list[UploadFile] = File(
        ...,
        description="Lista de imágenes del cultivo afectado"
    ),
    weather_service: WeatherService = Depends(get_weather_service),
):
    """
    Endpoint temporal de validación multimodal y de clima.
    Flujo temporal:
    1. Valida inputs (formatos de archivo, user_id UUID).
    2. Consulta API del clima (OpenWeatherMap).
    3. Retorna un JSON temporal.
    """
    # ── Validar user_id como UUID ────────────────────────
    try:
        parsed_user_id = uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"user_id debe ser un UUID válido. Recibido: '{user_id}'",
        )

    # ── Validar que hay al menos una imagen ──────────────
    valid_images = [img for img in images if img.filename]
    if not valid_images:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Debe enviar al menos una imagen del cultivo.",
        )

    # ── Validar tipos de archivo ─────────────────────────
    for img in valid_images:
        if img.content_type and img.content_type not in ALLOWED_IMAGE_TYPES:
            raise HTTPException(
                status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                detail=(
                    f"Tipo de imagen no soportado: '{img.content_type}'. "
                    f"Formatos permitidos: JPEG, PNG, WebP, GIF, BMP."
                ),
            )

    if audio and audio.filename:
        if audio.content_type and audio.content_type not in ALLOWED_AUDIO_TYPES:
            raise HTTPException(
                status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                detail=(
                    f"Tipo de audio no soportado: '{audio.content_type}'. "
                    f"Formatos permitidos: MP3, WAV, OGG, WebM, M4A, AAC."
                ),
            )
    else:
        audio = None  # Normalizar: sin archivo = None

    # ── Consultar Clima ──────────────────────────────────
    try:
        weather_data = await weather_service.get_weather(latitude, longitude)
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Error consultando el clima en el endpoint: {e}")
        weather_data = {"error": "No se pudo obtener el clima"}

    # ── Respuesta Temporal (Ignorando DB/Gemini) ─────────
    return {
        "plaga_detectada": f"Imágenes: {len(valid_images)} | Clima: {weather_data.get('temperature', 'N/A')}°C",
        "nivel_gravedad": "INFO",
        "prioridad": "BAJA",
        "recomendaciones": [
            "Conexión Frontend-Backend Exitosa.",
            f"Archivos procesados: {len(valid_images)} imagen(es).",
            f"Audio recibido: {'Sí' if audio is not None else 'No'}.",
            f"Notas: {text_notes or 'Ninguna'}"
        ],
        "productos_sugeridos": [
            f"Temp: {weather_data.get('temperature', 'N/A')}°C",
            f"Humedad: {weather_data.get('humidity', 'N/A')}%",
            f"Condición: {weather_data.get('condition', 'N/A')}"
        ],
        "confianza": 1.0
    }


# ── GET /{id} — Consultar diagnóstico por ID ────────────
@router.get(
    "/{diagnosis_id}",
    response_model=DiagnosisResponse,
    summary="Obtener diagnóstico por ID",
)
def get_diagnosis(
    diagnosis_id: uuid.UUID,
    db: Session = Depends(get_db),
):
    """Recupera un diagnóstico existente con sus adjuntos."""
    diagnosis = (
        db.query(Diagnosis)
        .filter(Diagnosis.id == diagnosis_id)
        .first()
    )
    if not diagnosis:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Diagnóstico {diagnosis_id} no encontrado.",
        )
    return diagnosis


# ── GET /user/{user_id} — Diagnósticos por usuario ──────
@router.get(
    "/user/{user_id}",
    response_model=list[DiagnosisResponse],
    summary="Listar diagnósticos de un usuario",
)
def get_user_diagnoses(
    user_id: uuid.UUID,
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 20,
):
    """Lista todos los diagnósticos de un usuario con paginación."""
    diagnoses = (
        db.query(Diagnosis)
        .filter(Diagnosis.user_id == user_id)
        .order_by(Diagnosis.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    return diagnoses

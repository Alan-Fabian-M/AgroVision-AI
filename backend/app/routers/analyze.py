import uuid
from typing import List, Optional
from fastapi import APIRouter, UploadFile, File, Form, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies import get_orchestrator
from app.services.diagnosis_orchestrator import DiagnosisOrchestrator
from app.schemas.diagnosis import DiagnosisResponse

router = APIRouter(prefix="/diagnostics", tags=["AI Analysis"])


@router.post("/analyze", response_model=DiagnosisResponse, status_code=status.HTTP_201_CREATED)
async def analyze_crop(
    user_id: str = Form(default="00000000-0000-0000-0000-000000000001"),
    latitude: float = Form(default=-17.7863),
    longitude: float = Form(default=-63.1812),
    text_notes: Optional[str] = Form(default=None),
    images: List[UploadFile] = File(default=[]),
    audio: Optional[UploadFile] = File(default=None),
    db: Session = Depends(get_db),
    orchestrator: DiagnosisOrchestrator = Depends(get_orchestrator),
):
    """
    Endpoint principal de análisis multimodal.
    Acepta imágenes, audio y notas de texto para diagnosticar plagas/enfermedades.
    """
    try:
        uid = uuid.UUID(user_id)
    except ValueError:
        uid = uuid.UUID("00000000-0000-0000-0000-000000000001")

    try:
        result = await orchestrator.execute(
            db=db,
            user_id=uid,
            latitude=latitude,
            longitude=longitude,
            images=images,
            audio=audio if (audio and audio.filename) else None,
            text_notes=text_notes,
        )
        
        # --- Simulación de Alerta Fitosanitaria para la Hackathon ---
        from app.services.notifications import send_epidemiological_alert
        # Si el riesgo es 3 o mayor, disparamos la alerta de plaga cercana
        if result.severidad_riesgo and result.severidad_riesgo >= 3:
            # Para la demo, extraemos el nombre de la plaga o ponemos uno genérico
            plaga_detectada = result.diagnostico_ia if result.diagnostico_ia else "una plaga peligrosa"
            send_epidemiological_alert(pest_name=plaga_detectada, distance_km=5.0)
            
        return result
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error en el diagnóstico: {str(e)}"
        )

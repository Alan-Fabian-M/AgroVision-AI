"""
DiagnosisOrchestrator — Orquestador principal del flujo de diagnóstico.
Coordina todos los servicios inyectados para ejecutar el pipeline completo:
  1. Guardar archivos → 2. Obtener clima → 3. Analizar con IA →
  4. Generar tratamiento → 5. Persistir en BD.
"""
import logging
import uuid
from typing import Any

from fastapi import UploadFile
from sqlalchemy.orm import Session

from app.models.diagnosis import (
    Attachment,
    Diagnosis,
    FileType,
    PestType,
    RiskLevel,
)
from app.schemas.diagnosis import DiagnosisResponse
from app.services.interfaces.ai_diagnosis import AIDiagnosisService
from app.services.interfaces.file_storage import FileStorageService
from app.services.interfaces.treatment import TreatmentRecommendationService
from app.services.interfaces.weather import WeatherService

logger = logging.getLogger(__name__)


class DiagnosisOrchestrator:
    """
    Orquesta el flujo completo de diagnóstico.
    Recibe todas las dependencias por inyección (constructor injection).
    """

    def __init__(
        self,
        file_storage: FileStorageService,
        weather_service: WeatherService,
        ai_service: AIDiagnosisService,
        treatment_service: TreatmentRecommendationService,
    ) -> None:
        self._storage = file_storage
        self._weather = weather_service
        self._ai = ai_service
        self._treatment = treatment_service

    async def execute(
        self,
        db: Session,
        user_id: uuid.UUID,
        latitude: float,
        longitude: float,
        images: list[UploadFile],
        audio: UploadFile | None = None,
        text_notes: str | None = None,
    ) -> DiagnosisResponse:
        """
        Pipeline completo de diagnóstico:
        1. Guarda archivos (imágenes, audio) en almacenamiento.
        2. Obtiene datos climáticos para la ubicación.
        3. Envía datos multimodales al servicio de IA.
        4. Genera plan de tratamiento.
        5. Persiste Diagnosis + Attachments en PostgreSQL.
        6. Retorna DiagnosisResponse.
        """
        # ── 1. Guardar archivos ──────────────────────────────
        saved_files: list[dict[str, str]] = []
        image_local_paths: list[str] = []

        for img in images:
            file_url, local_path = await self._storage.save(
                img, subdir="images"
            )
            saved_files.append({
                "file_type": FileType.IMAGE.value,
                "file_url": file_url,
                "local_path": local_path,
            })
            image_local_paths.append(local_path)
            logger.info(f"Imagen guardada: {file_url}")

        audio_local_path: str | None = None
        if audio:
            file_url, local_path = await self._storage.save(
                audio, subdir="audio"
            )
            saved_files.append({
                "file_type": FileType.AUDIO.value,
                "file_url": file_url,
                "local_path": local_path,
            })
            audio_local_path = local_path
            logger.info(f"Audio guardado: {file_url}")

        # Guardar notas de texto como archivo si existen
        if text_notes and text_notes.strip():
            # Las notas de texto no se guardan como archivo,
            # se envían directamente al análisis IA.
            # Pero registramos la referencia como attachment tipo TEXT.
            saved_files.append({
                "file_type": FileType.TEXT.value,
                "file_url": "inline:text_notes",
                "local_path": "inline",
            })

        # ── 2. Obtener datos climáticos ──────────────────────
        weather_data = await self._weather.get_weather(latitude, longitude)
        logger.info(
            f"Clima obtenido: {weather_data.get('temp_celsius')}°C, "
            f"{weather_data.get('humidity_pct')}% humedad"
        )

        # ── 3. Análisis IA multimodal ────────────────────────
        ai_result = await self._ai.analyze(
            image_paths=image_local_paths,
            audio_path=audio_local_path,
            text_notes=text_notes,
            weather_data=weather_data,
        )
        logger.info(
            f"Diagnóstico IA: {ai_result.get('pest_detected')} "
            f"(confianza: {ai_result.get('confidence')})"
        )

        # ── 4. Generar plan de tratamiento ───────────────────
        treatment_plan = await self._treatment.recommend(ai_result)

        # Combinar action_plan de IA con plan de tratamiento
        full_action_plan = (
            f"{ai_result.get('action_plan', '')}\n\n"
            f"--- PLAN DE TRATAMIENTO DETALLADO ---\n"
            f"{treatment_plan}"
        )

        # ── 5. Validar y mapear enums ────────────────────────
        risk_level = self._safe_enum(
            RiskLevel, ai_result.get("risk_level", "MODERADO"), RiskLevel.MODERADO
        )
        pest_type = self._safe_enum(
            PestType, ai_result.get("pest_type", "OTRO"), PestType.OTRO
        )

        # ── 6. Persistir en PostgreSQL ───────────────────────
        diagnosis = Diagnosis(
            user_id=user_id,
            latitude=latitude,
            longitude=longitude,
            weather_data=weather_data,
            risk_level=risk_level,
            estimated_loss_usd=float(
                ai_result.get("estimated_loss_usd", 0.0)
            ),
            action_plan=full_action_plan,
            pest_detected=ai_result.get(
                "pest_detected", "No identificada"
            ),
            pest_type=pest_type,
            defoliation_pct=float(
                ai_result.get("defoliation_pct", 0.0)
            ),
            beneficial_controllers=ai_result.get(
                "beneficial_controllers"
            ),
            confidence=float(ai_result.get("confidence", 0.0)),
        )

        db.add(diagnosis)
        db.flush()  # Obtener el ID antes de crear attachments

        # Crear Attachments
        for sf in saved_files:
            attachment = Attachment(
                diagnosis_id=diagnosis.id,
                file_type=FileType(sf["file_type"]),
                file_url=sf["file_url"],
                local_path=sf["local_path"],
            )
            db.add(attachment)

        db.commit()
        db.refresh(diagnosis)

        logger.info(
            f"Diagnóstico {diagnosis.id} guardado con "
            f"{len(saved_files)} adjuntos"
        )

        # ── 7. Retornar respuesta ────────────────────────────
        return DiagnosisResponse.model_validate(diagnosis)

    @staticmethod
    def _safe_enum(enum_cls, value: str, default):
        """Mapea un string a un enum de forma segura."""
        try:
            return enum_cls(value)
        except ValueError:
            logger.warning(
                f"Valor de enum inválido '{value}' para {enum_cls.__name__}, "
                f"usando default: {default.value}"
            )
            return default

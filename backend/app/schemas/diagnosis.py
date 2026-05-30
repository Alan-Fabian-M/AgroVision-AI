"""
Schemas Pydantic para el módulo de Diagnóstico.
Cubre: respuesta de Attachment, respuesta de Diagnosis,
y el modelo interno que valida la salida JSON de Gemini.
"""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


# ── Attachment ───────────────────────────────────────────
class AttachmentOut(BaseModel):
    """Representación pública de un archivo adjunto."""
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    file_type: str
    file_url: str


# ── Diagnosis Response ───────────────────────────────────
class DiagnosisResponse(BaseModel):
    """Respuesta completa de un diagnóstico con sus adjuntos."""
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    latitude: float
    longitude: float
    weather_data: dict[str, Any] | None = None
    risk_level: str
    estimated_loss_usd: float
    action_plan: str
    pest_detected: str
    pest_type: str
    defoliation_pct: float
    beneficial_controllers: str | None = None
    confidence: float
    created_at: datetime
    attachments: list[AttachmentOut] = []


# ── Gemini Raw Response (validación interna) ─────────────
class GeminiRawResponse(BaseModel):
    """
    Modelo estricto que parsea y valida el JSON devuelto por Gemini.
    Si Gemini devuelve algo que no matchea estos campos, Pydantic
    lanzará un error de validación antes de llegar a la BD.
    """
    risk_level: str = Field(
        ...,
        description="BAJO | MODERADO | ALTO | CRITICO"
    )
    estimated_loss_usd: float = Field(
        ...,
        ge=0,
        description="Pérdida económica estimada en USD"
    )
    action_plan: str = Field(
        ...,
        min_length=1,
        description="Plan de acción inmediato para el agricultor"
    )
    pest_detected: str = Field(
        ...,
        min_length=1,
        description="Nombre de la plaga o enfermedad identificada"
    )
    pest_type: str = Field(
        ...,
        description="DEFOLIADOR | BARRENADOR | SUCCIONADOR | ENFERMEDAD_FUNGICA | ENFERMEDAD_BACTERIANA | OTRO"
    )
    defoliation_pct: float = Field(
        ...,
        ge=0,
        le=100,
        description="Porcentaje de defoliación observado"
    )
    beneficial_controllers: str | None = Field(
        None,
        description="Controladores benéficos identificados en el cultivo"
    )
    confidence: float = Field(
        ...,
        ge=0.0,
        le=1.0,
        description="Nivel de confianza del diagnóstico"
    )
    productos_sugeridos: list[str] = Field(
        default_factory=list,
        description="Lista de productos agroquímicos sugeridos"
    )
    recomendaciones_tratamiento: str = Field(
        default="",
        description="Recomendaciones detalladas de tratamiento"
    )

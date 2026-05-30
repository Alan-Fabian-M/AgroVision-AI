"""
Schemas Pydantic: DiagnosticoCultivo.
Los diagnósticos los genera la IA, por eso el Create incluye todos los campos
y no hay Update (los diagnósticos son inmutables).
"""
from datetime import datetime
from pydantic import BaseModel, ConfigDict
from app.models.diagnostico_ia import NivelGravedad, Prioridad


class DiagnosticoCultivoBase(BaseModel):
    plaga_detectada: str
    nivel_gravedad: NivelGravedad
    prioridad: Prioridad
    recomendaciones: str
    productos_sugeridos: str
    costo_estimado_ia: float | None = None


class DiagnosticoCultivoCreate(DiagnosticoCultivoBase):
    """Creado por el módulo de IA tras procesar evidencias (fotos, audio, texto)."""
    solicitud_id: int


class DiagnosticoCultivoOut(DiagnosticoCultivoBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    fecha: datetime
    solicitud_id: int

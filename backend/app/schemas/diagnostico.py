from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, Field, field_validator


class DiagnosticoCreate(BaseModel):
    user_id: str = Field(..., min_length=1, max_length=50)
    latitud: float = Field(..., ge=-90, le=90)
    longitud: float = Field(..., ge=-180, le=180)
    imagen_url: str = Field(..., min_length=1, max_length=500)
    clima_temp: float | None = Field(None, ge=-50, le=60)
    clima_humedad: float | None = Field(None, ge=0, le=100)
    severidad_riesgo: int = Field(..., ge=1, le=5)
    diagnostico_ia: str = Field(..., min_length=1)

    @field_validator("user_id", "imagen_url", "diagnostico_ia")
    @classmethod
    def not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Field cannot be empty")
        return v


class DiagnosticoResponse(BaseModel):
    id: UUID
    user_id: str
    latitud: float
    longitud: float
    imagen_url: str
    clima_temp: float | None
    clima_humedad: float | None
    severidad_riesgo: int
    diagnostico_ia: str
    fecha_creacion: datetime

    class Config:
        from_attributes = True

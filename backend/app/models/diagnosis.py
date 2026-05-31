"""
Modelos: Diagnosis & Attachment
- Diagnosis: resultado del análisis multimodal (Gemini + clima).
- Attachment: referencia a archivos subidos (imagen, audio, texto).
  NO almacena archivos directamente, solo rutas.
"""
import enum
import uuid
from datetime import datetime

from sqlalchemy import (
    Float,
    ForeignKey,
    String,
    Text,
    DateTime,
    Enum as SAEnum,
)
from sqlalchemy.dialects.postgresql import UUID, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.database import Base


# ── Enums ────────────────────────────────────────────────
class RiskLevel(str, enum.Enum):
    """Nivel de riesgo económico del diagnóstico."""
    BAJO = "BAJO"
    MODERADO = "MODERADO"
    ALTO = "ALTO"
    CRITICO = "CRITICO"


class PestType(str, enum.Enum):
    """Clasificación de la plaga según Planilla de Muestreo."""
    DEFOLIADOR = "DEFOLIADOR"
    BARRENADOR = "BARRENADOR"
    SUCCIONADOR = "SUCCIONADOR"
    ENFERMEDAD_FUNGICA = "ENFERMEDAD_FUNGICA"
    ENFERMEDAD_BACTERIANA = "ENFERMEDAD_BACTERIANA"
    OTRO = "OTRO"


class FileType(str, enum.Enum):
    """Tipo de archivo adjunto."""
    IMAGE = "image"
    AUDIO = "audio"
    TEXT = "text"


# ── Diagnosis ────────────────────────────────────────────
class Diagnosis(Base):
    __tablename__ = "diagnoses"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        index=True,
    )

    # FK → users
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # Geolocalización
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)

    # Datos climáticos (JSON completo de la API de clima)
    weather_data: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    # Resultado del análisis IA
    risk_level: Mapped[RiskLevel] = mapped_column(
        SAEnum(RiskLevel, name="risk_level_enum", create_constraint=True),
        nullable=False,
    )
    estimated_loss_usd: Mapped[float] = mapped_column(
        Float, nullable=False, default=0.0
    )
    action_plan: Mapped[str] = mapped_column(Text, nullable=False)

    # Campos de la Planilla de Muestreo de Plagas
    pest_detected: Mapped[str] = mapped_column(
        String(255), nullable=False
    )
    pest_type: Mapped[PestType] = mapped_column(
        SAEnum(PestType, name="pest_type_enum", create_constraint=True),
        nullable=False,
    )
    defoliation_pct: Mapped[float] = mapped_column(
        Float, nullable=False, default=0.0,
        comment="Porcentaje de defoliación observado (0-100)"
    )
    beneficial_controllers: Mapped[str | None] = mapped_column(
        Text, nullable=True,
        comment="Controladores benéficos identificados"
    )
    confidence: Mapped[float] = mapped_column(
        Float, nullable=False, default=0.0,
        comment="Confianza del diagnóstico (0.0 - 1.0)"
    )

    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )

    # ── Relaciones ──────────────────────────────────────
    user: Mapped["User"] = relationship(
        "User",
        back_populates="diagnoses",
    )
    attachments: Mapped[list["Attachment"]] = relationship(
        "Attachment",
        back_populates="diagnosis",
        cascade="all, delete-orphan",
        lazy="selectin",
    )

    def __repr__(self) -> str:
        return (
            f"<Diagnosis(id={self.id}, pest='{self.pest_detected}', "
            f"risk={self.risk_level.value})>"
        )


# ── Attachment ───────────────────────────────────────────
class Attachment(Base):
    __tablename__ = "attachments"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        index=True,
    )

    # FK → diagnoses
    diagnosis_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("diagnoses.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    file_type: Mapped[FileType] = mapped_column(
        SAEnum(FileType, name="file_type_enum", create_constraint=True),
        nullable=False,
    )
    file_url: Mapped[str] = mapped_column(
        String(500), nullable=False,
        comment="URL relativa accesible (ej: /static/uploads/images/...)"
    )
    local_path: Mapped[str] = mapped_column(
        String(500), nullable=False,
        comment="Ruta absoluta en el disco del servidor"
    )

    # ── Relaciones ──────────────────────────────────────
    diagnosis: Mapped["Diagnosis"] = relationship(
        "Diagnosis",
        back_populates="attachments",
    )

    def __repr__(self) -> str:
        return (
            f"<Attachment(id={self.id}, type={self.file_type.value}, "
            f"url='{self.file_url}')>"
        )

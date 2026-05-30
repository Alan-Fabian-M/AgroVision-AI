"""
Modelo: DiagnosticoCultivo.
Resultado del análisis automático de un reporte agrícola.
"""
import enum
from datetime import datetime
from sqlalchemy import Float, ForeignKey, Text, DateTime, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.core.database import Base


class NivelGravedad(str, enum.Enum):
    """Nivel de gravedad determinado por la IA."""
    LEVE = "LEVE"
    MEDIO = "MEDIO"
    GRAVE = "GRAVE"
    CRITICO = "CRITICO"


class Prioridad(str, enum.Enum):
    """Prioridad de atención."""
    BAJA = "BAJA"
    MEDIA = "MEDIA"
    ALTA = "ALTA"
    URGENTE = "URGENTE"


class DiagnosticoCultivo(Base):
    __tablename__ = "diagnosticos_cultivo"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    plaga_detectada: Mapped[str] = mapped_column(Text, nullable=False)
    nivel_gravedad: Mapped[NivelGravedad] = mapped_column(
        SAEnum(NivelGravedad, name="nivel_gravedad_cultivo", create_constraint=True),
        nullable=False,
    )
    prioridad: Mapped[Prioridad] = mapped_column(
        SAEnum(Prioridad, name="prioridad_cultivo", create_constraint=True),
        nullable=False,
    )
    recomendaciones: Mapped[str] = mapped_column(Text, nullable=False)
    productos_sugeridos: Mapped[str] = mapped_column(Text, nullable=False) # Lista separada por comas o JSON
    costo_estimado_ia: Mapped[float | None] = mapped_column(Float)
    fecha: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # FK — relación 1:1 con solicitud de análisis
    solicitud_id: Mapped[int] = mapped_column(
        ForeignKey("solicitudes_analisis.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )

    # Relaciones (Comentado hasta que se defina SolicitudAnalisis)
    # solicitud: Mapped["SolicitudAnalisis"] = relationship(
    #     back_populates="diagnostico"
    # )

    def __repr__(self) -> str:
        return (
            f"<DiagnosticoCultivo(id={self.id}, plaga='{self.plaga_detectada[:30]}')>"
        )

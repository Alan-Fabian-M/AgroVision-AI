import uuid
from datetime import datetime
from sqlalchemy import String, Float, Integer, Text, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class Diagnostico(Base):
    __tablename__ = "diagnosticos"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    latitud: Mapped[float] = mapped_column(Float, nullable=False)
    longitud: Mapped[float] = mapped_column(Float, nullable=False)
    imagen_url: Mapped[str] = mapped_column(String(500), nullable=False)
    clima_temp: Mapped[float] = mapped_column(Float, nullable=True)
    clima_humedad: Mapped[float] = mapped_column(Float, nullable=True)
    severidad_riesgo: Mapped[int] = mapped_column(Integer, nullable=False)
    diagnostico_ia: Mapped[str] = mapped_column(Text, nullable=False)
    fecha_creacion: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

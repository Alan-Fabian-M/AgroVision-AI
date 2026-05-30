from uuid import UUID
from sqlalchemy.orm import Session
from app.models.diagnostico import Diagnostico
from app.schemas.diagnostico import DiagnosticoCreate


class DiagnosticoService:
    def __init__(self, db: Session):
        self.db = db

    def create(self, diagnostico: DiagnosticoCreate) -> Diagnostico:
        db_diagnostico = Diagnostico(
            user_id=diagnostico.user_id,
            latitud=diagnostico.latitud,
            longitud=diagnostico.longitud,
            imagen_url=diagnostico.imagen_url,
            clima_temp=diagnostico.clima_temp,
            clima_humedad=diagnostico.clima_humedad,
            severidad_riesgo=diagnostico.severidad_riesgo,
            diagnostico_ia=diagnostico.diagnostico_ia,
        )
        self.db.add(db_diagnostico)
        self.db.commit()
        self.db.refresh(db_diagnostico)
        return db_diagnostico

    def get_by_id(self, diagnostico_id: UUID) -> Diagnostico | None:
        return self.db.query(Diagnostico).filter(Diagnostico.id == diagnostico_id).first()

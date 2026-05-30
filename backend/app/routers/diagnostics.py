from uuid import UUID
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.exceptions import DatabaseException, NotFoundException
from app.schemas.diagnostico import DiagnosticoCreate, DiagnosticoResponse
from app.services.diagnostico import DiagnosticoService

router = APIRouter(prefix="/diagnostics", tags=["Diagnostics"])


@router.get("/", response_model=List[DiagnosticoResponse])
def list_diagnosticos(
    limit: int = Query(default=10, ge=1, le=50),
    db: Session = Depends(get_db)
):
    from app.models.diagnostico import Diagnostico
    return db.query(Diagnostico).order_by(Diagnostico.fecha_creacion.desc()).limit(limit).all()


@router.post("/", response_model=DiagnosticoResponse, status_code=status.HTTP_201_CREATED)
def create_diagnostico(
    diagnostico: DiagnosticoCreate,
    db: Session = Depends(get_db)
):
    try:
        service = DiagnosticoService(db)
        return service.create(diagnostico)
    except DatabaseException as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=e.detail)


@router.get("/{diagnostico_id}", response_model=DiagnosticoResponse)
def get_diagnostico(
    diagnostico_id: UUID,
    db: Session = Depends(get_db)
):
    service = DiagnosticoService(db)
    diagnostico = service.get_by_id(diagnostico_id)
    if not diagnostico:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Diagnostic not found")
    return diagnostico

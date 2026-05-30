from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.exceptions import DatabaseException, NotFoundException
from app.schemas.diagnostico import DiagnosticoCreate, DiagnosticoResponse
from app.services.diagnostico import DiagnosticoService

router = APIRouter(prefix="/diagnostics", tags=["Diagnostics"])


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

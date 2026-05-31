from uuid import UUID
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.diagnosis import DiagnosisResponse
from app.models.diagnosis import Diagnosis

router = APIRouter(prefix="/diagnostics", tags=["Diagnostics"])


@router.get("/", response_model=List[DiagnosisResponse])
def list_diagnostics(
    limit: int = Query(default=10, ge=1, le=50),
    db: Session = Depends(get_db)
):
    return db.query(Diagnosis).order_by(Diagnosis.created_at.desc()).limit(limit).all()


@router.get("/{diagnosis_id}", response_model=DiagnosisResponse)
def get_diagnosis(
    diagnosis_id: UUID,
    db: Session = Depends(get_db)
):
    diagnosis = db.query(Diagnosis).filter(Diagnosis.id == diagnosis_id).first()
    if not diagnosis:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Diagnosis not found")
    return diagnosis

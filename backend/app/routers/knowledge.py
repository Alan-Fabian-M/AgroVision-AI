from fastapi import APIRouter, Query, HTTPException, status
from app.services.knowledge_graph import (
    get_risks_by_crop_and_climate,
    get_all_crops,
    get_all_pests,
    get_treatments_by_pest,
)
from app.core.exceptions import DatabaseException

router = APIRouter(prefix="/knowledge-graph", tags=["Knowledge Graph"])


@router.get("/risks")
async def get_risks(
    cultivo: str = Query(..., description="Nombre del cultivo (ej. Soya, Maíz)"),
    clima: str = Query(..., description="Condición climática (ej. Alta Humedad, Sequía)")
):
    try:
        return await get_risks_by_crop_and_climate(cultivo, clima)
    except DatabaseException as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=e.detail)


@router.get("/crops")
async def list_crops():
    try:
        return await get_all_crops()
    except DatabaseException as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=e.detail)


@router.get("/pests")
async def list_pests():
    try:
        return await get_all_pests()
    except DatabaseException as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=e.detail)


@router.get("/treatments")
async def get_treatments(
    plaga: str = Query(..., description="Nombre de la plaga (ej. Roya de la Soya)")
):
    try:
        return await get_treatments_by_pest(plaga)
    except DatabaseException as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=e.detail)

import os
import json
import tempfile
from fastapi import APIRouter, UploadFile, File, Form, Depends
from fastapi.responses import JSONResponse
from typing import List
from sqlalchemy.orm import Session
from app.services.ia_service import asistente_ia
from app.core.database import get_db
from app.models.diagnostico import Diagnostico

router = APIRouter(prefix="/diagnostics", tags=["AI Analysis"])

_PRIORIDAD_A_SEVERIDAD = {"URGENTE": 5, "ALTA": 4, "MEDIA": 3, "BAJA": 2}


@router.post("/analyze")
async def analyze_crop(
    descripcion: str = Form(default=""),
    tipo: str = Form(default="Planta"),
    user_id: str = Form(default="agricultor"),
    latitud: float = Form(default=-17.7863),
    longitud: float = Form(default=-63.1812),
    clima_temp: float = Form(default=None),
    clima_humedad: float = Form(default=None),
    imagenes: List[UploadFile] = File(default=[]),
    db: Session = Depends(get_db),
):
    rutas_temporales = []
    try:
        for imagen in imagenes:
            suffix = os.path.splitext(imagen.filename or ".jpg")[1] or ".jpg"
            with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
                tmp.write(await imagen.read())
                rutas_temporales.append(tmp.name)

        resultado = asistente_ia.procesar_solicitud(
            descripcion=f"[Tipo: {tipo}] {descripcion}".strip(),
            ruta_audio=None,
            rutas_imagenes=rutas_temporales if rutas_temporales else None,
        )

        # Guardar diagnóstico en la base de datos
        diagnostico_texto = (
            f"Plaga: {resultado.get('plaga_detectada', 'N/A')} | "
            f"Gravedad: {resultado.get('nivel_gravedad', 'N/A')} | "
            f"{resultado.get('recomendaciones', '')}"
        )
        severidad = _PRIORIDAD_A_SEVERIDAD.get(resultado.get("prioridad", "MEDIA"), 3)

        db_diag = Diagnostico(
            user_id=user_id,
            latitud=latitud,
            longitud=longitud,
            imagen_url=rutas_temporales[0] if rutas_temporales else "sin_imagen",
            clima_temp=clima_temp,
            clima_humedad=clima_humedad,
            severidad_riesgo=severidad,
            diagnostico_ia=diagnostico_texto,
        )
        db.add(db_diag)
        db.commit()
        db.refresh(db_diag)

        # Devolver resultado IA + id del registro guardado
        resultado["diagnostico_id"] = str(db_diag.id)
        resultado["guardado"] = True

        return JSONResponse(content=resultado)

    except Exception as e:
        db.rollback()
        # Si falla el guardado, igual devolvemos el resultado de la IA
        resultado["guardado"] = False
        resultado["guardado_error"] = str(e)
        return JSONResponse(content=resultado)

    finally:
        for ruta in rutas_temporales:
            try:
                os.unlink(ruta)
            except OSError:
                pass

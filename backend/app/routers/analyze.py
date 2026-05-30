import os
import tempfile
from fastapi import APIRouter, UploadFile, File, Form
from fastapi.responses import JSONResponse
from typing import List
from app.services.ia_service import asistente_ia

router = APIRouter(prefix="/diagnostics", tags=["AI Analysis"])


@router.post("/analyze")
async def analyze_crop(
    descripcion: str = Form(default=""),
    tipo: str = Form(default="Planta"),
    imagenes: List[UploadFile] = File(default=[]),
):
    rutas_temporales = []
    try:
        # Guardar imágenes en archivos temporales
        for imagen in imagenes:
            suffix = os.path.splitext(imagen.filename or ".jpg")[1] or ".jpg"
            with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
                contenido = await imagen.read()
                tmp.write(contenido)
                rutas_temporales.append(tmp.name)

        texto_descripcion = f"[Tipo: {tipo}] {descripcion}".strip()

        resultado = asistente_ia.procesar_solicitud(
            descripcion=texto_descripcion,
            ruta_audio=None,
            rutas_imagenes=rutas_temporales if rutas_temporales else None,
        )

        return JSONResponse(content=resultado)

    finally:
        for ruta in rutas_temporales:
            try:
                os.unlink(ruta)
            except OSError:
                pass

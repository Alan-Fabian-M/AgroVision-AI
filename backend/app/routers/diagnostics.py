"""
Router: /api/v1/diagnostics
Endpoint principal de AgroVision AI — Pipeline completo:
  1. Recepción multipart (imágenes, audio, GPS, notas)
  2. Consulta climática (OpenWeatherMap)
  3. Análisis IA multimodal (Gemini 2.5 Flash)
  4. Recomendación basada en grafos (Neo4j)
  5. Respuesta consolidada al frontend
"""
import uuid
import logging
from typing import Optional
from fastapi import (
    APIRouter, Depends, File, Form, HTTPException, UploadFile, status,
)

from app.services.weather_service import WeatherService, get_weather_service
from app.services.gemini_service import GeminiService, get_gemini_service
from app.services.neo4j_service import Neo4jRecommendationService, get_recommendation_service
from app.api.dependencies import RoleChecker
from app.models.user import User

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/diagnostics", tags=["Diagnostics"])

# ── Extensiones permitidas ───────────────────────────────
ALLOWED_IMAGE_TYPES = {
    "image/jpeg", "image/png", "image/webp", "image/gif", "image/bmp"
}
ALLOWED_AUDIO_TYPES = {
    "audio/mpeg", "audio/wav", "audio/ogg", "audio/webm",
    "audio/mp4", "audio/x-m4a", "audio/aac",
}


# ── POST /analyze — Pipeline completo ────────────────────
@router.post(
    "/analyze",
    status_code=status.HTTP_201_CREATED,
    summary="Análisis multimodal de cultivo",
    description=(
        "Recibe datos multimodales (imágenes, audio, texto) junto con "
        "coordenadas geográficas. Ejecuta: Clima → Gemini → Neo4j → Respuesta."
    ),
)
async def analyze_crop(
    latitude: float = Form(
        ..., ge=-90, le=90,
        description="Latitud en grados decimales"
    ),
    longitude: float = Form(
        ..., ge=-180, le=180,
        description="Longitud en grados decimales"
    ),
    user_id: str = Form(
        ..., min_length=1,
        description="UUID del usuario registrado"
    ),
    text_notes: Optional[str] = Form(
        None,
        description="Notas de texto del agricultor (opcional)"
    ),
    audio: Optional[UploadFile] = File(
        None,
        description="Archivo de audio con descripción del problema (opcional)"
    ),
    images: list[UploadFile] = File(
        ...,
        description="Lista de imágenes del cultivo afectado"
    ),
    weather_service: WeatherService = Depends(get_weather_service),
    gemini_service: GeminiService = Depends(get_gemini_service),
    neo4j_service: Neo4jRecommendationService = Depends(get_recommendation_service),
    current_user: User = Depends(RoleChecker(["ADMIN", "AGRICULTOR"])),
):
    """
    Pipeline completo de análisis multimodal.
    """
    logger.info("═══════════════════════════════════════════════════════")
    logger.info("  🚀 NUEVO ANÁLISIS DE CULTIVO RECIBIDO")
    logger.info("═══════════════════════════════════════════════════════")

    # ── 1. Validar user_id como UUID ─────────────────────
    try:
        parsed_user_id = uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"user_id debe ser un UUID válido. Recibido: '{user_id}'",
        )

    # ── 2. Validar que hay al menos una imagen ───────────
    valid_images = [img for img in images if img.filename]
    if not valid_images:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Debe enviar al menos una imagen del cultivo.",
        )

    # ── 3. Validar tipos de archivo ──────────────────────
    for img in valid_images:
        if img.content_type and img.content_type not in ALLOWED_IMAGE_TYPES:
            raise HTTPException(
                status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                detail=(
                    f"Tipo de imagen no soportado: '{img.content_type}'. "
                    f"Formatos permitidos: JPEG, PNG, WebP, GIF, BMP."
                ),
            )

    if audio and audio.filename:
        if audio.content_type and audio.content_type not in ALLOWED_AUDIO_TYPES:
            raise HTTPException(
                status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                detail=(
                    f"Tipo de audio no soportado: '{audio.content_type}'. "
                    f"Formatos permitidos: MP3, WAV, OGG, WebM, M4A, AAC."
                ),
            )
    else:
        audio = None

    logger.info(f"📍 GPS: ({latitude}, {longitude})")
    logger.info(f"📸 Imágenes: {len(valid_images)}")
    logger.info(f"🎤 Audio: {'Sí' if audio else 'No'}")
    logger.info(f"📝 Notas: {text_notes or 'Ninguna'}")

    # ── 4. PASO 1: Consultar Clima ───────────────────────
    logger.info("🌤  Paso 1/3: Consultando clima...")
    try:
        weather_data = await weather_service.get_weather(latitude, longitude)
        logger.info(
            f"   ✓ Clima: {weather_data.get('temperature')}°C, "
            f"{weather_data.get('humidity')}% humedad, "
            f"{weather_data.get('condition')}"
        )
    except HTTPException:
        logger.warning("   ⚠ Servicio de clima no disponible. Usando datos por defecto.")
        weather_data = {
            "temperature": 25.0,
            "humidity": 60,
            "condition": "Datos climáticos no disponibles",
            "icon": "01d",
        }

    # ── 5. PASO 2: Analizar con Gemini ───────────────────
    logger.info("🤖 Paso 2/3: Enviando imágenes a Gemini 2.5 Flash...")
    gemini_result = await gemini_service.analyze_images(
        images=valid_images,
        weather_data=weather_data,
        text_notes=text_notes,
    )
    pest_name = gemini_result.get("pest_name", "No identificada")
    logger.info(f"   ✓ Plaga detectada: {pest_name}")
    logger.info(f"   ✓ Severidad: {gemini_result.get('severity_level')}")
    logger.info(f"   ✓ Confianza: {gemini_result.get('confidence')}")

    # ── 6. PASO 3: Consultar Neo4j para tratamientos ─────
    logger.info("🔗 Paso 3/3: Consultando Neo4j para tratamientos...")
    neo4j_result = await neo4j_service.get_treatment_recommendation(
        pest_name=pest_name,
        current_temp=weather_data.get("temperature", 25.0),
        current_humidity=weather_data.get("humidity", 60),
    )
    logger.info(f"   ✓ Tratamientos encontrados: {len(neo4j_result.get('treatments', []))}")
    logger.info(f"   ✓ Productos encontrados: {len(neo4j_result.get('products', []))}")
    logger.info(f"   ✓ Clima favorable: {neo4j_result.get('climate_context', {}).get('climate_favorable')}")

    # ── 7. Consolidar respuesta final ────────────────────
    # Extraer recomendaciones de Neo4j como lista legible
    recomendaciones = []
    for t in neo4j_result.get("treatments", []):
        rec = t.get("name", "")
        method = t.get("application_method", "")
        if rec:
            recomendaciones.append(f"{rec}: {method}" if method else rec)

    # Si no hay tratamientos de Neo4j, usar el plan de acción de Gemini
    if not recomendaciones:
        action_plan = gemini_result.get("action_plan", "")
        if action_plan:
            recomendaciones = [action_plan]
        else:
            recomendaciones = ["Consultar con un agrónomo local para evaluación presencial."]

    # Extraer productos de Neo4j como lista legible
    productos = []
    for p in neo4j_result.get("products", []):
        name = p.get("name", "")
        dosage = p.get("dosage", "")
        if name:
            productos.append(f"{name} ({dosage})" if dosage else name)

    # Si no hay productos de Neo4j, usar los sugeridos por Gemini
    if not productos:
        productos = ["Consultar con proveedor local de insumos agrícolas"]

    response = {
        # Datos principales para Flutter
        "plaga_detectada": pest_name,
        "nivel_gravedad": gemini_result.get("severity_level", "MODERADO"),
        "prioridad": _map_severity_to_priority(gemini_result.get("severity_level", "MODERADO")),
        "confianza": gemini_result.get("confidence", 0.0),
        "recomendaciones": recomendaciones,
        "productos_sugeridos": productos,

        # Datos extendidos
        "diagnostico_ia": {
            "pest_name": pest_name,
            "pest_type": gemini_result.get("pest_type", "OTRO"),
            "severity_level": gemini_result.get("severity_level", "MODERADO"),
            "propagation_risk": gemini_result.get("propagation_risk", "MODERADO"),
            "economic_impact_usd_ha": gemini_result.get("economic_impact_estimate", 0.0),
            "description": gemini_result.get("description", ""),
            "confidence": gemini_result.get("confidence", 0.0),
        },
        "clima": weather_data,
        "conocimiento_grafo": {
            "treatments": neo4j_result.get("treatments", []),
            "products": neo4j_result.get("products", []),
            "climate_favorable": neo4j_result.get("climate_context", {}).get("climate_favorable", False),
            "affected_crops": neo4j_result.get("affected_crops", []),
            "source": neo4j_result.get("source", "no_data"),
        },
        "metadata": {
            "user_id": str(parsed_user_id),
            "latitude": latitude,
            "longitude": longitude,
            "images_count": len(valid_images),
            "audio_received": audio is not None,
        },
    }

    logger.info("═══════════════════════════════════════════════════════")
    logger.info("  ✅ ANÁLISIS COMPLETADO EXITOSAMENTE")
    logger.info(f"  Plaga: {pest_name} | Severidad: {response['nivel_gravedad']}")
    logger.info(f"  Tratamientos: {len(recomendaciones)} | Productos: {len(productos)}")
    logger.info("═══════════════════════════════════════════════════════")

    # --- Simulación de Alerta Fitosanitaria para la Hackathon ---
    try:
        from app.services.notifications import send_epidemiological_alert
        if response["prioridad"] in ["ALTA", "URGENTE"] and pest_name != "No identificada":
            send_epidemiological_alert(pest_name=pest_name, distance_km=5.0)
    except Exception as e:
        logger.error(f"Error enviando alerta fitosanitaria push: {e}")

    return response


def _map_severity_to_priority(severity: str) -> str:
    """Mapea severity_level de Gemini a prioridad para Flutter."""
    mapping = {
        "BAJO": "BAJA",
        "MODERADO": "MEDIA",
        "ALTO": "ALTA",
        "CRITICO": "URGENTE",
    }
    return mapping.get(severity.upper(), "MEDIA")

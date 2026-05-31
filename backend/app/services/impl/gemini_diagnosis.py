"""
Implementación: GeminiDiagnosisService
Servicio de diagnóstico multimodal usando Google Gemini 1.5 Flash.
Incluye:
  - Transcripción local de audio (faster-whisper)
  - Prompt anti-alucinación con Planilla de Muestreo de Plagas
  - Envío multimodal (texto + imágenes + clima)
  - Validación estricta del JSON de respuesta via Pydantic
"""
import json
import os
import logging
from typing import Any

import google.generativeai as genai
from faster_whisper import WhisperModel
from pydantic import ValidationError

from app.core.config import get_settings
from app.schemas.diagnosis import GeminiRawResponse
from app.services.interfaces.ai_diagnosis import AIDiagnosisService

logger = logging.getLogger(__name__)


# ── Catálogo Base de Plagas (Referencia para el prompt) ──
CATALOGO_PLAGAS = [
    "Roya asiática de la soya (Phakopsora pachyrhizi)",
    "Tizón tardío (Phytophthora infestans)",
    "Mildiu (Peronospora spp.)",
    "Oidio (Erysiphe spp.)",
    "Pulgón verde (Myzus persicae)",
    "Mosca blanca (Bemisia tabaci)",
    "Cochinilla harinosa (Planococcus citri)",
    "Araña roja (Tetranychus urticae)",
    "Mancha foliar (Cercospora spp.)",
    "Podredumbre radicular (Fusarium spp.)",
    "Gusano cogollero (Spodoptera frugiperda)",
    "Chinche verde (Nezara viridula)",
    "Barrenador del tallo (Diatraea saccharalis)",
    "Trips (Frankliniella spp.)",
]


class GeminiDiagnosisService(AIDiagnosisService):
    """
    Análisis multimodal de cultivos con Gemini 3.5 Flash.
    Transcripción de audio local via faster-whisper (CPU, int8).
    """

    def __init__(self) -> None:
        settings = get_settings()
        api_key = settings.GEMINI_API_KEY
        if not api_key:
            raise ValueError(
                "GEMINI_API_KEY no configurada. "
                "Agrega la clave en el archivo .env"
            )
        genai.configure(api_key=api_key)

        # Modelo Gemini con salida JSON forzada
        self._model = genai.GenerativeModel(
            "gemini-3.5-flash",
            generation_config={"response_mime_type": "application/json"},
        )
        self._whisper: WhisperModel | None = None

    def _get_whisper(self) -> WhisperModel:
        """Lazy-load de Whisper para evitar carga innecesaria al inicio."""
        if self._whisper is None:
            logger.info("Cargando modelo Whisper (small, CPU, int8)...")
            self._whisper = WhisperModel("small", device="cpu", compute_type="int8")
        return self._whisper

    def _transcribe_audio(self, audio_path: str) -> str:
        """Transcribe audio a texto usando faster-whisper local."""
        if not audio_path or not os.path.exists(audio_path):
            return ""
        try:
            whisper = self._get_whisper()
            segments, _ = whisper.transcribe(audio_path, beam_size=5, language="es")
            text = " ".join(seg.text for seg in segments)
            return text.strip()
        except Exception as e:
            logger.error(f"Error en transcripción Whisper: {e}")
            return "[Error al transcribir audio]"

    def _build_system_prompt(
        self,
        text_notes: str | None,
        audio_transcript: str,
        weather_data: dict[str, Any],
        has_images: bool,
    ) -> str:
        """
        Construye el prompt anti-alucinación con formato de
        Planilla de Muestreo de Plagas oficial.
        """
        catalogo_fmt = "\n".join(
            f"    {i+1}. {p}" for i, p in enumerate(CATALOGO_PLAGAS)
        )

        weather_json = json.dumps(weather_data, indent=2, ensure_ascii=False)

        return f"""
Eres un ingeniero agrónomo PERITO con 20 años de experiencia en diagnóstico
fitosanitario de cultivos. Tu análisis sigue estrictamente el formato de una
**PLANILLA OFICIAL DE MUESTREO DE PLAGAS** utilizada en instituciones como
SENASAG, INTA y EMBRAPA.

═══════════════════════════════════════════════════════════
  PLANILLA DE MUESTREO DE PLAGAS — ANÁLISIS DIGITAL
═══════════════════════════════════════════════════════════

▸ DATOS DE ENTRADA DEL AGRICULTOR
───────────────────────────────────────────────────────────
  • Notas de texto:         {text_notes or "Ninguna proporcionada"}
  • Transcripción de audio: {audio_transcript or "Ninguna"}
  • Imágenes adjuntas:      {"Sí — analiza cada imagen detalladamente" if has_images else "No"}

▸ DATOS CLIMÁTICOS DE LA ZONA (fuente: estación meteorológica)
───────────────────────────────────────────────────────────
{weather_json}

▸ CATÁLOGO BASE DE PLAGAS Y ENFERMEDADES (referencia primaria)
───────────────────────────────────────────────────────────
{catalogo_fmt}

═══════════════════════════════════════════════════════════
  INSTRUCCIONES DE ANÁLISIS (Chain of Thought)
═══════════════════════════════════════════════════════════

Sigue ESTRICTAMENTE estos pasos:

PASO 1 — INSPECCIÓN VISUAL:
  Analiza las imágenes (si las hay). Identifica:
  - Manchas, decoloraciones, necrosis en hojas, tallos o frutos.
  - Presencia de insectos, huevos, telas, excrementos.
  - Patrones de daño: agujeros (defoliador), galerías (barrenador),
    amarillamiento/enrollamiento (succionador), lesiones húmedas (enfermedad).

PASO 2 — IDENTIFICACIÓN TAXONÓMICA:
  Determina la plaga o enfermedad. Prioriza el catálogo base.
  Si la evidencia apunta a otra plaga no listada, nómbrala con
  su nombre científico entre paréntesis.

PASO 3 — CLASIFICACIÓN POR TIPO DE PLAGA:
  Clasifica en: DEFOLIADOR | BARRENADOR | SUCCIONADOR |
  ENFERMEDAD_FUNGICA | ENFERMEDAD_BACTERIANA | OTRO

PASO 4 — ESTIMACIÓN DE DEFOLIACIÓN (%):
  Estima el porcentaje de área foliar dañada (0 a 100).
  Método: escala visual de Horsfall-Barratt.

PASO 5 — IDENTIFICACIÓN DE CONTROLADORES BENÉFICOS:
  Si en las imágenes o descripción hay evidencia de:
  - Mariquitas (Coccinellidae)
  - Avispas parasitoides (Trichogramma)
  - Crisopas (Chrysoperla)
  - Arañas predadoras
  Regístralos. Si no hay evidencia, indica "No identificados".

PASO 6 — EVALUACIÓN DE RIESGO ECONÓMICO:
  Nivel de riesgo: BAJO | MODERADO | ALTO | CRITICO
  - BAJO: Daño < 10% defoliación, sin impacto en rendimiento.
  - MODERADO: 10-25% defoliación, rendimiento afectado levemente.
  - ALTO: 25-50% defoliación, pérdida significativa de rendimiento.
  - CRITICO: > 50% defoliación, pérdida masiva inminente.

  Estima la pérdida económica en USD por hectárea basándote en:
  - Cultivo de soya promedio: rendimiento 3 ton/ha × $350/ton = $1050/ha potencial
  - Aplica el porcentaje de pérdida según defoliación y severidad.

PASO 7 — PLAN DE ACCIÓN INMEDIATO:
  Redacta acciones concretas que el agricultor debe tomar AHORA.

═══════════════════════════════════════════════════════════
  FORMATO DE RESPUESTA — JSON EXCLUSIVO
═══════════════════════════════════════════════════════════

REGLAS CRÍTICAS:
  1. Responde SOLO con un objeto JSON válido, SIN texto antes ni después.
  2. NO uses markdown, NO uses bloques de código.
  3. Usa EXACTAMENTE las claves listadas abajo.
  4. Los valores de enums deben coincidir EXACTAMENTE (mayúsculas).
  5. Si no puedes determinar algo con certeza, usa "confidence" baja.

{{
    "risk_level": "BAJO | MODERADO | ALTO | CRITICO",
    "estimated_loss_usd": 0.0,
    "action_plan": "Plan de acción inmediato detallado",
    "pest_detected": "Nombre de la plaga (nombre científico)",
    "pest_type": "DEFOLIADOR | BARRENADOR | SUCCIONADOR | ENFERMEDAD_FUNGICA | ENFERMEDAD_BACTERIANA | OTRO",
    "defoliation_pct": 0.0,
    "beneficial_controllers": "Lista de controladores o 'No identificados'",
    "confidence": 0.0,
    "productos_sugeridos": ["Producto 1", "Producto 2"],
    "recomendaciones_tratamiento": "Recomendaciones detalladas de tratamiento"
}}
"""

    async def analyze(
        self,
        image_paths: list[str],
        audio_path: str | None,
        text_notes: str | None,
        weather_data: dict[str, Any],
    ) -> dict[str, Any]:
        """
        Ejecuta el análisis multimodal completo:
        1. Transcribe audio (si existe) con Whisper local.
        2. Construye prompt anti-alucinación.
        3. Envía a Gemini con imágenes adjuntas.
        4. Valida respuesta con Pydantic.
        """
        # 1. Transcripción de audio
        audio_transcript = ""
        if audio_path:
            audio_transcript = self._transcribe_audio(audio_path)
            logger.info(
                f"Audio transcrito ({len(audio_transcript)} chars): "
                f"{audio_transcript[:100]}..."
            )

        # 2. Construir prompt
        prompt = self._build_system_prompt(
            text_notes=text_notes,
            audio_transcript=audio_transcript,
            weather_data=weather_data,
            has_images=bool(image_paths),
        )

        # 3. Preparar contenidos multimodales
        contents: list[Any] = [prompt]

        # Adjuntar imágenes
        for img_path in image_paths:
            if img_path and os.path.exists(img_path):
                try:
                    uploaded = genai.upload_file(img_path)
                    contents.append(uploaded)
                    logger.info(f"Imagen adjuntada: {img_path}")
                except Exception as e:
                    logger.error(f"Error subiendo imagen '{img_path}': {e}")

        # 4. Llamar a Gemini
        try:
            response = self._model.generate_content(contents)
            raw_text = response.text.strip()

            # Limpiar posible markdown
            if raw_text.startswith("```"):
                raw_text = (
                    raw_text.replace("```json", "")
                    .replace("```", "")
                    .strip()
                )

            parsed = json.loads(raw_text)
            logger.info(f"Gemini respondió con JSON válido: {list(parsed.keys())}")

        except json.JSONDecodeError as e:
            logger.error(f"Gemini devolvió JSON inválido: {e}")
            return self._fallback_response(
                "Error: respuesta de IA no es JSON válido"
            )
        except Exception as e:
            logger.error(f"Error en Gemini API: {e}")
            return self._fallback_response(f"Error en Gemini API: {str(e)}")

        # 5. Validar con Pydantic
        try:
            validated = GeminiRawResponse(**parsed)
            return validated.model_dump()
        except ValidationError as e:
            logger.warning(
                f"Gemini devolvió JSON incompleto, usando valores parciales. "
                f"Errores: {e.error_count()}"
            )
            # Usar lo que se pueda del JSON, completar con defaults
            return self._merge_with_defaults(parsed)

    def _fallback_response(self, error_msg: str) -> dict[str, Any]:
        """Respuesta de fallback cuando Gemini falla completamente."""
        return {
            "risk_level": "MODERADO",
            "estimated_loss_usd": 0.0,
            "action_plan": f"Análisis no disponible. {error_msg}. "
                           "Se recomienda inspección manual del cultivo.",
            "pest_detected": "No identificada — requiere inspección manual",
            "pest_type": "OTRO",
            "defoliation_pct": 0.0,
            "beneficial_controllers": "No evaluados",
            "confidence": 0.0,
            "productos_sugeridos": [],
            "recomendaciones_tratamiento": "Consultar con un agrónomo local.",
        }

    def _merge_with_defaults(self, partial: dict) -> dict[str, Any]:
        """Combina respuesta parcial de Gemini con valores por defecto."""
        defaults = self._fallback_response("Datos parciales de la IA")
        for key in defaults:
            if key not in partial or partial[key] is None:
                partial[key] = defaults[key]

        # Asegurar que productos_sugeridos sea lista
        prods = partial.get("productos_sugeridos", [])
        if isinstance(prods, str):
            partial["productos_sugeridos"] = [
                p.strip() for p in prods.split(",") if p.strip()
            ]

        return partial

"""
gemini_service.py — Servicio de diagnóstico con Gemini 2.5 Flash.
Analiza imágenes de cultivos y retorna un JSON estructurado con el diagnóstico.
"""
import json
import base64
import logging
from typing import Any
from fastapi import UploadFile
from app.core.config import get_settings

logger = logging.getLogger(__name__)

# ── Catálogo de Plagas que coincide con Neo4j ─────────────────────────────────
CATALOGO_PLAGAS_NEO4J = [
    "Roya Asiática (Phakopsora pachyrhizi)",
    "Gusano Cogollero (Spodoptera frugiperda)",
    "Pulgón Amarillo (Melanaphis sacchari)",
    "Cochinilla (Saccharicoccus sacchari)",
    "Mancha Anillada (Corynespora cassiicola)",
    "Piricularia (Magnaporthe oryzae)",
    "Roya del Trigo (Puccinia triticina)",
]


class GeminiService:
    """
    Servicio de análisis multimodal con Google Gemini 2.5 Flash.
    Recibe imágenes como bytes y contexto climático, retorna diagnóstico en JSON.
    """

    def __init__(self):
        settings = get_settings()
        self.api_key = settings.GEMINI_API_KEY
        self._client = None
        self._model_name = "gemini-2.5-flash"

    def _get_client(self):
        """Lazy-init del cliente de Gemini."""
        if self._client is None:
            if not self.api_key:
                raise ValueError("GEMINI_API_KEY no configurada en .env")
            from google import genai
            self._client = genai.Client(api_key=self.api_key)
        return self._client

    def _build_prompt(
        self,
        weather_data: dict[str, Any],
        text_notes: str | None = None,
        num_images: int = 0,
    ) -> str:
        """Construye el prompt anti-alucinación para Gemini."""
        weather_json = json.dumps(weather_data, indent=2, ensure_ascii=False)
        catalogo_fmt = "\n".join(f"  {i+1}. {p}" for i, p in enumerate(CATALOGO_PLAGAS_NEO4J))

        return f"""
Eres un INGENIERO AGRÓNOMO PERITO con 20 años de experiencia en diagnóstico
fitosanitario de cultivos tropicales de la zona de Santa Cruz, Bolivia.

═══════════════════════════════════════════════════════
  DATOS DE ENTRADA
═══════════════════════════════════════════════════════

▸ Imágenes adjuntas: {num_images} imagen(es) del cultivo (analízalas detalladamente).
▸ Notas del agricultor: {text_notes or "Ninguna proporcionada"}
▸ Datos climáticos actuales:
{weather_json}

▸ CATÁLOGO DE PLAGAS REGISTRADAS (usa estos nombres EXACTOS si detectas alguna):
{catalogo_fmt}

═══════════════════════════════════════════════════════
  INSTRUCCIONES DE ANÁLISIS
═══════════════════════════════════════════════════════

1. INSPECCIÓN VISUAL: Analiza las manchas, decoloraciones, presencia de insectos,
   patrones de daño visibles en las imágenes.

2. IDENTIFICACIÓN: Determina la plaga o enfermedad. PRIORIZA el catálogo de arriba.
   Si detectas una plaga del catálogo, usa EXACTAMENTE el nombre listado
   (ej: "Roya Asiática", no "Roya de la Soja" ni "Asian Rust").
   Si es otra plaga no listada, nómbrala con nombre científico entre paréntesis.

3. SEVERIDAD: Clasifica en BAJO | MODERADO | ALTO | CRITICO.

4. RIESGO DE PROPAGACIÓN: Clasifica en BAJO | MODERADO | ALTO | MUY_ALTO.
   JUSTIFICA explícitamente cómo las condiciones climáticas actuales (temperatura, humedad) aceleran o frenan el ciclo biológico de esta plaga.

5. IMPACTO ECONÓMICO: Estima la pérdida en USD/hectárea.
   Referencia: Soya = 3 ton/ha × $350/ton = $1,050/ha potencial.

═══════════════════════════════════════════════════════
  FORMATO DE RESPUESTA — JSON EXCLUSIVO
═══════════════════════════════════════════════════════

REGLAS CRÍTICAS:
- Responde SOLO con un objeto JSON válido, SIN texto antes ni después.
- NO uses bloques de código markdown (como ```json).
- PERMITIDO: DENTRO de los campos de texto, DEBES usar saltos de línea (\n) para separar ideas y **negrita** para resaltar términos importantes.
- Usa EXACTAMENTE estas claves:

{{
    "pest_name": "Nombre exacto del catálogo o nombre con (nombre científico)",
    "pest_type": "DEFOLIADOR | BARRENADOR | SUCCIONADOR | ENFERMEDAD_FUNGICA | ENFERMEDAD_BACTERIANA | OTRO",
    "severity_level": "BAJO | MODERADO | ALTO | CRITICO",
    "propagation_risk": "BAJO | MODERADO | ALTO | MUY_ALTO",
    "economic_impact_estimate": 0.0,
    "confidence": 0.0,
    "description": "Descripción breve del diagnóstico, detallando el impacto del clima actual en la proliferación.",
    "action_plan": "Paso 1: Haz esto.\nPaso 2: Usa **este producto**.\nPaso 3: Revisa esto."
}}
"""
    async def analyze_images(
        self,
        images: list[UploadFile],
        weather_data: dict[str, Any],
        text_notes: str | None = None,
    ) -> dict[str, Any]:
        """
        Envía las imágenes a Gemini 3.5 Flash y retorna el diagnóstico en JSON.
        """
        try:
            client = self._get_client()
            from google.genai import types

            # Construir el prompt
            prompt = self._build_prompt(
                weather_data=weather_data,
                text_notes=text_notes,
                num_images=len(images),
            )

            # Preparar contenidos multimodales
            contents: list[Any] = []

            # Leer cada imagen como bytes y adjuntarla
            for img in images:
                img_bytes = await img.read()
                content_type = img.content_type or "image/jpeg"
                contents.append(
                    types.Part.from_bytes(data=img_bytes, mime_type=content_type)
                )
                await img.seek(0)  # Reset para posible relectura

            # Añadir el prompt de texto
            contents.append(prompt)

            # Llamar a Gemini
            logger.info(f"📤 Enviando {len(images)} imagen(es) a Gemini {self._model_name}...")
            response = client.models.generate_content(
                model=self._model_name,
                contents=contents,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    temperature=0.2,
                ),
            )

            raw_text = response.text.strip()
            logger.info(f"📥 Respuesta cruda de Gemini ({len(raw_text)} chars)")

            # Limpiar posible markdown wrapper
            if raw_text.startswith("```"):
                raw_text = raw_text.replace("```json", "").replace("```", "").strip()

            parsed = json.loads(raw_text)
            logger.info(f"✓ Gemini respondió con JSON válido: {list(parsed.keys())}")

            # Validar campos mínimos
            return self._validate_response(parsed)

        except json.JSONDecodeError as e:
            logger.error(f"Gemini devolvió JSON inválido: {e}")
            return self._fallback_response("La IA devolvió una respuesta mal formateada")

        except Exception as e:
            logger.error(f"Error en Gemini API: {e}", exc_info=True)
            return self._fallback_response(f"Error del servicio de IA: {str(e)[:200]}")

    def _validate_response(self, data: dict) -> dict[str, Any]:
        """Valida y normaliza la respuesta de Gemini."""
        defaults = {
            "pest_name": "No identificada",
            "pest_type": "OTRO",
            "severity_level": "MODERADO",
            "propagation_risk": "MODERADO",
            "economic_impact_estimate": 0.0,
            "confidence": 0.0,
            "description": "Sin descripción disponible",
            "action_plan": "Se recomienda inspección manual del cultivo.",
        }
        for key, default in defaults.items():
            if key not in data or data[key] is None:
                data[key] = default

        # Asegurar tipos numéricos
        for num_key in ("economic_impact_estimate", "confidence"):
            try:
                data[num_key] = float(data[num_key])
            except (ValueError, TypeError):
                data[num_key] = 0.0

        return data

    def _fallback_response(self, error_msg: str) -> dict[str, Any]:
        """Respuesta de fallback cuando Gemini falla."""
        return {
            "pest_name": "No identificada — requiere inspección manual",
            "pest_type": "OTRO",
            "severity_level": "MODERADO",
            "propagation_risk": "MODERADO",
            "economic_impact_estimate": 0.0,
            "confidence": 0.0,
            "description": f"Análisis automático no disponible. {error_msg}",
            "action_plan": "Consultar con un agrónomo local para inspección presencial.",
        }


def get_gemini_service() -> GeminiService:
    """Factory function para inyección de dependencias en FastAPI."""
    return GeminiService()

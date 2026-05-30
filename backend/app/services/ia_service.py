import os
import json
from abc import ABC, abstractmethod
from faster_whisper import WhisperModel
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

# CATÁLOGO BASE DE PLAGAS Y ENFERMEDADES (AGRÍCOLA)
# La IA debe referenciarse primariamente de este catálogo.
CATALOGO_PLAGAS = [
    "Roya",
    "Tizón tardío",
    "Mildiu",
    "Oidio",
    "Pulgón",
    "Mosca blanca",
    "Cochinilla",
    "Araña roja",
    "Mancha foliar",
    "Podredumbre radicular"
]


# 1. MOTOR DE TRANSCRIPCIÓN LOCAL
class TranscriptionService:
    def __init__(self):
        # Configuramos para CPU con int8 para máxima eficiencia local
        self.model = WhisperModel("small", device="cpu", compute_type="int8")

    def transcribir(self, ruta_audio: str) -> str:
        if not ruta_audio or not os.path.exists(ruta_audio):
            return ""
        try:
            segments, info = self.model.transcribe(ruta_audio, beam_size=5, language="es")
            texto_completo = " ".join([segment.text for segment in segments])
            return texto_completo.strip()
        except Exception as e:
            print(f"Error en Whisper: {e}")
            return "[Error al transcribir audio]"


# 2. PATRÓN ESTRATEGIA PARA IA (LLMs)
class IAProvider(ABC):
    """Clase base para cualquier proveedor de Inteligencia Artificial."""
    @abstractmethod
    def analizar_cultivo(
        self,
        texto_transcrito: str,
        descripcion: str,
        rutas_imagenes: list[str] | None = None,
    ) -> dict:
        pass


class GeminiProvider(IAProvider):
    """Implementación específica para Google Gemini 2.5 Flash."""
    def __init__(self):
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError("Falta GEMINI_API_KEY en el entorno.")
        genai.configure(api_key=api_key)

        # Forzamos la salida en formato JSON
        self.model = genai.GenerativeModel(
            "gemini-2.5-flash",
            generation_config={"response_mime_type": "application/json"}
        )

    def analizar_cultivo(
        self,
        texto_transcrito: str,
        descripcion: str,
        rutas_imagenes: list[str] | None = None,
    ) -> dict:
        # ── Construir la sección del catálogo para el prompt ─────
        catalogo_formateado = "\n".join(
            f"  - {nombre}" for nombre in CATALOGO_PLAGAS
        )

        prompt = f"""
        Eres un perito agrónomo experto en diagnóstico de cultivos, plagas y enfermedades.

        Tu tarea es analizar el estado de un cultivo siguiendo un razonamiento
        paso a paso (Chain of Thought) y generar un diagnóstico técnico preliminar.

        ══════════════════════════════════════════
        DATOS DEL CULTIVO / REPORTE
        ══════════════════════════════════════════
        Descripción del agricultor: "{descripcion if descripcion else 'Ninguna'}"
        Transcripción de audio:     "{texto_transcrito if texto_transcrito else 'Ninguno'}"
        Imágenes adjuntas:          {"Sí" if rutas_imagenes else "No"}

        ══════════════════════════════════════════
        CATÁLOGO BASE DE PLAGAS Y ENFERMEDADES
        ══════════════════════════════════════════
        Utiliza este catálogo como referencia principal para identificar el problema. 
        Si hay mucha evidencia de una plaga diferente, puedes sugerirla, pero prioriza estas:

{catalogo_formateado}

        ══════════════════════════════════════════
        INSTRUCCIONES — FLUJO DE RAZONAMIENTO
        ══════════════════════════════════════════
        Sigue estrictamente estos pasos:

        PASO 1 — ANÁLISIS:
        Observa las imágenes (si las hay), lee la descripción y la transcripción de audio. 
        Identifica síntomas visuales en las hojas, tallos o frutos (manchas, decoloración, insectos visibles, marchitez).

        PASO 2 — IDENTIFICACIÓN DE PLAGA (plaga_detectada):
        Determina qué plaga o enfermedad está afectando el cultivo. Usa el catálogo base preferentemente.

        PASO 3 — RECOMENDACIONES TÉCNICAS (recomendaciones):
        Redacta recomendaciones breves y directas sobre qué acciones inmediatas debe tomar el agricultor (ej. aislar, reducir riego, podar áreas afectadas).

        PASO 4 — PRODUCTOS SUGERIDOS (productos_sugeridos):
        Proponer una lista genérica de productos agroquímicos o tratamientos (ej. "Insecticida piretroide", "Fungicida cúprico"). 
        Estos productos servirán para una fase posterior de evaluación con grafos de conocimiento.

        ══════════════════════════════════════════
        REGLAS DE EVALUACIÓN
        ══════════════════════════════════════════
        Define la PRIORIDAD de atención:
        - URGENTE: Riesgo de pérdida masiva de la cosecha inminente.
        - ALTA: Propagación rápida, daño severo.
        - MEDIA: Problema que requiere atención pero el daño avanza moderadamente.
        - BAJA: Daño incipiente, estético o muy localizado.

        Define el NIVEL DE GRAVEDAD del daño actual:
        - CRITICO: Planta muerta o daño irreversible generalizado.
        - GRAVE: Daño estructural profundo, impacto directo fuerte en rendimiento.
        - MEDIO: Afección clara pero tratable y reversible.
        - LEVE: Daños menores o infección en fase temprana.

        Evalúa la CONFIANZA del diagnóstico (0.0 a 1.0):
        - 0.0 - 0.4 → Información insuficiente o ambigua.
        - 0.5 - 0.7 → Diagnóstico probable.
        - 0.8 - 1.0 → Diagnóstico claro y con evidencia fuerte.

        ══════════════════════════════════════════
        FORMATO DE RESPUESTA (OBLIGATORIO JSON)
        ══════════════════════════════════════════
        Responde SOLO con este JSON válido:

        {{
            "plaga_detectada": "Nombre exacto de la plaga",
            "nivel_gravedad": "LEVE" | "MEDIO" | "GRAVE" | "CRITICO",
            "prioridad": "BAJA" | "MEDIA" | "ALTA" | "URGENTE",
            "recomendaciones": "Texto de la recomendación técnica",
            "productos_sugeridos": ["Nombre del tipo de producto 1", "Nombre del tipo de producto 2"],
            "confianza": 0.0
        }}
        """

        contenidos = [prompt]

        # ── Adjuntar TODAS las imágenes disponibles ──────────────
        if rutas_imagenes:
            for ruta in rutas_imagenes:
                if ruta and os.path.exists(ruta):
                    try:
                        imagen_file = genai.upload_file(ruta)
                        contenidos.append(imagen_file)
                    except Exception as e:
                        print(f"Error subiendo imagen '{ruta}': {e}")

        try:
            response = self.model.generate_content(contenidos)
            texto = response.text.strip()
            if texto.startswith("```"):
                texto = texto.replace("```json", "").replace("```", "").strip()
            resultado = json.loads(texto)

            # Para la base de datos se requiere un Text. 
            # Convertimos la lista devuelta por la IA a una cadena separada por comas.
            productos_lista = resultado.get("productos_sugeridos", [])
            if isinstance(productos_lista, list):
                productos_str = ", ".join(productos_lista)
            else:
                productos_str = str(productos_lista)

            return {
                "plaga_detectada": resultado.get("plaga_detectada", "No identificada"),
                "nivel_gravedad": resultado.get("nivel_gravedad", "MEDIO"),
                "prioridad": resultado.get("prioridad", "MEDIA"),
                "recomendaciones": resultado.get("recomendaciones", "Sin información suficiente"),
                "productos_sugeridos": productos_str,
                "confianza": float(resultado.get("confianza", 0.0)),
            }
        except Exception as e:
            print(f"Error en Gemini API: {e}")
            return {
                "plaga_detectada": "Error en el análisis",
                "nivel_gravedad": "MEDIO",
                "prioridad": "MEDIA",
                "recomendaciones": "No se pudo procesar el incidente",
                "productos_sugeridos": "",
                "confianza": 0.0,
            }


# 3. EL ORQUESTADOR PRINCIPAL
class AsistenteCultivo:
    def __init__(self, ia_provider: IAProvider):
        self.transcriptor = TranscriptionService()
        self.ia = ia_provider

    def procesar_solicitud(
        self,
        descripcion: str,
        ruta_audio: str = None,
        rutas_imagenes: list[str] | None = None,
    ) -> dict:
        texto_audio = ""
        if ruta_audio:
            texto_audio = self.transcriptor.transcribir(ruta_audio)
        diagnostico = self.ia.analizar_cultivo(texto_audio, descripcion, rutas_imagenes)
        return diagnostico

# Inyección de dependencias para uso en el router
asistente_ia = AsistenteCultivo(ia_provider=GeminiProvider())

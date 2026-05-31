import os
import google.generativeai as genai
from fastapi import APIRouter
from pydantic import BaseModel
from typing import List
from dotenv import load_dotenv

load_dotenv()

router = APIRouter(prefix="/advisor", tags=["Advisor"])

genai.configure(api_key=os.getenv("GEMINI_API_KEY", ""))

_model = genai.GenerativeModel(
    "gemini-2.5-flash",
    system_instruction=(
        "Eres AgroGuardian, un asesor agrónomo experto en cultivos de Bolivia y Latinoamérica. "
        "Ayudas a agricultores con diagnósticos de plagas, enfermedades, recomendaciones de "
        "agroquímicos y buenas prácticas agrícolas. Responde siempre en español, de forma clara "
        "y práctica. Si el agricultor describe síntomas, sugiere posibles causas y soluciones. "
        "Sé conciso: máximo 3-4 oraciones por respuesta."
    ),
)


class MensajeIn(BaseModel):
    mensaje: str
    historial: List[dict] = []


@router.post("/chat")
async def chat_advisor(body: MensajeIn):
    try:
        # Construir historial para contexto
        historial_gemini = []
        for item in body.historial[-10:]:  # máximo 10 turnos anteriores
            historial_gemini.append({
                "role": item.get("role", "user"),
                "parts": [item.get("content", "")],
            })

        chat = _model.start_chat(history=historial_gemini)
        response = chat.send_message(body.mensaje)
        return {"respuesta": response.text.strip(), "ok": True}

    except Exception as e:
        return {
            "respuesta": "Lo siento, no pude procesar tu consulta ahora. Intenta de nuevo.",
            "ok": False,
            "error": str(e),
        }

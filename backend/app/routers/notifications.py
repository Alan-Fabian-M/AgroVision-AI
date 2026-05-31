from fastapi import APIRouter, Body
from pydantic import BaseModel
from app.services.notifications import register_token

router = APIRouter(prefix="/notifications", tags=["Notifications"])

class TokenRequest(BaseModel):
    user_id: str
    fcm_token: str

@router.post("/register-token")
def register_device_token(request: TokenRequest):
    """Guarda el FCM Token de un dispositivo."""
    register_token(request.user_id, request.fcm_token)
    return {"status": "success", "message": "Token guardado correctamente"}

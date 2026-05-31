import firebase_admin
from firebase_admin import credentials, messaging
import os
import logging

logger = logging.getLogger(__name__)

# Diccionario temporal para guardar los tokens en memoria durante la hackathon
# En producción, esto debería ir a la base de datos (tabla Users o Devices).
device_tokens = {}

def init_firebase():
    """Inicializa la app de Firebase Admin SDK."""
    try:
        if not firebase_admin._apps:
            # Buscar el archivo serviceAccountKey.json en la raíz del backend
            key_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'serviceAccountKey.json')
            if os.path.exists(key_path):
                cred = credentials.Certificate(key_path)
                firebase_admin.initialize_app(cred)
                logger.info("Firebase Admin inicializado correctamente.")
            else:
                logger.warning(f"No se encontró {key_path}. Las notificaciones Push no funcionarán hasta agregarlo.")
    except Exception as e:
        logger.error(f"Error inicializando Firebase: {e}")

# Llamar a inicializar cuando se importe el módulo
init_firebase()

def register_token(user_id: str, token: str):
    """Guarda o actualiza el token del dispositivo de un usuario."""
    device_tokens[user_id] = token
    logger.info(f"Token registrado para usuario {user_id}")

def get_token(user_id: str) -> str:
    """Obtiene el token de un usuario."""
    return device_tokens.get(user_id)

def send_epidemiological_alert(pest_name: str, distance_km: float = 5.0):
    """
    Envía una alerta a TODOS los dispositivos registrados (Simulando cercanía de 5km).
    """
    if not firebase_admin._apps:
        logger.error("Firebase no está inicializado. No se puede enviar el push.")
        return False
        
    if not device_tokens:
        logger.warning("No hay dispositivos registrados para recibir alertas.")
        return False

    # Crear el mensaje
    title = "⚠️ Alerta Fitosanitaria"
    body = f"Se ha detectado {pest_name} a {distance_km}km de tu ubicación. Toca para ver detalles."
    
    # Enviar a todos los tokens registrados (Multicast)
    tokens = list(device_tokens.values())
    
    try:
        message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title=title,
                body=body
            ),
            data={
                "type": "epidemiological_alert",
                "pest_name": pest_name,
                "click_action": "FLUTTER_NOTIFICATION_CLICK"
            },
            tokens=tokens,
        )
        response = messaging.send_each_for_multicast(message)
        logger.info(f"Alerta enviada. Éxito: {response.success_count}, Fallos: {response.failure_count}")
        return True
    except Exception as e:
        logger.error(f"Error al enviar notificación push: {e}")
        return False

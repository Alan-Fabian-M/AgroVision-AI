"""
app.models — Registro central de todos los modelos SQLAlchemy.
Importar aquí garantiza que Base.metadata conozca todas las tablas
al momento de ejecutar create_all() o generar migraciones con Alembic.
"""
from app.models.user import User  # noqa: F401
from app.models.diagnosis import Diagnosis, Attachment  # noqa: F401

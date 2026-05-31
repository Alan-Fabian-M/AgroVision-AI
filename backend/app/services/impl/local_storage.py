"""
Implementación: LocalFileStorageService
Almacena archivos en el sistema de archivos local bajo ./uploads/.
Devuelve URLs estáticas relativas para acceso HTTP.
"""
import os
import uuid
from pathlib import Path

import aiofiles
from fastapi import UploadFile

from app.services.interfaces.file_storage import FileStorageService
from app.core.config import get_settings


class LocalFileStorageService(FileStorageService):
    """Almacenamiento local de archivos en disco."""

    def __init__(self) -> None:
        settings = get_settings()
        self._base_dir = Path(settings.UPLOAD_DIR)
        self._static_prefix = settings.STATIC_URL_PREFIX

    async def save(
        self,
        file: UploadFile,
        subdir: str = "general",
    ) -> tuple[str, str]:
        """
        Guarda el archivo en disco y devuelve (file_url, local_path).
        Genera un nombre único con UUID para evitar colisiones.
        """
        # Construir directorio destino
        target_dir = self._base_dir / subdir
        target_dir.mkdir(parents=True, exist_ok=True)

        # Nombre único: uuid_originalname
        safe_filename = file.filename or "unnamed"
        unique_name = f"{uuid.uuid4().hex}_{safe_filename}"
        file_path = target_dir / unique_name

        # Escritura asíncrona del archivo
        async with aiofiles.open(file_path, "wb") as out_file:
            content = await file.read()
            await out_file.write(content)

        # Rutas de retorno
        local_path = str(file_path.resolve())
        file_url = f"{self._static_prefix}/{subdir}/{unique_name}"

        return file_url, local_path

    async def delete(self, local_path: str) -> None:
        """Elimina un archivo del disco si existe."""
        path = Path(local_path)
        if path.exists():
            os.remove(path)

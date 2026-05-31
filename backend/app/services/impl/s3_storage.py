"""
Placeholder: AWSS3StorageService
Preparado para migración a Amazon S3 cuando haya presupuesto.
Hereda de FileStorageService pero NO está implementado aún.
"""
from fastapi import UploadFile

from app.services.interfaces.file_storage import FileStorageService


class AWSS3StorageService(FileStorageService):
    """
    Implementación futura de almacenamiento en Amazon S3.

    TODO: Implementar cuando se disponga de credenciales AWS.
    Requerirá:
      - boto3 / aioboto3
      - Variables de entorno: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY,
        AWS_S3_BUCKET_NAME, AWS_REGION.
      - Configurar políticas de bucket para acceso público/firmado.
    """

    def __init__(self) -> None:
        # TODO: Inicializar cliente S3
        pass

    async def save(
        self,
        file: UploadFile,
        subdir: str = "general",
    ) -> tuple[str, str]:
        """
        Subirá el archivo a S3 y retornará:
          - file_url: URL pública o firmada del objeto en S3.
          - local_path: Key del objeto en el bucket (no ruta local).
        """
        raise NotImplementedError(
            "AWSS3StorageService no está implementado. "
            "Migrar a S3 requiere configurar credenciales AWS."
        )

    async def delete(self, local_path: str) -> None:
        """Eliminará el objeto del bucket S3."""
        raise NotImplementedError(
            "AWSS3StorageService.delete() no está implementado."
        )

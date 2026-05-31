"""
Interfaz: FileStorageService
Define el contrato para cualquier servicio de almacenamiento de archivos.
Implementaciones concretas: LocalFileStorageService, AWSS3StorageService.
"""
from abc import ABC, abstractmethod
from fastapi import UploadFile


class FileStorageService(ABC):
    """Contrato para almacenamiento de archivos."""

    @abstractmethod
    async def save(
        self,
        file: UploadFile,
        subdir: str = "general",
    ) -> tuple[str, str]:
        """
        Persiste un archivo y devuelve sus rutas.

        Args:
            file: Archivo subido via FastAPI UploadFile.
            subdir: Subdirectorio lógico (ej. 'images', 'audio').

        Returns:
            tuple[file_url, local_path]:
                - file_url: ruta relativa accesible por HTTP (ej. /static/uploads/images/abc.jpg)
                - local_path: ruta absoluta en el disco del servidor.
        """
        ...

    @abstractmethod
    async def delete(self, local_path: str) -> None:
        """
        Elimina un archivo del almacenamiento.

        Args:
            local_path: Ruta absoluta del archivo a eliminar.
        """
        ...

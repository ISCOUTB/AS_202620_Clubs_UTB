from abc import ABC, abstractmethod

from linkclub.domain.publicacion import Publicacion


class CrearPublicacionPort(ABC):
    @abstractmethod
    def ejecutar(
        self,
        club_id: str,
        autor_id: str,
        titulo: str,
        contenido: str,
        tipo: str,
        opciones: dict | list | None = None,
        idempotency_key: str | None = None,
        imagen_url: str | None = None,
    ) -> Publicacion:
        ...
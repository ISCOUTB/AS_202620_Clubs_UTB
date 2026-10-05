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
        opciones: list[str] | None = None,
    ) -> Publicacion:
        ...
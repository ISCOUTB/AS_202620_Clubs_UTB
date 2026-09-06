from abc import ABC, abstractmethod

from linkclub.domain.publicacion import Publicacion


class PublicacionRepositoryPort(ABC):
    @abstractmethod
    def guardar(self, publicacion: Publicacion) -> Publicacion:
        ...

    @abstractmethod
    def listar_por_club(self, club_id: str) -> list[Publicacion]:
        ...
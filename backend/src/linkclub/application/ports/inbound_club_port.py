from abc import ABC, abstractmethod

from linkclub.domain.club import Club


class ListarClubesPort(ABC):
    @abstractmethod
    def ejecutar(self, q: str | None = None, categoria: str | None = None) -> list[Club]:
        ...


class ObtenerClubPort(ABC):
    @abstractmethod
    def ejecutar(self, club_id: str) -> Club:
        ...
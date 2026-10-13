from abc import ABC, abstractmethod

from linkclub.domain.club import Club


class ClubRepositoryPort(ABC):
    @abstractmethod
    def listar(self, q: str | None = None, categoria: str | None = None) -> list[Club]:
        ...

    @abstractmethod
    def obtener(self, club_id: str) -> Club | None:
        ...
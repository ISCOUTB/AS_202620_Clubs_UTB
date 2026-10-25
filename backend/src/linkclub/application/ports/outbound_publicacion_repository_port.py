from abc import ABC, abstractmethod
from typing import Optional

from linkclub.domain.publicacion import Publicacion

class PublicacionRepositoryPort(ABC):
    @abstractmethod
    def obtener_por_idempotencia(self, idempotency_key: str) -> Optional[Publicacion]:
        ...

    @abstractmethod
    def guardar(self, publicacion: Publicacion) -> Publicacion:
        ...

    @abstractmethod
    def listar_por_club(self, club_id: int) -> list[Publicacion]:
        ...
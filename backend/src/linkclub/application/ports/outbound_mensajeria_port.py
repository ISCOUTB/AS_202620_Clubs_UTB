from abc import ABC, abstractmethod

from linkclub.application.messaging.mensaje import Mensaje


class ErrorTransitorio(Exception):
    """Falla recuperable: se reintenta."""


class PublicadorPort(ABC):
    @abstractmethod
    def publicar(self, mensaje: Mensaje) -> None: ...


class OutboxPort(ABC):
    @abstractmethod
    def registrar(self, mensaje: Mensaje) -> None: ...
    @abstractmethod
    def pendientes(self) -> list[Mensaje]: ...
    @abstractmethod
    def marcar_enviado(self, message_id: str) -> None: ...


class DeduplicacionPort(ABC):
    @abstractmethod
    def ya_procesado(self, message_id: str) -> bool: ...
    @abstractmethod
    def marcar(self, message_id: str) -> None: ...


class NotificadorPort(ABC):
    @abstractmethod
    def notificar(self, club_id: str, publicacion_id: str, titulo: str) -> None: ...
from abc import ABC, abstractmethod


class TokenInvalido(Exception):
    ...


class AuthNoDisponible(Exception):
    ...


class AuthPort(ABC):
    @abstractmethod
    def verificar(self, token: str) -> str:
        """Devuelve el autor_id (identidad). Nunca claims ni correo."""
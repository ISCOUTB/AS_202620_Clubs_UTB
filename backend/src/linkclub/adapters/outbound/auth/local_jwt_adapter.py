import jwt

from linkclub.application.ports.outbound_auth_port import (
    AuthPort,
    TokenInvalido,
)

class LocalJwtAuthAdapter(AuthPort):
    def __init__(self, secret_key: str):
        self._secret_key = secret_key
        self._algorithm = "HS256"

    def verificar(self, token: str) -> str:
        try:
            claims = jwt.decode(
                token,
                self._secret_key,
                algorithms=[self._algorithm],
                options={"require": ["exp", "sub"]},
            )
        except jwt.PyJWTError as e:
            raise TokenInvalido("El token es inválido o ha expirado") from e
        
        return claims["sub"]

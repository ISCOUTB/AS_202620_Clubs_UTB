import jwt
from jwt import PyJWKClient, PyJWKClientConnectionError

from linkclub.application.ports.outbound_auth_port import (
    AuthPort,
    AuthNoDisponible,
    TokenInvalido,
)


class SupabaseJwtAuthAdapter(AuthPort):
    def __init__(self, supabase_url: str):
        self._issuer = f"{supabase_url.rstrip('/')}/auth/v1"
        self._jwks = PyJWKClient(f"{self._issuer}/.well-known/jwks.json")

    def verificar(self, token: str) -> str:
        try:
            key = self._jwks.get_signing_key_from_jwt(token).key
            claims = jwt.decode(
                token,
                key,
                algorithms=["ES256"],
                audience="authenticated",
                issuer=self._issuer,
                options={"require": ["exp", "sub"]},
            )
        except PyJWKClientConnectionError as e:
            raise AuthNoDisponible() from e
        except jwt.PyJWTError as e:
            raise TokenInvalido() from e
        return claims["sub"]
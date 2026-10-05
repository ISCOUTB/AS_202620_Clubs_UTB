import os
from functools import lru_cache

from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from linkclub.adapters.outbound.auth.supabase_jwt_adapter import SupabaseJwtAuthAdapter
from linkclub.application.ports.outbound_auth_port import (
    AuthNoDisponible,
    AuthPort,
    TokenInvalido,
)

bearer = HTTPBearer(auto_error=False)


@lru_cache
def get_auth_port() -> AuthPort:
    return SupabaseJwtAuthAdapter(os.environ["SUPABASE_URL"])


def require_auth(
    cred: HTTPAuthorizationCredentials | None = Depends(bearer),
    auth: AuthPort = Depends(get_auth_port),
) -> str:
    if cred is None:
        raise HTTPException(status_code=401, detail="Falta el token de sesión")
    try:
        return auth.verificar(cred.credentials)
    except TokenInvalido:
        raise HTTPException(status_code=401, detail="Token inválido o expirado")
    except AuthNoDisponible:
        raise HTTPException(status_code=503, detail="Servicio de autenticación no disponible")
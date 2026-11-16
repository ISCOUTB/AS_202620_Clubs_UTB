import os
from functools import lru_cache
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from linkclub.adapters.outbound.auth.local_jwt_adapter import LocalJwtAuthAdapter
from linkclub.adapters.outbound.postgres.database import get_db
from linkclub.adapters.outbound.postgres.models.usuario_model import UsuarioModel
from linkclub.application.ports.outbound_auth_port import (
    AuthNoDisponible,
    AuthPort,
    TokenInvalido,
)

bearer = HTTPBearer(auto_error=False)


@lru_cache
def get_auth_port() -> AuthPort:
    secret_key = os.environ.get("JWT_SECRET")
    if not secret_key:
        raise ValueError(
            "ERROR CRÍTICO: La variable de entorno JWT_SECRET no está configurada. "
            "La aplicación no puede iniciar de forma segura."
        )
    return LocalJwtAuthAdapter(secret_key)


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


def get_current_user(
    identidad: Annotated[str, Depends(require_auth)],
    db: Annotated[Session, Depends(get_db)],
) -> UsuarioModel:
    usuario = (
        db.query(UsuarioModel)
        .filter(
            (UsuarioModel.matricula == identidad) | (UsuarioModel.correo == identidad)
        )
        .first()
    )
    if not usuario or usuario.estado_cuenta != "ACTIVO":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario inactivo o no encontrado.",
        )
    return usuario


def require_superadmin(
    usuario: Annotated[UsuarioModel, Depends(get_current_user)],
) -> UsuarioModel:
    if usuario.rol != "SUPERADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acceso exclusivo para desarrolladores administradores.",
        )
    return usuario
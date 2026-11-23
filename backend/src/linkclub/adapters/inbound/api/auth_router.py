import os
import uuid
from datetime import datetime, timedelta, timezone
from typing import Annotated, Optional

import bcrypt
import jwt
from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel, ConfigDict, Field, field_validator
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from linkclub.adapters.outbound.postgres.database import get_db
from linkclub.adapters.outbound.postgres.models.club_model import ClubModel
from linkclub.adapters.outbound.postgres.models.solicitud_admin_model import (
    SolicitudAdminClubModel,
)
from linkclub.adapters.outbound.postgres.models.usuario_model import UsuarioModel

router = APIRouter(tags=["auth"])

JWT_SECRET = os.environ.get("JWT_SECRET")
if not JWT_SECRET:
    raise ValueError(
        "ERROR CRÍTICO: La variable de entorno JWT_SECRET no está configurada. "
        "La aplicación no puede iniciar de forma segura."
    )

JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_DAYS = int(os.environ.get("JWT_EXPIRES_DAYS", "7"))


def _hashear_password(password: str) -> str:
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")


def _verificar_password(password_plano: str, password_hash: str) -> bool:
    if not password_plano or not password_hash:
        return False
    try:
        return bcrypt.checkpw(
            password_plano.encode("utf-8"),
            password_hash.encode("utf-8"),
        )
    except (ValueError, TypeError):
        return False


class CrearUsuarioRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    nombre: str = Field(min_length=1)
    matricula: str = Field(pattern=r"^T[0-9]{7,8}$")
    correo: str = Field(pattern=r"^[^@\s]+@utb\.edu\.co$")
    password: str = Field(min_length=6, max_length=72)
    solicitar_admin: bool = False
    club_id: Optional[str] = None
    justificacion_admin: Optional[str] = None

    @field_validator("nombre", mode="before")
    @classmethod
    def normalizar_nombre(cls, v):
        return v.strip() if isinstance(v, str) else v

    @field_validator("matricula", mode="before")
    @classmethod
    def normalizar_matricula(cls, v):
        return v.strip().upper() if isinstance(v, str) else v

    @field_validator("correo", mode="before")
    @classmethod
    def normalizar_correo(cls, v):
        return v.strip().lower() if isinstance(v, str) else v


class UsuarioResponse(BaseModel):
    id: str
    nombre: str
    matricula: str
    correo: str
    rol: str
    verificado: bool
    club_administrado_id: Optional[str] = None
    creado_en: datetime

    model_config = ConfigDict(from_attributes=True)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str


def crear_token_acceso(data: dict, expires_delta: timedelta) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + expires_delta
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, JWT_SECRET, algorithm=JWT_ALGORITHM)


@router.post(
    "/auth/registro",
    response_model=UsuarioResponse,
    status_code=status.HTTP_201_CREATED,
    responses={409: {"description": "El correo o la matrícula ya están registrados"}},
)
def registrar_usuario(
    payload: CrearUsuarioRequest,
    db: Annotated[Session, Depends(get_db)],
):
    correo_normalizado = payload.correo.strip().lower()
    matricula_normalizada = payload.matricula.strip().upper()
    club_uuid: Optional[uuid.UUID] = None

    if payload.solicitar_admin:
        if not payload.club_id or not payload.justificacion_admin or not payload.justificacion_admin.strip():
            raise HTTPException(
                status_code=422,
                detail="Debes seleccionar un club y escribir una justificación para solicitar Admin de Club.",
            )
        try:
            club_uuid = uuid.UUID(payload.club_id)
        except ValueError as exc:
            raise HTTPException(status_code=422, detail="ID de club inválido.") from exc

        if not db.query(ClubModel).filter(ClubModel.id == club_uuid).first():
            raise HTTPException(status_code=404, detail="El club seleccionado no existe.")

    if db.query(UsuarioModel).filter(func.lower(UsuarioModel.correo) == correo_normalizado).first():
        raise HTTPException(status_code=409, detail="El correo ya está registrado")

    if db.query(UsuarioModel).filter(UsuarioModel.matricula == matricula_normalizada).first():
        raise HTTPException(status_code=409, detail="La matrícula ya está registrada")

    nuevo_usuario = UsuarioModel(
        matricula=matricula_normalizada,
        nombre=payload.nombre.strip(),
        correo=correo_normalizado,
        password_hash=_hashear_password(payload.password),
        rol="ADMIN_CLUB" if payload.solicitar_admin else "ESTUDIANTE",
        verificado=not payload.solicitar_admin,
    )

    try:
        db.add(nuevo_usuario)
        db.flush()

        if payload.solicitar_admin and club_uuid is not None:
            db.add(
                SolicitudAdminClubModel(
                    usuario_matricula=matricula_normalizada,
                    club_id=club_uuid,
                    justificacion=payload.justificacion_admin.strip(),
                )
            )

        db.commit()
        db.refresh(nuevo_usuario)
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="El correo, la matrícula ya existen o el club seleccionado no es válido.",
        ) from exc

    return UsuarioResponse(
        id=nuevo_usuario.matricula,
        nombre=nuevo_usuario.nombre,
        matricula=nuevo_usuario.matricula,
        correo=nuevo_usuario.correo,
        rol=nuevo_usuario.rol,
        verificado=nuevo_usuario.verificado,
        club_administrado_id=(
            str(nuevo_usuario.club_administrado_id)
            if nuevo_usuario.club_administrado_id
            else None
        ),
        creado_en=nuevo_usuario.creado_en,
    )


@router.post("/auth/login", response_model=TokenResponse)
async def iniciar_sesion(
    request: Request,
    db: Annotated[Session, Depends(get_db)],
):
    content_type = request.headers.get("content-type", "")
    if "application/json" in content_type:
        try:
            body = await request.json()
        except Exception as exc:
            raise HTTPException(status_code=422, detail="Cuerpo JSON inválido.") from exc
        if not isinstance(body, dict):
            raise HTTPException(status_code=422, detail="El cuerpo debe ser un objeto JSON.")
        identificador = str(body.get("correo") or body.get("username") or "").strip().lower()
        password = str(body.get("password") or "")
    else:
        form = await request.form()
        identificador = str(form.get("username") or form.get("correo") or "").strip().lower()
        password = str(form.get("password") or "")

    usuario = (
        db.query(UsuarioModel)
        .filter(
            (func.lower(UsuarioModel.correo) == identificador)
            | (func.lower(UsuarioModel.matricula) == identificador)
        )
        .first()
    )

    if not usuario or not _verificar_password(password, usuario.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo o contraseña incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if usuario.estado_cuenta != "ACTIVO":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Esta cuenta se encuentra suspendida o eliminada.",
        )

    token = crear_token_acceso(
        {
            "sub": usuario.matricula,
            "rol": usuario.rol,
            "verificado": usuario.verificado,
            "club_id": str(usuario.club_administrado_id) if usuario.club_administrado_id else None,
        },
        timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS),
    )
    return TokenResponse(access_token=token, token_type="bearer")
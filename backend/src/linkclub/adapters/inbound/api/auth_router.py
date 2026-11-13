import os
from datetime import datetime, timedelta, timezone
from typing import Annotated

import jwt
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from passlib.context import CryptContext
from pydantic import BaseModel, ConfigDict
from sqlalchemy.orm import Session

from linkclub.adapters.outbound.postgres.database import get_db
from linkclub.adapters.outbound.postgres.models.usuario_model import UsuarioModel

router = APIRouter(tags=["auth"])

JWT_SECRET = os.environ.get("JWT_SECRET")
if not JWT_SECRET:
    raise ValueError("ERROR CRÍTICO: La variable de entorno JWT_SECRET no está configurada. La aplicación no puede iniciar de forma segura.")

JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_DAYS = int(os.environ.get("JWT_EXPIRES_DAYS", "7"))

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class CrearUsuarioRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    nombre: str
    matricula: str
    correo: str
    password: str

class UsuarioResponse(BaseModel):
    id: str
    nombre: str
    matricula: str
    correo: str
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

@router.post("/auth/registro", response_model=UsuarioResponse, status_code=status.HTTP_201_CREATED, responses={
        409: {"description": "El correo o la matrícula ya están registrados"}
    }
)
def registrar_usuario(
    payload: CrearUsuarioRequest, 
    db: Annotated[Session, Depends(get_db)]
):
    
    if db.query(UsuarioModel).filter(UsuarioModel.correo == payload.correo).first():
        raise HTTPException(status_code=409, detail="El correo ya está registrado")
    
    if db.query(UsuarioModel).filter(UsuarioModel.matricula == payload.matricula).first():
        raise HTTPException(status_code=409, detail="La matrícula ya está registrada")
    
    hashed_password = pwd_context.hash(payload.password)

    nuevo_usuario = UsuarioModel(
        matricula=payload.matricula,
        nombre=payload.nombre,
        correo=payload.correo,
        password_hash=hashed_password,
    )
    
    db.add(nuevo_usuario)
    db.commit()
    db.refresh(nuevo_usuario)
    
    return UsuarioResponse(
        id=nuevo_usuario.matricula,
        nombre=nuevo_usuario.nombre,
        matricula=nuevo_usuario.matricula,
        correo=nuevo_usuario.correo,
        creado_en=nuevo_usuario.creado_en
    )

@router.post("/auth/login", response_model=TokenResponse)
def iniciar_sesion(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()], 
    db: Annotated[Session, Depends(get_db)]
):
    
    usuario = db.query(UsuarioModel).filter(UsuarioModel.correo == form_data.username).first()
    
    if not usuario or not pwd_context.verify(form_data.password, usuario.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo o contraseña incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    tiempo_expiracion = timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS)
    token = crear_token_acceso({"sub": usuario.matricula}, tiempo_expiracion)
    
    return TokenResponse(access_token=token, token_type="bearer")
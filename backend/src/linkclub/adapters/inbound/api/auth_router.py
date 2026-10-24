import os
from datetime import datetime, timedelta, timezone
from typing import Annotated
from uuid import uuid4

import jwt
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel, ConfigDict

router = APIRouter(tags=["auth"])

JWT_SECRET = os.environ.get("JWT_SECRET", "secreto-desarrollo-local-super-seguro")
JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_DAYS = int(os.environ.get("JWT_EXPIRES_DAYS", "7"))

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
    rol: str
    creado_en: datetime

class TokenResponse(BaseModel):
    access_token: str
    token_type: str

db_usuarios_memoria = {}

def crear_token_acceso(data: dict, expires_delta: timedelta) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + expires_delta
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, JWT_SECRET, algorithm=JWT_ALGORITHM)

@router.post("/auth/registro", response_model=UsuarioResponse, status_code=status.HTTP_201_CREATED)
def registrar_usuario(payload: CrearUsuarioRequest):
    if any(u["correo"] == payload.correo for u in db_usuarios_memoria.values()):
        raise HTTPException(status_code=409, detail="El correo ya está registrado")
    
    nuevo_id = str(uuid4())
    nuevo_usuario = {
        "id": nuevo_id,
        "nombre": payload.nombre,
        "matricula": payload.matricula,
        "correo": payload.correo,
        "password_hash": payload.password, 
        "rol": "estudiante",
        "creado_en": datetime.now(timezone.utc)
    }
    db_usuarios_memoria[payload.correo] = nuevo_usuario
    
    return UsuarioResponse(**nuevo_usuario)

@router.post("/auth/login", response_model=TokenResponse)
def iniciar_sesion(form_data: Annotated[OAuth2PasswordRequestForm, Depends()]):
    usuario = db_usuarios_memoria.get(form_data.username)
    if not usuario or usuario["password_hash"] != form_data.password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo o contraseña incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    tiempo_expiracion = timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS)
    token = crear_token_acceso({"sub": usuario["id"]}, tiempo_expiracion)
    
    return TokenResponse(access_token=token, token_type="bearer")

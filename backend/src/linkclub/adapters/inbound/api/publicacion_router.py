from datetime import datetime
from typing import Annotated, Optional, List
import json
from fastapi import APIRouter, Depends, HTTPException, Header, status
from pydantic import BaseModel, ConfigDict
from sqlalchemy.orm import Session
from sqlalchemy import Column, Integer, String, Text, DateTime
from sqlalchemy.sql import func

from linkclub.adapters.inbound.api.auth_dependency import require_auth
from linkclub.adapters.outbound.postgres.database import get_db, Base

router = APIRouter(tags=["publicaciones"])

class PublicacionModel(Base):
    __tablename__ = "publicaciones"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    club_id = Column(Integer, nullable=False, index=True)
    autor_matricula = Column(String, nullable=False)
    titulo = Column(String, nullable=False)
    contenido = Column(Text, nullable=False)
    tipo = Column(String, nullable=False, default="aviso")
    opciones = Column(Text, nullable=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

class CrearPublicacionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    club_id: Optional[int] = 1
    titulo: Optional[str] = "Publicación"
    contenido: str
    tipo: str = "aviso"
    opciones: list[str] | None = None
    imagen_url: Optional[str] = None

class PublicacionResponse(BaseModel):
    id: int
    club_id: int
    autor_id: str
    titulo: str
    contenido: str
    tipo: str
    opciones: list[str] | None = None
    imagen_url: Optional[str] = None
    creado_en: datetime

    model_config = ConfigDict(from_attributes=True)

def a_respuesta(pub: PublicacionModel) -> PublicacionResponse:
    opciones_val = None
    imagen_url_val = None
    
    if pub.opciones:
        try:
            parsed = json.loads(pub.opciones) if isinstance(pub.opciones, str) else pub.opciones
            if isinstance(parsed, dict):
                opciones_val = parsed.get("opciones")
                imagen_url_val = parsed.get("imagen_url")
            elif isinstance(parsed, list):
                opciones_val = parsed
        except Exception:
            pass

    return PublicacionResponse(
        id=pub.id,
        club_id=pub.club_id,
        autor_id=pub.autor_matricula,
        titulo=pub.titulo,
        contenido=pub.contenido,
        tipo=pub.tipo,
        opciones=opciones_val,
        imagen_url=imagen_url_val,
        creado_en=pub.creado_en,
    )

@router.post(
    "/clubes/{club_id}/publicaciones",
    response_model=PublicacionResponse,
    status_code=status.HTTP_201_CREATED,
    responses={
        422: {"description": "Error de validación en los datos de la publicación"},
        409: {"description": "Conflicto de idempotencia"}
    },
)
def crear_publicacion_por_club(
    club_id: int,
    payload: CrearPublicacionRequest,
    autor_id: Annotated[str, Depends(require_auth)],
    db: Session = Depends(get_db),
    idempotency_key: Annotated[Optional[str], Header(alias="Idempotency-Key")] = None,
):
    try:
        meta_data = {
            "opciones": payload.opciones,
            "imagen_url": payload.imagen_url
        }

        nueva_pub = PublicacionModel(
            club_id=club_id,
            autor_matricula=autor_id,
            titulo=payload.titulo,
            contenido=payload.contenido,
            tipo=payload.tipo,
            opciones=json.dumps(meta_data),
        )

        db.add(nueva_pub)
        db.commit()
        db.refresh(nueva_pub)
        return a_respuesta(nueva_pub)
    except Exception as error:
        db.rollback()
        raise HTTPException(status_code=422, detail=str(error))

@router.post(
    "/publicaciones",
    response_model=PublicacionResponse,
    status_code=status.HTTP_201_CREATED,
)
def crear_publicacion_general(
    payload: CrearPublicacionRequest,
    autor_id: Annotated[str, Depends(require_auth)],
    db: Session = Depends(get_db),
    idempotency_key: Annotated[Optional[str], Header(alias="Idempotency-Key")] = None,
):
    try:
        meta_data = {
            "opciones": payload.opciones,
            "imagen_url": payload.imagen_url
        }

        nueva_pub = PublicacionModel(
            club_id=payload.club_id or 1,
            autor_matricula=autor_id,
            titulo=payload.titulo,
            contenido=payload.contenido,
            tipo=payload.tipo,
            opciones=meta_data,
        )

        db.add(nueva_pub)
        db.commit()
        db.refresh(nueva_pub)
        return a_respuesta(nueva_pub)
    except Exception as error:
        db.rollback()
        raise HTTPException(status_code=422, detail=str(error))

@router.get(
    "/clubes/{club_id}/publicaciones",
    response_model=list[PublicacionResponse],
)
def listar_publicaciones_por_club(club_id: int, db: Session = Depends(get_db)):
    pubs = (
        db.query(PublicacionModel)
        .filter(PublicacionModel.club_id == club_id)
        .order_by(PublicacionModel.creado_en.desc())
        .all()
    )
    return [a_respuesta(p) for p in pubs]

@router.get(
    "/publicaciones",
    response_model=list[PublicacionResponse],
)
def listar_todas_las_publicaciones(db: Session = Depends(get_db)):
    pubs = (
        db.query(PublicacionModel)
        .order_by(PublicacionModel.creado_en.desc())
        .all()
    )
    return [a_respuesta(p) for p in pubs]
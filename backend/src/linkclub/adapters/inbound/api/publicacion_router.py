from datetime import datetime
from typing import Annotated, Optional
from uuid import uuid4
from fastapi import APIRouter, Depends, HTTPException, Header, status
from pydantic import BaseModel, ConfigDict

from linkclub.adapters.inbound.api.auth_dependency import require_auth
from linkclub.adapters.outbound.persistence.in_memory_publicacion_adapter import (
    InMemoryPublicacionAdapter,
)
from linkclub.application.use_cases.crear_publicacion import CrearPublicacionUseCase
from linkclub.domain.publicacion import TipoPublicacion, PublicacionDuplicada

router = APIRouter(tags=["publicaciones"])

repository = InMemoryPublicacionAdapter()
use_case = CrearPublicacionUseCase(repository=repository)

class CrearPublicacionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    titulo: Optional[str] = "Publicación"
    contenido: str
    tipo: str = TipoPublicacion.AVISO.value
    opciones: list[str] | None = None
    imagen_url: Optional[str] = None

class PublicacionResponse(BaseModel):
    id: str
    club_id: str
    autor_id: str
    titulo: str
    contenido: str
    tipo: str
    opciones: list[str] | None = None
    imagen_url: Optional[str] = None
    creado_en: datetime

    model_config = ConfigDict(from_attributes=True)

def a_respuesta(publicacion) -> PublicacionResponse:
    return PublicacionResponse(
        id=str(publicacion.id),
        club_id=getattr(publicacion, 'club_id', 'general'),
        autor_id=getattr(publicacion, 'autor_id', 'sistema'),
        titulo=getattr(publicacion, 'titulo', 'Publicación'),
        contenido=publicacion.contenido,
        tipo=getattr(publicacion, 'tipo', TipoPublicacion.AVISO).value if hasattr(getattr(publicacion, 'tipo', None), 'value') else str(getattr(publicacion, 'tipo', 'aviso')),
        opciones=getattr(publicacion, 'opciones', None),
        imagen_url=getattr(publicacion, 'imagen_url', None),
        creado_en=getattr(publicacion, 'creada_en', getattr(publicacion, 'creado_en', datetime.now())),
    )

@router.post(
    "/clubes/{club_id}/publicaciones",
    response_model=PublicacionResponse,
    status_code=status.HTTP_201_CREATED,
    responses={
        422: {"description": "Error de validación en la regla de negocio o datos de la publicación"},
        409: {"description": "Conflicto: Petición duplicada interceptada por Idempotencia"}
    },
)
def crear_publicacion_por_club(
    club_id: str,
    payload: CrearPublicacionRequest,
    autor_id: Annotated[str, Depends(require_auth)],
    idempotency_key: Annotated[str, Header(alias="Idempotency-Key", description="Llave única generada por el cliente")],
):
    try:
        publicacion = use_case.ejecutar(
            club_id=club_id,
            autor_id=autor_id,
            titulo=payload.titulo,
            contenido=payload.contenido,
            tipo=payload.tipo,
            opciones=payload.opciones,
            idempotency_key=idempotency_key,
        )
        # Inyectar imagen_url si el dominio lo soporta temporalmente en el objeto devuelto
        if hasattr(publicacion, '__dict__'):
            setattr(publicacion, 'imagen_url', payload.imagen_url)
    except ValueError as error:
        raise HTTPException(status_code=422, detail=str(error))
    except PublicacionDuplicada:
        raise HTTPException(status_code=409, detail="Petición duplicada interceptada por Idempotencia")

    return a_respuesta(publicacion)

@router.post(
    "/publicaciones",
    response_model=PublicacionResponse,
    status_code=status.HTTP_201_CREATED,
    responses={
        422: {"description": "Error de validación"},
        409: {"description": "Petición duplicada interceptada por Idempotencia"}
    },
)
def crear_publicacion_general(
    payload: CrearPublicacionRequest,
    autor_id: Annotated[str, Depends(require_auth)],
    idempotency_key: Annotated[Optional[str], Header(alias="Idempotency-Key")] = None,
):
    key = idempotency_key or str(uuid4())
    try:
        publicacion = use_case.ejecutar(
            club_id="general",
            autor_id=autor_id,
            titulo=payload.titulo,
            contenido=payload.contenido,
            tipo=payload.tipo,
            opciones=payload.opciones,
            idempotency_key=key,
        )
        if hasattr(publicacion, '__dict__'):
            setattr(publicacion, 'imagen_url', payload.imagen_url)
    except ValueError as error:
        raise HTTPException(status_code=422, detail=str(error))
    except PublicacionDuplicada:
        raise HTTPException(status_code=409, detail="Petición duplicada interceptada por Idempotencia")

    return a_respuesta(publicacion)

@router.get(
    "/clubes/{club_id}/publicaciones",
    response_model=list[PublicacionResponse],
)
def listar_publicaciones_por_club(club_id: str):
    return [a_respuesta(p) for p in repository.listar_por_club(club_id)]

@router.get(
    "/publicaciones",
    response_model=list[PublicacionResponse],
)
def listar_todas_las_publicaciones():
    pubs = repository.listar_todas() if hasattr(repository, 'listar_todas') else []
    # Orden estricto: Lo más reciente primero (orden cronológico inverso)
    pubs_ordenadas = sorted(
        pubs, 
        key=lambda x: getattr(x, 'creada_en', getattr(x, 'creado_en', datetime.min)), 
        reverse=True
    )
    return [a_respuesta(p) for p in pubs_ordenadas]
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from linkclub.adapters.outbound.persistence.in_memory_publicacion_adapter import (
    InMemoryPublicacionAdapter,
)
from linkclub.application.use_cases.crear_publicacion import CrearPublicacionUseCase
from linkclub.domain.publicacion import TipoPublicacion

router = APIRouter(prefix="/publicaciones", tags=["publicaciones"])

repository = InMemoryPublicacionAdapter()
use_case = CrearPublicacionUseCase(repository=repository)


class CrearPublicacionRequest(BaseModel):
    club_id: str
    titulo: str
    contenido: str
    tipo: str = TipoPublicacion.AVISO.value
    opciones: list[str] | None = None


class PublicacionResponse(BaseModel):
    id: str
    club_id: str
    titulo: str
    contenido: str
    tipo: str
    opciones: list[str] | None = None


@router.post("", response_model=PublicacionResponse, status_code=201)
def crear_publicacion(payload: CrearPublicacionRequest):
    try:
        publicacion = use_case.ejecutar(
            club_id=payload.club_id,
            titulo=payload.titulo,
            contenido=payload.contenido,
            tipo=payload.tipo,
            opciones=payload.opciones,
        )
    except ValueError as error:
        raise HTTPException(status_code=422, detail=str(error))

    return PublicacionResponse(
        id=str(publicacion.id),
        club_id=publicacion.club_id,
        titulo=publicacion.titulo,
        contenido=publicacion.contenido,
        tipo=publicacion.tipo.value,
        opciones=publicacion.opciones,
    )


@router.get("/{club_id}", response_model=list[PublicacionResponse])
def listar_publicaciones(club_id: str):
    publicaciones = repository.listar_por_club(club_id)
    return [
        PublicacionResponse(
            id=str(p.id),
            club_id=p.club_id,
            titulo=p.titulo,
            contenido=p.contenido,
            tipo=p.tipo.value,
            opciones=p.opciones,
        )
        for p in publicaciones
    ]
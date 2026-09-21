from datetime import datetime

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, ConfigDict

from linkclub.adapters.outbound.persistence.in_memory_publicacion_adapter import (
    InMemoryPublicacionAdapter,
)
from linkclub.application.use_cases.crear_publicacion import CrearPublicacionUseCase
from linkclub.domain.publicacion import TipoPublicacion

router = APIRouter(tags=["publicaciones"])

repository = InMemoryPublicacionAdapter()
use_case = CrearPublicacionUseCase(repository=repository)


class CrearPublicacionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

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
    creado_en: datetime


def a_respuesta(publicacion) -> PublicacionResponse:
    return PublicacionResponse(
        id=str(publicacion.id),
        club_id=publicacion.club_id,
        titulo=publicacion.titulo,
        contenido=publicacion.contenido,
        tipo=publicacion.tipo.value,
        opciones=publicacion.opciones,
        creado_en=publicacion.creada_en,
    )


@router.post(
    "/clubes/{club_id}/publicaciones",
    response_model=PublicacionResponse,
    status_code=201,
)
def crear_publicacion(club_id: str, payload: CrearPublicacionRequest):
    try:
        publicacion = use_case.ejecutar(
            club_id=club_id,
            titulo=payload.titulo,
            contenido=payload.contenido,
            tipo=payload.tipo,
            opciones=payload.opciones,
        )
    except ValueError as error:
        raise HTTPException(status_code=422, detail=str(error))

    return a_respuesta(publicacion)


@router.get(
    "/clubes/{club_id}/publicaciones",
    response_model=list[PublicacionResponse],
)
def listar_publicaciones(club_id: str):
    return [a_respuesta(p) for p in repository.listar_por_club(club_id)]
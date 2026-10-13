from datetime import datetime

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from linkclub.adapters.outbound.persistence.in_memory_club_adapter import InMemoryClubAdapter
from linkclub.application.use_cases.consultar_clubes import (
    ListarClubesUseCase,
    ObtenerClubUseCase,
)
from linkclub.domain.club import ClubNoEncontrado

router = APIRouter(tags=["clubes"])

repository = InMemoryClubAdapter()
listar_use_case = ListarClubesUseCase(repository=repository)
obtener_use_case = ObtenerClubUseCase(repository=repository)


class ClubResponse(BaseModel):
    id: str
    nombre: str
    descripcion: str
    categoria: str
    creado_en: datetime


def a_respuesta(club) -> ClubResponse:
    return ClubResponse(
        id=str(club.id),
        nombre=club.nombre,
        descripcion=club.descripcion,
        categoria=club.categoria,
        creado_en=club.creado_en,
    )


@router.get("/clubes", response_model=list[ClubResponse])
def listar_clubes(q: str | None = None, categoria: str | None = None):
    return [a_respuesta(c) for c in listar_use_case.ejecutar(q=q, categoria=categoria)]


@router.get(
    "/clubes/{club_id}",
    response_model=ClubResponse,
    responses={404: {"description": "El club no existe"}},
)
def obtener_club(club_id: str):
    try:
        return a_respuesta(obtener_use_case.ejecutar(club_id))
    except ClubNoEncontrado:
        raise HTTPException(status_code=404, detail="El club no existe")
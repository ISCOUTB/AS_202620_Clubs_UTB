import uuid
from datetime import datetime, timezone
from typing import Annotated, Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy.orm import Session

from linkclub.adapters.inbound.api.auth_dependency import get_current_user
from linkclub.adapters.outbound.postgres.database import get_db
from linkclub.adapters.outbound.postgres.models.club_model import ClubModel
from linkclub.adapters.outbound.postgres.models.usuario_model import UsuarioModel

router = APIRouter(tags=["clubes"])


class AdministradorClubResponse(BaseModel):
    usuario_id: str
    nombre: str


class ClubResponse(BaseModel):
    id: str
    nombre: str
    descripcion: str
    categoria: str
    descripcion_completa: Optional[str] = None
    icono: Optional[str] = None
    logo_url: Optional[str] = None
    horario: Optional[str] = None
    lugar: Optional[str] = None
    lider: Optional[str] = None
    redes_json: Dict[str, Any] = Field(default_factory=dict)
    inscripciones_abiertas: bool = False
    ms_forms_url: Optional[str] = None
    aviso_inscripcion: Optional[str] = None
    total_miembros: int = 0
    administradores: List[AdministradorClubResponse] = Field(default_factory=list)
    creado_en: datetime


class CrearClubRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    nombre: str = Field(min_length=1, max_length=120)
    descripcion: str = Field(min_length=1, max_length=500)
    categoria: str = Field(min_length=1, max_length=60)
    descripcion_completa: Optional[str] = None
    icono: Optional[str] = None
    logo_url: Optional[str] = None
    horario: Optional[str] = None
    lugar: Optional[str] = None
    lider: Optional[str] = None
    redes_json: Optional[Dict[str, Any]] = None
    inscripciones_abiertas: bool = False
    ms_forms_url: Optional[str] = None
    aviso_inscripcion: Optional[str] = None


class ActualizarClubRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    nombre: Optional[str] = Field(default=None, min_length=1, max_length=120)
    descripcion: Optional[str] = Field(default=None, min_length=1, max_length=500)
    descripcion_completa: Optional[str] = None
    categoria: Optional[str] = Field(default=None, min_length=1, max_length=60)
    icono: Optional[str] = None
    logo_url: Optional[str] = None
    horario: Optional[str] = None
    lugar: Optional[str] = None
    lider: Optional[str] = None
    redes_json: Optional[Dict[str, Any]] = None
    inscripciones_abiertas: Optional[bool] = None
    ms_forms_url: Optional[str] = None
    aviso_inscripcion: Optional[str] = None


def _serializar_club(club: ClubModel, db: Session) -> ClubResponse:
    admins = (
        db.query(UsuarioModel)
        .filter(
            UsuarioModel.club_administrado_id == club.id,
            UsuarioModel.rol == "ADMIN_CLUB",
            UsuarioModel.verificado.is_(True),
        )
        .all()
    )
    return ClubResponse(
        id=str(club.id),
        nombre=club.nombre,
        descripcion=club.descripcion,
        categoria=club.categoria,
        descripcion_completa=club.descripcion_completa,
        icono=club.icono,
        logo_url=club.logo_url,
        horario=club.horario,
        lugar=club.lugar,
        lider=club.lider,
        redes_json=club.redes_json or {},
        inscripciones_abiertas=bool(club.inscripciones_abiertas),
        ms_forms_url=club.ms_forms_url,
        aviso_inscripcion=club.aviso_inscripcion,
        total_miembros=len(admins),
        administradores=[
            AdministradorClubResponse(usuario_id=a.matricula, nombre=a.nombre)
            for a in admins
        ],
        creado_en=club.creado_en or datetime.now(timezone.utc),
    )


@router.get("/clubes", response_model=List[ClubResponse])
def listar_clubes(
    db: Annotated[Session, Depends(get_db)],
    q: Optional[str] = Query(default=None, description="Texto a buscar en nombre o descripción"),
    categoria: Optional[str] = Query(default=None, description="Categoría exacta del club"),
):
    clubes = db.query(ClubModel).order_by(ClubModel.nombre.asc()).all()
    if q and q.strip():
        texto = q.strip().casefold()
        clubes = [
            c
            for c in clubes
            if texto in (c.nombre or "").casefold()
            or texto in (c.descripcion or "").casefold()
        ]
    if categoria and categoria.strip():
        cat = categoria.strip().casefold()
        clubes = [
            c
            for c in clubes
            if (c.categoria or "").strip().casefold() == cat
        ]
    return [_serializar_club(c, db) for c in clubes]


@router.post("/clubes", response_model=ClubResponse, status_code=status.HTTP_201_CREATED)
def crear_club(
    payload: CrearClubRequest,
    usuario: Annotated[UsuarioModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    if usuario.rol != "SUPERADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo un administrador del sistema puede registrar nuevos clubes.",
        )

    existe = db.query(ClubModel).filter(ClubModel.nombre.ilike(payload.nombre.strip())).first()
    if existe:
        raise HTTPException(status_code=409, detail="Ya existe un club con ese nombre.")

    nuevo_club = ClubModel(
        nombre=payload.nombre.strip(),
        descripcion=payload.descripcion.strip(),
        categoria=payload.categoria.strip(),
        descripcion_completa=payload.descripcion_completa,
        icono=payload.icono,
        logo_url=payload.logo_url,
        horario=payload.horario,
        lugar=payload.lugar,
        lider=payload.lider,
        redes_json=payload.redes_json or {},
        inscripciones_abiertas=payload.inscripciones_abiertas,
        ms_forms_url=payload.ms_forms_url,
        aviso_inscripcion=payload.aviso_inscripcion,
    )
    db.add(nuevo_club)
    db.commit()
    db.refresh(nuevo_club)
    return _serializar_club(nuevo_club, db)


@router.get("/clubes/{club_id}", response_model=ClubResponse)
def obtener_club(
    club_id: str,
    db: Annotated[Session, Depends(get_db)],
):
    try:
        club_uuid = uuid.UUID(club_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail="Club no encontrado.") from exc

    club = db.query(ClubModel).filter(ClubModel.id == club_uuid).first()
    if not club:
        raise HTTPException(status_code=404, detail="Club no encontrado.")
    return _serializar_club(club, db)


@router.patch("/clubes/{club_id}", response_model=ClubResponse)
def actualizar_club(
    club_id: str,
    payload: ActualizarClubRequest,
    usuario: Annotated[UsuarioModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    try:
        club_uuid = uuid.UUID(club_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail="Club no encontrado.") from exc

    club = db.query(ClubModel).filter(ClubModel.id == club_uuid).first()
    if not club:
        raise HTTPException(status_code=404, detail="Club no encontrado.")

    es_superadmin = usuario.rol == "SUPERADMIN"
    es_admin_de_este_club = (
        usuario.rol == "ADMIN_CLUB"
        and usuario.verificado
        and usuario.club_administrado_id == club.id
    )
    if not (es_superadmin or es_admin_de_este_club):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permisos de administración sobre este club.",
        )

    datos_actualizados = payload.model_dump(exclude_unset=True)
    for campo, valor in datos_actualizados.items():
        if isinstance(valor, str):
            valor = valor.strip()
        setattr(club, campo, valor)

    db.commit()
    db.refresh(club)
    return _serializar_club(club, db)
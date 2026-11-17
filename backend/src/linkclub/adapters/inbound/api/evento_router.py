import uuid
from datetime import datetime, timezone
from typing import Annotated, List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator
from sqlalchemy import func
from sqlalchemy.orm import Session

from linkclub.adapters.inbound.api.auth_dependency import (
    get_auth_port,
    get_current_user,
)
from linkclub.adapters.outbound.postgres.database import get_db
from linkclub.adapters.outbound.postgres.models.club_model import ClubModel
from linkclub.adapters.outbound.postgres.models.evento_model import (
    AsistenciaModel,
    EventoModel,
)
from linkclub.adapters.outbound.postgres.models.usuario_model import UsuarioModel
from linkclub.application.ports.outbound_auth_port import AuthPort, TokenInvalido

router = APIRouter(tags=["eventos"])
optional_bearer = HTTPBearer(auto_error=False)


class CrearEventoRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    club_id: Optional[str] = None
    titulo: str = Field(min_length=1, max_length=180)
    descripcion: str = Field(min_length=1)
    fecha_inicio: datetime
    fecha_fin: Optional[datetime] = None
    lugar: str = Field(min_length=1, max_length=200)
    visibilidad: str = "PUBLICO"
    enlace_registro_ms: Optional[str] = None
    imagen_url: Optional[str] = None

    @field_validator("visibilidad")
    @classmethod
    def validar_visibilidad(cls, v: str) -> str:
        permitidas = {"PUBLICO", "SOLO_CLUB"}
        valor = v.strip().upper()
        if valor not in permitidas:
            raise ValueError(f"visibilidad debe ser una de {sorted(permitidas)}")
        return valor

    @model_validator(mode="after")
    def validar_fechas(self) -> "CrearEventoRequest":
        if self.fecha_fin is not None and self.fecha_fin < self.fecha_inicio:
            raise ValueError("fecha_fin no puede ser anterior a fecha_inicio.")
        return self


class EventoResponse(BaseModel):
    id: str
    club_id: str
    club_nombre: str
    club_categoria: str
    club_logo_url: Optional[str] = None
    autor_matricula: str
    titulo: str
    descripcion: str
    fecha_inicio: datetime
    fecha_fin: Optional[datetime] = None
    lugar: str
    creado_en: datetime
    visibilidad: str
    enlace_registro_ms: Optional[str] = None
    imagen_url: Optional[str] = None
    total_asistentes: int = 0
    usuario_asiste: bool = False


class AsistenciaToggleResponse(BaseModel):
    usuario_asiste: bool
    total_asistentes: int


def _obtener_usuario_opcional(
    cred: HTTPAuthorizationCredentials | None = Depends(optional_bearer),
    auth: AuthPort = Depends(get_auth_port),
    db: Session = Depends(get_db),
) -> Optional[UsuarioModel]:
    if cred is None:
        return None
    try:
        identidad = auth.verificar(cred.credentials)
    except Exception:
        return None
    return (
        db.query(UsuarioModel)
        .filter(
            (UsuarioModel.matricula == identidad) | (UsuarioModel.correo == identidad)
        )
        .first()
    )


def _serializar_evento(
    ev: EventoModel,
    club: Optional[ClubModel],
    db: Session,
    usuario_actual: Optional[UsuarioModel] = None,
) -> EventoResponse:
    total = (
        db.query(func.count(AsistenciaModel.id))
        .filter(
            AsistenciaModel.evento_id == ev.id,
            AsistenciaModel.estado == "confirmado",
        )
        .scalar()
        or 0
    )

    usuario_asiste = False
    if usuario_actual is not None:
        usuario_asiste = (
            db.query(AsistenciaModel)
            .filter(
                AsistenciaModel.evento_id == ev.id,
                AsistenciaModel.usuario_matricula == usuario_actual.matricula,
                AsistenciaModel.estado == "confirmado",
            )
            .first()
            is not None
        )

    return EventoResponse(
        id=str(ev.id),
        club_id=str(ev.club_id),
        club_nombre=club.nombre if club else "Club UTB",
        club_categoria=club.categoria if club else "General",
        club_logo_url=club.logo_url if club else None,
        autor_matricula=ev.autor_matricula,
        titulo=ev.titulo,
        descripcion=ev.descripcion,
        fecha_inicio=ev.fecha_inicio,
        fecha_fin=ev.fecha_fin,
        lugar=ev.lugar,
        creado_en=ev.creado_en or datetime.now(timezone.utc),
        visibilidad=ev.visibilidad or "PUBLICO",
        enlace_registro_ms=ev.enlace_registro_ms,
        imagen_url=ev.imagen_url,
        total_asistentes=int(total),
        usuario_asiste=usuario_asiste,
    )


@router.get("/eventos", response_model=List[EventoResponse])
def listar_eventos(
    db: Annotated[Session, Depends(get_db)],
    usuario: Annotated[Optional[UsuarioModel], Depends(_obtener_usuario_opcional)],
    club_id: Optional[str] = None,
):
    query = db.query(EventoModel)
    if club_id:
        try:
            query = query.filter(EventoModel.club_id == uuid.UUID(club_id))
        except ValueError:
            return []

    eventos = query.order_by(EventoModel.fecha_inicio.asc()).all()
    clubes_map = {c.id: c for c in db.query(ClubModel).all()}

    resultado: List[EventoResponse] = []
    for ev in eventos:
        if ev.visibilidad == "SOLO_CLUB":
            if usuario is None:
                continue
            es_superadmin = usuario.rol == "SUPERADMIN"
            es_admin_club = (
                usuario.rol == "ADMIN_CLUB"
                and usuario.verificado
                and usuario.club_administrado_id == ev.club_id
            )
            if not (es_superadmin or es_admin_club):
                continue

        resultado.append(
            _serializar_evento(ev, clubes_map.get(ev.club_id), db, usuario)
        )

    return resultado


@router.post(
    "/eventos",
    response_model=EventoResponse,
    status_code=status.HTTP_201_CREATED,
)
def crear_evento(
    payload: CrearEventoRequest,
    usuario: Annotated[UsuarioModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    es_superadmin = usuario.rol == "SUPERADMIN"
    es_admin_club = usuario.rol == "ADMIN_CLUB" and usuario.verificado

    if not (es_superadmin or es_admin_club):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo los administradores de club verificados pueden programar eventos.",
        )

    raw_club_id = (
        payload.club_id
        if es_superadmin and payload.club_id
        else (str(usuario.club_administrado_id) if usuario.club_administrado_id else payload.club_id)
    )

    if not raw_club_id:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Debes especificar el club organizador del evento.",
        )

    try:
        club_uuid = uuid.UUID(str(raw_club_id))
    except ValueError as exc:
        raise HTTPException(status_code=404, detail="Club no encontrado.") from exc

    if not es_superadmin and usuario.club_administrado_id != club_uuid:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permisos para crear eventos en otro club.",
        )

    club = db.query(ClubModel).filter(ClubModel.id == club_uuid).first()
    if not club:
        raise HTTPException(status_code=404, detail="Club no encontrado.")

    nuevo_evento = EventoModel(
        club_id=club.id,
        autor_matricula=usuario.matricula,
        titulo=payload.titulo.strip(),
        descripcion=payload.descripcion.strip(),
        fecha_inicio=payload.fecha_inicio,
        fecha_fin=payload.fecha_fin,
        lugar=payload.lugar.strip(),
        visibilidad=payload.visibilidad,
        enlace_registro_ms=(
            payload.enlace_registro_ms.strip() if payload.enlace_registro_ms else None
        ),
        imagen_url=payload.imagen_url.strip() if payload.imagen_url else None,
    )

    db.add(nuevo_evento)
    db.commit()
    db.refresh(nuevo_evento)

    return _serializar_evento(nuevo_evento, club, db, usuario)


@router.post(
    "/eventos/{evento_id}/asistencia",
    response_model=AsistenciaToggleResponse,
)
def alternar_asistencia_evento(
    evento_id: str,
    usuario: Annotated[UsuarioModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    try:
        evento_uuid = uuid.UUID(evento_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail="Evento no encontrado.") from exc

    evento = db.query(EventoModel).filter(EventoModel.id == evento_uuid).first()
    if not evento:
        raise HTTPException(status_code=404, detail="Evento no encontrado.")

    registro = (
        db.query(AsistenciaModel)
        .filter(
            AsistenciaModel.evento_id == evento.id,
            AsistenciaModel.usuario_matricula == usuario.matricula,
        )
        .first()
    )

    if registro and registro.estado == "confirmado":
        db.delete(registro)
        usuario_asiste = False
    elif registro:
        registro.estado = "confirmado"
        usuario_asiste = True
    else:
        db.add(
            AsistenciaModel(
                evento_id=evento.id,
                usuario_matricula=usuario.matricula,
                estado="confirmado",
            )
        )
        usuario_asiste = True

    db.commit()

    total = (
        db.query(func.count(AsistenciaModel.id))
        .filter(
            AsistenciaModel.evento_id == evento.id,
            AsistenciaModel.estado == "confirmado",
        )
        .scalar()
        or 0
    )

    return AsistenciaToggleResponse(
        usuario_asiste=usuario_asiste,
        total_asistentes=int(total),
    )
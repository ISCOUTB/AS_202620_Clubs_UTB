from datetime import datetime, timezone
from typing import Annotated, List, Optional
import uuid

from fastapi import APIRouter, Depends, Header, HTTPException, Response, status
from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator
from sqlalchemy.orm import Session

from linkclub.adapters.inbound.api.auth_dependency import require_auth
from linkclub.adapters.outbound.messaging.in_memory_broker import InMemoryBroker
from linkclub.adapters.outbound.messaging.outbox import OutboxWorker
from linkclub.adapters.outbound.persistence.postgres_publicacion_adapter import (
    PostgresPublicacionAdapter,
)
from linkclub.adapters.outbound.postgres.database import get_db
from linkclub.adapters.outbound.postgres.models.club_model import ClubModel
from linkclub.adapters.outbound.postgres.models.usuario_model import UsuarioModel
from linkclub.application.use_cases.crear_publicacion import (
    CrearPublicacion,
    DatosInvalidos,
)
from linkclub.domain.publicacion import Publicacion

router = APIRouter(tags=["publicaciones"])
broker = InMemoryBroker()


def get_use_case(db: Session = Depends(get_db)) -> CrearPublicacion:
    repo = PostgresPublicacionAdapter(db)
    outbox = OutboxWorker(db, broker)
    return CrearPublicacion(repo, outbox)


class CrearPublicacionBody(BaseModel):
    model_config = ConfigDict(extra="forbid")

    titulo: Optional[str] = None
    contenido: str = Field(min_length=1)
    tipo: str = "aviso"
    opciones: Optional[List[str]] = None
    imagen_url: Optional[str] = None

    @field_validator("tipo")
    @classmethod
    def validar_tipo(cls, v: str) -> str:
        permitidos = {"aviso", "encuesta", "noticia"}
        if v not in permitidos:
            raise ValueError(f"tipo debe ser uno de {sorted(permitidos)}")
        return v

    @model_validator(mode="after")
    def validar_opciones_de_encuesta(self) -> "CrearPublicacionBody":
        if self.tipo == "encuesta":
            limpias = [o.strip() for o in (self.opciones or []) if o and o.strip()]
            if not limpias:
                raise ValueError("Una encuesta debe incluir al menos una opción no vacía.")
            self.opciones = limpias
        return self


class PublicacionResponse(BaseModel):
    id: str
    club_id: str
    club_nombre: Optional[str] = None
    autor_id: str
    autor_nombre: Optional[str] = None
    titulo: str
    contenido: str
    tipo: str
    opciones: Optional[List[str]] = None
    imagen_url: Optional[str] = None
    creado_en: datetime


def _serializar_publicacion(p: Publicacion, db: Session) -> PublicacionResponse:
    autor = db.query(UsuarioModel).filter(UsuarioModel.matricula == p.autor_id).first()
    club_nombre = None
    try:
        club = db.query(ClubModel).filter(ClubModel.id == uuid.UUID(str(p.club_id))).first()
        if club:
            club_nombre = club.nombre
    except ValueError:
        pass

    return PublicacionResponse(
        id=str(p.id),
        club_id=str(p.club_id),
        club_nombre=club_nombre,
        autor_id=p.autor_id,
        autor_nombre=autor.nombre if autor else p.autor_id,
        titulo=p.titulo,
        contenido=p.contenido,
        tipo=p.tipo,
        opciones=p.opciones,
        imagen_url=p.imagen_url,
        creado_en=getattr(p, "creado_en", None) or datetime.now(timezone.utc),
    )


def _verificar_permiso_publicar(club_id: str, autor_id: str, db: Session) -> None:
    usuario = (
        db.query(UsuarioModel)
        .filter((UsuarioModel.matricula == autor_id) | (UsuarioModel.correo == autor_id))
        .first()
    )
    if usuario is None:
        return

    if usuario.estado_cuenta != "ACTIVO":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tu cuenta no se encuentra activa.",
        )

    if usuario.rol == "SUPERADMIN":
        return

    es_admin_valido = (
        usuario.rol == "ADMIN_CLUB"
        and usuario.verificado
        and usuario.club_administrado_id is not None
        and str(usuario.club_administrado_id) == str(club_id)
    )
    if not es_admin_valido:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el administrador verificado de este club puede publicar aquí.",
        )


@router.get("/publicaciones", response_model=List[PublicacionResponse])
def listar_publicaciones_feed(
    db: Annotated[Session, Depends(get_db)],
    club_id: Optional[str] = None,
    use_case: CrearPublicacion = Depends(get_use_case),
):
    publicaciones = use_case.listar_todas()
    if club_id:
        publicaciones = [p for p in publicaciones if str(p.club_id) == str(club_id)]
    return [_serializar_publicacion(p, db) for p in publicaciones]


@router.get("/clubes/{club_id}/publicaciones", response_model=List[PublicacionResponse])
def listar_publicaciones_por_club(
    club_id: str,
    db: Annotated[Session, Depends(get_db)],
    use_case: CrearPublicacion = Depends(get_use_case),
):
    publicaciones = [p for p in use_case.listar_todas() if str(p.club_id) == str(club_id)]
    return [_serializar_publicacion(p, db) for p in publicaciones]


@router.post(
    "/clubes/{club_id}/publicaciones",
    response_model=PublicacionResponse,
    status_code=status.HTTP_201_CREATED,
)
def crear_publicacion_endpoint(
    club_id: str,
    body: CrearPublicacionBody,
    response: Response,
    db: Annotated[Session, Depends(get_db)],
    autor_id: str = Depends(require_auth),
    idempotency_key: Optional[str] = Header(default=None, alias="Idempotency-Key"),
    use_case: CrearPublicacion = Depends(get_use_case),
):
    if idempotency_key is not None and not idempotency_key.strip():
        raise HTTPException(
            status_code=422,
            detail="Idempotency-Key no puede ser una cadena vacía",
        )

    _verificar_permiso_publicar(club_id, autor_id, db)

    try:
        publicacion = use_case.ejecutar(
            club_id=club_id,
            autor_id=autor_id,
            titulo=body.titulo or "Publicación",
            contenido=body.contenido,
            tipo=body.tipo,
            opciones=body.opciones,
            imagen_url=body.imagen_url,
            idempotency_key=idempotency_key,
        )
    except DatosInvalidos as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc

    response.status_code = 201
    return _serializar_publicacion(publicacion, db)
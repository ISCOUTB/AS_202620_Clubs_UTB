from datetime import datetime, timezone
from typing import Annotated, List, Optional
import uuid

from fastapi import APIRouter, Depends, Header, HTTPException, Response, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from linkclub.adapters.inbound.api.auth_dependency import (
    get_auth_port,
    get_current_user,
    require_auth,
)
from linkclub.adapters.outbound.postgres.database import get_db
from linkclub.adapters.outbound.postgres.models.club_model import ClubModel
from linkclub.adapters.outbound.postgres.models.publicacion_model import (
    PublicacionLikeModel,
    PublicacionModel,
)
from linkclub.adapters.outbound.postgres.models.usuario_model import UsuarioModel
from linkclub.adapters.outbound.postgres.publicacion_repository import (
    PublicacionRepositoryPostgres,
)
from linkclub.application.ports.outbound_auth_port import AuthPort
from linkclub.application.use_cases.crear_publicacion import CrearPublicacionUseCase
from linkclub.domain.publicacion import Publicacion, PublicacionDuplicada

router = APIRouter(tags=["publicaciones"])
optional_bearer = HTTPBearer(auto_error=False)


def get_use_case(db: Session = Depends(get_db)) -> CrearPublicacionUseCase:
    repo = PublicacionRepositoryPostgres(db)
    return CrearPublicacionUseCase(repo)


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
    total_likes: int = 0
    usuario_dio_like: bool = False


class LikeToggleResponse(BaseModel):
    usuario_dio_like: bool
    total_likes: int


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
    usuario = (
        db.query(UsuarioModel)
        .filter((UsuarioModel.matricula == identidad) | (UsuarioModel.correo == identidad))
        .first()
    )
    if not usuario or usuario.estado_cuenta != "ACTIVO":
        return None
    return usuario


def _contar_likes(pub_uuid: uuid.UUID, db: Session) -> int:
    return int(
        db.query(func.count(PublicacionLikeModel.id))
        .filter(PublicacionLikeModel.publicacion_id == pub_uuid)
        .scalar()
        or 0
    )


def _serializar_publicacion(
    p: Publicacion,
    db: Session,
    usuario_actual: Optional[UsuarioModel] = None,
) -> PublicacionResponse:
    autor = db.query(UsuarioModel).filter(UsuarioModel.matricula == p.autor_id).first()
    club_nombre = None
    try:
        club = db.query(ClubModel).filter(ClubModel.id == uuid.UUID(str(p.club_id))).first()
        if club:
            club_nombre = club.nombre
    except ValueError:
        pass

    total_likes = 0
    usuario_dio_like = False
    try:
        pub_uuid = uuid.UUID(str(p.id))
        total_likes = _contar_likes(pub_uuid, db)
        if usuario_actual is not None:
            usuario_dio_like = (
                db.query(PublicacionLikeModel)
                .filter(
                    PublicacionLikeModel.publicacion_id == pub_uuid,
                    PublicacionLikeModel.usuario_matricula == usuario_actual.matricula,
                )
                .first()
                is not None
            )
    except ValueError:
        pass

    tipo_valor = p.tipo.value if hasattr(p.tipo, "value") else str(p.tipo)
    fecha_creacion = getattr(p, "creada_en", None) or datetime.now(timezone.utc)

    return PublicacionResponse(
        id=str(p.id),
        club_id=str(p.club_id),
        club_nombre=club_nombre,
        autor_id=p.autor_id,
        autor_nombre=autor.nombre if autor else p.autor_id,
        titulo=p.titulo,
        contenido=p.contenido,
        tipo=tipo_valor,
        opciones=p.opciones,
        imagen_url=p.imagen_url,
        creado_en=fecha_creacion,
        total_likes=total_likes,
        usuario_dio_like=usuario_dio_like,
    )


def _verificar_permiso_publicar(club_id: str, autor_id: str, db: Session) -> None:
    usuario = (
        db.query(UsuarioModel)
        .filter((UsuarioModel.matricula == autor_id) | (UsuarioModel.correo == autor_id))
        .first()
    )
    if usuario is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario inactivo o no encontrado.",
        )

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
    usuario: Annotated[Optional[UsuarioModel], Depends(_obtener_usuario_opcional)] = None,
):
    query = db.query(PublicacionModel)
    if club_id:
        try:
            query = query.filter(PublicacionModel.club_id == uuid.UUID(str(club_id)))
        except ValueError:
            return []
    registros = query.order_by(PublicacionModel.creado_en.desc()).all()
    repo = PublicacionRepositoryPostgres(db)
    return [
        _serializar_publicacion(repo._mapear_a_dominio(r), db, usuario)
        for r in registros
    ]


@router.get("/clubes/{club_id}/publicaciones", response_model=List[PublicacionResponse])
def listar_publicaciones_por_club(
    club_id: str,
    db: Annotated[Session, Depends(get_db)],
    usuario: Annotated[Optional[UsuarioModel], Depends(_obtener_usuario_opcional)] = None,
):
    repo = PublicacionRepositoryPostgres(db)
    try:
        publicaciones = repo.listar_por_club(club_id)
    except ValueError:
        return []
    return [_serializar_publicacion(p, db, usuario) for p in publicaciones]


@router.post(
    "/publicaciones/{publicacion_id}/like",
    response_model=LikeToggleResponse,
)
def alternar_like_publicacion(
    publicacion_id: str,
    usuario: Annotated[UsuarioModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    try:
        pub_uuid = uuid.UUID(publicacion_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail="Publicación no encontrada.") from exc

    existe_pub = (
        db.query(PublicacionModel).filter(PublicacionModel.id == pub_uuid).first()
    )
    if not existe_pub:
        raise HTTPException(status_code=404, detail="Publicación no encontrada.")

    like_existente = (
        db.query(PublicacionLikeModel)
        .filter(
            PublicacionLikeModel.publicacion_id == pub_uuid,
            PublicacionLikeModel.usuario_matricula == usuario.matricula,
        )
        .first()
    )

    if like_existente:
        db.delete(like_existente)
        usuario_dio_like = False
    else:
        db.add(
            PublicacionLikeModel(
                publicacion_id=pub_uuid,
                usuario_matricula=usuario.matricula,
            )
        )
        usuario_dio_like = True

    db.commit()
    return LikeToggleResponse(
        usuario_dio_like=usuario_dio_like,
        total_likes=_contar_likes(pub_uuid, db),
    )


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
    use_case: CrearPublicacionUseCase = Depends(get_use_case),
):
    if idempotency_key is not None and not idempotency_key.strip():
        raise HTTPException(
            status_code=422,
            detail="Idempotency-Key no puede ser una cadena vacía",
        )

    _verificar_permiso_publicar(club_id, autor_id, db)

    imagen_limpia = body.imagen_url.strip() if body.imagen_url else None

    try:
        publicacion = use_case.ejecutar(
            club_id=club_id,
            autor_id=autor_id,
            titulo=body.titulo or "Publicación",
            contenido=body.contenido,
            tipo=body.tipo,
            opciones=body.opciones,
            idempotency_key=idempotency_key,
            imagen_url=imagen_limpia,
        )
    except PublicacionDuplicada as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=404, detail="Club o autor no encontrado.") from exc

    response.status_code = 201
    return _serializar_publicacion(publicacion, db)
from datetime import datetime
from typing import Annotated, Optional, List
from fastapi import APIRouter, Depends, HTTPException, Header, status
from pydantic import BaseModel, ConfigDict
from sqlalchemy.orm import Session

from linkclub.adapters.inbound.api.auth_dependency import require_auth
from linkclub.adapters.outbound.postgres.database import get_db
from linkclub.adapters.outbound.postgres.models.publicacion_model import PublicacionModel
from linkclub.adapters.outbound.postgres.models.usuario_model import UsuarioModel

router = APIRouter(tags=["publicaciones"])


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
    autor_nombre: Optional[str] = None
    titulo: str
    contenido: str
    tipo: str
    opciones: list[str] | None = None
    imagen_url: Optional[str] = None
    creado_en: datetime

    model_config = ConfigDict(from_attributes=True)


def _obtener_matricula_usuario(db: Session, autor_identity: str) -> str:
    """Resuelve el usuario por correo o matrícula para asegurar la FK exacta."""
    usuario = (
        db.query(UsuarioModel)
        .filter(
            (UsuarioModel.correo == autor_identity) | (UsuarioModel.matricula == autor_identity)
        )
        .first()
    )

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Usuario con identidad '{autor_identity}' no existe en la base de datos."
        )

    return usuario.matricula


def a_respuesta(pub: PublicacionModel) -> PublicacionResponse:
    opciones_val = None
    imagen_url_val = None

    if pub.opciones:
        parsed = pub.opciones
        if isinstance(parsed, dict):
            opciones_val = parsed.get("opciones")
            imagen_url_val = parsed.get("imagen_url")
        elif isinstance(parsed, list):
            opciones_val = parsed

    # Extrae el nombre real del usuario desde la relación con UsuarioModel si existe
    nombre_autor = pub.autor.nombre if (hasattr(pub, 'autor') and pub.autor) else pub.autor_matricula

    return PublicacionResponse(
        id=pub.id,
        club_id=pub.club_id,
        autor_id=pub.autor_matricula,
        autor_nombre=nombre_autor,
        titulo=pub.titulo or "Publicación",
        contenido=pub.contenido,
        tipo=str(pub.tipo),
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
    autor_matricula = _obtener_matricula_usuario(db, autor_id)

    try:
        meta_data = {
            "opciones": payload.opciones,
            "imagen_url": payload.imagen_url
        }

        nueva_pub = PublicacionModel(
            club_id=club_id,
            autor_matricula=autor_matricula,
            titulo=payload.titulo or "Publicación",
            contenido=payload.contenido,
            tipo=payload.tipo or "aviso",
            opciones=meta_data,
        )

        db.add(nueva_pub)
        db.commit()
        db.refresh(nueva_pub)
        return a_respuesta(nueva_pub)
    except Exception as error:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Error al guardar publicación: {str(error)}"
        )


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
    autor_matricula = _obtener_matricula_usuario(db, autor_id)

    try:
        meta_data = {
            "opciones": payload.opciones,
            "imagen_url": payload.imagen_url
        }

        nueva_pub = PublicacionModel(
            club_id=payload.club_id or 1,
            autor_matricula=autor_matricula,
            titulo=payload.titulo or "Publicación",
            contenido=payload.contenido,
            tipo=payload.tipo or "aviso",
            opciones=meta_data,
        )

        db.add(nueva_pub)
        db.commit()
        db.refresh(nueva_pub)
        return a_respuesta(nueva_pub)
    except Exception as error:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Error al guardar publicación: {str(error)}"
        )


@router.get(
    "/clubes/{club_id}/publicaciones",
    response_model=List[PublicacionResponse],
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
    response_model=List[PublicacionResponse],
)
def listar_todas_las_publicaciones(db: Session = Depends(get_db)):
    pubs = (
        db.query(PublicacionModel)
        .order_by(PublicacionModel.creado_en.desc())
        .all()
    )
    return [a_respuesta(p) for p in pubs]
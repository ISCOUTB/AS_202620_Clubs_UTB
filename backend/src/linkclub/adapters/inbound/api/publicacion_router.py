from datetime import datetime
from typing import Annotated, Optional, List
from fastapi import APIRouter, Depends, HTTPException, Header, status
from pydantic import BaseModel, ConfigDict
from sqlalchemy.orm import Session

from linkclub.adapters.inbound.api.auth_dependency import require_auth
from linkclub.adapters.outbound.postgres.database import get_db
from linkclub.adapters.outbound.postgres.models.publicacion_model import PublicacionModel
from linkclub.adapters.outbound.postgres.models.usuario_model import UsuarioModel

from linkclub.application.use_cases.crear_publicacion import CrearPublicacionUseCase
from linkclub.adapters.outbound.postgres.publicacion_repository import PublicacionRepositoryPostgres

router = APIRouter(tags=["publicaciones"])

TITULO_POR_DEFECTO = "Publicación"

class CrearPublicacionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    club_id: Optional[int] = 1
    titulo: Optional[str] = TITULO_POR_DEFECTO
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

def a_respuesta(pub) -> PublicacionResponse:
    opciones_val = None
    imagen_url_val = None

    if pub.opciones:
        parsed = pub.opciones
        if isinstance(parsed, dict):
            opciones_val = parsed.get("opciones")
            imagen_url_val = parsed.get("imagen_url")
        elif isinstance(parsed, list):
            opciones_val = parsed

    if hasattr(pub, "autor_matricula"):
        autor_identity = pub.autor_matricula
        nombre_autor = pub.autor.nombre if (hasattr(pub, 'autor') and pub.autor) else pub.autor_matricula
        tipo_str = str(pub.tipo)
        creado_en_val = pub.creado_en
    else:
        autor_identity = pub.autor_id
        nombre_autor = pub.autor_id 
        tipo_str = pub.tipo.value if hasattr(pub.tipo, 'value') else str(pub.tipo)
        creado_en_val = getattr(pub, "creado_en", datetime.now()) 

    return PublicacionResponse(
        id=pub.id,
        club_id=pub.club_id,
        autor_id=autor_identity,
        autor_nombre=nombre_autor,
        titulo=pub.titulo or TITULO_POR_DEFECTO,
        contenido=pub.contenido,
        tipo=tipo_str,
        opciones=opciones_val,
        imagen_url=imagen_url_val,
        creado_en=creado_en_val,
    )

def _inyectar_nombres(db: Session, publicaciones: list) -> list[PublicacionResponse]:
    """Inyecta los nombres reales resolviendo las matrículas en bloque para optimizar BD."""
    respuestas = [a_respuesta(p) for p in publicaciones]
    matriculas = {r.autor_id for r in respuestas if r.autor_id}
    
    if matriculas:
        usuarios = db.query(UsuarioModel).filter(UsuarioModel.matricula.in_(matriculas)).all()
        mapa_nombres = {u.matricula: getattr(u, "nombre", u.matricula) for u in usuarios}
        
        for r in respuestas:
            if r.autor_id in mapa_nombres and mapa_nombres[r.autor_id]:
                r.autor_nombre = mapa_nombres[r.autor_id]
                
    return respuestas

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
    db: Annotated[Session, Depends(get_db)],
    idempotency_key: Annotated[Optional[str], Header(alias="Idempotency-Key")] = None,
):
    autor_matricula = _obtener_matricula_usuario(db, autor_id)

    try:
        meta_data = {
            "opciones": payload.opciones,
            "imagen_url": payload.imagen_url
        }

        repository = PublicacionRepositoryPostgres(db)
        use_case = CrearPublicacionUseCase(repository)

        pub_guardada = use_case.ejecutar(
            club_id=club_id,
            autor_matricula=autor_matricula,
            titulo=payload.titulo or TITULO_POR_DEFECTO,
            contenido=payload.contenido,
            tipo=payload.tipo or "aviso",
            opciones=meta_data,
            idempotency_key=idempotency_key
        )

        respuesta = a_respuesta(pub_guardada)
        
        usuario = db.query(UsuarioModel).filter(UsuarioModel.matricula == autor_matricula).first()
        if usuario and hasattr(usuario, "nombre") and usuario.nombre:
            respuesta.autor_nombre = usuario.nombre
            
        return respuesta
    except ValueError as val_error:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(val_error)
        )
    except Exception as error:
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
    db: Annotated[Session, Depends(get_db)],
    idempotency_key: Annotated[Optional[str], Header(alias="Idempotency-Key")] = None,
):
    autor_matricula = _obtener_matricula_usuario(db, autor_id)

    try:
        meta_data = {
            "opciones": payload.opciones,
            "imagen_url": payload.imagen_url
        }

        repository = PublicacionRepositoryPostgres(db)
        use_case = CrearPublicacionUseCase(repository)

        pub_guardada = use_case.ejecutar(
            club_id=payload.club_id or 1,
            autor_matricula=autor_matricula,
            titulo=payload.titulo or TITULO_POR_DEFECTO,
            contenido=payload.contenido,
            tipo=payload.tipo or "aviso",
            opciones=meta_data,
            idempotency_key=idempotency_key
        )

        respuesta = a_respuesta(pub_guardada)
        
        usuario = db.query(UsuarioModel).filter(UsuarioModel.matricula == autor_matricula).first()
        if usuario and hasattr(usuario, "nombre") and usuario.nombre:
            respuesta.autor_nombre = usuario.nombre
            
        return respuesta
    except ValueError as val_error:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(val_error)
        )
    except Exception as error:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Error al guardar publicación: {str(error)}"
        )

@router.get(
    "/clubes/{club_id}/publicaciones",
    response_model=List[PublicacionResponse],
)
def listar_publicaciones_por_club(
    club_id: int, 
    db: Annotated[Session, Depends(get_db)]
):
    pubs = (
        db.query(PublicacionModel)
        .filter(PublicacionModel.club_id == club_id)
        .order_by(PublicacionModel.creado_en.desc())
        .all()
    )
    return _inyectar_nombres(db, pubs)

@router.get(
    "/publicaciones",
    response_model=List[PublicacionResponse],
)
def listar_todas_las_publicaciones(
    db: Annotated[Session, Depends(get_db)]
):
    pubs = (
        db.query(PublicacionModel)
        .order_by(PublicacionModel.creado_en.desc())
        .all()
    )
    return _inyectar_nombres(db, pubs)
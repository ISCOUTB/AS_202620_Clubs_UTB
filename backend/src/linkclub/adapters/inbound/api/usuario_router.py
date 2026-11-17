import uuid
from datetime import datetime
from typing import Annotated, List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy.orm import Session

from linkclub.adapters.inbound.api.auth_dependency import (
    get_current_user,
    require_superadmin,
)
from linkclub.adapters.inbound.api.auth_router import (
    _hashear_password,
    _verificar_password,
)
from linkclub.adapters.outbound.postgres.database import get_db
from linkclub.adapters.outbound.postgres.models.club_model import ClubModel
from linkclub.adapters.outbound.postgres.models.solicitud_admin_model import (
    SolicitudAdminClubModel,
)
from linkclub.adapters.outbound.postgres.models.usuario_model import UsuarioModel

router = APIRouter(tags=["usuarios"])


class PerfilUsuarioResponse(BaseModel):
    matricula: str
    nombre: str
    correo: str
    rol: str
    verificado: bool
    club_administrado_id: Optional[str] = None
    club_administrado_nombre: Optional[str] = None
    descripcion: Optional[str] = None
    foto_perfil_url: Optional[str] = None
    solicitud_pendiente: bool = False


class ActualizarPerfilRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    nombre: Optional[str] = Field(default=None, min_length=1, max_length=120)
    descripcion: Optional[str] = Field(default=None, max_length=500)
    foto_perfil_url: Optional[str] = None


class CambiarPasswordRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    password_actual: str
    password_nueva: str = Field(min_length=8, max_length=72)


class SolicitudAdminResponse(BaseModel):
    id: str
    usuario_matricula: str
    usuario_nombre: str
    usuario_correo: str
    club_id: str
    club_nombre: str
    justificacion: str
    estado: str
    creado_en: datetime


@router.get("/usuarios/me", response_model=PerfilUsuarioResponse)
def obtener_mi_perfil(
    usuario: Annotated[UsuarioModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    club_nombre = None
    if usuario.club_administrado_id:
        club = db.query(ClubModel).filter(ClubModel.id == usuario.club_administrado_id).first()
        if club:
            club_nombre = club.nombre

    solicitud_pendiente = (
        db.query(SolicitudAdminClubModel)
        .filter(
            SolicitudAdminClubModel.usuario_matricula == usuario.matricula,
            SolicitudAdminClubModel.estado == "PENDIENTE",
        )
        .first()
        is not None
    )

    return PerfilUsuarioResponse(
        matricula=usuario.matricula,
        nombre=usuario.nombre,
        correo=usuario.correo,
        rol=usuario.rol,
        verificado=usuario.verificado,
        club_administrado_id=(
            str(usuario.club_administrado_id) if usuario.club_administrado_id else None
        ),
        club_administrado_nombre=club_nombre,
        descripcion=usuario.descripcion,
        foto_perfil_url=usuario.foto_perfil_url,
        solicitud_pendiente=solicitud_pendiente,
    )


@router.patch("/usuarios/me", response_model=PerfilUsuarioResponse)
def actualizar_mi_perfil(
    payload: ActualizarPerfilRequest,
    usuario: Annotated[UsuarioModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    if payload.nombre is not None:
        usuario.nombre = payload.nombre.strip()
    if payload.descripcion is not None:
        usuario.descripcion = payload.descripcion.strip()
    if payload.foto_perfil_url is not None:
        usuario.foto_perfil_url = payload.foto_perfil_url.strip()

    db.commit()
    db.refresh(usuario)
    return obtener_mi_perfil(usuario, db)


@router.post("/usuarios/me/password", status_code=status.HTTP_204_NO_CONTENT)
def cambiar_mi_password(
    payload: CambiarPasswordRequest,
    usuario: Annotated[UsuarioModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    if not _verificar_password(payload.password_actual, usuario.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La contraseña actual no es correcta.",
        )
    usuario.password_hash = _hashear_password(payload.password_nueva)
    db.commit()


@router.delete("/usuarios/me", status_code=status.HTTP_204_NO_CONTENT)
def eliminar_mi_cuenta(
    usuario: Annotated[UsuarioModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    db.delete(usuario)
    db.commit()


@router.get("/admin/solicitudes", response_model=List[SolicitudAdminResponse])
def listar_solicitudes_admin(
    _: Annotated[UsuarioModel, Depends(require_superadmin)],
    db: Annotated[Session, Depends(get_db)],
):
    solicitudes = (
        db.query(SolicitudAdminClubModel)
        .filter(SolicitudAdminClubModel.estado == "PENDIENTE")
        .order_by(SolicitudAdminClubModel.creado_en.desc())
        .all()
    )
    resultado = []
    for s in solicitudes:
        u = db.query(UsuarioModel).filter(UsuarioModel.matricula == s.usuario_matricula).first()
        c = db.query(ClubModel).filter(ClubModel.id == s.club_id).first()
        resultado.append(
            SolicitudAdminResponse(
                id=str(s.id),
                usuario_matricula=s.usuario_matricula,
                usuario_nombre=u.nombre if u else s.usuario_matricula,
                usuario_correo=u.correo if u else "",
                club_id=str(s.club_id),
                club_nombre=c.nombre if c else "Club UTB",
                justificacion=s.justificacion,
                estado=s.estado,
                creado_en=s.creado_en,
            )
        )
    return resultado


@router.post("/admin/solicitudes/{solicitud_id}/aprobar", status_code=status.HTTP_200_OK)
def aprobar_solicitud_admin(
    solicitud_id: str,
    admin_dev: Annotated[UsuarioModel, Depends(require_superadmin)],
    db: Annotated[Session, Depends(get_db)],
):
    try:
        solicitud_uuid = uuid.UUID(solicitud_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada.") from exc

    solicitud = (
        db.query(SolicitudAdminClubModel)
        .filter(SolicitudAdminClubModel.id == solicitud_uuid)
        .first()
    )
    if not solicitud:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada.")

    usuario = (
        db.query(UsuarioModel)
        .filter(UsuarioModel.matricula == solicitud.usuario_matricula)
        .first()
    )
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario solicitante no encontrado.")

    usuario.rol = "ADMIN_CLUB"
    usuario.verificado = True
    usuario.club_administrado_id = solicitud.club_id
    solicitud.estado = "APROBADA"
    solicitud.revisado_por = admin_dev.matricula
    db.commit()
    return {"detail": f"Admin verificado para {usuario.nombre}"}


@router.post("/admin/solicitudes/{solicitud_id}/rechazar", status_code=status.HTTP_200_OK)
def rechazar_solicitud_admin(
    solicitud_id: str,
    admin_dev: Annotated[UsuarioModel, Depends(require_superadmin)],
    db: Annotated[Session, Depends(get_db)],
):
    try:
        solicitud_uuid = uuid.UUID(solicitud_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada.") from exc

    solicitud = (
        db.query(SolicitudAdminClubModel)
        .filter(SolicitudAdminClubModel.id == solicitud_uuid)
        .first()
    )
    if not solicitud:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada.")

    usuario = (
        db.query(UsuarioModel)
        .filter(UsuarioModel.matricula == solicitud.usuario_matricula)
        .first()
    )
    if usuario:
        usuario.rol = "ESTUDIANTE"
        usuario.verificado = True
        usuario.club_administrado_id = None

    solicitud.estado = "RECHAZADA"
    solicitud.revisado_por = admin_dev.matricula
    db.commit()
    return {"detail": "Solicitud rechazada; cuenta mantenida como Estudiante."}
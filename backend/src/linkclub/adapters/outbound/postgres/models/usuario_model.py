from sqlalchemy import Boolean, Column, DateTime, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func

from linkclub.adapters.outbound.postgres.database import Base


class UsuarioModel(Base):
    __tablename__ = "usuarios"

    matricula = Column(String, primary_key=True)
    nombre = Column(String, nullable=False)
    correo = Column(String, unique=True, nullable=False)
    password_hash = Column(String, nullable=False)
    rol = Column(String(20), nullable=False, server_default="ESTUDIANTE", default="ESTUDIANTE")
    verificado = Column(Boolean, nullable=False, server_default="true", default=True)
    club_administrado_id = Column(
        UUID(as_uuid=True),
        ForeignKey("clubes.id", ondelete="SET NULL"),
        nullable=True,
    )
    descripcion = Column(Text, nullable=True)
    foto_perfil_url = Column(Text, nullable=True)
    estado_cuenta = Column(String(20), nullable=False, server_default="ACTIVO", default="ACTIVO")
    creado_en = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
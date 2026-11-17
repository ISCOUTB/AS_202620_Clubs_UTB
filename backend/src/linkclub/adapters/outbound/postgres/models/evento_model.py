import uuid
from sqlalchemy import Column, DateTime, ForeignKey, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func

from linkclub.adapters.outbound.postgres.database import Base


class EventoModel(Base):
    __tablename__ = "eventos"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    club_id = Column(
        UUID(as_uuid=True),
        ForeignKey("clubes.id", ondelete="CASCADE"),
        nullable=False,
    )
    autor_matricula = Column(
        String,
        ForeignKey("usuarios.matricula", ondelete="CASCADE"),
        nullable=False,
    )
    titulo = Column(String, nullable=False)
    descripcion = Column(Text, nullable=False)
    fecha_inicio = Column(DateTime(timezone=True), nullable=False)
    fecha_fin = Column(DateTime(timezone=True), nullable=True)
    lugar = Column(String, nullable=False)
    visibilidad = Column(
        String(20),
        nullable=False,
        server_default="PUBLICO",
        default="PUBLICO",
    )
    enlace_registro_ms = Column(Text, nullable=True)
    imagen_url = Column(Text, nullable=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)


class AsistenciaModel(Base):
    __tablename__ = "asistencias"
    __table_args__ = (
        UniqueConstraint(
            "evento_id",
            "usuario_matricula",
            name="uq_asistencias_evento_usuario",
        ),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    evento_id = Column(
        UUID(as_uuid=True),
        ForeignKey("eventos.id", ondelete="CASCADE"),
        nullable=False,
    )
    usuario_matricula = Column(
        String,
        ForeignKey("usuarios.matricula", ondelete="CASCADE"),
        nullable=False,
    )
    estado = Column(
        String(20),
        nullable=False,
        server_default="confirmado",
        default="confirmado",
    )
    actualizado_en = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
import uuid
from sqlalchemy import Column, DateTime, ForeignKey, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.sql import func

from linkclub.adapters.outbound.postgres.database import Base


class PublicacionModel(Base):
    __tablename__ = "publicaciones"
    __table_args__ = (
        UniqueConstraint(
            "autor_matricula",
            "idempotency_key",
            name="uq_publicaciones_autor_idempotency",
        ),
    )

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
    contenido = Column(Text, nullable=False)
    tipo = Column(String, nullable=False, server_default="aviso")
    opciones = Column(JSONB, nullable=True)
    imagen_url = Column(Text, nullable=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    idempotency_key = Column(String, nullable=True)

class PublicacionLikeModel(Base):
    __tablename__ = "publicacion_likes"
    __table_args__ = (
        UniqueConstraint(
            "publicacion_id",
            "usuario_matricula",
            name="uq_publicacion_likes_pub_usuario",
        ),
    )
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    publicacion_id = Column(
        UUID(as_uuid=True),
        ForeignKey("publicaciones.id", ondelete="CASCADE"),
        nullable=False,
    )
    usuario_matricula = Column(
        String,
        ForeignKey("usuarios.matricula", ondelete="CASCADE"),
        nullable=False,
    )
    creado_en = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
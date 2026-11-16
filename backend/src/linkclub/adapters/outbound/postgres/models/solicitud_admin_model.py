import uuid
from sqlalchemy import Column, DateTime, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func

from linkclub.adapters.outbound.postgres.database import Base


class SolicitudAdminClubModel(Base):
    __tablename__ = "solicitudes_admin_club"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    usuario_matricula = Column(
        String(20),
        ForeignKey("usuarios.matricula", ondelete="CASCADE"),
        nullable=False,
    )
    club_id = Column(
        UUID(as_uuid=True),
        ForeignKey("clubes.id", ondelete="CASCADE"),
        nullable=False,
    )
    justificacion = Column(Text, nullable=False)
    estado = Column(String(20), nullable=False, server_default="PENDIENTE", default="PENDIENTE")
    revisado_por = Column(String(20), nullable=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
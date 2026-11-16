import uuid
from sqlalchemy import Boolean, Column, DateTime, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.sql import func

from linkclub.adapters.outbound.postgres.database import Base


class ClubModel(Base):
    __tablename__ = "clubes"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    nombre = Column(String, nullable=False)
    descripcion = Column(Text, nullable=False)
    descripcion_completa = Column(Text, nullable=True)
    categoria = Column(String, nullable=False)
    icono = Column(String, nullable=True)
    logo_url = Column(Text, nullable=True)
    horario = Column(String, nullable=True)
    lugar = Column(String, nullable=True)
    lider = Column(String, nullable=True)
    redes_json = Column(JSONB, nullable=False, server_default="{}", default=dict)
    inscripciones_abiertas = Column(Boolean, nullable=False, server_default="false", default=False)
    ms_forms_url = Column(Text, nullable=True)
    aviso_inscripcion = Column(Text, nullable=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
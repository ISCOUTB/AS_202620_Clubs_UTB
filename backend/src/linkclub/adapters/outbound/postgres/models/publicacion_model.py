from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from linkclub.adapters.outbound.postgres.database import Base

class PublicacionModel(Base):
    __tablename__ = "publicaciones"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    club_id = Column(Integer, ForeignKey("clubes.id", ondelete="CASCADE"), nullable=False)
    autor_matricula = Column(String, ForeignKey("usuarios.matricula", ondelete="CASCADE"), nullable=False)
    titulo = Column(String, nullable=False)
    contenido = Column(Text, nullable=False)
    tipo = Column(String, nullable=False, server_default='aviso')
    opciones = Column(JSONB, nullable=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    idempotency_key = Column(String, unique=True, nullable=True)
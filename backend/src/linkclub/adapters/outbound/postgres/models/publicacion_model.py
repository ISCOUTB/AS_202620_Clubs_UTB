from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from linkclub.adapters.outbound.postgres.database import Base

class PublicacionModel(Base):
    __tablename__ = "publicaciones"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    club_id = Column(Integer, ForeignKey("clubes.id", ondelete="CASCADE"), nullable=False, default=1)
    autor_matricula = Column(String, ForeignKey("usuarios.matricula", ondelete="CASCADE"), nullable=False)
    titulo = Column(String, nullable=False, default="Aviso")
    contenido = Column(Text, nullable=False)
    tipo = Column(String, nullable=False, default="aviso")
    opciones = Column(JSON, nullable=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    autor = relationship("UsuarioModel", foreign_keys=[autor_matricula], lazy="joined")
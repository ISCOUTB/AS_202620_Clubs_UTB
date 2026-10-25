from sqlalchemy import Column, String, DateTime, Text
from sqlalchemy.sql import func
from linkclub.adapters.outbound.postgres.database import Base

class PublicacionModel(Base):
    __tablename__ = "publicaciones"

    id = Column(String, primary_key=True, index=True)
    autor_nombre = Column(String, nullable=False)
    contenido = Column(Text, nullable=False)
    imagen_url = Column(String, nullable=True)
    idempotency_key = Column(String, unique=True, index=True, nullable=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now())
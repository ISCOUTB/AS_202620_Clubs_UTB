from sqlalchemy import Column, String, DateTime
from sqlalchemy.sql import func

from linkclub.adapters.outbound.postgres.database import Base

class UsuarioModel(Base):
    __tablename__ = "usuarios"

    matricula = Column(String, primary_key=True, index=True)
    nombre = Column(String, nullable=False)
    correo = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    creado_en = Column(DateTime(timezone=True), server_default=func.now())
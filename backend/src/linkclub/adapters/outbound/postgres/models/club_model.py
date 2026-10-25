from sqlalchemy import Column, Integer, String, Text, DateTime
from sqlalchemy.sql import func
from linkclub.adapters.outbound.postgres.database import Base

class ClubModel(Base):
    __tablename__ = "clubes"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    nombre = Column(String, nullable=False)
    descripcion = Column(Text, nullable=False)
    categoria = Column(String, nullable=False)
    creado_en = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
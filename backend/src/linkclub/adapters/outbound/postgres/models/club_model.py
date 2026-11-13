import uuid
from sqlalchemy import Column, String, Text, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from linkclub.adapters.outbound.postgres.database import Base

class ClubModel(Base):
    __tablename__ = "clubes"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    nombre = Column(String, nullable=False)
    descripcion = Column(Text, nullable=False)
    categoria = Column(String, nullable=False)
    creado_en = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
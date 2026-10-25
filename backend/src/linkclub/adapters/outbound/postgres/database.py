import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

from .models.club_model import ClubModel
from .models.usuario_model import UsuarioModel
from .models.publicacion_model import PublicacionModel

SQLALCHEMY_DATABASE_URL = os.environ.get(
    "DATABASE_URL", 
    "postgresql://postgres:postgres@localhost:5432/linkclub"
)

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
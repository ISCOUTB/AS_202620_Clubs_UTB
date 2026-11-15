import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

_raw_db_url = os.environ.get(
    "DATABASE_URL",
    "postgresql://postgres:postgres@localhost:5432/linkclub",
)

if _raw_db_url.startswith("postgres://"):
    SQLALCHEMY_DATABASE_URL = _raw_db_url.replace("postgres://", "postgresql://", 1)
else:
    SQLALCHEMY_DATABASE_URL = _raw_db_url

_engine_kwargs = (
    {"connect_args": {"check_same_thread": False}}
    if SQLALCHEMY_DATABASE_URL.startswith("sqlite")
    else {"pool_pre_ping": True}
)

engine = create_engine(SQLALCHEMY_DATABASE_URL, **_engine_kwargs)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
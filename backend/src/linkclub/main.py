from contextlib import asynccontextmanager
import logging
import os
from uuid import NAMESPACE_DNS, uuid5

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from linkclub.adapters.inbound.api.auth_router import router as auth_router
from linkclub.adapters.inbound.api.club_router import router as club_router
from linkclub.adapters.inbound.api.evento_router import router as evento_router
from linkclub.adapters.inbound.api.health_router import router as health_router
from linkclub.adapters.inbound.api.publicacion_router import router as publicacion_router
from linkclub.adapters.inbound.api.recurso_router import router as recurso_router
from linkclub.adapters.inbound.api.usuario_router import router as usuario_router
from linkclub.adapters.outbound.persistence.in_memory_club_adapter import _SEMILLA
from linkclub.adapters.outbound.postgres.database import Base, SessionLocal, engine
from linkclub.adapters.outbound.postgres.models import (  # noqa: F401
    club_model,
    evento_model,
    publicacion_model,
    solicitud_admin_model,
    usuario_model,
)
from linkclub.adapters.outbound.postgres.models.club_model import ClubModel

logger = logging.getLogger("linkclub")

_MIGRACIONES_POSTGRES = (
    """
    ALTER TABLE clubes
        ADD COLUMN IF NOT EXISTS descripcion_completa TEXT,
        ADD COLUMN IF NOT EXISTS icono VARCHAR,
        ADD COLUMN IF NOT EXISTS logo_url TEXT,
        ADD COLUMN IF NOT EXISTS horario VARCHAR,
        ADD COLUMN IF NOT EXISTS lugar VARCHAR,
        ADD COLUMN IF NOT EXISTS lider VARCHAR,
        ADD COLUMN IF NOT EXISTS redes_json JSONB NOT NULL DEFAULT '{}'::jsonb,
        ADD COLUMN IF NOT EXISTS inscripciones_abiertas BOOLEAN NOT NULL DEFAULT false,
        ADD COLUMN IF NOT EXISTS ms_forms_url TEXT,
        ADD COLUMN IF NOT EXISTS aviso_inscripcion TEXT,
        ADD COLUMN IF NOT EXISTS creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
    """,
    """
    DO $$
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name = 'usuarios' AND column_name = 'matricula'
        ) THEN
            ALTER TABLE usuarios ADD COLUMN matricula VARCHAR;
            UPDATE usuarios SET matricula = COALESCE(id::text, gen_random_uuid()::text) WHERE matricula IS NULL;
            ALTER TABLE usuarios ALTER COLUMN matricula SET NOT NULL;
            ALTER TABLE usuarios ADD CONSTRAINT usuarios_matricula_key UNIQUE (matricula);
        END IF;
    END $$
    """,
    """
    ALTER TABLE usuarios
        ADD COLUMN IF NOT EXISTS rol VARCHAR(20) NOT NULL DEFAULT 'ESTUDIANTE',
        ADD COLUMN IF NOT EXISTS verificado BOOLEAN NOT NULL DEFAULT true,
        ADD COLUMN IF NOT EXISTS club_administrado_id UUID REFERENCES clubes(id) ON DELETE SET NULL,
        ADD COLUMN IF NOT EXISTS descripcion TEXT,
        ADD COLUMN IF NOT EXISTS foto_perfil_url TEXT,
        ADD COLUMN IF NOT EXISTS estado_cuenta VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
        ADD COLUMN IF NOT EXISTS creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
    """,
    """
    ALTER TABLE publicaciones
        ADD COLUMN IF NOT EXISTS autor_matricula VARCHAR,
        ADD COLUMN IF NOT EXISTS tipo VARCHAR NOT NULL DEFAULT 'aviso',
        ADD COLUMN IF NOT EXISTS opciones JSONB,
        ADD COLUMN IF NOT EXISTS creado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
        ADD COLUMN IF NOT EXISTS idempotency_key VARCHAR
    """,
    """
    CREATE UNIQUE INDEX IF NOT EXISTS uq_publicaciones_autor_idempotency
        ON publicaciones (autor_matricula, idempotency_key)
    """,
    """
    DO $$
    BEGIN
        ALTER TABLE publicaciones ALTER COLUMN autor_id DROP NOT NULL;
    EXCEPTION
        WHEN undefined_column THEN NULL;
    END $$
    """,
    """
    ALTER TABLE solicitudes_admin_club
        ADD COLUMN IF NOT EXISTS revisado_por VARCHAR(20),
        ADD COLUMN IF NOT EXISTS creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
    """,
)


def _sincronizar_columnas_postgres() -> None:
    """Asegura que las tablas existentes en PostgreSQL tengan todas las columnas del ORM."""
    if engine.dialect.name != "postgresql":
        return
    with engine.begin() as conn:
        for sentencia in _MIGRACIONES_POSTGRES:
            conn.execute(text(sentencia))


def _inicializar_base_datos() -> None:
    """Crea tablas faltantes y sincroniza los clubes semilla en PostgreSQL al arrancar."""
    try:
        Base.metadata.create_all(bind=engine)
        _sincronizar_columnas_postgres()
        with SessionLocal() as db:
            for nombre, descripcion, categoria in _SEMILLA:
                club_uuid = uuid5(NAMESPACE_DNS, f"linkclub.{nombre}")
                existe = db.query(ClubModel).filter(ClubModel.id == club_uuid).first()
                if not existe:
                    db.add(
                        ClubModel(
                            id=club_uuid,
                            nombre=nombre,
                            descripcion=descripcion,
                            categoria=categoria,
                        )
                    )
            db.commit()
    except SQLAlchemyError:
        logger.exception("No se pudo inicializar el esquema/semilla en PostgreSQL al arrancar")


@asynccontextmanager
async def lifespan(app: FastAPI):
    _inicializar_base_datos()
    yield


def _configurar_cors(app: FastAPI) -> None:
    origenes_raw = os.environ.get("CORS_ORIGINS", "")
    origenes = [o.strip() for o in origenes_raw.split(",") if o.strip()]
    if origenes:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=origenes,
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )


app = FastAPI(title="LinkClub API", version="3.1.0", lifespan=lifespan)
_configurar_cors(app)


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content={"detail": str(exc.errors())},
    )


upload_dir = os.environ.get("UPLOAD_DIR", "uploads")
os.makedirs(upload_dir, exist_ok=True)
app.mount("/static", StaticFiles(directory=upload_dir), name="static")

app.include_router(health_router)
app.include_router(auth_router)
app.include_router(usuario_router)
app.include_router(club_router)
app.include_router(publicacion_router)
app.include_router(evento_router)
app.include_router(recurso_router)
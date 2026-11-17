import os
import sys
import uuid
from pathlib import Path

import pytest
import yaml
from jsonschema import Draft202012Validator
from sqlalchemy import create_engine
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src")))
os.environ.setdefault("JWT_SECRET", "clave-secreta-de-prueba-para-ci-local-2026")

from linkclub.adapters.inbound.api.auth_dependency import get_auth_port
from linkclub.adapters.outbound.persistence.in_memory_club_adapter import _SEMILLA
from linkclub.adapters.outbound.postgres.database import Base, get_db
from linkclub.adapters.outbound.postgres.models import (  # noqa: F401
    club_model,
    evento_model,
    publicacion_model,
    solicitud_admin_model,
    usuario_model,
)
from linkclub.adapters.outbound.postgres.models.club_model import ClubModel
from linkclub.adapters.outbound.postgres.models.usuario_model import UsuarioModel
from linkclub.application.ports.outbound_auth_port import AuthPort, TokenInvalido
from linkclub.main import app


# SQLite no conoce JSONB ni UUID de PostgreSQL: en las pruebas se compilan a tipos compatibles.
@compiles(JSONB, "sqlite")
def _jsonb_en_sqlite(tipo, compilador, **kw):
    return "JSON"


@compiles(UUID, "sqlite")
def _uuid_en_sqlite(tipo, compilador, **kw):
    return "CHAR(36)"


TOKEN_VALIDO = "token-valido"
TOKEN_ADMIN_CLUB = "token-admin-club"
TOKEN_ESTUDIANTE = "token-estudiante"

AUTOR_DE_PRUEBA = "usuario-123"
ADMIN_CLUB_DE_PRUEBA = "T00011111"
ESTUDIANTE_DE_PRUEBA = "T00022222"

CLUB_1_ID = uuid.UUID("00000000-0000-0000-0000-000000000001")
CLUB_2_ID = uuid.UUID("00000000-0000-0000-0000-000000000002")
CLUB_3_ID = uuid.UUID("00000000-0000-0000-0000-000000000003")
CLUB_4_ID = uuid.UUID("00000000-0000-0000-0000-000000000004")
CLUB_5_ID = uuid.UUID("00000000-0000-0000-0000-000000000005")
CLUB_IDS = [CLUB_1_ID, CLUB_2_ID, CLUB_3_ID, CLUB_4_ID, CLUB_5_ID]


class AuthFalso(AuthPort):
    _TOKENS = {
        TOKEN_VALIDO: AUTOR_DE_PRUEBA,
        TOKEN_ADMIN_CLUB: ADMIN_CLUB_DE_PRUEBA,
        TOKEN_ESTUDIANTE: ESTUDIANTE_DE_PRUEBA,
    }

    def verificar(self, token: str) -> str:
        identidad = self._TOKENS.get(token)
        if identidad is not None:
            return identidad
        raise TokenInvalido()


@pytest.fixture(autouse=True)
def entorno_de_prueba():
    """BD SQLite en memoria (una nueva por prueba) y autenticacion falsa."""
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    Sesion = sessionmaker(autocommit=False, autoflush=False, bind=engine)

    with Sesion() as db:
        db.add_all(
            [
                ClubModel(
                    id=CLUB_IDS[i],
                    nombre=nombre,
                    descripcion=descripcion,
                    categoria=categoria,
                )
                for i, (nombre, descripcion, categoria) in enumerate(_SEMILLA)
            ]
        )
        db.add_all(
            [
                UsuarioModel(
                    matricula=AUTOR_DE_PRUEBA,
                    nombre="Usuario de prueba",
                    correo="usuario123@utb.edu.co",
                    password_hash="x",
                    rol="SUPERADMIN",
                ),
                UsuarioModel(
                    matricula=ADMIN_CLUB_DE_PRUEBA,
                    nombre="Admin Club Prueba",
                    correo="adminclub@utb.edu.co",
                    password_hash="x",
                    rol="ADMIN_CLUB",
                    verificado=True,
                    club_administrado_id=CLUB_1_ID,
                ),
                UsuarioModel(
                    matricula=ESTUDIANTE_DE_PRUEBA,
                    nombre="Estudiante Prueba",
                    correo="estudiante@utb.edu.co",
                    password_hash="x",
                    rol="ESTUDIANTE",
                ),
            ]
        )
        db.commit()

    def _get_db():
        db = Sesion()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_auth_port] = lambda: AuthFalso()
    app.dependency_overrides[get_db] = _get_db
    yield
    app.dependency_overrides.clear()
    Base.metadata.drop_all(engine)
    engine.dispose()


@pytest.fixture
def headers_auth():
    return {"Authorization": f"Bearer {TOKEN_VALIDO}"}


@pytest.fixture
def headers_admin_club():
    return {"Authorization": f"Bearer {TOKEN_ADMIN_CLUB}"}


@pytest.fixture
def headers_estudiante():
    return {"Authorization": f"Bearer {TOKEN_ESTUDIANTE}"}


RUTA_CONTRATO = Path(__file__).resolve().parents[2] / "docs" / "api" / "openapi.yaml"
_contrato = yaml.safe_load(RUTA_CONTRATO.read_text(encoding="utf-8"))


@pytest.fixture
def validar():
    def _validar(cuerpo, nombre_schema):
        schema = {
            "$ref": f"#/components/schemas/{nombre_schema}",
            "components": _contrato["components"],
        }
        Draft202012Validator(schema).validate(cuerpo)

    return _validar
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src")))
os.environ.setdefault("SUPABASE_URL", "https://proyecto-de-prueba.supabase.co")

import pytest
from fastapi.testclient import TestClient

from linkclub.adapters.inbound.api.auth_dependency import get_auth_port
from linkclub.application.ports.outbound_auth_port import AuthPort, TokenInvalido
from linkclub.main import app

TOKEN_VALIDO = "token-valido"
AUTOR_DE_PRUEBA = "usuario-123"


class AuthFalso(AuthPort):
    def verificar(self, token: str) -> str:
        if token == TOKEN_VALIDO:
            return AUTOR_DE_PRUEBA
        raise TokenInvalido()


@pytest.fixture(autouse=True)
def auth_falso():
    app.dependency_overrides[get_auth_port] = lambda: AuthFalso()
    yield
    app.dependency_overrides.clear()


@pytest.fixture
def headers_auth():
    return {"Authorization": f"Bearer {TOKEN_VALIDO}"}
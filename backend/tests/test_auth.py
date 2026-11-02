from fastapi.routing import APIRoute

from linkclub.adapters.inbound.api.auth_dependency import require_auth


import os
import sys
from fastapi.testclient import TestClient
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src")))

from linkclub.main import app  # pyright: ignore[reportMissingImports]

client = TestClient(app)


CUERPO = {"titulo": "x", "contenido": "y"}


def test_publicar_sin_token_devuelve_401():
    r = client.post("/clubes/1/publicaciones", json=CUERPO)
    assert r.status_code == 401
    assert isinstance(r.json()["detail"], str)


def test_publicar_con_token_invalido_devuelve_401():
    r = client.post(
        "/clubes/1/publicaciones",
        json=CUERPO,
        headers={"Authorization": "Bearer token-falso"},
    )
    assert r.status_code == 401
    assert isinstance(r.json()["detail"], str)


def test_publicar_con_token_valido_devuelve_201(headers_auth):
    r = client.post("/clubes/1/publicaciones", json=CUERPO, headers=headers_auth)
    assert r.status_code == 201


def test_listar_publicaciones_es_publico():
    r = client.get("/clubes/1/publicaciones")
    assert r.status_code == 200



METODOS_ESCRITURA = {"POST", "PUT", "PATCH", "DELETE"}
# Rutas de escritura que son publicas por definicion (no hay sesion antes de entrar).
ESCRITURA_PUBLICA = {"/auth/login", "/auth/registro"}


def _rutas_api(rutas):
    """Aplana app.routes: en FastAPI reciente include_router deja _IncludedRouter."""
    for r in rutas:
        if isinstance(r, APIRoute):
            yield r
        elif hasattr(r, "original_router"):
            yield from _rutas_api(r.original_router.routes)


def _depende_de_require_auth(dependant) -> bool:
    return any(
        d.call is require_auth or _depende_de_require_auth(d)
        for d in dependant.dependencies
    )


def test_toda_ruta_de_escritura_exige_auth():
    rutas = [
        r for r in _rutas_api(app.routes)
        if r.methods & METODOS_ESCRITURA and r.path not in ESCRITURA_PUBLICA
    ]
    assert rutas, "No se encontró ninguna ruta de escritura"

    sin_auth = [r.path for r in rutas if not _depende_de_require_auth(r.dependant)]
    print(f"\nU3: {len(rutas) - len(sin_auth)} de {len(rutas)} rutas de escritura protegidas")
    assert not sin_auth, f"Rutas de escritura sin auth: {sin_auth}"

def test_publicacion_guarda_el_autor_del_token(headers_auth):
    r = client.post("/clubes/4/publicaciones", json=CUERPO, headers=headers_auth)
    assert r.status_code == 201
    assert r.json()["autor_id"] == "usuario-123"  # AUTOR_DE_PRUEBA de conftest.py
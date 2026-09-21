from pathlib import Path

import yaml
from fastapi.testclient import TestClient
from jsonschema import Draft202012Validator
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src")))

from linkclub.main import app

RUTA = Path(__file__).resolve().parents[2] / "docs" / "api" / "openapi.yaml"
contrato = yaml.safe_load(RUTA.read_text(encoding="utf-8"))
client = TestClient(app)


def validar(cuerpo, nombre_schema):
    schema = {
        "$ref": f"#/components/schemas/{nombre_schema}",
        "components": contrato["components"],
    }
    Draft202012Validator(schema).validate(cuerpo)


def test_health_cumple_contrato():
    r = client.get("/health")
    assert r.status_code == 200
    validar(r.json(), "HealthStatus")



def test_crear_publicacion_cumple_contrato():
    r = client.post(
        "/clubes/club-1/publicaciones",
        json={"titulo": "Hola", "contenido": "Reunion el lunes", "tipo": "aviso"},
    )
    assert r.status_code == 201
    validar(r.json(), "Publicacion")


def test_rutas_del_codigo_existen_en_el_contrato():
    for ruta in app.openapi()["paths"]:
        assert ruta in contrato["paths"], f"{ruta} no esta en el contrato"

def test_noticia_cumple_contrato():
    r = client.post(
        "/clubes/club-2/publicaciones",
        json={"titulo": "Ganamos", "contenido": "Torneo interno", "tipo": "noticia"},
    )
    assert r.status_code == 201
    validar(r.json(), "Publicacion")


def test_error_422_cumple_contrato():
    r = client.post("/clubes/club-3/publicaciones", json={"contenido": "sin titulo"})
    assert r.status_code == 422
    validar(r.json(), "ErrorResponse")
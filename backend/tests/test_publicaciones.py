import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src")))

from fastapi.testclient import TestClient
from linkclub.main import app

client = TestClient(app)


def test_crear_publicacion_tipo_aviso():
    response = client.post(
        "/publicaciones",
        json={
            "club_id": "club-ajedrez",
            "titulo": "Reunión general",
            "contenido": "Este sábado a las 10am en el auditorio",
            "tipo": "aviso",
        },
    )
    assert response.status_code == 201
    body = response.json()
    assert body["tipo"] == "aviso"
    assert body["club_id"] == "club-ajedrez"


def test_listar_publicaciones_por_club():
    client.post(
        "/publicaciones",
        json={"club_id": "club-futbol", "titulo": "Torneo", "contenido": "Inscripciones abiertas", "tipo": "aviso"},
    )
    response = client.get("/publicaciones/club-futbol")
    assert response.status_code == 200
    assert len(response.json()) == 1


def test_crear_publicacion_tipo_no_soportado():
    response = client.post(
        "/publicaciones",
        json={"club_id": "club-musica", "titulo": "x", "contenido": "y", "tipo": "invalido"},
    )
    assert response.status_code == 422


def test_crear_publicacion_tipo_encuesta():
    response = client.post(
        "/publicaciones",
        json={
            "club_id": "club-ajedrez",
            "titulo": "¿Qué horario prefieren para el torneo?",
            "contenido": "Vota por la opción que más te convenga",
            "tipo": "encuesta",
            "opciones": ["Sábado 9am", "Sábado 2pm", "Domingo 10am"],
        },
    )
    assert response.status_code == 201
    body = response.json()
    assert body["tipo"] == "encuesta"
    assert body["opciones"] == ["Sábado 9am", "Sábado 2pm", "Domingo 10am"]


def test_crear_encuesta_sin_opciones_falla():
    response = client.post(
        "/publicaciones",
        json={"club_id": "club-ajedrez", "titulo": "Encuesta vacía", "contenido": "x", "tipo": "encuesta"},
    )
    assert response.status_code == 422
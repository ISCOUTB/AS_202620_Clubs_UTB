from fastapi.testclient import TestClient
from linkclub.main import app

client = TestClient(app)


def test_crear_publicacion_tipo_aviso(headers_auth):
    response = client.post(
        "/clubes/club-ajedrez/publicaciones",
        json={
            "titulo": "Reunión general",
            "contenido": "Este sábado a las 10am en el auditorio",
            "tipo": "aviso",
        },
        headers=headers_auth,
    )
    assert response.status_code == 201
    body = response.json()
    assert body["tipo"] == "aviso"
    assert body["club_id"] == "club-ajedrez"
    assert "creado_en" in body


def test_listar_publicaciones_por_club(headers_auth):
    client.post(
        "/clubes/club-futbol/publicaciones",
        json={"titulo": "Torneo", "contenido": "Inscripciones abiertas", "tipo": "aviso"},
        headers=headers_auth,
    )
    response = client.get("/clubes/club-futbol/publicaciones")
    assert response.status_code == 200
    assert len(response.json()) == 1


def test_crear_publicacion_tipo_no_soportado(headers_auth):
    response = client.post(
        "/clubes/club-musica/publicaciones",
        json={"titulo": "x", "contenido": "y", "tipo": "invalido"},
        headers=headers_auth,
    )
    assert response.status_code == 422


def test_crear_publicacion_tipo_encuesta(headers_auth):
    response = client.post(
        "/clubes/club-ajedrez/publicaciones",
        json={
            "titulo": "¿Qué horario prefieren para el torneo?",
            "contenido": "Vota por la opción que más te convenga",
            "tipo": "encuesta",
            "opciones": ["Sábado 9am", "Sábado 2pm", "Domingo 10am"],
        },
        headers=headers_auth,
    )
    assert response.status_code == 201
    body = response.json()
    assert body["tipo"] == "encuesta"
    assert body["opciones"] == ["Sábado 9am", "Sábado 2pm", "Domingo 10am"]


def test_crear_encuesta_sin_opciones_falla(headers_auth):
    response = client.post(
        "/clubes/club-ajedrez/publicaciones",
        json={"titulo": "Encuesta vacía", "contenido": "x", "tipo": "encuesta"},
        headers=headers_auth,
    )
    assert response.status_code == 422


def test_crear_publicacion_tipo_noticia(headers_auth):
    response = client.post(
        "/clubes/club-teatro/publicaciones",
        json={"titulo": "Ganamos", "contenido": "Torneo interno", "tipo": "noticia"},
        headers=headers_auth,
    )
    assert response.status_code == 201
    assert response.json()["tipo"] == "noticia"


def test_error_de_validacion_usa_formato_uniforme(headers_auth):
    response = client.post(
        "/clubes/club-teatro/publicaciones",
        json={"contenido": "falta el titulo"},
        headers=headers_auth,
    )
    assert response.status_code == 422
    assert isinstance(response.json()["detail"], str)


def test_club_id_en_el_cuerpo_es_rechazado(headers_auth):
    response = client.post(
        "/clubes/club-teatro/publicaciones",
        json={"club_id": "otro", "titulo": "x", "contenido": "y"},
        headers=headers_auth,
    )
    assert response.status_code == 422
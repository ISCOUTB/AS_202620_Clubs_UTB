import uuid
from datetime import datetime, timedelta, timezone

from fastapi.testclient import TestClient

from linkclub.main import app

client = TestClient(app)

CLUB_1_ID = uuid.UUID("00000000-0000-0000-0000-000000000001")
CLUB_2_ID = uuid.UUID("00000000-0000-0000-0000-000000000002")


def test_flujo_eventos_permisos_y_asistencia(
    headers_admin_club,
    headers_estudiante,
    validar,
):
    inicio = (datetime.now(timezone.utc) + timedelta(days=2)).isoformat()
    fin = (datetime.now(timezone.utc) + timedelta(days=2, hours=2)).isoformat()

    resp_forbidden = client.post(
        "/eventos",
        headers=headers_estudiante,
        json={
            "club_id": str(CLUB_1_ID),
            "titulo": "Evento no autorizado",
            "descripcion": "Intento de estudiante",
            "fecha_inicio": inicio,
            "lugar": "Campus UTB",
        },
    )
    assert resp_forbidden.status_code == 403

    resp_otro_club = client.post(
        "/eventos",
        headers=headers_admin_club,
        json={
            "club_id": str(CLUB_2_ID),
            "titulo": "Evento asignado a su propio club",
            "descripcion": "El backend fuerza club_administrado_id.",
            "fecha_inicio": inicio,
            "lugar": "Campus UTB",
        },
    )
    assert resp_otro_club.status_code == 201
    assert resp_otro_club.json()["club_id"] == str(CLUB_1_ID)

    resp_crear = client.post(
        "/eventos",
        headers=headers_admin_club,
        json={
            "titulo": "Taller de Robótica Móvil",
            "descripcion": "Introducción a sensores y control.",
            "fecha_inicio": inicio,
            "fecha_fin": fin,
            "lugar": "Lab 3, Módulo A",
            "visibilidad": "PUBLICO",
        },
    )
    assert resp_crear.status_code == 201
    evento = resp_crear.json()
    validar(evento, "Evento")
    evento_id = evento["id"]
    assert evento["club_id"] == str(CLUB_1_ID)
    assert evento["total_asistentes"] == 0
    assert evento["usuario_asiste"] is False

    resp_lista = client.get("/eventos")
    assert resp_lista.status_code == 200
    eventos = resp_lista.json()
    assert len(eventos) == 2
    validar(eventos[0], "Evento")

    resp_asistir = client.post(
        f"/eventos/{evento_id}/asistencia",
        headers=headers_estudiante,
    )
    assert resp_asistir.status_code == 200
    validar(resp_asistir.json(), "AsistenciaToggleResponse")
    assert resp_asistir.json() == {"usuario_asiste": True, "total_asistentes": 1}

    resp_cancelar = client.post(
        f"/eventos/{evento_id}/asistencia",
        headers=headers_estudiante,
    )
    assert resp_cancelar.status_code == 200
    validar(resp_cancelar.json(), "AsistenciaToggleResponse")
    assert resp_cancelar.json() == {"usuario_asiste": False, "total_asistentes": 0}


def test_evento_solo_club_oculto_para_usuarios_externos(
    headers_admin_club,
    headers_estudiante,
):
    inicio = (datetime.now(timezone.utc) + timedelta(days=3)).isoformat()

    resp = client.post(
        "/eventos",
        headers=headers_admin_club,
        json={
            "titulo": "Reunión Interna Directiva",
            "descripcion": "Planificación semestral del club.",
            "fecha_inicio": inicio,
            "lugar": "Sala de Juntas B",
            "visibilidad": "SOLO_CLUB",
        },
    )
    assert resp.status_code == 201
    evento_id = resp.json()["id"]

    assert client.get("/eventos").json() == []
    assert client.get("/eventos", headers=headers_estudiante).json() == []

    visibles_admin = client.get("/eventos", headers=headers_admin_club).json()
    assert any(e["id"] == evento_id for e in visibles_admin)
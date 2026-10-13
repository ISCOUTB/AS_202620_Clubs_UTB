from fastapi.testclient import TestClient

from linkclub.main import app

client = TestClient(app)


def test_listar_clubes_devuelve_la_semilla():
    r = client.get("/clubes")
    assert r.status_code == 200
    assert len(r.json()) == 5


def test_listar_clubes_cumple_contrato(validar):
    for club in client.get("/clubes").json():
        validar(club, "Club")


def test_buscar_por_texto_ignora_mayusculas():
    r = client.get("/clubes", params={"q": "ROBÓTICA"})
    assert [c["nombre"] for c in r.json()] == ["Club de Robótica"]


def test_filtrar_por_categoria():
    r = client.get("/clubes", params={"categoria": "arte y cultura"})
    assert len(r.json()) == 2


def test_busqueda_sin_resultados_devuelve_lista_vacia():
    r = client.get("/clubes", params={"q": "no-existe"})
    assert r.status_code == 200
    assert r.json() == []


def test_obtener_club_existente():
    club = client.get("/clubes").json()[0]
    r = client.get(f"/clubes/{club['id']}")
    assert r.status_code == 200
    assert r.json() == club


def test_obtener_club_inexistente_devuelve_404_uniforme(validar):
    r = client.get("/clubes/no-existe")
    assert r.status_code == 404
    validar(r.json(), "ErrorResponse")
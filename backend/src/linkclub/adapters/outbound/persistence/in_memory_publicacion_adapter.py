from linkclub.application.ports.outbound_publicacion_repository_port import PublicacionRepositoryPort
from linkclub.domain.publicacion import Publicacion


class InMemoryPublicacionAdapter(PublicacionRepositoryPort):
    def __init__(self):
        self._publicaciones: list[Publicacion] = []

    def guardar(self, publicacion: Publicacion) -> Publicacion:
        self._publicaciones.append(publicacion)
        return publicacion

    def listar_por_club(self, club_id: str) -> list[Publicacion]:
        return [p for p in self._publicaciones if p.club_id == club_id]
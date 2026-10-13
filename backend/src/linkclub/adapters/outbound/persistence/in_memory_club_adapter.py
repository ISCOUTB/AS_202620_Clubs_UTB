from uuid import NAMESPACE_DNS, uuid5

from linkclub.application.ports.outbound_club_repository_port import ClubRepositoryPort
from linkclub.domain.club import Club

_SEMILLA = [
    ("Club de Programación", "Aprende programación y desarrolla proyectos de software.", "Tecnología"),
    ("Club de Robótica", "Diseña, construye y programa robots.", "Tecnología"),
    ("Club de Música", "Un espacio para compartir y desarrollar talentos musicales.", "Arte y cultura"),
    ("Club de Deportes", "Participa en actividades deportivas y conoce nuevos compañeros.", "Deportes"),
    ("Club de Fotografía", "Explora la fotografía y aprende nuevas técnicas.", "Arte y cultura"),
]


class InMemoryClubAdapter(ClubRepositoryPort):
    def __init__(self, con_semilla: bool = True):
        self._clubes: dict[str, Club] = {}
        if con_semilla:
            for nombre, descripcion, categoria in _SEMILLA:
                club = Club(
                    id=uuid5(NAMESPACE_DNS, f"linkclub.{nombre}"),
                    nombre=nombre,
                    descripcion=descripcion,
                    categoria=categoria,
                )
                self._clubes[str(club.id)] = club

    def listar(self, q: str | None = None, categoria: str | None = None) -> list[Club]:
        resultado = list(self._clubes.values())
        if categoria:
            resultado = [c for c in resultado if c.categoria.lower() == categoria.lower()]
        if q:
            texto = q.lower()
            resultado = [
                c for c in resultado
                if texto in c.nombre.lower() or texto in c.descripcion.lower()
            ]
        return resultado

    def obtener(self, club_id: str) -> Club | None:
        return self._clubes.get(club_id)
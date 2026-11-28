from uuid import NAMESPACE_DNS, uuid5

from linkclub.application.ports.outbound_club_repository_port import ClubRepositoryPort
from linkclub.domain.club import Club

_SEMILLA = [
    ("AIChE UTB", "Capítulo estudiantil del American Institute of Chemical Engineers en la UTB.", "Ciencia e Ingeniería"),
    ("ACS Student Chapter General", "Capítulo estudiantil de la American Chemical Society dedicado a la divulgación científica y química verde.", "Ciencia e Ingeniería"),
    ("ANEIAP", "Capítulo UTB de la Asociación Nacional de Estudiantes de Ingeniería Industrial, Administrativa y de Producción.", "Ciencia e Ingeniería"),
    ("M.A.R UTB", "Grupo estudiantil de ingeniería naval, asuntos marítimos, portuarios y oceánicos de la UTB.", "Ciencia e Ingeniería"),
    ("Mentoras WSTEM 2026", "Red de mentoría y liderazgo de mujeres en Ciencia, Tecnología, Ingeniería y Matemáticas en la UTB.", "Ciencia e Ingeniería"),
    ("Rincón del dibujante", "Colectivo estudiantil de dibujo, ilustración tradicional y digital, cómic y artes visuales.", "Arte y Cultura"),
    ("Café y Crochet", "Espacio creativo y social de tejido en crochet, manualidades y tertulia alrededor del café.", "Arte y Cultura"),
    ("Cine y debate", "Cineclub universitario para proyección de películas, apreciación audiovisual y debate crítico.", "Arte y Cultura"),
    ("Club de Lectura UTB: Viajes Literarios", "Tertulia literaria y club de lectura para descubrir novelas, cuentos y ensayos en comunidad.", "Arte y Cultura"),
    ("Pastoral Universitaria UTB", "Espacio institucional de espiritualidad, acompañamiento humano y voluntariado solidario.", "Comunidad y Espiritualidad"),
    ("Koinonía", "Comunidad estudiantil cristiana de compañerismo, integración, música y valores en el campus.", "Comunidad y Espiritualidad"),
    ("FE UTB", "Grupo estudiantil de fe, oración, diálogo espiritual y acompañamiento fraterno en la UTB.", "Comunidad y Espiritualidad"),
    ("Francolombia", "Club de intercambio cultural y lingüístico franco-colombiano en la Universidad Tecnológica de Bolívar.", "Idiomas e Intercambio"),
    ("Hallyu UTB", "Comunidad estudiantil dedicada a la cultura coreana, idioma coreano, K-pop, K-drama y tradiciones.", "Idiomas e Intercambio"),
    ("Sociedad del juego", "Club universitario de juegos de mesa modernos, estrategia, rol y juegos de cartas.", "Juegos y Tecnología"),
    ("Endless", "Colectivo estudiantil de cultura gamer, eSports, desarrollo creativo e innovación digital.", "Juegos y Tecnología"),
    ("Proyecto CAHAFU", "Iniciativa estudiantil de innovación social, ideación y proyectos con impacto comunitario.", "Liderazgo e Impacto Social"),
    ("La Mesa Redonda", "Círculo estudiantil de diálogo, debate de ideas, pensamiento crítico y actualidad.", "Liderazgo e Impacto Social"),
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
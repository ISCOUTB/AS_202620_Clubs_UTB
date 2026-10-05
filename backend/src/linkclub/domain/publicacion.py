from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from uuid import UUID, uuid4


class TipoPublicacion(str, Enum):
    AVISO = "aviso"
    ENCUESTA = "encuesta"
    NOTICIA = "noticia"


@dataclass
class Publicacion:
    club_id: str
    autor_id: str  # solo la identidad (regla de dueño único); el perfil vive en Usuarios
    titulo: str
    contenido: str
    tipo: TipoPublicacion = TipoPublicacion.AVISO
    id: UUID = field(default_factory=uuid4)
    creada_en: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    # Solo se usa cuando tipo == ENCUESTA.
    opciones: list[str] | None = None
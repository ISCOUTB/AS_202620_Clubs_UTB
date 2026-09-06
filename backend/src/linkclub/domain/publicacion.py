from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from uuid import UUID, uuid4


class TipoPublicacion(str, Enum):
    AVISO = "aviso"
    ENCUESTA = "encuesta"


@dataclass
class Publicacion:
    club_id: str
    titulo: str
    contenido: str
    tipo: TipoPublicacion = TipoPublicacion.AVISO
    id: UUID = field(default_factory=uuid4)
    creada_en: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    # Solo se usa cuando tipo == ENCUESTA. Reutiliza la misma entidad Publicacion
    # en vez de crear una jerarquía de clases nueva, para que el resto del
    # sistema (repositorio, endpoints, casos de uso) no necesite conocer el tipo.
    opciones: list[str] | None = None
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from uuid import UUID, uuid4

class TipoPublicacion(str, Enum):
    AVISO = "aviso"
    ENCUESTA = "encuesta"
    NOTICIA = "noticia"

class PublicacionDuplicada(Exception):
    pass

@dataclass
class Publicacion:
    club_id: str
    autor_id: str
    titulo: str
    contenido: str
    tipo: TipoPublicacion = TipoPublicacion.AVISO
    id: UUID = field(default_factory=uuid4)
    creada_en: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    opciones: list[str] | None = None
    idempotency_key: str | None = None

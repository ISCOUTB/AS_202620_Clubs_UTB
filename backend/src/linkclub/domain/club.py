from dataclasses import dataclass, field
from datetime import datetime, timezone
from uuid import UUID, uuid4


class ClubNoEncontrado(Exception):
    ...


@dataclass
class Club:
    nombre: str
    descripcion: str
    categoria: str
    id: UUID = field(default_factory=uuid4)
    creado_en: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
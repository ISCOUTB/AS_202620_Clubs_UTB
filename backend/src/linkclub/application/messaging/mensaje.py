import json
import uuid
from dataclasses import asdict, dataclass
from datetime import datetime, timezone

from linkclub.domain.publicacion import Publicacion

TIPO = "publicacion.creada"
MAJOR_SOPORTADO = 1
CAMPOS_REQUERIDOS = ("publicacion_id", "club_id", "autor_id", "tipo", "titulo")


class ContratoInvalido(Exception):
    """Error permanente: reintentar no lo arregla."""


@dataclass(frozen=True)
class Mensaje:
    message_id: str
    type: str
    version: str
    correlation_id: str
    occurred_at: str
    data: dict

    @staticmethod
    def publicacion_creada(p: Publicacion, correlation_id: str | None = None) -> "Mensaje":
        return Mensaje(
            message_id=str(uuid.uuid4()),
            type=TIPO,
            version="1.0",
            correlation_id=correlation_id or str(uuid.uuid4()),
            occurred_at=datetime.now(timezone.utc).isoformat(),
            data={
                "publicacion_id": str(p.id),
                "club_id": p.club_id,
                "autor_id": p.autor_id,
                "tipo": p.tipo.value,
                "titulo": p.titulo,
            },
        )

    def a_json(self) -> str:
        return json.dumps(asdict(self))

    @staticmethod
    def desde_json(raw: str) -> "Mensaje":
        try:
            m = Mensaje(**json.loads(raw))
        except (ValueError, TypeError) as e:
            raise ContratoInvalido(f"mensaje ilegible: {e}") from e
        m.validar()
        return m

    def validar(self) -> None:
        if self.type != TIPO:
            raise ContratoInvalido(f"tipo inesperado: {self.type}")
        if str(self.version).split(".")[0] != str(MAJOR_SOPORTADO):
            raise ContratoInvalido(f"version mayor no soportada: {self.version}")
        faltan = [c for c in CAMPOS_REQUERIDOS if not isinstance(self.data.get(c), str)]
        if faltan:
            raise ContratoInvalido(f"campos requeridos ausentes: {faltan}")
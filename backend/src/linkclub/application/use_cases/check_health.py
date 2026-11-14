from linkclub.application.ports.inbound_health_port import HealthPort
from linkclub.application.ports.outbound_status_port import StatusPort


class ServicioNoDisponible(Exception):
    """Se lanza cuando una dependencia crítica (p. ej. PostgreSQL) no responde."""


class CheckHealthUseCase(HealthPort):
    def __init__(self, status_port: StatusPort):
        self.status_port = status_port

    def check(self) -> dict:
        status = self.status_port.get_status()
        if status != "ok":
            raise ServicioNoDisponible("Base de datos no disponible")
        return {"status": "ok", "database": "online"}
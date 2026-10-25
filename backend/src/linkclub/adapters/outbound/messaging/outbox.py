from linkclub.application.messaging.mensaje import Mensaje
from linkclub.application.messaging.observabilidad import Metricas, traza
from linkclub.application.ports.outbound_mensajeria_port import (
    ErrorTransitorio, OutboxPort, PublicadorPort,
)


class InMemoryOutbox(OutboxPort):
    def __init__(self):
        self._pend: dict[str, Mensaje] = {}

    def registrar(self, m): self._pend[m.message_id] = m
    def pendientes(self): return list(self._pend.values())
    def marcar_enviado(self, message_id): self._pend.pop(message_id, None)


class OutboxRelay:
    def __init__(self, outbox: OutboxPort, publicador: PublicadorPort, metricas: Metricas):
        self.outbox, self.publicador, self.metricas = outbox, publicador, metricas

    def drenar(self) -> int:
        enviados = 0
        for m in self.outbox.pendientes():
            try:
                self.publicador.publicar(m)
            except ErrorTransitorio:
                self.metricas.inc("outbox_fallos")
                traza("outbox_pendiente", m.message_id, m.correlation_id)
                break                        # queda pendiente, se reintenta luego
            self.outbox.marcar_enviado(m.message_id)
            enviados += 1
        return enviados
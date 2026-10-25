from linkclub.application.messaging.mensaje import Mensaje
from linkclub.application.messaging.observabilidad import Metricas, traza
from linkclub.application.ports.outbound_mensajeria_port import (
    DeduplicacionPort, NotificadorPort,
)


class NotificarPublicacionCreada:
    def __init__(self, notificador: NotificadorPort, dedup: DeduplicacionPort, metricas: Metricas):
        self.notificador, self.dedup, self.metricas = notificador, dedup, metricas

    def __call__(self, raw: str) -> None:
        m = Mensaje.desde_json(raw)               # ContratoInvalido -> permanente
        if self.dedup.ya_procesado(m.message_id):
            self.metricas.inc("duplicados_descartados")
            traza("duplicado_descartado", m.message_id, m.correlation_id)
            return
        self.notificador.notificar(               # ErrorTransitorio -> reintento
            m.data["club_id"], m.data["publicacion_id"], m.data["titulo"])
        self.dedup.marcar(m.message_id)           # se marca DESPUÉS del efecto
        self.metricas.inc("procesados")
        traza("procesado", m.message_id, m.correlation_id)
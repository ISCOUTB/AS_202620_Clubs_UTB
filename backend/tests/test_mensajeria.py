import logging
import re

from linkclub.adapters.outbound.messaging.in_memory_broker import (
    InMemoryBroker, PoliticaReintentos,
)
from linkclub.adapters.outbound.messaging.outbox import InMemoryOutbox, OutboxRelay
from linkclub.adapters.outbound.persistence.in_memory_dedup import InMemoryDedup
from linkclub.application.messaging.mensaje import Mensaje
from linkclub.application.messaging.observabilidad import Metricas
from linkclub.application.ports.outbound_mensajeria_port import (
    ErrorTransitorio, NotificadorPort,
)
from linkclub.application.use_cases.notificar_publicacion import NotificarPublicacionCreada
from linkclub.domain.publicacion import Publicacion


class NotificadorFalso(NotificadorPort):
    def __init__(self, fallos=0):
        self.fallos, self.enviados = fallos, []

    def notificar(self, club_id, publicacion_id, titulo):
        if self.fallos > 0:
            self.fallos -= 1
            raise ErrorTransitorio("servicio push caído")
        self.enviados.append(publicacion_id)


def armar(fallos=0):
    m, esperas = Metricas(), []
    broker = InMemoryBroker(m, PoliticaReintentos(max_intentos=4),
                            sleep=esperas.append, rng=lambda: 1.0)
    notif = NotificadorFalso(fallos)
    broker.suscribir(NotificarPublicacionCreada(notif, InMemoryDedup(), m))
    return broker, notif, m, esperas


def mensaje(**data_extra):
    msg = Mensaje.publicacion_creada(
        Publicacion(club_id="c1", autor_id="u1", titulo="Torneo", contenido="x"))
    if data_extra:
        msg = Mensaje(**{**msg.__dict__, "data": {**msg.data, **data_extra}})
    return msg


def test_duplicado_no_repite_el_efecto():
    broker, notif, m, _ = armar()
    broker.perder_acks = 1                      # el broker redelivera el mismo mensaje
    broker.publicar(mensaje())
    broker.procesar_pendientes()
    assert len(notif.enviados) == 1
    assert m.contadores["duplicados_descartados"] == 1


def test_fallo_recuperable_se_reintenta_con_backoff():
    broker, notif, m, esperas = armar(fallos=2)
    broker.publicar(mensaje())
    broker.procesar_pendientes()
    assert len(notif.enviados) == 1
    assert m.contadores["reintentos"] == 2
    assert esperas == [0.5, 1.0]                # exponencial (rng=1.0 => sin jitter)
    assert broker.dlq == []


def test_reintentos_agotados_van_a_dlq_y_se_pueden_reprocesar():
    broker, notif, m, _ = armar(fallos=99)
    broker.publicar(mensaje())
    broker.procesar_pendientes()
    assert len(broker.dlq) == 1
    assert notif.enviados == []
    notif.fallos = 0                           # el servicio se recuperó
    broker.reprocesar_dlq()
    assert len(notif.enviados) == 1 and broker.dlq == []


def test_mensaje_invalido_va_a_dlq_sin_reintentos():
    broker, notif, m, esperas = armar()
    broker.publicar(Mensaje(**{**mensaje().__dict__, "data": {"club_id": "c1"}}))
    broker.procesar_pendientes()
    assert len(broker.dlq) == 1 and esperas == []
    assert m.contadores["reintentos"] == 0


def test_campo_nuevo_opcional_es_compatible():
    broker, notif, _, _ = armar()
    msg = mensaje(campo_nuevo="x")
    broker.publicar(Mensaje(**{**msg.__dict__, "version": "1.1"}))
    broker.procesar_pendientes()
    assert len(notif.enviados) == 1


def test_version_mayor_incompatible_va_a_dlq():
    broker, _, _, _ = armar()
    broker.publicar(Mensaje(**{**mensaje().__dict__, "version": "2.0"}))
    broker.procesar_pendientes()
    assert len(broker.dlq) == 1


def test_outbox_recupera_publicacion_cuando_el_broker_vuelve():
    broker, notif, m, _ = armar()
    outbox = InMemoryOutbox()
    relay = OutboxRelay(outbox, broker, m)
    outbox.registrar(mensaje())
    broker.caido = True
    assert relay.drenar() == 0 and len(outbox.pendientes()) == 1
    broker.caido = False
    assert relay.drenar() == 1 and outbox.pendientes() == []
    broker.procesar_pendientes()
    assert len(notif.enviados) == 1


def test_un_mensaje_se_puede_seguir_de_productor_a_consumidor(caplog):
    caplog.set_level(logging.INFO, logger="linkclub.mensajeria")
    broker, _, _, _ = armar(fallos=1)
    msg = mensaje()
    broker.publicar(msg)
    broker.procesar_pendientes()
    etapas = [re.search(r"etapa=(\w+)", r.getMessage()).group(1)
              for r in caplog.records if msg.message_id in r.getMessage()]
    assert etapas == ["publicado", "recibido", "reintento", "recibido", "procesado", "ack"]
    assert all(msg.correlation_id in r.getMessage() for r in caplog.records)
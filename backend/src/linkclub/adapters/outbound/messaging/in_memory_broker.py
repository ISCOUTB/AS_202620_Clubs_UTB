import random
import time
from collections import deque
from dataclasses import dataclass

from linkclub.application.messaging.mensaje import ContratoInvalido, Mensaje
from linkclub.application.messaging.observabilidad import Metricas, traza
from linkclub.application.ports.outbound_mensajeria_port import (
    ErrorTransitorio, PublicadorPort,
)


@dataclass(frozen=True)
class PoliticaReintentos:
    max_intentos: int = 4
    base_s: float = 0.5
    tope_s: float = 8.0

    def espera(self, intento: int, rng=random.random) -> float:
        return rng() * min(self.tope_s, self.base_s * 2 ** (intento - 1))  # full jitter


@dataclass
class _Entrega:
    raw: str
    message_id: str
    correlation_id: str
    intentos: int = 0


class InMemoryBroker(PublicadorPort):
    """Simula entrega al-menos-una-vez: reintenta y puede redeliverar."""

    def __init__(self, metricas: Metricas, politica: PoliticaReintentos = PoliticaReintentos(),
                 sleep=time.sleep, rng=random.random):
        self._m, self._p, self._sleep, self._rng = metricas, politica, sleep, rng
        self._cola: deque[_Entrega] = deque()
        self._handler = None
        self.dlq: list[tuple[_Entrega, str]] = []
        self.caido = False        # simula broker no disponible
        self.perder_acks = 0      # simula ack perdido -> redelivery

    def suscribir(self, handler) -> None:
        self._handler = handler

    def publicar(self, m: Mensaje) -> None:
        if self.caido:
            raise ErrorTransitorio("broker no disponible")
        self._cola.append(_Entrega(m.a_json(), m.message_id, m.correlation_id))
        self._m.inc("publicados")
        traza("publicado", m.message_id, m.correlation_id)

    def procesar_pendientes(self) -> None:
        while self._cola:
            e = self._cola.popleft()
            e.intentos += 1
            traza("recibido", e.message_id, e.correlation_id, intento=e.intentos)
            try:
                self._handler(e.raw)
            except ContratoInvalido as exc:                       # no se reintenta
                self._a_dlq(e, f"contrato: {exc}")
                continue
            except ErrorTransitorio as exc:
                if e.intentos >= self._p.max_intentos:
                    self._a_dlq(e, f"reintentos agotados: {exc}")
                    continue
                espera = self._p.espera(e.intentos, self._rng)
                self._m.inc("reintentos")
                traza("reintento", e.message_id, e.correlation_id,
                      intento=e.intentos, espera_s=round(espera, 2))
                self._sleep(espera)
                self._cola.appendleft(e)
                continue
            if self.perder_acks > 0:                              # el ack no llega
                self.perder_acks -= 1
                e.intentos = 0
                self._cola.append(e)
                traza("ack_perdido", e.message_id, e.correlation_id)
            else:
                traza("ack", e.message_id, e.correlation_id)

    def _a_dlq(self, e: _Entrega, motivo: str) -> None:
        self.dlq.append((e, motivo))
        self._m.inc("dlq")
        traza("dlq", e.message_id, e.correlation_id, motivo=motivo)

    def reprocesar_dlq(self) -> None:
        pendientes, self.dlq = self.dlq, []
        for e, _ in pendientes:
            e.intentos = 0
            self._cola.append(e)
        self.procesar_pendientes()
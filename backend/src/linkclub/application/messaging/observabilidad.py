import logging
from collections import Counter

logger = logging.getLogger("linkclub.mensajeria")


class Metricas:
    def __init__(self):
        self.contadores: Counter = Counter()

    def inc(self, nombre: str) -> None:
        self.contadores[nombre] += 1


def traza(etapa: str, message_id: str, correlation_id: str, **extra) -> None:
    detalle = " ".join(f"{k}={v}" for k, v in extra.items())
    logger.info("etapa=%s message_id=%s correlation_id=%s %s",
                etapa, message_id, correlation_id, detalle)
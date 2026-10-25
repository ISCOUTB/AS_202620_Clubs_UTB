from linkclub.application.ports.outbound_mensajeria_port import DeduplicacionPort


class InMemoryDedup(DeduplicacionPort):
    def __init__(self): self._ids: set[str] = set()
    def ya_procesado(self, message_id): return message_id in self._ids
    def marcar(self, message_id): self._ids.add(message_id)
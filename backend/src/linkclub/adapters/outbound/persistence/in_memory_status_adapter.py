from linkclub.application.ports.outbound_status_port import StatusPort


class InMemoryStatusAdapter(StatusPort):
    def get_status(self) -> str:
        return "ok"
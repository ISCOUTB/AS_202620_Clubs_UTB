from linkclub.application.ports.inbound_club_port import ListarClubesPort, ObtenerClubPort
from linkclub.application.ports.outbound_club_repository_port import ClubRepositoryPort
from linkclub.domain.club import Club, ClubNoEncontrado


class ListarClubesUseCase(ListarClubesPort):
    def __init__(self, repository: ClubRepositoryPort):
        self.repository = repository

    def ejecutar(self, q: str | None = None, categoria: str | None = None) -> list[Club]:
        return self.repository.listar(q=q, categoria=categoria)


class ObtenerClubUseCase(ObtenerClubPort):
    def __init__(self, repository: ClubRepositoryPort):
        self.repository = repository

    def ejecutar(self, club_id: str) -> Club:
        club = self.repository.obtener(club_id)
        if club is None:
            raise ClubNoEncontrado(club_id)
        return club
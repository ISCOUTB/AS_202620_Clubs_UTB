from linkclub.application.ports.inbound_publicacion_port import CrearPublicacionPort
from linkclub.application.ports.outbound_publicacion_repository_port import PublicacionRepositoryPort
from linkclub.domain.publicacion import Publicacion, TipoPublicacion


class CrearPublicacionUseCase(CrearPublicacionPort):
    def __init__(self, repository: PublicacionRepositoryPort):
        self.repository = repository

    def ejecutar(
        self,
        club_id: str,
        titulo: str,
        contenido: str,
        tipo: str = TipoPublicacion.AVISO.value,
        opciones: list[str] | None = None,
    ) -> Publicacion:
        try:
            tipo_publicacion = TipoPublicacion(tipo)
        except ValueError as error:
            raise ValueError(f"Tipo de publicación no soportado: {tipo}") from error

        if tipo_publicacion == TipoPublicacion.ENCUESTA and not opciones:
            raise ValueError("Una publicación de tipo encuesta requiere al menos una opción")

        publicacion = Publicacion(
            club_id=club_id,
            titulo=titulo,
            contenido=contenido,
            tipo=tipo_publicacion,
            opciones=opciones,
        )
        return self.repository.guardar(publicacion)
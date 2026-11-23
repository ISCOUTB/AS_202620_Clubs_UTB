from linkclub.application.ports.inbound_publicacion_port import CrearPublicacionPort
from linkclub.application.ports.outbound_publicacion_repository_port import (
    PublicacionRepositoryPort,
)
from linkclub.domain.publicacion import Publicacion, PublicacionDuplicada, TipoPublicacion


class CrearPublicacionUseCase(CrearPublicacionPort):
    def __init__(self, repository: PublicacionRepositoryPort):
        self.repository = repository

    def ejecutar(
        self,
        club_id: str,
        autor_id: str,
        titulo: str,
        contenido: str,
        tipo: str = TipoPublicacion.AVISO.value,
        opciones: dict | list | None = None,
        idempotency_key: str | None = None,
        imagen_url: str | None = None,
    ) -> Publicacion:
        try:
            tipo_publicacion = TipoPublicacion(tipo)
        except ValueError as error:
            raise ValueError(f"Tipo de publicación no soportado: {tipo}") from error

        if tipo_publicacion == TipoPublicacion.ENCUESTA and not opciones:
            raise ValueError("Una publicación de tipo encuesta requiere al menos una opción")

        if idempotency_key:
            existente = self.repository.obtener_por_idempotencia(autor_id, idempotency_key)
            if existente:
                mismo_contenido = (
                    str(existente.club_id) == str(club_id)
                    and existente.titulo == titulo
                    and existente.contenido == contenido
                    and existente.tipo == tipo_publicacion
                    and existente.opciones == opciones
                    and existente.imagen_url == imagen_url
                )
                if not mismo_contenido:
                    raise PublicacionDuplicada(
                        "La Idempotency-Key ya fue utilizada con un contenido diferente"
                    )
                return existente

        publicacion = Publicacion(
            club_id=club_id,
            autor_id=autor_id,
            titulo=titulo,
            contenido=contenido,
            tipo=tipo_publicacion,
            opciones=opciones,
            idempotency_key=idempotency_key,
            imagen_url=imagen_url,
        )

        return self.repository.guardar(publicacion)
from typing import Optional
import uuid

from sqlalchemy.orm import Session

from linkclub.adapters.outbound.postgres.models.publicacion_model import PublicacionModel
from linkclub.application.ports.outbound_publicacion_repository_port import (
    PublicacionRepositoryPort,
)
from linkclub.domain.publicacion import Publicacion, TipoPublicacion


class PublicacionRepositoryPostgres(PublicacionRepositoryPort):
    def __init__(self, db: Session):
        self.db = db

    def obtener_por_idempotencia(
        self,
        autor_id: str,
        idempotency_key: str,
    ) -> Optional[Publicacion]:
        pub_db = (
            self.db.query(PublicacionModel)
            .filter(
                PublicacionModel.autor_matricula == autor_id,
                PublicacionModel.idempotency_key == idempotency_key,
            )
            .first()
        )
        if not pub_db:
            return None
        return self._mapear_a_dominio(pub_db)

    def guardar(self, publicacion: Publicacion) -> Publicacion:
        club_uuid = uuid.UUID(str(publicacion.club_id))
        pub_uuid = (
            publicacion.id
            if isinstance(publicacion.id, uuid.UUID)
            else uuid.UUID(str(publicacion.id))
        )

        nueva_pub_db = PublicacionModel(
            id=pub_uuid,
            club_id=club_uuid,
            autor_matricula=publicacion.autor_id,
            titulo=publicacion.titulo,
            contenido=publicacion.contenido,
            tipo=(
                publicacion.tipo.value
                if hasattr(publicacion.tipo, "value")
                else str(publicacion.tipo)
            ),
            opciones=publicacion.opciones,
            idempotency_key=publicacion.idempotency_key,
        )

        self.db.add(nueva_pub_db)
        self.db.commit()
        self.db.refresh(nueva_pub_db)

        return self._mapear_a_dominio(nueva_pub_db)

    def listar_por_club(self, club_id: str) -> list[Publicacion]:
        club_uuid = uuid.UUID(str(club_id))
        pubs_db = (
            self.db.query(PublicacionModel)
            .filter(PublicacionModel.club_id == club_uuid)
            .order_by(PublicacionModel.creado_en.desc())
            .all()
        )
        return [self._mapear_a_dominio(p) for p in pubs_db]

    def _mapear_a_dominio(self, pub_db: PublicacionModel) -> Publicacion:
        return Publicacion(
            id=pub_db.id,
            club_id=str(pub_db.club_id),
            autor_id=pub_db.autor_matricula,
            titulo=pub_db.titulo,
            contenido=pub_db.contenido,
            tipo=TipoPublicacion(pub_db.tipo),
            opciones=pub_db.opciones,
            creada_en=pub_db.creado_en,
            idempotency_key=pub_db.idempotency_key,
        )
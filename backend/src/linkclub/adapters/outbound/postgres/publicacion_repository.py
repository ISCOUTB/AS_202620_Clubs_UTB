from typing import Optional
from sqlalchemy.orm import Session

from linkclub.application.ports.outbound_publicacion_repository_port import PublicacionRepositoryPort
from linkclub.domain.publicacion import Publicacion, TipoPublicacion
from linkclub.adapters.outbound.postgres.models.publicacion_model import PublicacionModel

from linkclub.adapters.outbound.postgres.models.club_model import ClubModel
from linkclub.adapters.outbound.postgres.models.usuario_model import UsuarioModel
from linkclub.adapters.outbound.postgres.models.publicacion_model import PublicacionModel

class PublicacionRepositoryPostgres(PublicacionRepositoryPort):
    def __init__(self, db: Session):
        self.db = db

    def obtener_por_idempotencia(self, idempotency_key: str) -> Optional[Publicacion]:
        pub_db = self.db.query(PublicacionModel).filter(
            PublicacionModel.idempotency_key == idempotency_key
        ).first()
        
        if not pub_db:
            return None
            
        return Publicacion(
            club_id=pub_db.club_id,
            autor_id=pub_db.autor_matricula,
            titulo=pub_db.titulo,
            contenido=pub_db.contenido,
            tipo=TipoPublicacion(pub_db.tipo),
            opciones=pub_db.opciones,
            idempotency_key=pub_db.idempotency_key,
        )

    def guardar(self, publicacion: Publicacion) -> Publicacion:
        nueva_pub_db = PublicacionModel(
            club_id=publicacion.club_id,
            autor_matricula=publicacion.autor_id,
            titulo=publicacion.titulo,
            contenido=publicacion.contenido,
            tipo=publicacion.tipo.value if hasattr(publicacion.tipo, "value") else str(publicacion.tipo),
            opciones=publicacion.opciones,
            idempotency_key=publicacion.idempotency_key
        )
        
        self.db.add(nueva_pub_db)
        self.db.commit()
        self.db.refresh(nueva_pub_db)
        
        if hasattr(publicacion, "id"):
            publicacion.id = nueva_pub_db.id
            
        return publicacion

    def listar_por_club(self, club_id: int) -> list[Publicacion]:
        pubs_db = self.db.query(PublicacionModel).filter(PublicacionModel.club_id == club_id).all()
        return [
            Publicacion(
                club_id=p.club_id,
                autor_id=p.autor_matricula,
                titulo=p.titulo,
                contenido=p.contenido,
                tipo=TipoPublicacion(p.tipo),
                opciones=p.opciones,
                idempotency_key=p.idempotency_key
            ) for p in pubs_db
        ]
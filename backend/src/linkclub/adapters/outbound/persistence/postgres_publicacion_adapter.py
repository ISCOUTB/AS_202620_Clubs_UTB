from datetime import datetime
from typing import List, Optional
from sqlalchemy.orm import Session
from linkclub.adapters.outbound.postgres.models.publicacion_model import PublicacionModel
from linkclub.domain.publicacion import Publicacion, TipoPublicacion, PublicacionDuplicada

class PostgresPublicacionAdapter:
    def __init__(self, db: Session):
        self.db = db

    def guardar(self, publicacion: Publicacion, idempotency_key: Optional[str] = None) -> Publicacion:
        if idempotency_key:
            existente = self.db.query(PublicacionModel).filter(PublicacionModel.idempotency_key == idempotency_key).first()
            if existente:
                raise PublicacionDuplicada("Petición duplicada")

        db_pub = PublicacionModel(
            id=str(publicacion.id),
            autor_nombre=publicacion.autor_id,
            contenido=publicacion.contenido,
            imagen_url=getattr(publicacion, 'imagen_url', None),
            idempotency_key=idempotency_key,
        )
        self.db.add(db_pub)
        self.db.commit()
        self.db.refresh(db_pub)
        return publicacion

    def listar_todas(self) -> List[Publicacion]:
        registros = self.db.query(PublicacionModel).order_by(PublicacionModel.creado_en.desc()).all()
        return [
            Publicacion(
                id=r.id,
                club_id="general",
                autor_id=r.autor_nombre,
                titulo="Publicación",
                contenido=r.contenido,
                tipo=TipoPublicacion.AVISO,
                creada_en=r.creado_en
            ) for r in registros
        ]

    def listar_por_club(self, club_id: str) -> List[Publicacion]:
        return [p for p in self.listar_todas() if p.club_id == club_id]
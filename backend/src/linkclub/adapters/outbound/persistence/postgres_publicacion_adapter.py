from datetime import datetime
from typing import List, Optional
import uuid
from sqlalchemy.orm import Session
from linkclub.adapters.outbound.postgres.models.publicacion_model import PublicacionModel
from linkclub.domain.publicacion import Publicacion, TipoPublicacion

class PostgresPublicacionAdapter:
    def __init__(self, db: Session):
        self.db = db

    def obtener_por_idempotencia(self, idempotency_key: str) -> Optional[Publicacion]:
        db_pub = self.db.query(PublicacionModel).filter(PublicacionModel.idempotency_key == idempotency_key).first()
        if not db_pub:
            return None
        return self._mapear_a_dominio(db_pub)

    def guardar(self, publicacion: Publicacion, idempotency_key: Optional[str] = None) -> Publicacion:
        if idempotency_key:
            existente = self.db.query(PublicacionModel).filter(PublicacionModel.idempotency_key == idempotency_key).first()
            if existente:
                return self._mapear_a_dominio(existente)

        db_pub = PublicacionModel(
            id=uuid.uuid4(),
            club_id=uuid.UUID(str(publicacion.club_id)) if publicacion.club_id else uuid.uuid4(),
            autor_matricula=publicacion.autor_id,
            titulo=publicacion.titulo,
            contenido=publicacion.contenido,
            tipo=publicacion.tipo.value if hasattr(publicacion.tipo, 'value') else str(publicacion.tipo),
            opciones=publicacion.opciones,
            idempotency_key=idempotency_key,
        )
        self.db.add(db_pub)
        self.db.commit()
        self.db.refresh(db_pub)
        return self._mapear_a_dominio(db_pub)

    def listar_todas(self) -> List[Publicacion]:
        registros = self.db.query(PublicacionModel).order_by(PublicacionModel.creado_en.desc()).all()
        return [self._mapear_a_dominio(r) for r in registros]

    def listar_por_club(self, club_id: str) -> List[Publicacion]:
        registros = self.db.query(PublicacionModel).filter(PublicacionModel.club_id == club_id).order_by(PublicacionModel.creado_en.desc()).all()
        return [self._mapear_a_dominio(r) for r in registros]

    def _mapear_a_dominio(self, db_pub: PublicacionModel) -> Publicacion:
        tipo_enum = TipoPublicacion.AVISO
        try:
            tipo_enum = TipoPublicacion(db_pub.tipo)
        except ValueError:
            pass

        pub = Publicacion(
            id=str(db_pub.id),
            club_id=str(db_pub.club_id),
            autor_id=db_pub.autor_matricula,
            titulo=db_pub.titulo,
            contenido=db_pub.contenido,
            tipo=tipo_enum,
            opciones=db_pub.opciones,
            creada_en=db_pub.creado_en
        )
        pub.autor_nombre = getattr(db_pub, "autor_nombre", db_pub.autor_matricula)
        return pub
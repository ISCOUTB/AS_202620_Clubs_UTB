import logging
from sqlalchemy.orm import Session
from sqlalchemy import text
from linkclub.application.ports.outbound_status_port import StatusPort

logger = logging.getLogger(__name__)

class PostgresStatusAdapter(StatusPort):
    def __init__(self, db_session: Session):
        self.db_session = db_session

    def get_status(self) -> str:
        try:
            self.db_session.execute(text("SELECT 1"))
            return "ok"
        except Exception:
            logger.exception("Fallo en Health Check de la Base de Datos")
            return "error"
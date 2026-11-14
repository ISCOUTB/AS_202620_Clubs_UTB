from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from linkclub.adapters.outbound.postgres.database import get_db
from linkclub.adapters.outbound.postgres.postgres_status_adapter import PostgresStatusAdapter
from linkclub.application.use_cases.check_health import (
    CheckHealthUseCase,
    ServicioNoDisponible,
)

router = APIRouter(tags=["health"])


@router.get(
    "/health",
    responses={
        status.HTTP_503_SERVICE_UNAVAILABLE: {
            "description": "Base de datos no disponible"
        }
    },
)
def health_check(db: Annotated[Session, Depends(get_db)]):
    use_case = CheckHealthUseCase(status_port=PostgresStatusAdapter(db))
    try:
        return use_case.check()
    except ServicioNoDisponible as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc
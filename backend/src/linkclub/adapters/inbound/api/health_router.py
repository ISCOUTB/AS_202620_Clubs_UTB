from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Annotated

from linkclub.adapters.outbound.postgres.database import get_db
from linkclub.adapters.outbound.postgres.postgres_status_adapter import PostgresStatusAdapter

router = APIRouter(tags=["health"])

@router.get("/health")
def health_check(db: Annotated[Session, Depends(get_db)]):
    status_adapter = PostgresStatusAdapter(db)
    
    if status_adapter.get_status() == "ok":
        return {"status": "ok", "database": "online"}
    
    raise HTTPException(status_code=503, detail="Base de datos no disponible")
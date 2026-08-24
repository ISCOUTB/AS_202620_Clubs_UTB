from fastapi import APIRouter
from linkclub.application.use_cases.check_health import CheckHealthUseCase
from linkclub.adapters.outbound.persistence.in_memory_status_adapter import InMemoryStatusAdapter

router = APIRouter()

use_case = CheckHealthUseCase(status_port=InMemoryStatusAdapter())


@router.get("/health")
def health():
    return use_case.check()
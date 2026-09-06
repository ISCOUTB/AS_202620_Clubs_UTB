from fastapi import FastAPI

from linkclub.adapters.inbound.api.health_router import router as health_router
from linkclub.adapters.inbound.api.publicacion_router import router as publicacion_router

app = FastAPI(title="LinkClub API")
app.include_router(health_router)
app.include_router(publicacion_router)
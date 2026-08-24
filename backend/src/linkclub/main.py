from fastapi import FastAPI
from linkclub.adapters.inbound.api.health_router import router

app = FastAPI(title="LinkClub API")
app.include_router(router)
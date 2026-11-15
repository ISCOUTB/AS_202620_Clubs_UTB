import logging
import os

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from linkclub.adapters.inbound.api.auth_router import router as auth_router
from linkclub.adapters.inbound.api.club_router import router as club_router
from linkclub.adapters.inbound.api.health_router import router as health_router
from linkclub.adapters.inbound.api.publicacion_router import router as publicacion_router
from linkclub.adapters.inbound.api.recurso_router import router as recurso_router

logger = logging.getLogger("linkclub.api")

app = FastAPI(title="LinkClub API")

raw_origins = os.environ.get(
    "CORS_ORIGINS",
    "",
)
allowed_origins = [origin.strip() for origin in raw_origins.split(",") if origin.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Idempotency-Key"],
)


@app.exception_handler(RequestValidationError)
async def manejar_validacion(request: Request, exc: RequestValidationError):
    primero = exc.errors()[0]
    campo = ".".join(str(p) for p in primero["loc"] if p != "body")
    mensaje = f"{campo}: {primero['msg']}" if campo else primero["msg"]
    return JSONResponse(status_code=422, content={"detail": mensaje})


@app.exception_handler(Exception)
async def manejar_error_interno(request: Request, exc: Exception):
    logger.exception("Error interno no controlado en %s %s", request.method, request.url.path)
    return JSONResponse(
        status_code=500,
        content={"detail": "Error interno del servidor."},
    )


upload_dir = os.environ.get("UPLOAD_DIR", "uploads")
os.makedirs(upload_dir, exist_ok=True)

app.mount("/static", StaticFiles(directory=upload_dir), name="static")

app.include_router(health_router)
app.include_router(publicacion_router)
app.include_router(club_router)
app.include_router(auth_router)
app.include_router(recurso_router)
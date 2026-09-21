from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from linkclub.adapters.inbound.api.health_router import router as health_router
from linkclub.adapters.inbound.api.publicacion_router import router as publicacion_router

app = FastAPI(title="LinkClub API")


@app.exception_handler(RequestValidationError)
async def manejar_validacion(request: Request, exc: RequestValidationError):
    primero = exc.errors()[0]
    campo = ".".join(str(p) for p in primero["loc"] if p != "body")
    mensaje = f"{campo}: {primero['msg']}" if campo else primero["msg"]
    return JSONResponse(status_code=422, content={"detail": mensaje})


app.include_router(health_router)
app.include_router(publicacion_router)
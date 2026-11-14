import os
import shutil
import uuid
from pathlib import Path
from typing import Annotated

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

from linkclub.adapters.inbound.api.auth_dependency import require_auth

router = APIRouter(prefix="/recursos", tags=["Recursos"])

UPLOAD_DIR = Path(os.environ.get("UPLOAD_DIR", "uploads"))
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png", "webp", "gif"}
MAX_UPLOAD_BYTES = 5 * 1024 * 1024  # 5 MB


@router.post("/upload", status_code=status.HTTP_201_CREATED)
def subir_imagen(
    file: Annotated[UploadFile, File(...)],
    autor_id: Annotated[str, Depends(require_auth)],
):
    if not file.filename or "." not in file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El archivo no contiene un nombre o extensión válidos.",
        )

    ext = file.filename.rsplit(".", 1)[-1].lower()

    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Formato no permitido. Usa: {', '.join(sorted(ALLOWED_EXTENSIONS))}",
        )

    file.file.seek(0, os.SEEK_END)
    tamano = file.file.tell()
    file.file.seek(0)
    if tamano > MAX_UPLOAD_BYTES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El archivo supera el límite máximo de 5 MB.",
        )

    nuevo_nombre = f"{uuid.uuid4()}.{ext}"
    file_path = UPLOAD_DIR / nuevo_nombre

    try:
        with file_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error interno al guardar el archivo.",
        ) from exc

    url_publica = f"https://api-linkclub.iscoutb.dev/static/{nuevo_nombre}"
    return {"url": url_publica}
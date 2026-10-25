import uuid
import shutil
import os
from pathlib import Path
from fastapi import APIRouter, UploadFile, File, HTTPException, status

router = APIRouter(prefix="/recursos", tags=["Recursos"])

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
try:
    os.chmod(UPLOAD_DIR, 0o777)
except Exception:
    pass

ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png", "webp", "gif", "svg"}

@router.post("/upload", status_code=status.HTTP_201_CREATED)
def subir_imagen(file: UploadFile = File(...)):
    if not file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El archivo no contiene un nombre válido."
        )

    ext = file.filename.split('.')[-1].lower()
    
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail=f"Formato no permitido. Usa: {', '.join(ALLOWED_EXTENSIONS)}"
        )
    
    nuevo_nombre = f"{uuid.uuid4()}.{ext}"
    file_path = UPLOAD_DIR / nuevo_nombre
    
    try:
        with file_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        os.chmod(file_path, 0o666)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al guardar el archivo: {str(e)}"
        )
    
    url_publica = f"https://api-linkclub.iscoutb.dev/static/{nuevo_nombre}"
    
    return {"url": url_publica}
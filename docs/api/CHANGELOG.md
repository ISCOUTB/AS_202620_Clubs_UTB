# Historial del contrato

Versionado SemVer sobre `openapi.yaml` (campo `info.version`).

## 1.1.0 - 2026-10-04
- Agregado `autor_id` (opcional) a la respuesta de `Publicacion`. Cambio aditivo: no rompe clientes existentes.

## 1.0.0 - 2026-09-20
- Contrato inicial: health, clubes, membresías, eventos y publicaciones.
- Implementado en el backend: health y publicaciones (aviso, encuesta, noticia).
# Historial del contrato

Versionado SemVer sobre `openapi.yaml` (campo `info.version`).

## 1.2.0 - 2026-10-13
Cambios aditivos (no rompen clientes existentes):
- Nuevo `POST /usuarios`: registro de usuario (el `id` lo genera el backend).
- Nuevo `POST /auth/login`: devuelve un token de acceso JWT propio.
- Nuevo `GET /usuarios/me`: perfil del usuario autenticado.
- Nuevo `POST /clubes`: crea un club; quien lo crea queda como administrador.
- `Club` agrega campos opcionales: `descripcion_completa`, `icono`, `horario`, `lugar`, `total_miembros` (calculado) y `administradores` (resuelto por referencia, sin copiar datos del usuario).
- Nuevos esquemas: `Usuario`, `CrearUsuarioRequest`, `LoginRequest`, `TokenResponse`, `CrearClubRequest`, `AdministradorClub`.
- `bearerAuth`: el token ya no lo emite Supabase Auth sino el propio backend (JWT HS256, 7 días). El formato del encabezado no cambia.

## 1.1.0 - 2026-10-04
- Agregado `autor_id` (opcional) a la respuesta de `Publicacion`. Cambio aditivo: no rompe clientes existentes.

## 1.0.0 - 2026-09-20
- Contrato inicial: health, clubes, membresías, eventos y publicaciones.
- Implementado en el backend: health y publicaciones (aviso, encuesta, noticia).
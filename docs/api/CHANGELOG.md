# Historial del contrato

Versionado SemVer sobre `openapi.yaml` (campo `info.version`).

## 3.0.0 - 2026-11-14
Cambio incompatible: unificación de identificadores a `string` (`uuid`) para sincronizar el contrato con el esquema inicial de PostgreSQL (`001_esquema_inicial.sql`) y los modelos ORM refactorizados:
- `Publicacion.id`, `Publicacion.club_id`, `CrearPublicacionRequest.club_id` y el parámetro de ruta en `/clubes/{club_id}/publicaciones` vuelven de `integer` a `string` (`format: uuid`); se elimina el parámetro `ClubIdEntero`.
- `Usuario.id` pasa de `integer` a `string` (matrícula institucional o identificador serializado por `auth_router.py`) y `Usuario.rol` pasa a propiedad opcional.
- **Observabilidad (`/health`):** Se añade el campo obligatorio `database` en `HealthStatus` y la respuesta `503 Service Unavailable` (`ErrorResponse`) para la comprobación activa contra PostgreSQL.
- **Multimedia (`/recursos/upload`):** Se registra el tag raíz `recursos`, se extrae el esquema `UploadResponse`, se tipan los errores `400` y `500` con `ErrorResponse` y se retira `svg` de las extensiones admitidas (`jpg`, `jpeg`, `png`, `webp`, `gif`).
- **Idempotencia homogénea:** Se unifican las respuestas `200`, `201` y `409` junto con la cabecera opcional `Idempotency-Key` en `POST /clubes/{club_id}/publicaciones` y `POST /publicaciones`.

## 2.0.0 - 2026-10-25
Cambio incompatible: los identificadores de publicaciones y clubes de la BD pasan de `uuid` a entero (migración de esquema).
- `Publicacion.id` y `Publicacion.club_id` pasan de `string` a `integer`; la ruta `/clubes/{club_id}/publicaciones` acepta `club_id` entero.
- Nuevos `GET /publicaciones` (feed general) y `POST /publicaciones` (con `club_id` en el cuerpo).
- `Publicacion` agrega `autor_nombre` e `imagen_url` (opcionales). `CrearPublicacionRequest`: `titulo` pasa a opcional, se agregan `club_id` e `imagen_url`.
- `Idempotency-Key` pasa a opcional (si se envía, evita duplicados).

## 1.3.0 - 2026-10-18
Cambios de resiliencia y refactorización arquitectónica (Evidencia S11):
- **Idempotencia:** Se añade la cabecera obligatoria `Idempotency-Key` en `POST /clubes/{club_id}/publicaciones` para mitigar fallos parciales de red y evitar registros duplicados.
- Se agrega el código de error `409 Conflict` en `POST /clubes/{club_id}/publicaciones` para interceptar reintentos con la misma llave de idempotencia.
- **Refactorización de Auth:** Se renombra el endpoint de registro de `POST /usuarios` a `POST /auth/registro` para centralizar los dominios de seguridad.
- **Desacoplamiento:** Se actualiza la descripción del esquema `bearerAuth` confirmando la erradicación definitiva de Supabase.

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
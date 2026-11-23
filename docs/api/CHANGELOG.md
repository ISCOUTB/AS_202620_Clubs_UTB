### Historial del contrato

Versionado SemVer sobre `openapi.yaml` (campo `info.version`).

#### 3.1.0 - 2026-11-22
Cambios aditivos (compatibles con clientes de la serie `3.x`) para cubrir eventos, asistencias, gestión de perfiles, aprobación de administradores y administración de clubes:
* **Eventos y asistencia (`evento_router.py`):**
  * Nuevos endpoints `GET /eventos` (con soporte de autenticación opcional para filtrar eventos `SOLO_CLUB` y calcular `usuario_asiste`), `POST /eventos` (restringido a `ADMIN_CLUB` verificado o `SUPERADMIN`) y `POST /eventos/{evento_id}/asistencia` (alterna confirmación de asistencia).
  * Nuevos esquemas `Evento`, `CrearEventoRequest`, `VisibilidadEvento` (`PUBLICO`, `SOLO_CLUB`) y `AsistenciaToggleResponse`.
* **Perfil de usuario y gobernanza de roles (`usuario_router.py`):**
  * Nuevos endpoints de autogestión: `GET /usuarios/me`, `PATCH /usuarios/me`, `POST /usuarios/me/password` y `DELETE /usuarios/me`.
  * Nuevos endpoints exclusivos para `SUPERADMIN`: `GET /admin/solicitudes`, `POST /admin/solicitudes/{solicitud_id}/aprobar` y `POST /admin/solicitudes/{solicitud_id}/rechazar`.
  * Nuevos esquemas `PerfilUsuario`, `ActualizarPerfilRequest`, `CambiarPasswordRequest` y `SolicitudAdmin`.
* **Administración de clubes e inscripciones externas (`club_router.py`):**
  * Nuevos endpoints `POST /clubes` (`SUPERADMIN`) y `PATCH /clubes/{club_id}` (`ADMIN_CLUB` verificado del club o `SUPERADMIN`).
  * Ampliación de `Club` con los campos `logo_url`, `lider`, `redes_json`, `inscripciones_abiertas`, `ms_forms_url` y `aviso_inscripcion` para enlazar inscripciones a formularios institucionales externos.
* **Autenticación y feed general (`auth_router.py`, `publicacion_router.py`):**
  * `POST /auth/login` acepta tanto `application/json` (`LoginJsonRequest`) como `application/x-www-form-urlencoded` (`LoginRequest`) y documenta `403` ante cuentas inactivas.
  * `POST /auth/registro` incorpora los campos opcionales `solicitar_admin`, `club_id` y `justificacion_admin`.
  * Nuevo endpoint `GET /publicaciones` para consultar el feed general con filtro opcional `club_id`, y consolidación de la creación de publicaciones en `POST /clubes/{club_id}/publicaciones`.

#### 3.0.0 - 2026-11-14
Cambio incompatible: unificación de identificadores a `string` (`uuid`) para sincronizar el contrato con el esquema inicial de PostgreSQL (`001_esquema_inicial.sql`) y los modelos ORM refactorizados:
* `Publicacion.id`, `Publicacion.club_id` y el parámetro de ruta en `/clubes/{club_id}/publicaciones` vuelven de `integer` a `string` (`format: uuid`); se elimina el parámetro `ClubIdEntero`.
* `Usuario.id` pasa de `integer` a `string` (matrícula institucional serializada por `auth_router.py`) y `Usuario.rol` pasa a propiedad opcional.
* **Observabilidad (`/health`):** Se añade el campo obligatorio `database` en `HealthStatus` y la respuesta `503 Service Unavailable` (`ErrorResponse`) para la comprobación activa contra PostgreSQL.
* **Multimedia (`/recursos/upload`):** Se registra el tag raíz `recursos`, se define el esquema `ArchivoSubido`, se tipan los errores `400` y `500` con `ErrorResponse` y se retira `svg` de las extensiones admitidas (`jpg`, `jpeg`, `png`, `webp`, `gif`).
* **Idempotencia homogénea:** Se documenta la cabecera `Idempotency-Key` y el manejo de conflictos `409` en `POST /clubes/{club_id}/publicaciones`.

#### 1.2.0 - 2026-10-13
Cambios aditivos (no rompen clientes existentes):
* Nuevo `POST /usuarios`: registro de usuario (el id lo genera el backend).
* Nuevo `POST /auth/login`: devuelve un token de acceso JWT propio.
* Nuevo `GET /usuarios/me`: perfil del usuario autenticado.
* Nuevo `POST /clubes`: crea un club; quien lo crea queda como administrador.
* `Club` agrega campos opcionales: `descripcion_completa`, `icono`, `horario`, `lugar`, `total_miembros` (calculado) y `administradores` (resuelto por referencia, sin copiar datos del usuario).
* Nuevos esquemas: `Usuario`, `CrearUsuarioRequest`, `LoginRequest`, `TokenResponse`, `CrearClubRequest`, `AdministradorClub`.
* `bearerAuth`: el token ya no lo emite Supabase Auth sino el propio backend (JWT HS256, 7 días). El formato del encabezado no cambia.

#### 1.1.0 - 2026-10-04
* Agregado `autor_id` (opcional) a la respuesta de `Publicacion`. Cambio aditivo: no rompe clientes existentes.

#### 1.0.0 - 2026-09-20
* Contrato inicial: health, clubes, membresías, eventos y publicaciones.
* Implementado en el backend: health y publicaciones (aviso, encuesta, noticia).
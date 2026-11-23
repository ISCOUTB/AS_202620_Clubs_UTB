### Contrato de API — LinkClub (v3.1.0)

**Qué es este documento:** la guía explicativa del contrato REST vigente en [openapi.yaml](./openapi.yaml) (`version: 3.1.0`) entre el backend FastAPI y la aplicación móvil Flutter, cubriendo los tres actores del sistema ([C4 de contexto](../c4/contexto.md)): **Estudiante**, **Administrador de Club (`ADMIN_CLUB`)** y **Superadmin (`SUPERADMIN`)**[cite: 2, 4].

**Enfoque API-first:** la especificación ejecutable en `docs/api/openapi.yaml` es la fuente única de verdad[cite: 4]. Cada Pull Request ejecuta `spectral lint`, `oasdiff breaking` y la suite `pytest tests/test_contrato_openapi.py` para garantizar que el código y los esquemas de respuesta no divergen[cite: 3].

#### 1. Alcance: de los actores del sistema a las operaciones

| Rol / Actor | Necesita poder... | Operaciones del contrato (`v3.1.0`) |
| ------ | ------ | ------ |
| Estudiante | Explorar clubes, filtrar por categoría/texto y consultar el enlace institucional de inscripción (`ms_forms_url`) | `GET /clubes`, `GET /clubes/{club_id}`[cite: 2, 4] |
| Estudiante | Leer el feed general, las publicaciones por club y la agenda pública de eventos | `GET /publicaciones`, `GET /clubes/{club_id}/publicaciones`, `GET /eventos`[cite: 2, 4] |
| Estudiante | Registrarse en la plataforma (como estudiante o solicitando rol de administrador de club) | `POST /auth/registro`[cite: 2, 4] |
| Estudiante | Confirmar o cancelar asistencia a eventos institucionales | `POST /eventos/{evento_id}/asistencia`[cite: 2, 4] |
| Estudiante / Admin | Consultar y editar su perfil, cambiar contraseña o eliminar su cuenta | `GET /usuarios/me`, `PATCH /usuarios/me`, `POST /usuarios/me/password`, `DELETE /usuarios/me`[cite: 2, 4] |
| Administrador de club (`ADMIN_CLUB`) | Publicar avisos, encuestas y noticias con soporte de imágenes | `POST /clubes/{club_id}/publicaciones`, `POST /recursos/upload`, `GET /static/{archivo}`[cite: 2, 4] |
| Administrador de club (`ADMIN_CLUB`) | Programar eventos (`PUBLICO` o `SOLO_CLUB`) y actualizar la ficha e inscripciones de su club | `POST /eventos`, `PATCH /clubes/{club_id}`[cite: 2, 4] |
| Superadmin (`SUPERADMIN`) | Crear nuevos clubes y aprobar o rechazar solicitudes de administradores de club | `POST /clubes`, `GET /admin/solicitudes`, `POST /admin/solicitudes/{solicitud_id}/aprobar`, `POST /admin/solicitudes/{solicitud_id}/rechazar`[cite: 2, 4] |
| Todos / Monitoreo | Iniciar sesión (JSON o formulario OAuth2) y verificar disponibilidad del servicio y PostgreSQL | `POST /auth/login`, `GET /health`[cite: 2, 4] |

#### 2. Convenciones del contrato

* **Autenticación y roles (`bearerAuth`):** JWT firmado localmente con `HS256` por FastAPI (`JWT_SECRET` obligatorio, vigencia por defecto de 7 días), validado contra PostgreSQL (`usuarios`)[cite: 2]. El sujeto (`sub`) del token es la matrícula institucional (`T000...`)[cite: 2]. Las consultas de lectura son públicas (`GET /eventos` acepta token opcional para incluir eventos `SOLO_CLUB` del club administrado y calcular `usuario_asiste`), mientras que toda escritura exige sesión y validación de rol (`403 Forbidden` si el usuario no es `ADMIN_CLUB` verificado del club o `SUPERADMIN`)[cite: 2].
* **Inscripción a clubes:** En lugar de gestionar membresías internas en la API, cada club expone en su ficha (`Club`) los campos `inscripciones_abiertas`, `ms_forms_url` y `aviso_inscripcion` para redirigir al estudiante al formulario institucional oficial[cite: 2, 4].
* **Idempotencia:** El cliente móvil envía automáticamente una cabecera `Idempotency-Key` (UUID v4) en toda petición `POST` protegida mediante un interceptor de Dio[cite: 3]. En el servidor la cabecera es opcional para facilitar pruebas directas, pero si se envía vacía responde `422`, y si se reutiliza con distinto payload en `POST /clubes/{club_id}/publicaciones` responde `409 Conflict`[cite: 2, 4].
* **Formato de error uniforme:** Toda respuesta de error (`400`, `401`, `403`, `404`, `409`, `422`, `500`, `503`) devuelve `{"detail": "mensaje legible"}` (`ErrorResponse`)[cite: 2, 4].
* **Identificadores y versionado:** Los recursos principales (`Club`, `Publicacion`, `Evento`, `SolicitudAdmin`) usan `string` con formato `uuid`, mientras que los usuarios se identifican por su `matricula` (`^T[0-9]{7,8}$`)[cite: 2, 4]. El campo `info.version` sigue SemVer independiente del código[cite: 3].

#### 3. Especificación OpenAPI vigente

La definición completa y ejecutable reside en [docs/api/openapi.yaml](./openapi.yaml) (`openapi: 3.1.0`, `info.version: 3.1.0`), desplegada en:
* **Producción (Dokploy):** `https://api-linkclub.iscoutb.dev` (`https://api-linkclub.iscoutb.dev/docs` para Swagger UI)[cite: 4].
* **Desarrollo local:** `http://localhost:8000`[cite: 4].

#### 4. Estado de implementación en `backend/`

| Operación | Contrato (`v3.1.0`) | Implementado en `backend/` | Router / Módulo |
| ------ | ------ | ------ | ------ |
| `GET /health` | ✅ `implementado` | ✅ Sondea PostgreSQL (`SELECT 1`) y responde `200` o `503` | `health_router.py`[cite: 2] |
| `POST /auth/registro` | ✅ `implementado` | ✅ Hash `bcrypt`, validación `@utb.edu.co` y solicitud opcional de `ADMIN_CLUB` | `auth_router.py`[cite: 2] |
| `POST /auth/login` | ✅ `implementado` | ✅ Acepta `application/json` y `application/x-www-form-urlencoded`, emite JWT `HS256` | `auth_router.py`[cite: 2] |
| `GET /usuarios/me` | ✅ `implementado` | ✅ Devuelve perfil completo, rol, club administrado y estado de solicitud | `usuario_router.py`[cite: 2] |
| `PATCH /usuarios/me` | ✅ `implementado` | ✅ Actualiza nombre, descripción y `foto_perfil_url` | `usuario_router.py`[cite: 2] |
| `POST /usuarios/me/password` | ✅ `implementado` | ✅ Verifica contraseña actual y actualiza hash `bcrypt` (`204 No Content`) | `usuario_router.py`[cite: 2] |
| `DELETE /usuarios/me` | ✅ `implementado` | ✅ Elimina la cuenta del usuario autenticado (`204 No Content`) | `usuario_router.py`[cite: 2] |
| `GET /admin/solicitudes` | ✅ `implementado` | ✅ Lista solicitudes pendientes de `ADMIN_CLUB` (solo `SUPERADMIN`) | `usuario_router.py`[cite: 2] |
| `POST /admin/solicitudes/{solicitud_id}/aprobar` | ✅ `implementado` | ✅ Asigna rol `ADMIN_CLUB`, `verificado=true` y `club_administrado_id` | `usuario_router.py`[cite: 2] |
| `POST /admin/solicitudes/{solicitud_id}/rechazar` | ✅ `implementado` | ✅ Rechaza la solicitud y mantiene el rol `ESTUDIANTE` | `usuario_router.py`[cite: 2] |
| `GET /clubes`, `GET /clubes/{club_id}` | ✅ `implementado` | ✅ Consulta PostgreSQL con filtros Unicode (`q`, `categoria`) y ficha completa | `club_router.py`[cite: 2] |
| `POST /clubes`, `PATCH /clubes/{club_id}` | ✅ `implementado` | ✅ Creación (`SUPERADMIN`) y edición de ficha/enlace Microsoft Forms (`ADMIN_CLUB`) | `club_router.py`[cite: 2] |
| `GET /publicaciones`, `GET /clubes/{club_id}/publicaciones` | ✅ `implementado` | ✅ Feed general y listado por club ordenados cronológicamente | `publicacion_router.py`[cite: 2] |
| `POST /clubes/{club_id}/publicaciones` | ✅ `implementado` | ✅ Soporta `aviso`, `encuesta` y `noticia`, `Idempotency-Key` y control de rol | `publicacion_router.py`[cite: 2] |
| `GET /eventos`, `POST /eventos` | ✅ `implementado` | ✅ Agenda pública y `SOLO_CLUB`, creación restringida a admins verificados | `evento_router.py`[cite: 2] |
| `POST /eventos/{evento_id}/asistencia` | ✅ `implementado` | ✅ Alterna asistencia (`confirmado`/eliminado) y devuelve `total_asistentes` | `evento_router.py`[cite: 2] |
| `POST /recursos/upload`, `GET /static/{archivo}` | ✅ `implementado` | ✅ Sube imágenes (`jpg`, `jpeg`, `png`, `webp`, `gif`, máx. 5 MB) al volumen Docker | `recurso_router.py` / `main.py`[cite: 2] |
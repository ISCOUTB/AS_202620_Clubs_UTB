# Tabla de amenazas

La siguiente tabla muestra las amenazas de seguridad identificadas en **LinkClub**, valorando su probabilidad, impacto, prioridad, estrategia de mitigación, responsable y estado de verificación actual en el código.

## Criterio de priorización

Probabilidad e impacto se valoran de 1 a 3 (Baja = 1, Media = 2, Alta = 3). La prioridad resulta del producto de ambos valores:

| Producto (Prob. $\times$ Impacto) | Prioridad |
| ------ | ------ |
| 6 o 9 | Alta |
| 3 o 4 | Media |
| 1 o 2 | Baja |

## Registro de amenazas

| ID | Amenaza | Prob. | Impacto | Prioridad | Mitigación | Responsable | Estado | Evidencia |
| ------ | ------ | ------ | ------ | ------ | ------ | ------ | ------ | ------ |
| **A01** | Acceso no autorizado a cuentas de usuario. | Media | Alta | Alta | Autenticación JWT `HS256`, verificación de credenciales con `bcrypt`, almacenamiento cifrado en `flutter_secure_storage` y validación de `estado_cuenta == ACTIVO`. | Josh Ortega | **Mitigada** | `local_jwt_adapter.py`, `auth_router.py`, `test_auth.py` |
| **A02** | Exposición de claves secretas (`JWT_SECRET` con valor por defecto en el código fuente). | Media | Alta | Alta | Eliminado cualquier secreto por defecto; `JWT_SECRET` es obligatorio al arrancar con validación *fail-fast* (`NC-11`). | Diego Ramos | **Mitigada** | `auth_dependency.py`, `auth_router.py`, `.gitignore` |
| **A03** | Envío de datos incompletos, malformados o incompatibles a la base de datos. | Alta | Media | Alta | Validación estricta con Pydantic, restricciones `CHECK`/`NOT NULL`/`UNIQUE` en SQL y modelos ORM sincronizados a `UUID` (`NC-08`). | Luis Salas | **Mitigada** | `001_esquema_inicial.sql`, `002_sincronizar_esquema_orm.sql`, `models/` |
| **A04** | Acceso no autorizado a funciones administrativas de clubes o de plataforma. | Media | Alta | Alta | Control de acceso por roles (`ESTUDIANTE`, `ADMIN_CLUB` con `verificado = true` y `club_administrado_id == club_id`, `SUPERADMIN`) devolviendo `403 Forbidden` (`NC-16`). | Luis Salas | **Mitigada** | `club_router.py`, `publicacion_router.py`, `evento_router.py`, `usuario_router.py` |
| **A05** | Pérdida de información de PostgreSQL o del volumen `linkclub_uploads` por falla de disco. | Media | Alta | Alta | Procedimiento documentado de despliegue ([Sección 7](./07_vista_de_despliegue.md)); pendiente automatizar `pg_dump` periódico y copia externa del volumen. | Diego Ramos | **Pendiente** | [Sección 7.2](./07_vista_de_despliegue.md), [Sección 11](./11_riesgos_y_deuda_tecnica.md) |
| **A06** | Un estudiante consulta o modifica información privada de otro usuario. | Baja | Alta | Media | Los endpoints `/usuarios/me` (`GET`, `PATCH`, `DELETE`) resuelven la identidad exclusivamente desde `current_user.matricula` extraída del token JWT. | Luis Salas | **Mitigada** | `usuario_router.py`, `auth_dependency.py` |
| **A07** | Ataques de fuerza bruta contra el inicio de sesión (`POST /auth/login`). | Alta | Media | Alta | Mensaje de error uniforme (`401 Credenciales inválidas`) sin revelar si existe el correo; pendiente implementar bloqueo temporal o *rate-limiting* por IP/correo. | Josh Ortega | **Pendiente** | `auth_router.py` |
| **A08** | Contraseñas almacenadas o comparadas en texto plano. | Media | Alta | Alta | Hash adaptativo `bcrypt` aplicado al registrar usuarios y al actualizar contraseñas (`NC-05`). | Josh Ortega | **Mitigada** | `auth_router.py`, `usuario_router.py` |
| **A09** | Subida de archivos maliciosos (XSS vía SVG), sin sesión o que agoten el disco. | Alta | Media | Alta | Exigido `require_auth` en `POST /recursos/upload`, retirado `.svg` de las extensiones permitidas y limitado el tamaño máximo a 5 MB (`NC-12`). | Hollman De Orta | **Mitigada** | `recurso_router.py`, `test_auth.py` |
| **A10** | Configuración CORS abierta a cualquier origen (`*`) en producción. | Media | Media | Media | Variable `CORS_ORIGINS` parametrizada por entorno en Dokploy (`[https://api-linkclub.iscoutb.dev](https://api-linkclub.iscoutb.dev)`), manteniendo regex local solo para desarrollo. | Diego Ramos | **Mitigada** | `main.py`, `.env.example` |
| **A11** | Filtración de trazas internas o detalles SQL en respuestas de error HTTP. | Media | Media | Media | Manejadores globales en `main.py` interceptan errores de validación (`422`) y excepciones internas (`500`) devolviendo JSON genérico `{"detail": "..."}` (`NC-06`). | Hollman De Orta | **Mitigada** | `main.py` |
| **A12** | Exposición de la matrícula estudiantil del autor en el feed público (`autor_id`). | Alta | Media | Alta | La API resuelve y entrega `autor_nombre` en publicaciones y eventos; la interfaz Flutter omite la matrícula en tarjetas públicas (`NC-18`). | Hollman De Orta | **Mitigada** | `publicacion_router.py`, `evento_router.py`, `feed_screen.dart` |
| **A13** | Colisión global de `Idempotency-Key` entre distintos autores. | Baja | Media | Baja | Restricción única y consulta aislada por `(autor_matricula, idempotency_key)` en PostgreSQL (`NC-10`). | Josh Ortega | **Mitigada** | `publicacion_repository.py`, `publicacion_model.py` |
| **A14** | Ejecución del contenedor backend con privilegios de `root` o permisos excesivos. | Media | Media | Media | `backend/Dockerfile` crea y ejecuta el proceso bajo el usuario sin privilegios `appuser` (UID `1000`) con propiedad acotada sobre `/app/uploads`. | Diego Ramos | **Mitigada** | `backend/Dockerfile` |
| **A15** | Dependencias de terceros con vulnerabilidades conocidas (`CVE` / `PYSEC`). | Media | Media | Media | Actualizadas `PyJWT` y `python-multipart` y auditado `requirements.txt` con `pip-audit` sin vulnerabilidades activas. | Luis Salas | **Mitigada** | [analisis_dependencias.md](./analisis_dependencias.md) |
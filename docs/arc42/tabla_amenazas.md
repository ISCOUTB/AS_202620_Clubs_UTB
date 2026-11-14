# Tabla de amenazas

La siguiente tabla muestra las amenazas que pueden poner en peligro la seguridad de LinkClub. Cada amenaza tiene probabilidad, impacto, prioridad, mitigación, responsable y estado. Las amenazas A08 a A15 se identificaron revisando el código del repositorio.

## Criterio de priorización

Probabilidad e impacto se valoran de 1 a 3 (Baja = 1, Media = 2, Alta = 3). La prioridad sale del producto de ambos:

| Producto (prob. x impacto) | Prioridad |
|---|---|
| 6 o 9 | Alta |
| 3 o 4 | Media |
| 1 o 2 | Baja |

La probabilidad tiene en cuenta si el control ya existe en el código. Una amenaza sin ningún control implementado no se valora como Baja.

## Amenazas priorizadas con mitigación asignada

| ID | Amenaza | Prob. | Impacto | Prioridad | Mitigación | Responsable | Estado | Evidencia |
|---|---|---|---|---|---|---|---|---|
| A08 | Contraseñas almacenadas y comparadas en texto plano (`auth_router.py`) | Media | Alta | Alta | Hash con `bcrypt` implementado al registrar y verificar credenciales en `auth_router.py` (NC-05 resuelta). | Josh Ortega | Mitigada | `auth_router.py`, `lista_errores.md` (NC-05) |
| A01 | Acceso no autorizado a cuentas | Media | Alta | Alta | Autenticación con JWT, validación de credenciales con hash `bcrypt` y flujo OAuth2 (implementado). Pendiente: expiración corta con renovación. | Josh Ortega | En curso | `local_jwt_adapter.py`, `auth_router.py`, `test_auth.py` |
| A02 | Exposición de claves secretas y variables de entorno: `JWT_SECRET` tenía un valor por defecto en el código | Media | Alta | Alta | Eliminado el secreto por defecto; `JWT_SECRET` se exige al arrancar aplicando *fail-fast* en `auth_router.py` y `auth_dependency.py` (NC-11 resuelta). | Diego Ramos | Mitigada | `auth_router.py`, `auth_dependency.py`, `.gitignore` |
| A09 | Subida de archivos sin sesión, sin límite de tamaño y con SVG permitido (riesgo de XSS y de llenar el disco) | Alta | Media | Alta | Exigido `require_auth` en `/recursos/upload` y retirado `svg` de las extensiones permitidas (NC-12 resuelta). Pendiente: límite máximo de tamaño y validación por magic bytes. | Hollman De Orta | En curso | `recurso_router.py`, `test_auth.py::test_toda_ruta_de_escritura_exige_auth` |
| A12 | La matrícula del autor se expone en el feed público (`autor_id`) | Alta | Media | Alta | Decidir con el equipo: exponer solo el nombre, o usar un identificador opaco en lugar de la matrícula. Ajustar contrato y respuesta. | Hollman De Orta | Pendiente | `publicacion_router.py`, `openapi.yaml` |
| A04 | Acceso no autorizado a funciones administrativas: no hay autorización por rol dentro de cada club | Media | Alta | Alta | Implementar membresías y validar el rol en cada operación (respuesta 403). | Luis Salas | Pendiente | Contrato `/clubes/{id}/miembros`, Sección 9 |
| A05 | Pérdida de información de la base de datos y del volumen de imágenes: no hay respaldo automático | Media | Alta | Alta | `pg_dump` periódico y copia del volumen a un destino externo al servidor; documentar el procedimiento de restauración. | Diego Ramos | Pendiente | Sección 7.2.2, Sección 11 |
| A07 | Ataques de fuerza bruta contra el inicio de sesión: no hay límite de intentos | Alta | Media | Alta | Límite de intentos por correo e IP con tiempo de espera; mensaje de error uniforme. | Josh Ortega | Pendiente | `auth_router.py` |
| A03 | Envío de datos incompletos o incorrectos a la base de datos | Alta | Media | Alta | Validación con Pydantic en la API, restricciones `CHECK` y `NOT NULL` en la migración y sincronización de modelos ORM a `UUID` con `001_esquema_inicial.sql` (NC-08 resuelta). | Luis Salas | Mitigada | `001_esquema_inicial.sql`, `club_model.py`, `publicacion_model.py` |
| A10 | CORS abierto a cualquier origen (`allow_origins=["*"]`) | Media | Media | Media | Aplicar la lista de orígenes de `CORS_ORIGINS`; en producción no usar comodín. | Diego Ramos | Pendiente | `main.py`, `compose.lab.yaml` |
| A11 | Filtración de detalles internos: la API devuelve `str(error)` al cliente | Media | Media | Media | Corregida errata de validación en `main.py` (NC-06). Pendiente: depurar mensajes genéricos en excepciones no previstas y distinguir 404, 409 y 500. | Hollman De Orta | En curso | `main.py`, `publicacion_router.py` |
| A14 | Configuración insegura del contenedor: `chmod 777` en `/app/uploads` y pasos del Dockerfile sin encadenar | Media | Media | Media | Corregir el Dockerfile (instrucciones `RUN` válidas, permisos mínimos al usuario `appuser`); verificar que el build funcione. | Diego Ramos | Pendiente | `backend/Dockerfile` |
| A15 | Dependencias con vulnerabilidades conocidas, obsoletas o innecesarias | Media | Media | Media | Vulnerabilidades corregidas (pip-audit sin hallazgos). Pendiente: retirar dependencias sin uso y separar las de pruebas. Ver [análisis de dependencias](./analisis_dependencias.md). | Luis Salas | En curso | `analisis_dependencias.md`, `requirements.txt` |
| A06 | Un estudiante accede a la información privada de otro | Baja | Alta | Media | Verificar propiedad de los recursos y permisos del usuario autenticado; el perfil (`/usuarios/me`) debe devolver solo al usuario del token. | Luis Salas | Pendiente | Contrato `/usuarios/me` |
| A13 | La clave de idempotencia es única globalmente y no por autor; un reintento con la clave de otro usuario devolvería su publicación | Baja | Media | Baja | Implementada restricción y consulta por `(autor_id, idempotency_key)` con reconstrucción de `UUID` (NC-10 resuelta). | Josh Ortega | Mitigada | `publicacion_repository.py`, `publicacion_model.py` |


## Seguimiento

El estado se actualiza al cerrar cada Pull Request. Una amenaza pasa a "Mitigada" solo si hay una prueba o un cambio verificable enlazado en la columna Evidencia.
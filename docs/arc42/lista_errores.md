# Correcciones y No Conformidades (NC)

El objetivo del documento es registrar las no conformidades, desviaciones o aspectos de mejora identificados a lo largo del desarrollo de **LinkClub**, junto con su estado, responsable y evidencia de resolución.

## Registro de No Conformidades

| ID | Descripción del hallazgo | Severidad | Responsable | Estado | Resolución y evidencia |
| ------ | ------ | ------ | ------ | ------ | ------ |
| **NC-01** | La aplicación móvil mostraba datos de clubes codificados localmente en `clubs_page.dart` en lugar de consultar la API. | Alta | Hollman De Orta | **Resuelta** | Implementado `ClubRepository` en Flutter consumiendo `GET /clubes` y `GET /clubes/{id}` desde PostgreSQL. |
| **NC-02** | El backend servía el catálogo de clubes desde `InMemoryClubAdapter` sin persistencia en PostgreSQL. | Alta | Diego Ramos | **Resuelta** | `club_router.py` consulta `ClubModel` en PostgreSQL e inicializa `_SEMILLA` de forma idempotente al arrancar (`main.py`). |
| **NC-03** | El buscador de clubes carecía de filtrado funcional en UI y sensibilidad a tildes/mayúsculas en backend. | Media | Hollman De Orta | **Resuelta** | Filtro con `.casefold()` en `club_router.py` (`q`, `categoria`) y búsqueda reactiva en `ClubsPage`. |
| **NC-04** | Endpoints de eventos, confirmación de asistencia y perfil de usuario (`/usuarios/me`) definidos en el contrato pero sin implementar. | Alta | Luis Salas | **Resuelta** | Implementados `evento_router.py`, `usuario_router.py`, `EventoRepository` y pantallas correspondientes en Flutter. |
| **NC-05** | Contraseñas almacenadas y comparadas en texto plano en `auth_router.py`. | Crítica | Josh Ortega | **Resuelta** | Implementado hash adaptativo `bcrypt` en registro, inicio de sesión y cambio de contraseña (`auth_router.py`, `usuario_router.py`). |
| **NC-06** | Errata en el manejador de excepciones de validación en `main.py` que impedía formatear errores `422` uniformes. | Media | Hollman De Orta | **Resuelta** | Corregido `RequestValidationError` y manejador global `Exception` en `main.py` devolviendo `{"detail": "..."}`. |
| **NC-07** | Divergencias entre `docs/api/openapi.yaml` y las rutas/esquemas reales de la API. | Alta | Diego Ramos | **Resuelta** | Contrato actualizado a `openapi.yaml` v3.1.0, validado con `Spectral`, `oasdiff` y `test_contrato_openapi.py`. |
| **NC-08** | Desalineación entre `001_esquema_inicial.sql` (`UUID`) y los modelos ORM de SQLAlchemy (enteros). | Alta | Luis Salas | **Resuelta** | Unificados todos los modelos ORM (`club_model.py`, `publicacion_model.py`, `evento_model.py`, `usuario_model.py`, `solicitud_admin_model.py`) a `UUID` y creada migración `002_sincronizar_esquema_orm.sql`. |
| **NC-09** | El endpoint `GET /health` devolvía `200 OK` estático sin comprobar la disponibilidad de PostgreSQL. | Alta | Diego Ramos | **Resuelta** | `PostgresStatusAdapter` ejecuta `SELECT 1` y responde `503 Service Unavailable` si falla la conexión (`test_health.py`). |
| **NC-10** | La clave de idempotencia colisionaba globalmente y reconstruía mal el `UUID` de la publicación existente. | Alta | Josh Ortega | **Resuelta** | Aislada por `(autor_matricula, idempotency_key)` en `PublicacionRepositoryPostgres` y `CrearPublicacionUseCase` (`201`/`409`). |
| **NC-11** | `JWT_SECRET` tenía un valor por defecto inseguro en el código fuente. | Crítica | Diego Ramos | **Resuelta** | Eliminado el valor por defecto; validación *fail-fast* obligatoria al arrancar en `auth_dependency.py` y `auth_router.py`. |
| **NC-12** | `/recursos/upload` permitía cargas sin autenticación, sin límite de tamaño y aceptaba archivos `.svg`. | Alta | Hollman De Orta | **Resuelta** | Exigido `require_auth`, retirado `svg` y limitado el tamaño máximo a 5 MB (`MAX_UPLOAD_BYTES`) en `recurso_router.py`. |
| **NC-13** | Registro duplicado de matrícula o correo producía errores de integridad no controlados (`500`). | Media | Josh Ortega | **Resuelta** | Captura explícita de duplicados devolviendo `409 Conflict` uniforme en `auth_router.py`. |
| **NC-14** | Logs de red en el cliente Flutter imprimían cuerpos de petición/respuesta con credenciales y tokens. | Alta | Hollman De Orta | **Resuelta** | Eliminado el volcado de cuerpos sensibles en `ApiClient`. |
| **NC-15** | Silenciamiento de errores globales de Flutter ocultaba fallos de renderizado en desarrollo. | Media | Hollman De Orta | **Resuelta** | Restaurado el manejo controlado de errores en `main.dart`. |
| **NC-16** | Ausencia de control de acceso por rol (`403 Forbidden`) para operaciones administrativas de clubes y publicaciones. | Alta | Luis Salas | **Resuelta** | Implementado RBAC (`ESTUDIANTE`, `ADMIN_CLUB` verificado, `SUPERADMIN`) y flujo de solicitudes (`/admin/solicitudes`). |
| **NC-17** | La pantalla de creación de publicaciones en Flutter solo permitía crear `aviso` y mostraba datos fijos en vista previa. | Baja | Hollman De Orta | **Resuelta** | Incorporado selector de tipo (`aviso`, `encuesta`, `noticia`) y vista previa dinámica con datos reales de `SessionController`. |
| **NC-18** | Exposición de la matrícula institucional (`autor_id`) en las tarjetas públicas del feed. | Media | Hollman De Orta | **Resuelta** | La API expone `autor_nombre` y la interfaz pública oculta la matrícula estudiantil. |
| **NC-19** | Sintaxis YAML inválida en `.github/workflows/backend-tests.yml` bloqueaba la ejecución de CI. | Media | Diego Ramos | **Resuelta** | Corregida la estructura YAML; workflows `backend-tests.yml` y `contrato.yml` operativos. |
| **NC-20** | Nombre del archivo ADR 0003 con espacios (`0003- integacion rest openapi.md`). | Baja | Equipo LinkClub | **Documentada** | Conservado para preservar historial Git; referencias enlazadas con codificación URL (`%20`). |
| **NC-21** | `deploy/compose.lab.yaml` declara `postgres:16-alpine` mientras Dokploy ejecuta `postgres:18`. | Baja | Diego Ramos | **Abierta** | Pendiente actualizar la etiqueta de imagen en `compose.lab.yaml` para paridad exacta con producción. |
| **NC-22** | Ausencia de respaldo automatizado de PostgreSQL (`pg_dump`) y del volumen `linkclub_uploads`. | Media | Diego Ramos | **Abierta** | Registrada como riesgo operacional pendiente en la [Sección 11](./11_riesgos_y_deuda_tecnica.md). |
| **NC-23** | Los endpoints `GET /publicaciones`, `GET /clubes` y `GET /eventos` devuelven listados sin paginación. | Baja | Luis Salas | **Abierta** | Aceptado para el volumen institucional actual (P95 = 131 ms $\le 800\text{ ms}$); candidato a paginación en evolución futura. |

## Recorrido de auditoría

La lista se puede verificar ejecutando los comandos siguientes desde la raíz del repositorio. Alcance: `backend/src`, `backend/tests`, `backend/migrations`, `deploy`, `.github/workflows`, `frontend/linkclub/lib` y `docs`.

| Verificación | Comando | NC relacionadas |
| ------ | ------ | ------ |
| Suite de pruebas (38 tests) | `cd backend && PYTHONPATH=src JWT_SECRET=test DATABASE_URL=sqlite:///./test.db pytest tests/ -v` | NC-02 a NC-16 |
| Validez de los workflows | `python -c "import yaml; [yaml.safe_load(open(f)) for f in ['.github/workflows/backend-tests.yml','.github/workflows/contrato.yml']]; print('OK')"` | NC-19 |
| Validación del contrato OpenAPI | `npx @stoplight/spectral-cli lint docs/api/openapi.yaml` | NC-07, NC-08, NC-10, NC-12 |
| Auditoría de dependencias Python | `cd backend && pip-audit -r requirements.txt` | Amenaza A15 |
# Correcciones y No Conformidades (NC)

El objetivo del documento es registrar las no conformidades, desviaciones o aspectos de mejora identificados en el proyecto LinkClub, y establecer un plan, un responsable y una referencia para cada hallazgo.

## Registro

| ID | Hallazgo | Estado | Plan | Referencia |
| --- | --- | --- | --- | --- |
| NC-01 | Los datos de los clubes están fijos en `clubs_page.dart` y la API los sirve desde un adaptador en memoria. | Pendiente | Persistir el catálogo en la tabla `clubes` y consumirlo desde la aplicación. | Regla de dueño único, [Sección 8](./08_conceptos_transversales.md) |
| NC-02 | No existía manejo de errores de conexión en la aplicación. | Resuelto en el cliente | Las pantallas capturan `DioException` y muestran mensajes controlados; el feed informa cuando no hay conexión. Sigue pendiente el manejo centralizado de errores de conexión a la base en la API. | U2 |
| NC-03 | El campo de búsqueda de la pantalla de clubes no filtra. | Pendiente | Conectar el campo a los parámetros `q` y `categoria` de `GET /clubes`. | U1 |
| NC-04 | Cierre de sesión sin lógica asociada. | Resuelto en el cliente | Se elimina el token del almacenamiento seguro y se regresa al inicio de sesión. Al ser un token sin estado, no hay revocación en el servidor hasta que vence. | U3 |
| NC-05 | Las contraseñas se guardan y se comparan sin hash (`auth_router.py`). | Resuelto | Implementado cifrado con `bcrypt` al registrar usuarios y verificación de hash en el inicio de sesión (`auth_router.py`). | Amenaza A08, [Sección 11](./11_riesgos_y_deuda_tecnica.md) |
| NC-06 | El manejador de errores de validación de `main.py` referencia una variable inexistente; un cuerpo JSON que no sea un objeto produce un error 500. Verificado por ejecución. | Resuelto | Corregida la errata en el manejador `RequestValidationError` en `main.py`, garantizando respuestas `422` con formato uniforme `{"detail": "..."}`. | Contrato de errores uniforme |
| NC-07 | El contrato define el inicio de sesión como formulario con campo `username`; el código y la aplicación usan JSON con campo `correo`. | Resuelto | `auth_router.py` refactorizado para usar `OAuth2PasswordRequestForm` (`application/x-www-form-urlencoded` con campo `username`), alineado con `openapi.yaml` v3.0.0. | [ADR 0003](../adr/0003-%20integacion%20rest%20openapi.md) |
| NC-08 | El esquema de `001_esquema_inicial.sql` no coincide con los modelos ORM (tipo de identificadores, llave de usuarios, columna de idempotencia). Las pruebas usan SQLite, que no aplica llaves foráneas: publicar en un club inexistente devuelve 201 en pruebas. | Resuelto | Modelos ORM (`club_model.py` y `publicacion_model.py`) sincronizados a `UUID` nativo conforme a `001_esquema_inicial.sql` y `openapi.yaml` v3.0.0. | Amenaza A03, Sección 11 |
| NC-09 | `/health` devuelve un valor fijo y no sondea la base de datos. | Resuelto | Reemplazado `InMemoryStatusAdapter` por `PostgresStatusAdapter` con consulta activa `SELECT 1` y respuesta controlada `503 Service Unavailable` si la base falla. | U2 |
| NC-10 | El reintento con la misma `Idempotency-Key` responde 422 (el identificador reconstruido es un UUID y la respuesta exige un entero). La clave es única globalmente, no por autor, y la consulta no compara autor ni contenido. El código de estado difiere entre código, contrato y documento de diseño. Verificado por ejecución. | Resuelto | Corregida la reconstrucción con tipo `UUID`, aislada la clave por autor `(autor_id, idempotency_key)` y unificada la respuesta en `openapi.yaml` v3.0.0 (devuelve la publicación original sin duplicar o `409` ante payload distinto). | R1, [idempotencia.md](../resilience/idempotencia.md), [ADR 0008](../adr/0008-no-extraer-publicaciones.md) |
| NC-11 | El secreto de firma de tokens tiene un valor por defecto en el código y CORS acepta cualquier origen. | Resuelto en `JWT_SECRET` | Eliminado el secreto por defecto en `auth_dependency.py` y `auth_router.py`, aplicando validación *fail-fast* al arrancar si falta `JWT_SECRET`. | Amenazas A02 y A10 |
| NC-12 | La carga de imágenes exige sesión, pero no limita el tamaño y admite SVG. | Resuelto en extensión y sesión | Exigida autenticación con `require_auth` y retirado `svg` de `ALLOWED_EXTENSIONS` en `recurso_router.py` (`jpg`, `jpeg`, `png`, `webp`, `gif`). | Amenaza A09 |
| NC-13 | El registro con una matrícula repetida produce un error 500 en lugar de 409; dos registros simultáneos con el mismo correo pueden producir el mismo error. Verificado por ejecución para la matrícula. | Resuelto | Añadida validación explícita de unicidad de matrícula y manejo de conflicto en `auth_router.py` devolviendo `409 Conflict`. | Contrato, [8.4](./08_conceptos_transversales.md) |
| NC-14 | El cliente HTTP registra cuerpos de petición y respuesta, lo que expone credenciales en los registros de consola, y agrega el interceptor de registro dos veces. | Pendiente | Retirar el registro de cuerpos fuera de depuración y dejar un único interceptor. | [Privacidad](./privacidad.md) |
| NC-15 | `main.dart` descarta todos los errores del framework de Flutter, lo que oculta fallos reales. | Pendiente | Retirar el manejador vacío o reemplazarlo por uno que registre el error. | U2 |

## Recorrido de auditoría

La lista se puede repetir con los comandos siguientes, ejecutados desde la raíz del repositorio. Alcance: `backend/src`, `backend/tests`, `backend/migrations`, `deploy`, `.github/workflows`, `frontend/linkclub/lib` y `docs`. Última ejecución: 2026-11-14.

| Verificación | Comando | NC relacionadas |
|---|---|---|
| Suite de pruebas | `cd backend && PYTHONPATH=src pytest tests/ -v` | NC-05, NC-06, NC-07, NC-08, NC-09, NC-10, NC-11, NC-12, NC-13 |
| Validez de los workflows | `python -c "import yaml,sys; [yaml.safe_load(open(f)) for f in ['.github/workflows/backend-tests.yml','.github/workflows/contrato.yml']]; print('OK')"` | CI/CD |
| Validación del contrato OpenAPI | `npx @stoplight/spectral-cli lint docs/api/openapi.yaml` | NC-07, NC-08, NC-10, NC-12 |
| Auditoría de dependencias Python | `cd backend && pip-audit -r requirements.txt` | Amenaza A15 |
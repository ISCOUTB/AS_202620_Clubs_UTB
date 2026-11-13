# Correcciones y No Conformidades (NC)

El objetivo del documento es registrar las no conformidades, desviaciones o aspectos de mejora identificados en el proyecto LinkClub, y establecer un plan, un responsable y una referencia para cada hallazgo.

## Registro

| ID | Hallazgo | Estado | Plan | Referencia |
| --- | --- | --- | --- | --- |
| NC-01 | Los datos de los clubes están fijos en `clubs_page.dart` y la API los sirve desde un adaptador en memoria. | Pendiente | Persistir el catálogo en la tabla `clubes` y consumirlo desde la aplicación. | Regla de dueño único, [Sección 8](./08_conceptos_transversales.md) |
| NC-02 | No existía manejo de errores de conexión en la aplicación. | Resuelto en el cliente | Las pantallas capturan `DioException` y muestran mensajes controlados; el feed informa cuando no hay conexión. Sigue pendiente el manejo centralizado de errores de conexión a la base en la API. | U2 |
| NC-03 | El campo de búsqueda de la pantalla de clubes no filtra. | Pendiente | Conectar el campo a los parámetros `q` y `categoria` de `GET /clubes`. | U1 |
| NC-04 | Cierre de sesión sin lógica asociada. | Resuelto en el cliente | Se elimina el token del almacenamiento seguro y se regresa al inicio de sesión. Al ser un token sin estado, no hay revocación en el servidor hasta que vence. | U3 |
| NC-05 | Las contraseñas se guardan y se comparan sin hash (`auth_router.py`). | Pendiente, prioritario | Aplicar argon2 o bcrypt en un adaptador de salida, restablecer las cuentas existentes y registrar la decisión en un ADR nuevo. | Amenaza A08, [Sección 11](./11_riesgos_y_deuda_tecnica.md) |
| NC-06 | El manejador de errores de validación de `main.py` referencia una variable inexistente; un cuerpo JSON que no sea un objeto produce un error 500. Verificado por ejecución. | Pendiente | Corregir el nombre de la variable y agregar una prueba con cuerpo inválido. | Contrato de errores uniforme |
| NC-07 | El contrato define el inicio de sesión como formulario con campo `username`; el código y la aplicación usan JSON con campo `correo`. | Pendiente | Alinear contrato y código, y agregar una prueba de contrato del inicio de sesión. | [ADR 0003](../adr/0003-%20integacion%20rest%20openapi.md) |
| NC-08 | El esquema de `001_esquema_inicial.sql` no coincide con los modelos ORM (tipo de identificadores, llave de usuarios, columna de idempotencia). Las pruebas usan SQLite, que no aplica llaves foráneas: publicar en un club inexistente devuelve 201 en pruebas. | Pendiente | Unificar un único esquema, probarlo contra PostgreSQL y documentar la migración. | Amenaza A03, Sección 11 |
| NC-09 | `/health` devuelve un valor fijo y no sondea la base de datos. | Pendiente | Mantenerlo como liveness y agregar una comprobación de disponibilidad (readiness) mediante un puerto real. | U2 |
| NC-10 | El reintento con la misma `Idempotency-Key` responde 422 (el identificador reconstruido es un UUID y la respuesta exige un entero). La clave es única globalmente, no por autor, y la consulta no compara autor ni contenido. El código de estado difiere entre código, contrato y documento de diseño. Verificado por ejecución. | Pendiente | Reconstruir la publicación existente con su identificador real, aislar la clave por autor, validar el contenido, unificar el código de estado y agregar una prueba. | R1, [idempotencia.md](../resilience/idempotencia.md), [ADR 0008](../adr/0008-no-extraer-publicaciones.md) |
| NC-11 | El secreto de firma de tokens tiene un valor por defecto en el código y CORS acepta cualquier origen. | Pendiente | Exigir `JWT_SECRET` al arrancar, fallar si falta y aplicar `CORS_ORIGINS`. | Amenazas A02 y A10 |
| NC-12 | La carga de imágenes exige sesión, pero no limita el tamaño y admite SVG. | Pendiente | Limitar tamaño, validar el tipo real del archivo y retirar SVG de las extensiones permitidas. | Amenaza A09 |
| NC-13 | El registro con una matrícula repetida produce un error 500 en lugar de 409; dos registros simultáneos con el mismo correo pueden producir el mismo error. Verificado por ejecución para la matrícula. | Pendiente | Capturar la violación de unicidad y responder 409. | Contrato, [8.4](./08_conceptos_transversales.md) |
| NC-14 | El cliente HTTP registra cuerpos de petición y respuesta, lo que expone credenciales en los registros de consola, y agrega el interceptor de registro dos veces. | Pendiente | Retirar el registro de cuerpos fuera de depuración y dejar un único interceptor. | [Privacidad](./privacidad.md) |
| NC-15 | `main.dart` descarta todos los errores del framework de Flutter, lo que oculta fallos reales. | Pendiente | Retirar el manejador vacío o reemplazarlo por uno que registre el error. | U2 |

## Recorrido de auditoría

La lista se puede repetir con los comandos siguientes, ejecutados desde la raíz del repositorio. Alcance: `backend/src`, `backend/tests`, `backend/migrations`, `deploy`, `.github/workflows`, `frontend/linkclub/lib` y `docs`. Última ejecución: 2026-11-12.

| Verificación | Comando | NC relacionadas |
|---|---|---|
| Suite de pruebas | `cd backend && PYTHONPATH=src pytest tests/ -v` | NC-22 |
| Validez de los workflows | `python -c "import yaml,sys;

# Diseño de Idempotencia: Creación de Publicaciones

## 1. Escenario de Fallo Parcial

En la integración entre la aplicación móvil (**Flutter**) y la API (**FastAPI**), la creación de publicaciones (`POST /clubes/{club_id}/publicaciones`) está expuesta a la **falacia de la red confiable**: un estudiante o administrador de club puede enviar una publicación y sufrir una pérdida de conexión o *timeout* justo después de que PostgreSQL haya confirmado la transacción, pero antes de que el dispositivo reciba la respuesta `201 Created`.

Sin un mecanismo de idempotencia, el reintento automático o manual del usuario produciría publicaciones duplicadas en el feed del club.

## 2. Flujo de Extremo a Extremo (Flutter $\rightarrow$ FastAPI $\rightarrow$ PostgreSQL)

1. **Generación en el cliente móvil (`ApiClient`):**
   El interceptor de `Dio` en `frontend/linkclub/lib/core/network/api_client.dart` detecta toda solicitud `POST` saliente y, si no trae ya una clave asignada, genera e inyecta automáticamente la cabecera HTTP:
   ```text
   Idempotency-Key: <UUID-v4>
   ```
   Si la operación se reintenta por fallo de red dentro del mismo flujo de envío, se reutiliza la misma clave UUID v4.

2. **Recepción y validación en la capa web (`publicacion_router.py`):**
   El endpoint `POST /clubes/{club_id}/publicaciones` extrae el encabezado `Idempotency-Key` (obligatorio en `openapi.yaml` v3.1.0), verifica el token JWT y el rol del usuario (`ADMIN_CLUB` verificado del club o `SUPERADMIN`), y delega la ejecución a `CrearPublicacionUseCase`. Si la cabecera llega vacía o compuesta solo por espacios, responde `422 Unprocessable Entity`.

3. **Evaluación en la capa de aplicación (`CrearPublicacionUseCase`):**
   Antes de persistir una nueva entidad, el caso de uso consulta el repositorio por la dupla aislada `(autor_id, idempotency_key)`:
   * **Si no existe registro previo:** crea la entidad `Publicacion` y la persiste en PostgreSQL.
   * **Si existe registro previo con idéntico contenido** (`club_id`, `titulo`, `contenido`, `tipo` y `opciones`): devuelve la entidad original sin insertar una nueva fila.
   * **Si existe registro previo con distinto contenido:** lanza `PublicacionDuplicada` para evitar reutilización indebida de claves.

4. **Garantía en persistencia (`PublicacionRepositoryPostgres` y PostgreSQL 18):**
   La tabla `publicaciones` define la columna `idempotency_key` junto con la restricción de integridad compuesta `UNIQUE (autor_matricula, idempotency_key)` (migración `002_sincronizar_esquema_orm.sql`), garantizando aislamiento por autor y atomicidad transaccional incluso bajo peticiones concurrentes.

## 3. Reglas de Respuesta HTTP

| Situación | Código HTTP | Comportamiento |
| ------ | ------ | ------ |
| Primera petición válida con `Idempotency-Key` nueva | `201 Created` | Crea la publicación en PostgreSQL y devuelve el objeto creado. |
| Reintento con la misma `Idempotency-Key`, mismo autor y **mismo cuerpo** | `201 Created` | No inserta filas nuevas; devuelve el objeto `PublicacionResponse` original. |
| Petición con la misma `Idempotency-Key` y mismo autor, pero **cuerpo diferente** | `409 Conflict` | Rechaza la operación con `{"detail": "La Idempotency-Key ya fue utilizada con un contenido diferente"}`. |
| Ausencia de cabecera `Idempotency-Key` o valor en blanco | `422 Unprocessable Entity` | Rechaza la petición por incumplir el contrato de entrada. |

## 4. Trazabilidad en Código y Esquema

* **Cliente móvil:** `frontend/linkclub/lib/core/network/api_client.dart`
* **Contrato OpenAPI:** `docs/api/openapi.yaml` (`POST /clubes/{club_id}/publicaciones`)
* **Adaptador de entrada:** `backend/src/linkclub/adapters/inbound/api/publicacion_router.py`
* **Dominio y caso de uso:** `backend/src/linkclub/domain/publicacion.py` (`PublicacionDuplicada`), `backend/src/linkclub/application/use_cases/crear_publicacion.py` (`CrearPublicacionUseCase`)
* **Persistencia y esquema:** `backend/src/linkclub/adapters/outbound/postgres/publicacion_repository.py`, `backend/src/linkclub/adapters/outbound/postgres/models/publicacion_model.py`, `backend/migrations/002_sincronizar_esquema_orm.sql`
* **Pruebas automatizadas:** `backend/tests/test_publicaciones.py` y `backend/tests/test_contrato_openapi.py`
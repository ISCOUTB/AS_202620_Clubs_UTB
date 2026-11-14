# Diseño de Idempotencia: Creación de Publicaciones

## 1. Escenario de Fallo Parcial
En la integración principal entre la aplicación móvil (Flutter) y la API (FastAPI), las operaciones de creación de publicaciones (`POST /clubes/{club_id}/publicaciones` y `POST /publicaciones`) son susceptibles a la **falacia de la red confiable**. 

Si ocurre un *timeout* durante el tránsito de la respuesta (la API guardó el dato en PostgreSQL, pero la respuesta nunca llegó a Flutter), el cliente asumirá que la operación falló y ejecutará un reintento automático. Sin un control de idempotencia, esto resultaría en **registros duplicados** en el feed del club, degradando la integridad de los datos y la experiencia del usuario.

## 2. Mecanismo de Mitigación: Cabecera `Idempotency-Key`
Para mitigar este fallo, el sistema implementa un diseño de idempotencia basado en llaves únicas generadas por el cliente y aisladas por autor, garantizando que múltiples peticiones idénticas tengan el efecto de una sola.

### 2.1 Modificación en la Base de Datos (PostgreSQL)
Se define una columna `idempotency_key` (tipo `UUID` / `VARCHAR`) en la tabla `publicaciones` junto con una restricción de unicidad compuesta por autor (`UNIQUE (autor_id, idempotency_key)`), evitando colisiones entre distintos usuarios y asegurando que la reconstrucción del registro conserve su identificador `UUID` nativo.

### 2.2 Flujo de Ejecución del Patrón
1. **Generación (Cliente):** Antes de enviar el formulario de la publicación, Flutter genera un identificador único universal (UUID v4) mediante su interceptor HTTP.
2. **Transmisión:** Flutter envía la petición HTTP incluyendo la cabecera `Idempotency-Key: <uuid>`.
3. **Procesamiento (API):**
   - FastAPI extrae el `autor_id` del token JWT y el caso de uso (`CrearPublicacionUseCase`) consulta si ya existe un registro para el par `(autor_id, idempotency_key)`.
   - **Camino feliz (Primer intento):** No existe registro previo; la base de datos guarda la publicación y la API responde `201 Created`.
   - **Reintento idéntico (Fallo parcial previo):** Si Flutter reintenta con la misma llave y el mismo contenido, la API recupera la publicación original (sin duplicar) y devuelve `200 OK` / `201 Created` con los datos ya persistidos.
   - **Conflicto de contenido:** Si se reutiliza la misma `Idempotency-Key` para el mismo autor con un payload distinto, la API rechaza la operación con `409 Conflict` (`{"detail": "..."}`).
4. **Resolución:** Flutter recibe la publicación original sin errores `422` ni `500` y el usuario nunca percibe la interrupción de red.
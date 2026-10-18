# Diseño de Idempotencia: Creación de Publicaciones

## 1. Escenario de Fallo Parcial
En la integración principal entre la aplicación móvil (Flutter) y la API (FastAPI), la operación de crear una publicación (`POST /clubes/{club_id}/publicaciones`) es susceptible a la **falacia de la red confiable**. 

Si ocurre un *timeout* durante el tránsito de la respuesta (la API guardó el dato en PostgreSQL, pero el 201 Created nunca llegó a Flutter), el cliente asumirá que la operación falló y ejecutará un reintento automático. Sin un control de idempotencia, esto resultaría en **registros duplicados** en el feed del club, degradando la integridad de los datos y la experiencia del usuario.

## 2. Mecanismo de Mitigación: Cabecera `Idempotency-Key`
Para mitigar este fallo, el sistema implementa un diseño de idempotencia basado en llaves únicas generadas por el cliente, garantizando que múltiples peticiones idénticas tengan el efecto de una sola.

### 2.1 Modificación en la Base de Datos (PostgreSQL)
Se añade una columna `idempotency_key` (tipo `UUID` o `VARCHAR`) a la tabla `publicaciones` con una restricción de unicidad (`UNIQUE CONSTRAINT`).

### 2.2 Flujo de Ejecución del Patrón
1. **Generación (Cliente):** Antes de enviar el formulario de la publicación, Flutter genera un identificador único universal (UUID v4).
2. **Transmisión:** Flutter envía la petición HTTP incluyendo la cabecera `Idempotency-Key: <uuid>`.
3. **Procesamiento (API):**
   - FastAPI recibe la petición y el caso de uso intenta insertar el registro en la base de datos adjuntando la llave de idempotencia.
   - **Camino feliz (Primer intento):** La base de datos guarda el registro. La API responde `201 Created`.
   - **Camino de fallo (Reintento):** Si Flutter reintenta con la misma llave, PostgreSQL rechaza la inserción por violación de unicidad (`UniqueViolation`).
4. **Resolución:** El adaptador de persistencia captura la excepción de unicidad. En lugar de devolver un error 500, la API busca la publicación existente asociada a esa llave y devuelve un `200 OK` con los datos originales. Flutter recibe el éxito y el usuario nunca nota la interrupción.

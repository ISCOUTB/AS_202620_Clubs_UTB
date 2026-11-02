# ADR 0009: Mensajería asíncrona para notificar publicaciones creadas (al-menos-una-vez con consumidor idempotente)

## Estado
Propuesto

## Fecha
25/10/2026

## Contexto

Cuando un líder crea una publicación, el sistema debería avisar a los miembros del club. Hoy esa notificación no existe. El [ADR 0003](0003-%20integacion%20rest%20openapi.md) la difirió y el [ADR 0008](0008-no-extraer-publicaciones.md) dejó la alternativa B (entrega de notificaciones como proceso asíncrono) como la extracción mejor justificada, a reabrir cuando hubiera un transporte elegido. Este ADR es el experimento que evalúa esa alternativa con propiedades verificables.

La operación elegida es **publicación creada, notificar a los miembros**. Tiene desacoplamiento temporal real: crear la publicación debe responder rápido y no debe fallar porque el envío de la notificación esté lento o caído. Esa entrega puede ocurrir segundos después sin que el líder lo note.

Restricciones que pesan (las mismas del ADR 0008):
- **C2:** el cronograma no contempla tecnologías nuevas (broker, cola).
- **F1:** costo cero mensual en producción.
- **U1 y U2:** latencia de creación ≤ 800 ms y manejo controlado de fallos de dependencias.

Por C2 y F1 el transporte del experimento es un **simulador local en memoria** (`InMemoryBroker`) detrás de un puerto (`PublicadorPort`). Se pidió verificar propiedades, no usar una marca.

## Alternativas

### A. Notificación síncrona dentro de `POST /clubes/{club_id}/publicaciones`
El caso de uso guarda la publicación y, en la misma petición, llama al notificador.
- Simple: sin cola, sin duplicados, sin estados intermedios.
- Acopla la latencia y la disponibilidad: si el notificador tarda o falla, la creación tarda o falla (contra U1 y U2). Con muchos miembros el tiempo crece con el tamaño del club.
- Si la notificación falla después de guardar, hay que elegir entre devolver error (el cliente reintenta y duplica la publicación, aunque `Idempotency-Key` lo mitiga) o tragarse el error (se pierde el aviso sin rastro).
- No hay forma natural de reintentar solo la notificación.

### B. Mensajería asíncrona con outbox, reintentos y consumidor idempotente (elegida)
La creación registra un mensaje en un outbox; un relay lo publica al broker; un consumidor lo procesa con reintentos y deduplicación. Las fallas de notificación no afectan a la creación y se pueden reintentar o reprocesar.

### C. Cola real (RabbitMQ, Kafka o servicio administrado)
Daría durabilidad y escalado reales, pero exige infraestructura nueva (contra C2 y F1) y operarla en el único servidor de Dokploy (ADR 0007). Se difiere, no se descarta: el puerto permite cambiar el adaptador sin tocar el dominio.

## Decisión
Se adopta la **alternativa B con transporte simulado en memoria**, manteniendo la creación de publicaciones síncrona y desacoplando solo la notificación.

### 1. Contrato del mensaje y criterio de compatibilidad
Tipo `publicacion.creada`, versión `1.0`. Código: `application/messaging/mensaje.py`.

| Campo | Descripción |
|---|---|
| `message_id` | UUID único del mensaje; es la llave de deduplicación |
| `type` | siempre `publicacion.creada` |
| `version` | `MAYOR.MENOR` |
| `correlation_id` | une el mensaje con la petición que lo originó |
| `occurred_at` | fecha UTC ISO 8601 |
| `data` | `publicacion_id`, `club_id`, `autor_id`, `tipo`, `titulo` (todos requeridos, tipo string) |

Criterio de compatibilidad:
- **Compatible (versión menor, ej. 1.1):** se pueden agregar campos opcionales a `data`. Un consumidor `1.x` ignora los campos que no conoce.
- **Incompatible (versión mayor, ej. 2.0):** quitar o renombrar un campo requerido, o cambiar su tipo. El consumidor la rechaza como `ContratoInvalido` y el mensaje va a la DLQ sin reintentos.
- Orden de despliegue: primero el consumidor, después el productor.

### 2. Garantía de entrega
**Al-menos-una-vez**, con productor confiable (outbox) y consumidor idempotente. Se descarta "exactamente-una-vez" por ser costosa e inalcanzable de extremo a extremo sin transacciones distribuidas. Consecuencias asumidas:
- El consumidor puede recibir el mismo mensaje más de una vez (reintento, ack perdido); por eso la deduplicación es obligatoria.
- No hay garantía de orden global entre mensajes.
- La notificación llega con retraso (segundos), no dentro de la petición.

### 3. Duplicados
El consumidor (`application/use_cases/notificar_publicacion.py`) consulta `ya_procesado(message_id)`; si ya lo vio, lo descarta y cuenta `duplicados_descartados`. El `message_id` se marca **después** del efecto: si el proceso cae entre notificar y marcar, el mensaje se reprocesa y el efecto puede repetirse. Es el costo de preferir duplicar a perder. Ya existe un nivel previo de idempotencia en la API (`Idempotency-Key`, ver [`docs/resilience/idempotencia.md`](../resilience/idempotencia.md)) que evita publicaciones duplicadas.

### 4. Reintentos, backoff y DLQ
- Se distinguen **errores transitorios** (`ErrorTransitorio`, se reintentan) de **permanentes** (`ContratoInvalido`, van directo a la DLQ sin reintentar).
- Política (`PoliticaReintentos`): máximo 4 intentos, espera `aleatorio(0, min(8 s, 0.5 s * 2^(intento-1)))` (backoff exponencial con jitter completo).
- Agotados los intentos, el mensaje pasa a la **DLQ** con su motivo, y se cuenta `dlq`. Se reprocesa con `reprocesar_dlq()` tras corregir la causa.
- Si el broker está caído al publicar, el mensaje queda en el **outbox** y el relay (`OutboxRelay.drenar`) lo reintenta después; la creación de la publicación no falla.

### 5. Observabilidad
Cada etapa deja un log con `message_id` y `correlation_id` (`application/messaging/observabilidad.py`): `publicado`, `recibido`, `reintento`, `procesado`, `ack` (y `duplicado_descartado`, `dlq`, `ack_perdido`, `outbox_pendiente`). Filtrando por `message_id` se sigue un mensaje de productor a consumidor. Contadores en `Metricas`: `publicados`, `reintentos`, `duplicados_descartados`, `procesados`, `dlq`, `outbox_fallos`.

### 6. Verificación
`backend/tests/test_mensajeria.py` (8 pruebas, `pytest`):
- duplicado descartado (ack perdido, el efecto ocurre una sola vez);
- fallo recuperable con reintento y backoff (esperas 0.5 s y 1.0 s) y entrega final;
- agotamiento de reintentos a la DLQ y reprocesamiento;
- mensaje inválido a la DLQ sin reintentos;
- campo opcional nuevo (v1.1) aceptado; versión mayor (2.0) a la DLQ;
- recuperación del outbox con el broker caído;
- seguimiento por log de un mensaje de productor a consumidor.

Ejecución completa de la suite del backend: 36 pruebas pasan.

## Consecuencias

### Positivas
- La creación de publicaciones no depende de que la notificación funcione (cumple U1 y U2): la latencia de creación no crece con el tamaño del club.
- Las fallas se aíslan, se reintentan y quedan visibles (DLQ y logs), en lugar de perderse o duplicar publicaciones.
- Sin tecnología nueva ni costo (cumple C2 y F1); un broker real es cambiar un adaptador tras `PublicadorPort`.
- Contrato versionado con criterio explícito de compatibilidad.

### Negativas / costos asumidos
- Más piezas que operar y entender (outbox, relay, DLQ, deduplicación) frente a una sola llamada síncrona.
- Consistencia eventual: la notificación llega después de la publicación, y puede no llegar hasta que se reprocese la DLQ.
- Posibles notificaciones repetidas si el proceso cae entre el efecto y la marca de deduplicación.
- Sin orden global garantizado.

### Límites del experimento
- **El broker, el outbox y la deduplicación son en memoria:** si el proceso se reinicia, se pierden los mensajes pendientes, la DLQ y los `message_id` ya vistos. No se demuestra durabilidad real. Para producción el outbox debería ser una tabla en PostgreSQL (misma transacción que la publicación) y la deduplicación una tabla con restricción única.
- El notificador es un puerto sin envío real (no hay push ni correo); se verifica el flujo, no la entrega al usuario.
- La concurrencia es de un solo proceso y un solo consumidor; no se prueban varios consumidores ni condiciones de carrera.
- El backoff se prueba con reloj y azar inyectados, no con tiempos reales.
- No se midió rendimiento ni se comparó latencia real contra la alternativa síncrona; la comparación es de diseño y de modos de fallo.

### Condiciones que reabren esta decisión
Cambiar a un broker real (alternativa C) si ocurre alguno: se aprueba enviar push o correo reales; se necesita sobrevivir reinicios sin perder notificaciones; o el volumen de miembros hace inviable el procesamiento en el mismo proceso.

## Trazabilidad
- **Escenarios de calidad:** U1 y U2 de [Sección 10](../arc42/10_requisitos_de_calidad.md).
- **Restricciones:** C2 y F1 de [Sección 2](../arc42/02_restricciones.md).
- **Decisiones relacionadas:** [ADR 0003](0003-%20integacion%20rest%20openapi.md) (difirió notificaciones), [ADR 0008](0008-no-extraer-publicaciones.md) (alternativa B, condiciones de reapertura), [ADR 0001](0001-hexagonal.md) (puertos y adaptadores).
- **Modos de fallo e idempotencia:** [`docs/arc42/tabla_fallos.md`](../arc42/tabla_fallos.md), [`docs/resilience/idempotencia.md`](../resilience/idempotencia.md).
- **Código:** `backend/src/linkclub/application/messaging/mensaje.py`, `application/messaging/observabilidad.py`, `application/use_cases/notificar_publicacion.py`, `application/ports/outbound_mensajeria_port.py`, `adapters/outbound/messaging/in_memory_broker.py`, `adapters/outbound/messaging/outbox.py`, `adapters/outbound/persistence/in_memory_dedup.py`.
- **Pruebas:** `backend/tests/test_mensajeria.py`.

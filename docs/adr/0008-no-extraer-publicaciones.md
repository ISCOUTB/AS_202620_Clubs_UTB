# ADR 0008: No extraer Publicaciones: se mantiene un único backend desplegable

## Estado
Propuesto

## Fecha
18/10/2026

## Contexto


Publicaciones es el candidato natural a extraerse: es el contexto con escritura, el que más lectura recibiría y el punto donde a futuro se engancharía la entrega de notificaciones, diferida en el [ADR 0003](0003-%20integacion%20rest%20openapi.md). Antes de extraerlo hay que decidir si el beneficio compensa el costo: extraer convierte llamadas en memoria en llamadas de red y agrega modos de fallo nuevos (timeouts, duplicados por reintento, inconsistencia entre datos de dos servicios). Los modos de fallo y el diseño de idempotencia están en [`docs/arc42/tabla_fallos.md`](../arc42/tabla_fallos.md).

Restricciones que pesan en la decisión:
- **C2:** el cronograma no contempla tecnologías nuevas (broker, cola, descubrimiento de servicios).
- **F1:** costo cero mensual en producción.
- **U1 y U2:** latencia ≤ 800 ms y manejo controlado de fallos de dependencias.
- **Infraestructura (ADR 0007):** un único servidor de despliegue (Dokploy) con backend y base en la misma red.

## Alternativas

### A. Extraer Publicaciones como microservicio con su propia base de datos
Permitiría escalar y desplegar Publicaciones por separado. Costo concreto en este repo:
- Hay que eliminar la llave foránea `publicaciones.club_id → clubes`. Hoy la base impide publicar en un club inexistente; separada, esa validación pasaría a ser una llamada de red entre servicios o una verificación eventual.
- Un segundo despliegue, un segundo contenedor de base de datos y un segundo pipeline en el mismo servidor, contra O1 y la operación manual que el ADR 0007 ya reconoce como costo.
- Consistencia entre servicios (reintentos, idempotencia entre ellos) que hoy resuelve una transacción local.

### B. Extraer solo la entrega de notificaciones como proceso asíncrono
Es la extracción mejor justificada técnicamente (desacopla el envío de la creación), pero hoy no hay consumidor ni transporte elegido, y exigiría cola o broker y un patrón de entrega confiable (outbox o equivalente). Se difiere por la misma razón que en el ADR 0003.

### C. Mantener un único backend desplegable con contextos aislados (elegida)
Un solo backend, un solo despliegue y un solo contenedor de base de datos, con cada contexto aislado detrás de sus puertos. Conserva la opción de extraer más adelante sin pagar hoy el costo de la distribución.

## Decisión
**No se extrae ningún módulo en esta etapa.** Publicaciones, Clubes y Usuarios permanecen en el mismo backend, el mismo contenedor y la misma base. Para que extraer después siga siendo barato se establecen estas reglas:

1. Un contexto no importa clases de dominio de otro; se comunica por puertos y por identificadores (`club_id`, `autor_id`), como ya establece la regla de dueño único.
2. Ningún contexto hace consultas sobre tablas de otro contexto; cada uno accede solo a las suyas. Las llaves foráneas entre contextos son la única excepción aceptada, y se listan para poder retirarlas si algún día se extrae.
3. Las operaciones de creación que un cliente pueda reintentar (crear publicación) se diseñan idempotentes desde ya, con `Idempotency-Key` y restricción única `(autor_id, idempotency_key)` (ver [`tabla_fallos.md`](../arc42/tabla_fallos.md)), para que el día que haya red entre servicios un reintento no duplique datos.

### Condiciones que reabren esta decisión
Se escribirá un ADR nuevo que reemplace a este si ocurre alguno de estos disparadores:

| Disparador | Umbral | Módulo que se evalúa extraer |
|---|---|---|
| Se aprueba implementar notificaciones (push o correo) con transporte elegido | Decisión del equipo | Entrega de notificaciones (alternativa B) |
| La carga de lectura de publicaciones degrada el resto del API | Latencia de U1 superior a 800 ms de forma sostenida en horas pico, con consultas e índices ya optimizados | Publicaciones (alternativa A) |
| Publicaciones necesita un ciclo de despliegue distinto | Dos o más releases seguidos bloqueados por cambios de otro contexto | Publicaciones |
| Cambia el equipo o el presupuesto | Más de un equipo trabajando en contextos distintos, o se levanta F1 | A evaluar |

## Consecuencias

### Positivas
- Cero modos de fallo de red entre contextos: Publicaciones validando un club sigue siendo una llamada en memoria y, con la base real, una llave foránea.
- Un solo despliegue y un solo pipeline, sin tecnología nueva (cumple C2) y sin costo adicional (cumple F1; el servidor es el de la universidad).
- Transacciones locales de PostgreSQL bastan; no se necesita saga ni consistencia eventual hoy.
- La hexagonal ya aplicada hace que extraer después sea mover un adaptador, no reescribir el dominio.

### Negativas / costos asumidos
- Todo el backend escala junto: un pico de lectura de publicaciones consume los mismos recursos que Clubes.
- Un fallo grave en un contexto puede tumbar el proceso completo; no hay aislamiento de fallos entre contextos.
- Las fronteras dependen de disciplina (reglas 1 y 2), no de una barrera física. Hoy los routers instancian directamente su adaptador (`repository = InMemory...Adapter()` en cada router); cuando se conecte la base real conviene inyectarlo desde un único punto de composición.
- `crear_publicacion` no verifica hoy que el club exista; con la base real lo hará la llave foránea y habrá que traducir ese error a una respuesta controlada.

### Riesgos y qué los dispararía
- **Acoplamiento silencioso entre contextos:** se mitiga revisando en cada Pull Request que no haya imports cruzados entre dominios ni consultas sobre tablas ajenas.
- **Recurso compartido (conexiones a la base):** todos los contextos comparten el pool del backend y el límite de conexiones del contenedor PostgreSQL; se mitiga dimensionando el pool con tiempo de espera máximo y respondiendo 503 controlado cuando se agota (ver `tabla_fallos.md`). La Sección 11 todavía describe el pooler de Supabase y debe actualizarse con el ADR 0007.



## Trazabilidad
- **Escenarios de calidad:** U1 (umbral de 800 ms usado como disparador), U2 (no agregar fallos de red internos), C1 y C2 de [Sección 10](../arc42/10_requisitos_de_calidad.md).
- **Restricciones:** O1, C2 y F1 de [Sección 2](../arc42/02_restricciones.md).
- **Modos de fallo e idempotencia:** [`docs/arc42/tabla_fallos.md`](../arc42/tabla_fallos.md).
- **Decisiones relacionadas:** [ADR 0001](0001-hexagonal.md) (hace posible extraer luego), [ADR 0002](0002-ajuste-contextos-publicaciones.md) (define Publicaciones), [ADR 0003](0003-%20integacion%20rest%20openapi.md) (difiere notificaciones asíncronas), [ADR 0007](0007-migracion-supabase-a-dokploy.md) (base única en Dokploy; reemplaza al ADR 0004 en persistencia y despliegue).
- **Elementos C4 afectados:** contenedor API Backend (no se divide).
- **Código:** `backend/src/linkclub/main.py`, `adapters/inbound/api/publicacion_router.py`, `application/use_cases/crear_publicacion.py`, `domain/publicacion.py`.
- **Esquema:** `backend/migrations/001_esquema_inicial.sql` (llaves foráneas entre contextos).

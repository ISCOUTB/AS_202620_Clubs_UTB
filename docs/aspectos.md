# AS_202620_Clubs_UTB

**LinkClub** - Sistema para la gestión de clubes estudiantiles de la Universidad Tecnológica de Bolívar.

## Problema

En la Universidad Tecnológica de Bolívar existe una gran variedad de clubes abiertos a los estudiantes, pero aún no hay una herramienta destinada a que los grupos se den a conocer y comuniquen sus actividades. Esto afecta a los integrantes de cada club y también a los posibles interesados, para quienes es importante que la información llegue al mayor número de personas posible. El detalle está en la [ficha del problema](ficha_problema.md).

## Tecnologías

- Aplicación móvil: Flutter
- API: FastAPI (Python), arquitectura hexagonal
- Base de datos: PostgreSQL en contenedor
- Autenticación: tokens JWT emitidos por la propia API
- Despliegue: Docker y Dokploy en el servidor del laboratorio ([ADR 0007](adr/0007-migracion-dokploy-postgresql.md))

## Estado del proyecto

En desarrollo, con despliegue operativo en el servidor del laboratorio. Lo implementado y lo pendiente está en la [Sección 11 de arc42](arc42/11_riesgos_y_deuda_tecnica.md) y en la [lista de no conformidades](arc42/lista_errores.md).

## Autores

- Josh Robinson Ortega Castellón, T00082929  
- Luis Daniel Salas Reyes, T00082453
- Diego Andrés Ramos De Ávila, T00083217
- Hollman de Orta González, T00083586

# Aspectos de Calidad y Trazabilidad

Cada fila recorre la cadena aspecto, requisito, elementos C4, ADR, código, pruebas y evidencia. Las pruebas se ejecutan con `cd backend && PYTHONPATH=src pytest tests/ -v`; en la última ejecución local pasaron las 36 pruebas de la suite. Los escenarios citados están en la [Sección 10 de arc42](arc42/10_requisitos_de_calidad.md).

## Aspectos con evidencia

| ID | Aspecto | Requisito | C4 | ADR | Código | Pruebas | Evidencia |
|---|---|---|---|---|---|---|---|
| U2 | Disponibilidad ([escenario U2](arc42/10_requisitos_de_calidad.md#escenarios-de-uso)) | Comprobación de vida y disponibilidad (readiness) del servicio con consulta activa a PostgreSQL (`SELECT 1`) y respuesta controlada `503` ante fallo. | [C4](c4/contexto.md): `health_router`, `CheckHealthUseCase`, `StatusPort`, `PostgresStatusAdapter` | [0001](adr/0001-hexagonal.md), [0007](adr/0007-migracion-dokploy-postgresql.md) | [`health_router.py`](../backend/src/linkclub/adapters/inbound/api/health_router.py), [`check_health.py`](../backend/src/linkclub/application/use_cases/check_health.py), [`postgres_status_adapter.py`](../backend/src/linkclub/adapters/outbound/postgres/postgres_status_adapter.py) | [`test_health.py`](../backend/tests/test_health.py) | Mutación de la semana 9 (`ia.md`) y refactorización de NC-09: `/health` ejecuta `SELECT 1` contra PostgreSQL y responde `503 Service Unavailable` si la base no está disponible (registrado en [`mediciones_calidad.md`](mediciones_calidad.md)). |
| U3 | Seguridad ([escenario U3](arc42/10_requisitos_de_calidad.md#escenarios-de-uso)) | Token válido en el 100% de las rutas de escritura, excepto registro e inicio de sesión; las lecturas son públicas según el contrato. | [C4](c4/contexto.md): `auth_dependency`, `AuthPort`, `LocalJwtAuthAdapter` | [0003](adr/0003-%20integacion%20rest%20openapi.md), [0007](adr/0007-migracion-dokploy-postgresql.md) (reemplaza al [0006](adr/0006-validacion-token-jwt-supabase.md)) | [`auth_dependency.py`](../backend/src/linkclub/adapters/inbound/api/auth_dependency.py), [`local_jwt_adapter.py`](../backend/src/linkclub/adapters/outbound/auth/local_jwt_adapter.py), [`outbound_auth_port.py`](../backend/src/linkclub/application/ports/outbound_auth_port.py) | [`test_auth.py`](../backend/tests/test_auth.py): sin token, token inválido, token válido, lectura pública, autor tomado del token y `test_toda_ruta_de_escritura_exige_auth` | La prueba de cobertura recorre las rutas de escritura y excluye únicamente `/auth/login` y `/auth/registro`. Contraseñas cifradas con `bcrypt` (NC-05 resuelto) y `JWT_SECRET` obligatorio con *fail-fast* al arrancar (NC-11 resuelto). Límite: sin registro de intentos rechazados. |
| C1 | Modificabilidad ([escenario C1](arc42/10_requisitos_de_calidad.md#escenarios-de-cambio)) | Agregar un tipo de publicación modificando como máximo 3 módulos. | [C4](c4/contexto.md): `Publicacion`, `CrearPublicacionUseCase` | [0001](adr/0001-hexagonal.md) | [`publicacion.py`](../backend/src/linkclub/domain/publicacion.py), [`crear_publicacion.py`](../backend/src/linkclub/application/use_cases/crear_publicacion.py) | [`test_publicaciones.py`](../backend/tests/test_publicaciones.py) (aviso, encuesta, noticia), [`test_contrato_openapi.py`](../backend/tests/test_contrato_openapi.py) | Los tipos aviso, encuesta y noticia comparten una sola entidad y un solo caso de uso; el contrato valida la respuesta de cada tipo (2 módulos afectados en [`mediciones_calidad.md`](mediciones_calidad.md)). |
| C3 | Portabilidad ([escenario C3](arc42/10_requisitos_de_calidad.md#escenarios-de-cambio)) | Cambio de proveedor de datos o de autenticación limitado a los adaptadores de salida. | [C4](c4/contexto.md): adaptadores de salida | [0001](adr/0001-hexagonal.md), [0007](adr/0007-migracion-dokploy-postgresql.md) | [`adapters/outbound/postgres/`](../backend/src/linkclub/adapters/outbound/postgres/), [`adapters/outbound/auth/`](../backend/src/linkclub/adapters/outbound/auth/) | [`conftest.py`](../backend/tests/conftest.py) sustituye la base y la autenticación sin tocar los casos de uso | La migración desde Supabase del ADR 0007 se resolvió reemplazando adaptadores con 0 módulos modificados fuera de la capa de adaptadores (ver [`mediciones_calidad.md`](mediciones_calidad.md)). |
| M1 | Mensajería asíncrona de notificaciones ([escenarios U1 y U2](arc42/10_requisitos_de_calidad.md#escenarios-de-uso)) | Notificar publicaciones creadas sin acoplar la latencia de la creación; entrega al menos una vez con consumidor idempotente. | [C4](c4/contexto.md): `NotificarPublicacionCreada`, puertos de mensajería | [0009 de mensajería](adr/0009-mensajeria-asincrona-notificaciones.md) | [`application/messaging/`](../backend/src/linkclub/application/messaging/), [`notificar_publicacion.py`](../backend/src/linkclub/application/use_cases/notificar_publicacion.py), [`adapters/outbound/messaging/`](../backend/src/linkclub/adapters/outbound/messaging/) | [`test_mensajeria.py`](../backend/tests/test_mensajeria.py) (8 pruebas) | Duplicados, reintentos con retroceso, cola de mensajes fallidos, contrato versionado y seguimiento por registro. Límite: broker, outbox y deduplicación en memoria y sin endpoint que los invoque. |

## Aspectos declarados sin evidencia completa

Estos aspectos están definidos y cuentan con mediciones preliminares en [`mediciones_calidad.md`](mediciones_calidad.md), pero requieren cierre de pruebas de integración o automatización completa en el pipeline para defenderse al 100%.

| ID | Aspecto | Qué falta para defenderlo | Dónde se cierra |
|---|---|---|---|
| U1 | Rendimiento ([escenario U1](arc42/10_requisitos_de_calidad.md#escenarios-de-uso)) | Medición preliminar registrada en [`mediciones_calidad.md`](mediciones_calidad.md) (P95 de 131 ms ≤ 800 ms). Falta medir bajo carga concurrente en todos los endpoints de búsqueda y añadir paginación en el feed (NC-23). ADR relacionados: [0005](adr/0005-no-incorporacion-llm.md), [0008](adr/0008-no-extraer-publicaciones.md). | Evidencia S14 |
| C2 | Escalabilidad ([escenario C2](arc42/10_requisitos_de_calidad.md#escenarios-de-cambio)) | Simulación preliminar de 5x volumen documentada en [`mediciones_calidad.md`](mediciones_calidad.md) (< 300 ms). Falta automatizar la prueba de carga en el repositorio. | Evidencia S14 |
| R1 | Resiliencia ante fallos parciales (idempotencia de la creación) | Lógica corregida en código con manejo de `UUID`, aislamiento por autor `(autor_id, idempotency_key)` y respuesta consistente (NC-10 resuelto). Falta incorporar prueba automatizada de integración E2E contra PostgreSQL. | Prueba de integración en `backend/tests/` |
| P1 | Persistencia multimedia | Validación de extensiones (`svg` retirado, NC-12 resuelto) y autenticación (`require_auth`) implementadas en [`recurso_router.py`](../backend/src/linkclub/adapters/inbound/api/recurso_router.py) ([ADR 0009 de multimedia](adr/0009-estrategia-persistencia-multimedia.md)). Falta prueba automatizada de supervivencia tras redespliegue. | Prueba de carga y persistencia de volumen |

## Aspectos por contexto

| Contexto del [mapa](arc42/mapa-contextos-fundamentacion.md) | Filas de aspectos |
|---|---|
| Usuarios | U3 |
| Clubes | U1 (búsqueda) y C2 (crecimiento) |
| Publicaciones | C1, R1, M1 y P1 |
| Transversal a los tres | U2 y C3 |

## Estado de la integración continua

Los workflows de [`backend-tests.yml`](../.github/workflows/backend-tests.yml) y [`contrato.yml`](../.github/workflows/contrato.yml) ejecutan las pruebas y la validación del contrato en cada cambio a `master`. La evidencia automática se enlaza a la columna de evidencia en cuanto exista un run en verde; la causa del fallo previo y su corrección están en NC-19 de la [lista de no conformidades](arc42/lista_errores.md).
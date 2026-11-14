# 9. Decisiones de diseño

Esta sección resume las decisiones arquitectónicas de LinkClub y remite al Registro de Decisiones de Arquitectura (ADR) correspondiente para el detalle completo (contexto, alternativas descartadas y consecuencias). No repite ese contenido: su propósito es dar trazabilidad entre la decisión, la escenario que la motiva y los bloques que la implementan.

| # | Decisión | Estado | Motivada por | ADR | Implementada en |
|---|---|---|---|---|---|
| 1 | Adoptar arquitectura hexagonal (puertos y adaptadores) para el backend | Aceptada | Escenario **U2** y escenarios de cambio **C1** y **C3** ([Sección 10](./10_requisitos_de_calidad.md)) | [`0001-hexagonal.md`](../adr/0001-hexagonal.md) | [Sección 5](./05_vista_de_bloques.md) y `backend/src/linkclub/` |
| 2 | Fusionar Actividades y Notificaciones en el contexto Publicaciones | Aceptada | Regla de dueño único de datos ([Sección 8](./08_conceptos_transversales.md)) | [`0002-ajuste-contextos-publicaciones.md`](../adr/0002-ajuste-contextos-publicaciones.md) | [`tabla_modulo.md`](./tabla_modulo.md) y `domain/publicacion.py` |
| 3 | Integración REST síncrona con contrato OpenAPI verificado en el pipeline | Aceptada | Escenarios **U3** y **C1** | [`0003-integracion REST y OpenAPI`](../adr/0003-%20integacion%20rest%20openapi.md) | [`docs/api/openapi.yaml`](../api/openapi.yaml) y `.github/workflows/contrato.yml` |
| 4 | Usar Supabase como servicio gestionado de base de datos | Reemplazada por la decisión 7 | Escenario **U2**, restricción F1 | [`0004-despliegue-base-de-datos.md`](../adr/0004-despliegue-base-de-datos.md) | Sin implementación vigente |
| 5 | No incorporar un componente generativo (LLM) en el sistema | Aceptada | Escenario **U1** y restricción F1 | [`0005-no-incorporacion-llm.md`](../adr/0005-no-incorporacion-llm.md) | No aplica: decisión de no incorporar |
| 6 | Validar tokens con JWT asimétrico de Supabase (JWKS) | Reemplazada por la decisión 7 | Escenario **U3** | [`0006-validacion-token-jwt-supabase.md`](../adr/0006-validacion-token-jwt-supabase.md) | Sin implementación vigente |
| 7 | Migrar a infraestructura autónoma: PostgreSQL y autenticación JWT propios, desplegados en Dokploy | Aceptada | Deriva arquitectónica detectada en S10, **U2** y restricciones T4, T5, F1 | [`0007-migracion-dokploy-postgresql.md`](../adr/0007-migracion-dokploy-postgresql.md) | `deploy/compose.lab.yaml`, `backend/Dockerfile`, `adapters/outbound/auth/local_jwt_adapter.py`, `adapters/outbound/postgres/`, `backend/migrations/` |
| 8 | No extraer Publicaciones: mantener un único backend desplegable | Propuesta | Escenarios **U1** y **U2**, restricciones C2 y F1 | [`0008-no-extraer-publicaciones.md`](../adr/0008-no-extraer-publicaciones.md) | `backend/src/linkclub/main.py` |
| 9 | Almacenamiento local de archivos multimedia vía volúmenes Docker | Aceptada | Persistencia de imágenes subidas, restricciones F1, C2 y ADR 0007 | [`0009-estrategia-persistencia-multimedia.md`](../adr/0009-estrategia-persistencia-multimedia.md) | `adapters/inbound/api/recurso_router.py`, `main.py` y volumen `linkclub_uploads` ([Sección 7](./07_vista_de_despliegue.md)) |
| 10 | Mensajería asíncrona para notificar publicaciones creadas (al-menos-una-vez con consumidor idempotente) | Propuesta | Escenarios **U1** y **U2**, restricciones C2 y F1 | [`0010-mensajeria-asincrona-notificaciones.md`](../adr/0010-mensajeria-asincrona-notificaciones.md) | `application/messaging/`, `application/use_cases/notificar_publicacion.py`, `adapters/outbound/messaging/` |

## Estado de las decisiones

Los ADR no se editan una vez aceptados: si una decisión cambia, se escribe uno nuevo y el anterior pasa a "reemplazado por". Por esa razón las decisiones 4 y 6 se conservan en la tabla como historial. La decisión 7 las reemplaza en lo relativo a persistencia, autenticación y despliegue.

La idempotencia de la creación de publicaciones no tiene un ADR propio: su diseño está en [`docs/resilience/idempotencia.md`](../resilience/idempotencia.md) y se cita como regla 3 del ADR 0008.

## Decisiones pendientes de registrar

| Tema | Cuándo se registra |
|---|---|
| Autorización por rol dentro de cada club (respuesta 403) | Cuando se implemente el contexto Clubes con membresías |
| Estrategia de respaldo de la base de datos | Junto con la automatización de `pg_dump` y respaldo del volumen ([Sección 11](./11_riesgos_y_deuda_tecnica.md)) |
# Historial de Correcciones y Trazabilidad (S1 - S11)

Este documento recopila las no conformidades y observaciones emitidas por el equipo docente en las diferentes entregas del semestre, detallando la resolución aplicada y su evidencia en el repositorio.

## Resumen de Correcciones

- **S1-S3 (Estructura y Trazabilidad):** Se normalizó la estructura de carpetas a minúsculas (`docs/c4/`, `docs/adr/`), se implementó la tabla de aspectos de 8 columnas en `docs/aspectos.md`, y se enlazó correctamente el ADR-0001.
- **S4-S5 (Corte 1 y Pruebas):** Se configuró el flujo de pruebas automatizadas en GitHub Actions (`backend-tests.yml`) y se estructuró la base del backend en FastAPI.
- **S6-S7 (Contratos y Arquitectura):** Se versionó el contrato OpenAPI (`/docs/api/openapi.yaml`), se ajustó el mapa de contextos según el ADR 0002, y se implementó el control de errores y cierre de sesión seguro en el cliente móvil.
- **S8 (Despliegue y Operabilidad):** Se documentó la vista de despliegue (Arc42 §7), estimaciones de costos en la sección §2, y se configuró la estrategia de infraestructura en la nube bajo el plan gratuito de Supabase y un proveedor de backend.

## Correcciones Recientes (S9 - S11)

### S9-S10 (Corte 2 y Deriva Arquitectónica)
- **Observación Docente:** Se identificó una "deriva arquitectónica" donde el código utilizaba adaptadores en memoria (`InMemoryPublicacionAdapter`) mientras la documentación afirmaba usar Supabase.
  - **Resolución:** Se eliminó por completo la dependencia de Supabase (BaaS) y se migró la arquitectura hacia una base de datos PostgreSQL propia desplegada en Dokploy, alineando el código con la infraestructura real.
- **Observación Docente:** Se reportó que el endpoint `/health` retornaba un valor fijo (200) sin comprobar realmente la disponibilidad de Supabase. 
  - **Resolución:** Con la migración a Dokploy, la arquitectura ya no depende de proveedores de terceros (Supabase) inalcanzables.
- **Observación Docente:** Se identificó que las credenciales de validación de autenticación con token real y el comportamiento sin JWKS estaban pendientes o generaban dudas.
  - **Resolución:** Se erradicó el uso de Supabase Auth, reemplazándolo por un sistema nativo de emisión y validación de JWT firmado directamente por FastAPI y almacenado en PostgreSQL, cumpliendo el estándar OAuth2.
- **Observación Docente:** Los flujos de integración continua (CI) presentaban fallos atribuidos a sintaxis YAML inválida antes de la declaración de los jobs.
  - **Resolución:** Se corrigió la sintaxis estructural del archivo `.github/workflows/backend-tests.yml` para restablecer las ejecuciones exitosas.
- **Observación Docente:** Incumplimiento en la convención de nombres para el archivo del ADR 0003, el cual contenía espacios (`0003- integacion rest openapi.md`) en lugar de kebab-case.
  - **Resolución:** Se renombraron los archivos ADR afectados para cumplir estrictamente con el formato `NNNN-kebab-case.md`.

### S11 (Fallos Parciales, Idempotencia y Extracción)
- **Fallo Parcial y Resiliencia:** Se diseñó e implementó el patrón de Idempotencia en la operación crítica de crear publicaciones (`POST /clubes/{club_id}/publicaciones`) mediante la exigencia de la cabecera `Idempotency-Key`, mitigando la posible duplicación de datos por reintentos ante timeouts de red.
- **Evolución del Contrato:** Se actualizó `openapi.yaml` a la versión 1.3.0, incluyendo los nuevos endpoints locales de autenticación (`/auth/login`, `/auth/registro`), la cabecera de idempotencia y el estado HTTP 409 Conflict.
- **Decisión de Arquitectura:** Se redactó y aprobó el ADR correspondiente a la decisión de **No Extracción**, justificando con criterios técnicos (baja latencia, simplicidad operativa en Dokploy y volumen actual) el mantenimiento del sistema como un monolito modular limpio en lugar de fragmentarlo en microservicios distribuidos.

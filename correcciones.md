# Historial de Correcciones y Trazabilidad (S1 - S8)

Este documento recopila las no conformidades y observaciones emitidas por el equipo docente en las diferentes entregas del semestre, detallando la resolución aplicada y su evidencia en el repositorio.

## Resumen de Correcciones
* **S1-S3 (Estructura y Trazabilidad):** Se normalizó la estructura de carpetas a minúsculas (`docs/c4/`, `docs/adr/`), se implementó la tabla de aspectos de 8 columnas en `docs/aspectos.md`, y se enlazó correctamente el ADR-0001.
* **S4-S5 (Corte 1 y Pruebas):** Se configuró el flujo de pruebas automatizadas en GitHub Actions (`backend-tests.yml`) y se estructuró la base del backend en FastAPI.
* **S6-S7 (Contratos y Arquitectura):** Se versionó el contrato OpenAPI (`/docs/api/openapi.yaml`), se ajustó el mapa de contextos según el ADR 0002, y se implementó el control de errores y cierre de sesión seguro en el cliente móvil.
* **S8 (Despliegue y Operabilidad):** Se documentó la vista de despliegue (Arc42 §7), estimaciones de costos en la sección §2, y se configuró la estrategia de infraestructura en la nube bajo el plan gratuito de Supabase y un proveedor de backend.

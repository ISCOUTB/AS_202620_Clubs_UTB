# 9. Decisiones de diseño

Esta sección resume las decisiones arquitectónicas de LinkClub y remite al Registro de Decisiones de Arquitectura (ADR) correspondiente para el detalle completo (contexto, alternativas descartadas y consecuencias). No repite ese contenido, su propósito es dar trazabilidad entre la decisión, el escenario que la motiva y los bloques que la implementan.

| # | Decisión | Motivada por | ADR | Implementada en |
|---|---|---|---|---|
| 1 | Adoptar arquitectura hexagonal (puertos y adaptadores) para el backend | Escenario **U2**: Disponibilidad ante fallo de conexión con la base de datos (ver [Sección 10](./arc42/10_requisitos_de_calidad.md)) | [`docs/adr/0001-hexagonal.md`](../docs/adr/0001-hexagonal.md) | [Sección 5 — Vista de bloques](./arc42/05_vista_de_bloques.md) |

## Estado de las decisiones

La decisión de estilo arquitectónico (ADR 0001) está **aceptada** y ya se refleja en la estructura de bloques descrita en la Sección 5 (presentación, aplicación, dominio, infraestructura) y en el código del backend.

## Decisiones pendientes de registrar

El equipo aún no ha formalizado cómo se simula el fallo de conexión con la base de datos dentro del corte vertical que ejercita el escenario U2. Cuando esa decisión quede resuelta e implementada, debe documentarse como un nuevo ADR (`0002-*.md`) y agregarse a la tabla anterior, no como una modificación del ADR 0001, que permanece aceptado y sin reescribir.

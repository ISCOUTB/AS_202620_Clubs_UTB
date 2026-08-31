# AS_202620_Clubs_UTB

**LinkClub** - Sistema para la gestión de clubes estudiantiles de la Universidad Tecnológica de Bolívar.

## Problema

En la Universidad Tecnológica de Bolívar, existen gran variedad de clubes abiertos para los estudiantes, sin embargo, aún no existe una herramienta destinada para los grupos donde ellos puedan hacerse ver y ofrecer las maravillosas experiencias. Este problema no solo afecta a los integrantes del club, sino que también a los posibles interesados ya que es de suma importancia que dicho información llegue al mayor numero de personas posible

## Tecnologías

- Framework: Flutter
- Base de datos: PostgreSQL, con Supabase
- API: FastAPI

## Estado del proyecto
En etapa inicial 

## Autores
- Josh Robinson Ortega Castellón, T00082929  
- Luis Daniel Salas Reyes, T00082453
- Diego Andrés Ramos De Ávila, T00083217
- Hollman de Orta González, T00083586
## Aspectos de calidad


| ID | Aspecto de calidad | Escenario | Requisito (resumen) | C4 | ADR | Código | Pruebas |
|---|---|---|---|---|---|---|---|
| U1 | Rendimiento | [Escenario de uso U1](arc42/10_requisitos_de_calidad.md#escenarios-de-uso) | Latencia ≤ 800 ms en el camino crítico de búsqueda (red + FastAPI + Supabase) | [C4 — contexto y contenedores](c4/contexto.md) | — (pendiente; módulo de búsqueda aún no diseñado) | Pendiente | Pendiente |
| U2 | Disponibilidad | [Escenario de uso U2](arc42/10_requisitos_de_calidad.md#escenarios-de-uso) | Manejo explícito de errores de conexión a BD en el 100% de los endpoints, sin excepciones no controladas | [C4 — contexto y contenedores](c4/contexto.md) | [0001-hexagonal](adr/0001-hexagonal.md) — la separación de puertos/adaptadores aísla los fallos del proveedor externo | `backend/src/linkclub/adapters/inbound/api/health_router.py`, `application/use_cases/check_health.py`, `adapters/outbound/persistence/in_memory_status_adapter.py` | `backend/tests/test_health.py` |
| U3 | Seguridad | [Escenario de uso U3](arc42/10_requisitos_de_calidad.md#escenarios-de-uso) | Validación de token en el 100% de los endpoints protegidos | [C4 — contexto y contenedores](c4/contexto.md) | — (pendiente; depende de qué proveedor de auth se confirme, restricción T4) | Pendiente | Pendiente |
| C1 | Modificabilidad | [Escenario de cambio C1](arc42/10_requisitos_de_calidad.md#escenarios-de-cambio) | Agregar un nuevo tipo de publicación modificando ≤ 3 módulos, sin afectar auth/clubes/eventos | [C4 — contexto y contenedores](c4/contexto.md) | [0001-hexagonal](adr/0001-hexagonal.md) — la arquitectura hexagonal es la decisión que habilita este escenario | Pendiente | Pendiente |
| C2 | Escalabilidad | [Escenario de cambio C2](arc42/10_requisitos_de_calidad.md#escenarios-de-cambio) | Soportar crecimiento de hasta 5x en clubes/eventos sin cambios estructurales en el esquema de datos | [C4 — contexto y contenedores](c4/contexto.md) | — (pendiente; ligado a la decisión final de proveedor de BD, restricción T4) | Pendiente | Pendiente |
| C3 | Portabilidad | [Escenario de cambio C3](arc42/10_requisitos_de_calidad.md#escenarios-de-cambio) | Cambio de proveedor de BD/auth limitado al módulo de acceso a datos; ≤ 2 módulos fuera de esa capa | [C4 — contexto y contenedores](c4/contexto.md) | [0001-hexagonal](adr/0001-hexagonal.md) — motiva explícitamente este escenario (ver [Contexto](adr/0001-hexagonal.md#contexto)) | Pendiente | Pendiente |
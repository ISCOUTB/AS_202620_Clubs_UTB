# AS_202620_Clubs_UTB

**LinkClub** - Sistema para la gestión de clubes estudiantiles de la Universidad Tecnológica de Bolívar.

## Problema

En la Universidad Tecnológica de Bolívar, existen gran variedad de clubes abiertos para los estudiantes, sin embargo, aún no existe una herramienta destinada para los grupos donde ellos puedan hacerse ver y ofrecer las maravillosas experiencias. Este problema no solo afecta a los integrantes del club, sino que también a los posibles interesados ya que es de suma importancia que dicho información llegue al mayor numero de personas posible

## Tecnologías

- Framework: Flutter
- Base de datos: Supabase, con PostgreSQL
- API: FastAPI

## Estado del proyecto
En etapa de desarrollo bajo arquitectura 

## Autores
- Josh Robinson Ortega Castellón, T00082929  
- Luis Daniel Salas Reyes, T00082453
- Diego Andrés Ramos De Ávila, T00083217
- Hollman de Orta González, T00083586
## Aspectos de calidad


# Aspectos de Calidad y Trazabilidad

| ID | Aspecto de calidad | Escenario Relacionado | Requisito (Decisión/Táctica) | Componente C4 | ADR Relacionado | Archivo de Código | Pruebas y Evidencia |
|---|---|---|---|---|---|---|---|
| U1 | Rendimiento | [Escenario U1](arc42/10_requisitos_de_calidad.md#escenarios-de-uso) | Latencia ≤ 800 ms en el camino crítico de búsqueda. | [C4 - Contexto](c4/contexto.md) | Pendiente | Pendiente | Pendiente |
| U2 | Disponibilidad | [Escenario U2](arc42/10_requisitos_de_calidad.md#escenarios-de-uso) | Manejo de errores de conexión y Health Check activo. | [C4 - Contexto](c4/contexto.md) | [0001-hexagonal](adr/0001-hexagonal.md) y [0004-supabase](adr/0004-supabase.md) | `health_router.py`, `check_health.py` | `test_health.py`. *Mutación S9:* Se alteró el status a "caido_por_error" y la prueba falló (`AssertionError`), demostrando cobertura real. |
| U3 | Seguridad | [Escenario U3](arc42/10_requisitos_de_calidad.md#escenarios-de-uso) | Validación de token en el 100% de los endpoints protegidos. | [C4 - Contexto](c4/contexto.md) | [0004-supabase](adr/0004-supabase.md) | Pendiente | Pendiente |
| C1 | Modificabilidad | [Escenario C1](arc42/10_requisitos_de_calidad.md#escenarios-de-cambio) | Agregar nuevo tipo de publicación afectando ≤ 3 módulos. | [C4 - Contexto](c4/contexto.md) | [0001-hexagonal](adr/0001-hexagonal.md) | Pendiente | Pendiente |
| C2 | Portabilidad | [Escenario C3](arc42/10_requisitos_de_calidad.md#escenarios-de-cambio) | Cambio de proveedor de BD limitado al adaptador de salida. | [C4 - Contexto](c4/contexto.md) | [0001-hexagonal](adr/0001-hexagonal.md) | Pendiente | Pendiente |

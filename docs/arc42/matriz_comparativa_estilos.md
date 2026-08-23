# Matriz Comparativa de Estilos Arquitectónicos

Comparación de los tres estilos contra los escenarios de calidad ya definidos (Sección 10), respaldando  [`docs/adr/0001-hexagonal.md`](../adr/0001-hexagonal.md).

| Escenario | Atributo | Por capas | Monolito | Hexagonal |
|---|---|---|---|---|
| **U1** — Latencia ≤800ms en búsqueda de eventos/clubes | Rendimiento | Alta — acceso directo sin capas de indirección extra | Alta — misma razón | Media — la indirección de puertos añade una capa, aunque el objetivo de 800ms sigue siendo alcanzable |
| **U2** — Manejo controlado de fallo de conexión a BD, 100% de endpoints | Disponibilidad | Media — el manejo de errores suele mezclarse con la lógica de negocio, dificultando aplicarlo de forma consistente | Media — mejor organizado por módulos, pero el dominio sigue acoplado al proveedor de datos | **Alta** — el puerto de persistencia aísla el dominio, permitiendo centralizar timeout/reintento en un solo adaptador para todos los endpoints |
| **U3** — Validación de token en 100% de endpoints protegidos | Seguridad | Media — el control de acceso no está centralizado, cada capa podría manejarlo a su manera" | Media | **Alta** — la autenticación se implementa como adaptador de entrada, separado del dominio y fácil de verificar por revisión de código |
| **C1** — Nuevo tipo de publicación en ≤3 módulos | Modificabilidad | Media — agregar un tipo nuevo puede tocar varias capas transversales | Alta — los módulos ya separan por responsabilidad | **Alta** — el nuevo caso de uso se agrega en la capa de aplicación sin tocar infraestructura ni otros dominios |
| **C2** — Crecimiento 5x sin cambios estructurales en el esquema | Escalabilidad | Media | Media-Alta | Media-Alta — el aislamiento del dominio no afecta directamente el esquema de datos, pero tampoco lo mejora por sí solo |
| **C3** — Cambio de proveedor de BD en ≤2 módulos fuera de la capa de acceso a datos | Portabilidad | Baja — el acceso a datos suele estar disperso entre varias capas | Media — mejor encapsulado que capas simples | **Alta** — el puerto de persistencia es el único punto de contacto con el proveedor externo; cambiarlo no toca el dominio |

## Conclusión

Hexagonal responde directamente a la meta de disponibilidad que motivó su elección (Sección 4.2), y además resulta la opción más favorable en los escenarios de seguridad (U3) y portabilidad (C3), según el análisis anterior.

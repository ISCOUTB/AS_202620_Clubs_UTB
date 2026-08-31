# 4. Estrategia de Solución
 
## 4.1. Decisiones tecnológicas

Siguiendo las restricciones técnicas declaradas en la Sección 2 (T1-T4), el sistema se construye con:
 
- **Frontend / app móvil:** Flutter
- **Backend / API:** FastAPI (Python)
- **Persistencia:** PostgreSQL, por medio de Supabase


## 4.2. Decisión de estilo arquitectónico
 
El backend adopta el estilo **hexagonal (puertos y adaptadores)**, separando dominio, aplicación, infraestructura y presentación. Esta decisión responde a la meta de calidad de disponibilidad (Sección 1) y a la restricción T4: mientras la elección final de base de datos gestionada sigue abierta, el dominio de la aplicación puede desarrollarse y probarse sin depender de ella.
 
La comparación completa frente a las alternativas descartadas (capas, monolito modular) está documentada en [`docs/arc42/matriz_comparativa_estilos.md`](./matriz_comparativa_estilos.md), y la decisión formal con sus consecuencias en [`docs/adr/0001-hexagonal.md`](../adr/0001-hexagonal.md).

## 4.3. Enfoques para alcanzar las metas de calidad
 
| Meta de calidad (Sección 1) | Enfoque en esta estrategia |
|---|---|
| Disponibilidad | Aislamiento del dominio respecto a la infraestructura vía puertos; permite introducir tácticas como timeout y reintento en los adaptadores sin afectar la lógica de negocio |
| Rendimiento | Se evaluará en fases posteriores mediante tácticas como caché e índices sobre el adaptador de persistencia, sin comprometer el aislamiento del dominio |
| Usabilidad | No condicionada por esta decisión de backend; se aborda en el diseño de la app Flutter, fuera del alcance de esta sección |
| Mantenibilidad | La separación por responsabilidad (dominio / aplicación / infraestructura / presentación) permite que, por ejemplo, futuros integrantes del equipo ubiquen y modifiquen código sin conocimiento tácito del diseño original |

## 4.4. Alcance de esta entrega
 
Esta sección documenta la decisión de estilo y su justificación. La implementación se limita, por ahora, al esqueleto ejecutable descrito en el README (estructura de paquetes vacíos según el estilo elegido, sin lógica de negocio), en línea con lo pedido para esta entrega.

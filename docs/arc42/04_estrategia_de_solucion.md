# 4. Estrategia de Solución

## 4.1. Decisiones tecnológicas

Siguiendo las restricciones técnicas declaradas en la [Sección 2](./02_restricciones.md) (T1-T5), el sistema se construye con:

| Elemento | Tecnología | Decisión de referencia |
|---|---|---|
| Frontend / app móvil | Flutter (Dart), con Dio para HTTP y almacenamiento seguro del token | T1 |
| Backend / API | FastAPI (Python) con arquitectura hexagonal | T2, [ADR 0001](../adr/0001-hexagonal.md) |
| Persistencia | PostgreSQL en contenedor, acceso con SQLAlchemy; esquema en `backend/migrations/` | T3, T4, [ADR 0007](../adr/0007-migracion-dokploy-postgresql.md) |
| Autenticación | JWT firmado emitido y validado por la propia API | T4, [ADR 0007](../adr/0007-migracion-dokploy-postgresql.md) |
| Integración | API REST síncrona con contrato OpenAPI verificado en el pipeline | [ADR 0003](../adr/0003-%20integacion%20rest%20openapi.md) |
| Despliegue | Contenedores Docker en el servidor del laboratorio con Dokploy | T5, [ADR 0007](../adr/0007-migracion-dokploy-postgresql.md) |
| Integración continua | GitHub Actions y SonarCloud | [Sección 7](./07_vista_de_despliegue.md) |

## 4.2. Decisión de estilo arquitectónico

El backend adopta el estilo **hexagonal (puertos y adaptadores)**, separando dominio, aplicación y adaptadores de entrada y de salida. Esta decisión responde a la meta de calidad de disponibilidad (Sección 1) y a la necesidad de cambiar la infraestructura sin reescribir la lógica de negocio. Esa capacidad ya se ejerció en la práctica: el reemplazo de Supabase por PostgreSQL y autenticación propia (ADR 0007) se resolvió sustituyendo adaptadores.

La comparación completa frente a las alternativas descartadas (capas, monolito modular) está documentada en [`docs/arc42/matriz_comparativa_estilos.md`](./matriz_comparativa_estilos.md), y la decisión formal con sus consecuencias en [`docs/adr/0001-hexagonal.md`](../adr/0001-hexagonal.md). Se mantiene un único backend desplegable con contextos aislados ([ADR 0008](../adr/0008-no-extraer-publicaciones.md)).

El estilo se aplica completo en los casos de uso de salud, clubes y publicaciones. Algunos adaptadores de entrada aún acceden directamente a la sesión de base de datos o al sistema de archivos sin pasar por un puerto; esas desviaciones están detalladas en el [diagrama de componentes](../c4/contexto.md) y se tratan como deuda técnica.

## 4.3. Enfoques para alcanzar las metas de calidad

| Meta de calidad | Enfoque en esta estrategia |
|---|---|
| Disponibilidad | Aislamiento del dominio respecto a la infraestructura vía puertos. Idempotencia en la creación de publicaciones mediante la cabecera `Idempotency-Key`, para que un reintento tras un fallo parcial no duplique datos. Mensajes de error controlados en el cliente ante fallos de red. Previsto: comprobación real de la base en `/health`, tiempos de espera y respaldo periódico. |
| Rendimiento | Base de datos y API en la misma red interna del servidor. Índices por club y fecha definidos en la migración inicial. La estrategia de caché y su política de invalidación se definen en la [Sección 8](./08_conceptos_transversales.md). La latencia aún no se ha medido. |
| Seguridad (escenario U3, [Sección 10](./10_requisitos_de_calidad.md)) | Token JWT exigido por una dependencia de autenticación en las rutas de escritura, con la identidad del autor tomada siempre del token. Comunicación por HTTPS. Lecturas públicas según el contrato. |
| Usabilidad | No condicionada por esta decisión de backend; se aborda en el diseño de la app Flutter, fuera del alcance de esta sección. |
| Mantenibilidad | Separación por responsabilidad (dominio, aplicación, adaptadores). Contrato OpenAPI comprobado en cada Pull Request, pruebas automatizadas con pytest y análisis estático en SonarCloud. |

## 4.4. Estado de aplicación de la estrategia

| Aspecto | Estado |
|---|---|
| Arquitectura hexagonal | Aplicada en salud, clubes y publicaciones. Desviaciones declaradas en autenticación, carga de imágenes y listados de publicaciones. |
| Persistencia en PostgreSQL | Operativa para usuarios y publicaciones. El catálogo de clubes se sirve aún desde un adaptador en memoria. |
| Autenticación propia | Operativa: registro, inicio de sesión y validación de token. Pendientes: protección de contraseñas con hash y autorización por rol dentro de cada club. |
| Contrato OpenAPI | Verificado en el pipeline. Algunas rutas del contrato aún no están implementadas (membresías, eventos, asistencia). |
| Despliegue | Operativo en Dokploy con dominio HTTPS. |
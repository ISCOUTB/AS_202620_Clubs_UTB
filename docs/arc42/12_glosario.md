# 12. Glosario

| Término | Definición |
|---|---|
| Adaptador | Implementación concreta de un puerto, conecta el sistema con una tecnología específica (ej. una base de datos real o una en memoria). |
| Adaptador temporal | Adaptador en memoria que sustituye provisionalmente a uno real (ej. catálogo de clubes en memoria) y que está marcado como pendiente de reemplazo. |
| ADR (Architecture Decision Record) | Registro formal de una decisión arquitectónica, con su contexto, alternativas descartadas y consecuencias asumidas. No se edita una vez aceptado; si la decisión cambia se escribe uno nuevo. |
| arc42 | Plantilla de documentación de arquitectura de software usada como marco de referencia para todo el repositorio de LinkClub. |
| Arquitectura hexagonal | Estilo arquitectónico que aísla el dominio y la lógica de negocio de la infraestructura, comunicándose únicamente a través de puertos y adaptadores. Estilo elegido para LinkClub ([ADR 0001](../adr/0001-hexagonal.md)). |
| Arquitectura por capas (N-tier) | Estilo alternativo evaluado y descartado para LinkClub; organiza el sistema en capas técnicas (presentación, lógica, datos) sin aislar explícitamente el dominio de la infraestructura. |
| At-least-once (al menos una vez) | Garantía de entrega de mensajes en la que un mensaje puede llegar más de una vez; obliga a que el consumidor sea idempotente. |
| Atributo de calidad | Característica del sistema evaluada en un escenario o en la matriz comparativa de estilos (ej. Rendimiento, Seguridad, Escalabilidad). No todo atributo evaluado corresponde necesariamente a una meta declarada en la Sección 1. |
| BaaS (Backend as a Service) | Servicio gestionado que ofrece base de datos y autenticación como producto. LinkClub evaluó uno (Supabase) y lo descartó ([ADR 0007](../adr/0007-migracion-dokploy-postgresql.md)). |
| C4 | Modelo de diagramación de arquitectura por niveles de zoom, usado en LinkClub para los diagramas de contexto (nivel 1), contenedores (nivel 2) y componentes (nivel 3). |
| Caché | Copia temporal de datos para responder más rápido sin consultar la fuente original; exige una política de invalidación. |
| Caso de uso | Componente de la capa de aplicación que coordina una operación del sistema, usando los puertos disponibles sin conocer sus adaptadores concretos. |
| Consistencia eventual | Garantía en la que los datos pueden diferir temporalmente entre dos puntos del sistema pero convergen si no hay nuevas escrituras. |
| Contexto delimitado | Frontera dentro de la cual un término y un dato tienen un significado y un dueño únicos. LinkClub tiene tres: Usuarios, Clubes y Publicaciones. |
| Contrato de API | Descripción formal de la interfaz REST en `docs/api/openapi.yaml`, verificada automáticamente en el pipeline. |
| Corte vertical | Implementación mínima que atraviesa todas las capas del sistema (UI → lógica → persistencia) para un caso de uso específico, demostrando que la arquitectura documentada es ejecutable. |
| Deriva arquitectónica | Divergencia entre lo que la documentación afirma y lo que hace el código. Se registra y se corrige como parte de la deuda técnica. |
| Diagrama de componentes | Nivel 3 de C4: abre un contenedor en sus piezas internas y sus responsabilidades. |
| Diagrama de contenedores | Nivel 2 de C4: abre el sistema en sus piezas desplegables por separado (ej. app Flutter, API FastAPI, base de datos PostgreSQL), cada una con su tecnología. |
| Diagrama de contexto | Nivel 1 de C4: muestra el sistema como una caja única junto a sus usuarios y sistemas externos, sin exponer su estructura interna. |
| Docker | Tecnología de contenedores con la que se empaqueta y ejecuta el backend y la base de datos. |
| Dokploy | Plataforma de despliegue del servidor del laboratorio sobre la que se ejecutan los contenedores de LinkClub. |
| Dueño único | Regla según la cual cada dato pertenece a un solo contexto; los demás lo referencian por identidad sin copiarlo. |
| Escenario de calidad | Instancia concreta y medible de un atributo de calidad, con sus seis partes: fuente, estímulo, artefacto, entorno, respuesta y medida. |
| FastAPI | Framework usado para el backend / API de LinkClub (restricción T2). |
| Flutter | Framework usado para el frontend / app móvil de LinkClub (restricción T1). |
| Idempotencia | Propiedad de una operación que produce el mismo efecto aunque se repita. En LinkClub se logra con la cabecera `Idempotency-Key` en la creación de publicaciones. |
| Indirección | Capa adicional de comunicación entre componentes (ej. a través de un puerto) que se introduce para ganar flexibilidad, a costa de mayor complejidad de lectura del código. |
| Invalidación de caché | Regla que decide cuándo una copia en caché deja de ser válida y debe refrescarse. |
| JWT (JSON Web Token) | Token firmado que la API emite al iniciar sesión y exige en las operaciones de escritura. |
| Mermaid | Lenguaje de diagramas como texto usado para los diagramas C4 y el árbol de utilidad, permitiendo versionarlos junto al código y revisarlos en el PR. |
| Meta de calidad | Objetivo de calidad priorizado y declarado en la Sección 1 de arc42 (Disponibilidad, Rendimiento, Usabilidad, Mantenibilidad para LinkClub), sin una medida asociada todavía. |
| Monolito modular | Estilo alternativo evaluado y descartado para LinkClub; divide el sistema por módulos de dominio, pero sin el mismo aislamiento de persistencia que ofrece hexagonal. |
| OpenAPI | Estándar de descripción de APIs REST usado para el contrato de LinkClub. |
| Outbox | Patrón que registra un mensaje en un almacén local antes de enviarlo, para reenviarlo si el broker no está disponible. |
| PostgreSQL | Motor de base de datos relacional elegido para la persistencia de LinkClub (restricción T3), ejecutado en un contenedor propio. |
| Puerto | Interfaz que define un contrato de comunicación entre la capa de aplicación y el mundo exterior (BD, servicios externos), sin conocer su implementación concreta. |
| pytest | Framework de pruebas usado para las pruebas automatizadas del backend (ej. `test_health.py`). |
| Restricción | Decisión o limitación externa al diseño (técnica, organizacional o de tiempo) que reduce el espacio de opciones arquitectónicas disponibles (Sección 2). |
| SQLAlchemy | Biblioteca de acceso a datos que usa el adaptador de persistencia del backend. |
| Sistema externo | En un diagrama C4, un sistema fuera del control del equipo con el que LinkClub se comunica (ej. el repositorio en GitHub o los sitios que alojan imágenes referenciadas por URL). |
| Supabase | Plataforma BaaS evaluada al inicio del proyecto y descartada en el [ADR 0007](../adr/0007-migracion-dokploy-postgresql.md). Aparece solo como historial en los ADR 0004 y 0006. |
| Tensión de calidad | Conflicto entre dos metas de calidad donde mejorar una implica sacrificar parcialmente la otra (ej. Disponibilidad vs. Rendimiento en LinkClub). |
| uvicorn | Servidor usado para ejecutar la API de FastAPI de LinkClub (ver comando de arranque en el README). |
| Vista de bloques de construcción | Sección de arc42 que describe cómo está dividido internamente el sistema y la responsabilidad de cada componente (Sección 5). |
| Vista de ejecución | Sección de arc42 que documenta, paso a paso, cómo se comporta el sistema al ejecutar un escenario concreto (Sección 6). |
| Volumen Docker | Almacenamiento persistente asociado a un contenedor; conserva los datos entre redespliegues (imágenes subidas y datos de la base). |
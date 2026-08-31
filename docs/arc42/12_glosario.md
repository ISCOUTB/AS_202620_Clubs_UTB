# 12. Glosario

| Término | Definición |
|---|---|
| Adaptador | Implementación concreta de un puerto, conecta el sistema con una tecnología específica (ej. una base de datos real o una en memoria). |
| ADR (Architecture Decision Record) | Registro formal de una decisión arquitectónica, con su contexto, alternativas descartadas y consecuencias asumidas. |
| arc42 | Plantilla de documentación de arquitectura de software usada como marco de referencia para todo el repositorio de LinkClub. |
| Arquitectura hexagonal | Estilo arquitectónico que aísla el dominio y la lógica de negocio de la infraestructura, comunicándose únicamente a través de puertos y adaptadores. Estilo elegido para LinkClub ([ADR 0001](../docs/adr/)). |
| Arquitectura por capas (N-tier) | Estilo alternativo evaluado y descartado para LinkClub; organiza el sistema en capas técnicas (presentación, lógica, datos) sin aislar explícitamente el dominio de la infraestructura. |
| Atributo de calidad | Característica del sistema evaluada en un escenario o en la matriz comparativa de estilos (ej. Rendimiento, Seguridad, Escalabilidad). No todo atributo evaluado corresponde necesariamente a una meta declarada en la Sección 1. |
| C4 | Modelo de diagramación de arquitectura por niveles de zoom, usado en LinkClub para el diagrama de contexto (nivel 1) y de contenedores (nivel 2). |
| Caso de uso | Componente de la capa de aplicación que coordina una operación del sistema, usando los puertos disponibles sin conocer sus adaptadores concretos. |
| Corte vertical | Implementación mínima que atraviesa todas las capas del sistema (UI → lógica → persistencia) para un caso de uso específico, demostrando que la arquitectura documentada es ejecutable. |
| Diagrama de contenedores | Nivel 2 de C4: abre el sistema en sus piezas desplegables por separado (ej. app Flutter, API FastAPI, base de datos Supabase), cada una con su tecnología. |
| Diagrama de contexto | Nivel 1 de C4: muestra el sistema como una caja única junto a sus usuarios y sistemas externos, sin exponer su estructura interna. |
| Escenario de calidad | Instancia concreta y medible de un atributo de calidad, con sus seis partes: fuente, estímulo, artefacto, entorno, respuesta y medida. |
| FastAPI | Framework usado para el backend / API de LinkClub (restricción T2). |
| Flutter | Framework usado para el frontend / app móvil de LinkClub (restricción T1). |
| Indirección | Capa adicional de comunicación entre componentes (ej. a través de un puerto) que se introduce para ganar flexibilidad, a costa de mayor complejidad de lectura del código. |
| Mermaid | Lenguaje de diagramas como texto usado para los diagramas C4 y el árbol de utilidad, permitiendo versionarlos junto al código y revisarlos en el PR. |
| Meta de calidad | Objetivo de calidad priorizado y declarado en la Sección 1 de arc42 (Disponibilidad, Rendimiento, Usabilidad, Mantenibilidad para LinkClub), sin una medida asociada todavía. |
| Monolito modular | Estilo alternativo evaluado y descartado para LinkClub; divide el sistema por módulos de dominio, pero sin el mismo aislamiento de persistencia que ofrece hexagonal. |
| PostgreSQL | Motor de base de datos elegido para la persistencia de LinkClub (restricción T3). |
| Puerto | Interfaz que define un contrato de comunicación entre la capa de aplicación y el mundo exterior (BD, servicios externos), sin conocer su implementación concreta. |
| pytest | Framework de pruebas usado para las pruebas automatizadas del backend (ej. `test_health.py`). |
| Restricción | Decisión o limitación externa al diseño (técnica, organizacional o de tiempo) que reduce el espacio de opciones arquitectónicas disponibles (Sección 2). |
| Sistema externo | En un diagrama C4, un sistema fuera del control del equipo con el que LinkClub se comunica (ej. el proveedor de autenticación). |
| Supabase | Plataforma de base de datos gestionada y autenticación, en evaluación como implementación de persistencia (restricción T4, aún abierta). |
| Tensión de calidad | Conflicto entre dos metas de calidad donde mejorar una implica sacrificar parcialmente la otra (ej. Disponibilidad vs. Rendimiento en LinkClub). |
| uvicorn | Servidor usado para ejecutar la API de FastAPI de LinkClub en desarrollo (ver comando de arranque en el README). |
| Vista de bloques de construcción | Sección de arc42 que describe cómo está dividido internamente el sistema y la responsabilidad de cada componente (Sección 5). |
| Vista de ejecución | Sección de arc42 que documenta, paso a paso, cómo se comporta el sistema al ejecutar un escenario concreto (Sección 6). |

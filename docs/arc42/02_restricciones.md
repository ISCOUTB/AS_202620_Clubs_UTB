# 2. Restricciones

Las siguientes restricciones limitan el espacio de decisiones de arquitectura disponible para **LinkClub**. Se agrupan por origen: técnicas, organizacionales, de tiempo y financieras, además de las convenciones de documentación.

## 2.1. Restricciones técnicas

| # | Restricción | Justificación |
|---|---|---|
| T1 | El frontend/app móvil debe implementarse en **Flutter**. | Es requisito del curso y continuidad directa de la materia de desarrollo móvil inmediatamente anterior, donde el equipo ya adquirió experiencia práctica con el framework. |
| T2 | El backend debe implementarse como una **API con FastAPI**. | Mismo motivo que T1: continuidad con la experiencia previa del equipo, lo que reduce la curva de aprendizaje dentro del tiempo limitado del curso. |
| T3 | La persistencia de datos debe basarse en **PostgreSQL**. | Ya declarado como decisión en los [aspectos de calidad](../aspectos.md); es la base de datos con la que el equipo tiene experiencia previa. |
| T4 | La persistencia y la autenticación son **propias del sistema**: PostgreSQL en contenedor y tokens JWT emitidos por la API, sin proveedor BaaS externo. | Reemplaza la restricción original, que fijaba Supabase. Se descartó por la deriva detectada entre documentación y código, la latencia de red hacia un tercero y el riesgo de límites de capa gratuita (ver [ADR 0007](../adr/0007-migracion-dokploy-postgresql.md)). |
| T5 | El backend y la base de datos se despliegan como **contenedores Docker en el servidor del laboratorio, administrado con Dokploy**, y deben ser accesibles por una URL pública con HTTPS. | El curso exige una URL pública para la sustentación y el servidor del laboratorio es la alternativa sin tarjeta de crédito (F2). Ver [Sección 7](./07_vista_de_despliegue.md) y [ADR 0007](../adr/0007-migracion-dokploy-postgresql.md). |

## 2.2. Restricciones organizacionales

| # | Restricción | Justificación |
|---|---|---|
| O1 | El equipo de desarrollo está compuesto por **4 integrantes**. | Limita la cantidad de trabajo paralelo posible y obliga a una arquitectura con módulos claramente separables para permitir división de tareas sin bloqueos entre integrantes. |
| O2 | La documentación de arquitectura debe **corresponder con el código del commit evaluado** en cada entrega. | El proyecto avanza por entregas calificadas sobre el repositorio; cuando documentación y código divergen, se registra la deriva y se corrige (ver [Sección 11](./11_riesgos_y_deuda_tecnica.md)). Esta restricción reemplaza a la original, que condicionaba el inicio del desarrollo a la autorización del docente y quedó superada. |
| O3 | El proyecto se desarrolla bajo la organización de GitHub **ISCOUTB**, en el repositorio **AS_202620_Clubs_UTB**, con una convención de nombre de repositorio fija impuesta por el curso. | El nombre del repositorio no responde a decisiones de producto (de ahí que el nombre comercial de la app, **LinkClub**, sea independiente del nombre del repositorio). |

## 2.3. Restricciones de tiempo

| # | Restricción | Justificación |
|---|---|---|
| C1 | El proyecto debe avanzar por **entregas incrementales calificadas**, cada una usada como línea base para la siguiente ("reto de corte"). | Obliga a que cada entrega sea autocontenida y coherente con el repositorio en el momento de la evaluación, en lugar de dejar decisiones de arquitectura a medio documentar entre cortes. |
| C2 | El cronograma del curso **no contempla tiempo para adoptar tecnologías nuevas fuera de las ya conocidas por el equipo** (Flutter, FastAPI, PostgreSQL). | Justifica directamente las restricciones técnicas T1-T3: la prioridad es entregar dentro del tiempo del semestre, no explorar el stack óptimo en abstracto. |

## 2.4. Restricciones financieras

| # | Restricción | Justificación |
|---|---|---|
| F1 | **Costo Cero Mensual:** El sistema debe operar en producción a un costo de $0 mensuales. | Condición del proyecto académico, no se cuenta con presupuesto para infraestructura en la nube. |
| F2 | **Sin tarjeta de crédito obligatoria:** Al menos una alternativa de despliegue para cualquier pieza del sistema debe ser realizable sin registrar una tarjeta de crédito personal. | Requisito explícito de las rúbricas de evaluación del curso para evitar riesgos financieros del equipo. |

## 2.5. Convenciones

| # | Convención | Justificación |
|---|---|---|
| CV1 | Toda la documentación de arquitectura se organiza bajo [`/docs/arc42/`](./), [`/docs/c4/`](../c4/) y [`/docs/adr/`](../adr/), siguiendo la plantilla arc42 académica entregada en el curso. | Para mantener consistencia con lo ya montado en las entregas previas y con lo que el docente espera encontrar al evaluar la correspondencia entre documentación y repositorio. |

## 2.6. Historial de cambios

| Fecha | Cambio |
|---|---|
| 2026-10-25 | T4 reemplazada (de Supabase a persistencia y autenticación propias). Se agrega T5. O2 reformulada. Se actualiza la introducción. |
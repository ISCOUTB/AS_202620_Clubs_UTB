# 2. Restricciones

Las siguientes restricciones limitan el espacio de decisiones de arquitectura disponible para **LinkClub**. Se agrupan por origen: técnicas, organizacionales y de tiempo.

## 2.1 Restricciones técnicas

| # | Restricción | Justificación |
|---|---|---|
| T1 | El frontend/app móvil debe implementarse en **Flutter**. | Es requisito del curso y continuidad directa de la materia de desarrollo móvil inmediatamente anterior, donde el equipo ya adquirió experiencia práctica con el framework. |
| T2 | El backend debe implementarse como una **API con FastAPI**. | Mismo motivo que T1: continuidad con la experiencia previa del equipo, lo que reduce la curva de aprendizaje dentro del tiempo limitado del curso. |
| T3 | La persistencia de datos debe basarse en **PostgreSQL**. | Ya declarado como decisión en los [aspectos de calidad](../aspectos.md); es la base de datos con la que el equipo tiene experiencia previa. |
| T4 | La solución de base de datos gestionada y autenticación está **aún en evaluación entre Supabase u otra alternativa compatible con PostgreSQL**. | El equipo tiene experiencia previa con Supabase, pero no tiene aún claridad sobre la plataforma que se deba usar finalmente. |

## 2.2 Restricciones organizacionales

| # | Restricción | Justificación |
|---|---|---|
| O1 | El equipo de desarrollo está compuesto por **4 integrantes**. | Limita la cantidad de trabajo paralelo posible y obliga a una arquitectura con módulos claramente separables para permitir división de tareas sin bloqueos entre integrantes. |
| O2 | El desarrollo de código **no puede iniciar formalmente hasta recibir autorización del docente del curso**. | El proyecto se encuentra en fase de planeación por instrucción explícita de la materia; toda esta entrega corresponde a documentación de arquitectura, no a implementación. |
| O3 | El proyecto se desarrolla bajo la organización de GitHub **ISCOUTB**, en el repositorio **AS_202620_Clubs_UTB**, con una convención de nombre de repositorio fija impuesta por el curso. | El nombre del repositorio no responde a decisiones de producto (de ahí que el nombre comercial de la app, **LinkClub**, sea independiente del nombre del repositorio). |

## 2.3 Restricciones de tiempo

| # | Restricción | Justificación |
|---|---|---|
| C1 | El proyecto debe avanzar por **entregas incrementales calificadas**, cada una usada como línea base para la siguiente ("reto de corte"). | Obliga a que cada entrega sea autocontenida y coherente con el repositorio en el momento de la evaluación, en lugar de dejar decisiones de arquitectura a medio documentar entre cortes. |
| C2 | El cronograma del curso **no contempla tiempo para adoptar tecnologías nuevas fuera de las ya conocidas por el equipo** (Flutter, FastAPI, PostgreSQL). | Justifica directamente las restricciones técnicas T1-T3: la prioridad es entregar dentro del tiempo del semestre, no explorar el stack óptimo en abstracto. |

## 2.4 Convenciones

| # | Convención | Justificación |
|---|---|---|
| CV1 | Toda la documentación de arquitectura se organiza bajo [`/docs/arc42/`](./), [`/docs/C4/`](../C4/) y [`/docs/adr/`](../adr/), siguiendo la plantilla arc42 académica entregada en el curso. | Para mantener consistencia con lo ya montado en las entregas previas y con lo que el docente espera encontrar al evaluar la correspondencia entre documentación y repositorio. |

# 1. Introducción y Metas

## 1.1 Descripción del sistema

En la Universidad Tecnológica de Bolívar existe una amplia variedad de clubes y grupos estudiantiles abiertos a la comunidad universitaria, entre ellos los grupos de ajedrez, fútbol y teatro, pero no existe una herramienta destinada a que estos grupos puedan darse a conocer y comunicar sus actividades de forma centralizada. Esta carencia afecta tanto a los integrantes actuales de cada club, que carecen de un canal formal para difundir avisos, eventos y noticias, como a los estudiantes interesados en unirse, que no cuentan con un punto único donde descubrir qué clubes existen y qué actividades realizan.

El sistema **LinkClub** busca resolver este problema mediante una aplicación móvil que centraliza la gestión de avisos, eventos, grupos y noticias de los clubes estudiantiles, permitiendo tanto a los miembros como a los interesados externos mantenerse informados desde un solo lugar.

## 1.2 Metas de calidad

Con base en los [aspectos de calidad](../aspectos.md) declarados, las siguientes son las metas de calidad prioritarias para la arquitectura del sistema, ordenadas de mayor a menor prioridad:

| # | Meta de calidad | Motivación |
|---|---|---|
| 1 | Disponibilidad | El valor del sistema depende de que los avisos y eventos de los clubes sean consultables en todo momento; si el sistema no está disponible cuando un estudiante busca información sobre un evento próximo, el propósito central de la aplicación (mantener informada a la comunidad) se pierde. |
| 2 | Rendimiento (tiempo de respuesta) | La consulta de avisos, eventos y noticias es la operación más frecuente del sistema. Tiempos de respuesta altos desincentivan el uso frecuente, especialmente en un producto pensado para consultas rápidas y recurrentes desde el celular. |
| 3 | Usabilidad | El público objetivo incluye estudiantes que no pertenecen aún a ningún club y que solo exploran por interés; una interfaz poco intuitiva reduce la probabilidad de que ese público descubra y se sume a un grupo. |
| 4 | Mantenibilidad | El sistema se desarrolla en el marco de un curso académico con integrantes rotativos por semestre; la arquitectura debe permitir que futuros equipos comprendan y extiendan el sistema sin depender del conocimiento tácito del equipo original. |

## 1.3 Stakeholders

| Rol | Descripción | Expectativa frente a la arquitectura |
|---|---|---|
| Estudiante interesado | Estudiante que no pertenece a un club pero desea informarse o unirse a uno | Encontrar información actualizada y accesible sin fricción |
| Miembro de club | Estudiante ya vinculado a un club o grupo | Poder publicar avisos, eventos y noticias de su grupo de forma sencilla |
| Administrador de club | Estudiante o encargado con permisos para gestionar la información de un club específico | Control sobre el contenido publicado en nombre de su grupo |
| Equipo de desarrollo | Los 4 integrantes del proyecto | Una arquitectura documentada, coherente y mantenible a lo largo del curso |
| Docente del curso | Evaluador del proyecto | Correspondencia clara entre la documentación de arquitectura y el repositorio entregado |

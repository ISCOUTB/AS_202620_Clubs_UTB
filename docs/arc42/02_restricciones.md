# 2. Restricciones

Las siguientes restricciones técnicas, organizacionales y económicas acotan el espacio de diseño arquitectónico de **LinkClub** y justifican las decisiones registradas en `docs/adr/`.

## 2.1. Restricciones técnicas

| ID | Restricción | Descripción e impacto arquitectónico |
| ------ | ------ | ------ |
| **T1** | **Cliente móvil en Flutter** | La interfaz de usuario debe desarrollarse como aplicación móvil multiplataforma en Flutter (Dart, Material 3), consumiendo exclusivamente servicios REST sobre HTTPS sin acceso directo a base de datos. |
| **T2** | **Backend en FastAPI** | La API del servidor debe implementarse en Python 3.12 utilizando FastAPI y Pydantic para validación de esquemas y generación de metadatos OpenAPI. |
| **T3** | **Base de datos PostgreSQL** | La persistencia relacional debe realizarse en PostgreSQL (versión 18 en el despliegue vigente) dentro de un contenedor administrado por el equipo, utilizando SQL estándar compatible sin extensiones propietarias. |
| **T4** | **Despliegue autónomo en Dokploy** | Tras descartar servicios BaaS externos ([ADR 0007](../adr/0007-migracion-dokploy-postgresql.md)), todos los componentes del servidor deben empaquetarse en contenedores Docker y desplegarse en la instancia de Dokploy del laboratorio (`panel.iscoutb.dev`). |
| **T5** | **Autenticación JWT propia** | La emisión y verificación de tokens de sesión (`HS256`) y el almacenamiento seguro de credenciales (`bcrypt`) son responsabilidad exclusiva del backend FastAPI, identificando a cada usuario por su matrícula institucional (`^T[0-9]{7,8}$`). |

## 2.2. Restricciones organizacionales y de proceso

| ID | Restricción | Descripción e impacto arquitectónico |
| ------ | ------ | ------ |
| **O1** | **Equipo académico y horizonte semestral** | El proyecto es desarrollado por un equipo de 4 estudiantes dentro del curso *Arquitectura de Software* (NRC 1495, 2026-20). La arquitectura debe favorecer soluciones comprensibles, mantenibles y verificables mediante integración continua (GitHub Actions, `pytest` y SonarCloud). |

## 2.3. Convenciones y restricciones de diseño

| ID | Restricción | Descripción e impacto arquitectónico |
| ------ | ------ | ------ |
| **C1** | **Enfoque API-first y contrato uniforme** | El archivo `docs/api/openapi.yaml` es la fuente única de verdad de la interfaz REST. Todo cambio incompatible debe detectarse en CI (`oasdiff`) y toda respuesta de error debe respetar el formato `{"detail": "mensaje"}`. |
| **C2** | **Simplicidad operativa (monolito modular desplegable)** | Se mantiene un único contenedor de API en ejecución ([ADR 0008](../adr/0008-no-extraer-publicaciones.md)) y almacenamiento de archivos en volumen Docker local ([ADR 0009](../adr/0009-estrategia-persistencia-multimedia.md)), evitando introducir microservicios, Redis o brokers externos que incrementen la superficie de fallos. |

## 2.4. Restricciones financieras

| ID | Restricción | Descripción e impacto arquitectónico |
| ------ | ------ | ------ |
| **F1** | **Costo operativo cero ($0 USD)** | El sistema no dispone de presupuesto para servicios gestionados en la nube, almacenamiento S3 externo ni APIs comerciales de pago (incluida la exclusión de modelos LLM generativos documentada en el [ADR 0005](../adr/0005-no-incorporacion-llm.md)). |
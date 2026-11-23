# Mapa de contextos - LinkClub

## Contextos identificados

LinkClub se organiza en tres contextos internos, subdominios del propio sistema delimitados por responsabilidad de negocio. Desde el [ADR 0007](../adr/0007-migracion-dokploy-postgresql.md) no existen contextos externos de datos ni de identidad en ejecución: la autenticación y la persistencia son propias del sistema.

| Contexto | Tipo | Responsabilidad de negocio |
| ------ | ------ | ------ |
| **Clubes** | Interno | Gestiona la existencia de cada club, su ficha pública (líder, horario, lugar, redes), el estado de sus convocatorias y su enlace institucional de inscripción (`ms_forms_url`). |
| **Publicaciones** | Interno | Gestiona avisos, encuestas y noticias publicados en nombre de un club, así como la programación de eventos y el registro de asistencias. |
| **Usuarios** | Interno | Gestiona la identidad, el perfil, las credenciales (`bcrypt`), los tokens JWT, los roles (`ESTUDIANTE`, `ADMIN_CLUB`, `SUPERADMIN`) y las solicitudes de administración. |

## Estado de implementación por contexto

| Contexto | Implementado | Pendiente / Notas |
| ------ | ------ | ------ |
| **Usuarios** | Registro con hash `bcrypt` y solicitud opcional de admin, inicio de sesión (JSON y OAuth2), emisión/validación JWT `HS256`, perfil (`/usuarios/me`, edición, cambio de contraseña, eliminación de cuenta) y consola Superadmin (`/admin/solicitudes` aprobar/rechazar). | Sin pendientes funcionales en el alcance vigente. |
| **Clubes** | Persistencia completa en PostgreSQL (`ClubModel`), semilla inicial idempotente al arrancar, consulta con filtros Unicode (`q`, `categoria`), detalle, creación (`SUPERADMIN`), edición (`ADMIN_CLUB` verificado / `SUPERADMIN`) e inscripción externa vía Microsoft Forms (`ms_forms_url`). | No se gestionan membresías internas vía API; el flujo institucional usa `ms_forms_url`. |
| **Publicaciones** | Creación (`aviso`, `encuesta`, `noticia`), feed general (`GET /publicaciones`), listado por club, imágenes asociadas (`/recursos/upload`), idempotencia por autor (`Idempotency-Key`), control de rol por club (`403`) y gestión de eventos con confirmación/cancelación de asistencia (`GET/POST /eventos`, `POST /eventos/{evento_id}/asistencia`). | Votación interactiva sobre opciones de encuestas y envío de notificaciones push externas (prototipo de mensajería ya cubierto por `test_mensajeria.py`). |

## Notas

* Este diagrama modela únicamente conceptos de negocio y fronteras de control. Flutter y FastAPI son las tecnologías con las que se construye LinkClub: la interfaz y el backend son el sistema, no algo externo a él.
* La base de datos (PostgreSQL 18 en contenedor propio) es un detalle de infraestructura interno a cada contexto: cada uno es responsable de persistir sus propios datos mediante referencias por ID/matrícula, sin que eso constituya un contexto ni un actor aparte.
* Decisión que fusiona los módulos originales en estos tres contextos: [ADR 0002](../adr/0002-ajuste-contextos-publicaciones.md). Propiedad de datos: [tabla_modulo.md](./tabla_modulo.md). Decisión de mantener un único backend: [ADR 0008](../adr/0008-no-extraer-publicaciones.md).
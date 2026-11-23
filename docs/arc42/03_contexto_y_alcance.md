### 3. Contexto y alcance

**LinkClub** centraliza en una sola aplicación móvil los avisos, eventos, convocatorias y noticias de los clubes estudiantiles de la Universidad Tecnológica de Bolívar, para que tanto los integrantes como los estudiantes interesados los consulten desde un único punto. El sistema gestiona su propia autenticación, su control de roles y su propia persistencia: no depende de un proveedor externo de identidad ni de un servicio BaaS (ver [ADR 0007](../adr/0007-migracion-dokploy-postgresql.md)).

#### Contexto del sistema

| Socio de comunicación | Entendimiento |
| ------ | ------ |
| **Estudiante (`ESTUDIANTE`)** | Se registra, inicia sesión, explora el catálogo de clubes, consulta publicaciones y eventos, confirma asistencia y accede a enlaces institucionales de inscripción. |
| **Administrador del club (`ADMIN_CLUB`)** | Líder verificado que administra la ficha pública de su club, publica avisos, encuestas y noticias con imagen opcional, y programa eventos. |
| **Superadmin (`SUPERADMIN`)** | Administrador del sistema que crea nuevos clubes en el catálogo y aprueba o rechaza las solicitudes de rol de administrador de club. |

El diagrama C4 de contexto, de contenedores y de componentes está en [docs/c4/contexto.md](../c4/contexto.md).

#### 3.1. Contexto del negocio

Se describen las interacciones entre las personas que utilizan LinkClub y el sistema. LinkClub no consulta sistemas académicos internos de la universidad ni proveedores externos de identidad: la identidad se valida por formato institucional (correo `@utb.edu.co` y matrícula `T` + 7 u 8 dígitos) y la sesión la emite la propia API. La inscripción formal a un club se delega a formularios institucionales externos (`Microsoft Forms`) enlazados desde la ficha de cada club.

| Socio | Qué envía a LinkClub | Qué recibe de LinkClub | Estado |
| ------ | ------ | ------ | ------ |
| **Estudiante (`ESTUDIANTE`)** | Registro con nombre, matrícula, correo institucional y contraseña; inicio de sesión; consultas de clubes, feed y eventos; confirmación o cancelación de asistencia; edición de perfil. | Token JWT de sesión, catálogo de clubes filtrado desde PostgreSQL, feed de publicaciones, agenda de eventos, enlaces a formularios de inscripción y perfil actualizado. | Implementado de extremo a extremo. |
| **Administrador del club (`ADMIN_CLUB`)** | Solicitud de liderazgo al registrarse; creación de publicaciones (`aviso`, `encuesta`, `noticia`) con imagen opcional; programación de eventos (`PUBLICO` o `SOLO_CLUB`); actualización de ficha y enlace de inscripción de su club. | Confirmación de publicaciones y eventos creados, vista previa en modo estudiante y estado actualizado del club administrado. | Implementado con autorización estricta por club (`403 Forbidden` si intenta operar sobre otro club). |
| **Superadmin (`SUPERADMIN`)** | Creación de nuevos clubes en el directorio; aprobación o rechazo de solicitudes pendientes de administradores de club. | Listado de solicitudes pendientes, confirmación de asignación de roles y catálogo actualizado. | Implementado de extremo a extremo. |

#### 3.2. Contexto técnico

La aplicación móvil Flutter es el único cliente propio. Se comunica con la API FastAPI mediante REST sobre HTTPS, y la API persiste los datos en PostgreSQL 18 y las imágenes en un volumen Docker propio, todo dentro del mismo servidor de despliegue (Dokploy, `panel.iscoutb.dev`).

| Canal | Origen y destino | Tecnología y formato | Observaciones |
| ------ | ------ | ------ | ------ |
| Consumo de la API | Aplicación móvil hacia API | REST sobre HTTPS, JSON, cabecera `Authorization: Bearer` | URL de producción `https://api-linkclub.iscoutb.dev`. Contrato en `docs/api/openapi.yaml` (`v3.1.0`). Errores con formato uniforme `{"detail": "mensaje"}`. |
| Idempotencia de escrituras | Aplicación móvil hacia API | Cabecera `Idempotency-Key` (UUID v4) en peticiones `POST` | Generada automáticamente por un interceptor de `Dio` en el cliente móvil. |
| Subida de imágenes | Aplicación móvil hacia API | `multipart/form-data` en `POST /recursos/upload` | Extensiones permitidas: `jpg`, `jpeg`, `png`, `webp` y `gif` (máx. 5 MB). |
| Descarga de imágenes | Aplicación móvil hacia API | HTTPS, `GET /static/{archivo}` | Las imágenes se sirven desde el volumen persistente de la API. |
| Imágenes por URL externa | Aplicación móvil hacia sitios web de terceros | HTTPS | Publicaciones o eventos pueden referenciar una imagen alojada fuera del sistema. |
| Inscripción externa a clubes | Aplicación móvil hacia Microsoft Forms | HTTPS (`url_launcher` en navegador externo) | Cada club expone `inscripciones_abiertas`, `ms_forms_url` y `aviso_inscripcion`. |
| Persistencia de datos | API hacia PostgreSQL | SQL con SQLAlchemy y `psycopg2`, red interna `dokploy-network`, puerto `5432` | Host interno `clubsutb-db-2m0uk5`, base de datos `linkclub`. |
| Persistencia de archivos | API hacia volumen `linkclub_uploads` | Sistema de archivos, ruta `/app/uploads` | Decisión documentada en el ADR 0009. |
| Construcción y despliegue | GitHub hacia Dokploy | Build con `Dockerfile` de `./backend`, rama `master` | Ver [Sección 7](./07_vista_de_despliegue.md). |
| Integración continua | GitHub Actions | `pytest`, SonarCloud, `spectral` y `oasdiff` | Workflows `backend-tests.yml` y `contrato.yml`. |

Mecanismo de autenticación: la API emite tokens JWT firmados con `HS256`, con vigencia configurable (7 días por defecto). El identificador de usuario en el token (`sub`) es la matrícula. Las operaciones de lectura son públicas (`GET /eventos` acepta token opcional para incluir eventos `SOLO_CLUB` del club administrado y calcular `usuario_asiste`); toda operación de escritura exige un token válido y verificación de rol.

#### 3.3. Tecnologías y elementos técnicos

| Elemento | Descripción |
| ------ | ------ |
| **Aplicación móvil** | Interfaz principal de LinkClub, desarrollada en Flutter con Material 3 y tipografía DM Sans. |
| **Flutter y Dio** | Framework de interfaz y cliente HTTP singleton con interceptores para `Authorization` e `Idempotency-Key`. |
| **flutter_secure_storage** | Almacenamiento cifrado del token JWT en el dispositivo. |
| **url_launcher y flutter_markdown** | Apertura segura de formularios externos (Microsoft Forms) y renderizado enriquecido de publicaciones. |
| **FastAPI** | Framework del backend, organizado con arquitectura hexagonal (dominio, aplicación y adaptadores de entrada y salida). |
| **SQLAlchemy y psycopg2** | Mapeo objeto-relacional y acceso a datos desde la API hacia PostgreSQL. |
| **PostgreSQL 18** | Base de datos relacional que almacena `usuarios`, `clubes`, `publicaciones`, `eventos`, `asistencias` y `solicitudes_admin_club`. |
| **PyJWT y bcrypt** | Emisión/verificación de tokens JWT `HS256` y hash seguro de contraseñas. |
| **Docker y Dokploy** | Empaquetado de la API y plataforma de despliegue en el servidor del laboratorio. |
| **GitHub Actions y SonarCloud** | Pruebas automatizadas, verificación del contrato OpenAPI y análisis estático de código. |

#### 3.4. Alcance

| Dentro del alcance | Fuera del alcance |
| ------ | ------ |
| Registro e inicio de sesión con correo institucional (`@utb.edu.co`) y matrícula. | Integración directa con sistemas académicos o directorio activo (SSO) de la universidad. |
| Catálogo dinámico de clubes con filtros, feed de publicaciones con imagen y agenda de eventos con confirmación de asistencia. | Gestión interna de listas de miembros dentro de la app (las inscripciones se redirigen a Microsoft Forms). |
| Flujo de solicitud y aprobación de administradores de club (`ADMIN_CLUB` / `SUPERADMIN`) y autogestión de perfil. | Notificaciones push o por correo en tiempo real (diferidas; prototipo en memoria según ADR 0003 y ADR 0010). |
| Despliegue continuo en el servidor del laboratorio con URL pública HTTPS. | Componentes de inteligencia artificial generativa en ejecución (ver ADR 0005). |
# 3. Contexto y alcance

**LinkClub** centraliza en una sola aplicación móvil los avisos, eventos y noticias de los clubes estudiantiles de la Universidad Tecnológica de Bolívar, para que tanto los miembros como los estudiantes interesados los consulten desde un único punto. El sistema gestiona su propia autenticación y su propia persistencia: no depende de un proveedor externo de identidad ni de un servicio BaaS (ver [ADR 0007](../adr/0007-migracion-dokploy-postgresql.md)).

## Contexto del sistema

| Socio de comunicación | Entendimiento |
| --- | --- |
| Estudiante interesado | Se registra, inicia sesión y consulta los clubes disponibles y las publicaciones de la comunidad. |
| Miembro del club | Estudiante vinculado a un club que publica avisos, encuestas y noticias, con imagen opcional. |
| Administrador del club | Encargado de supervisar y administrar la información del club y su contenido. |

El diagrama C4 de contexto, de contenedores y de componentes está en [`docs/c4/contexto.md`](../c4/contexto.md).

## 3.1. Contexto del negocio

Se describen las interacciones entre las personas que utilizan LinkClub y el sistema. LinkClub no se comunica con ningún sistema externo de negocio: no consulta sistemas académicos de la universidad ni proveedores de identidad. La identidad se valida únicamente por formato (correo institucional y matrícula) y la sesión la emite la propia API.

| Socio | Qué envía a LinkClub | Qué recibe de LinkClub | Estado |
| --- | --- | --- | --- |
| Estudiante interesado | Registro con nombre, matrícula (letra T seguida de 7 u 8 dígitos), correo institucional (@utb.edu.co) y contraseña; inicio de sesión. | Token de sesión, catálogo de clubes y feed de publicaciones. | Registro, inicio de sesión, feed y catálogo implementados. El catálogo se sirve hoy desde datos en memoria. Inscripción en un club pendiente. |
| Miembro del club | Publicaciones (aviso, encuesta o noticia) con contenido en formato Markdown e imagen opcional. | Confirmación de la publicación y feed actualizado. | Publicación con imagen implementada. Eventos y confirmación de asistencia pendientes. |
| Administrador del club | Gestión de la información del club, de sus miembros y de sus eventos. | Listado de miembros y estado del club. | Pendiente. El rol de administrador existe en el esquema de membresías, pero la API aún no aplica control de permisos por rol. |

## 3.2. Contexto técnico

La aplicación móvil Flutter es el único cliente. Se comunica con la API FastAPI mediante REST sobre HTTPS, y la API persiste los datos en PostgreSQL y las imágenes en un volumen propio, todo dentro del mismo servidor de despliegue (Dokploy, `panel.iscoutb.dev`).

| Canal | Origen y destino | Tecnología y formato | Observaciones |
| --- | --- | --- | --- |
| Consumo de la API | Aplicación móvil hacia API | REST sobre HTTPS, JSON, cabecera `Authorization: Bearer` | URL de producción `https://api-linkclub.iscoutb.dev`. Contrato en `docs/api/openapi.yaml`. Errores con formato uniforme `{"detail": "mensaje"}`. |
| Idempotencia de escrituras | Aplicación móvil hacia API | Cabecera `Idempotency-Key` (UUID v4) en las peticiones POST | La genera un interceptor del cliente HTTP de la aplicación. |
| Subida de imágenes | Aplicación móvil hacia API | `multipart/form-data` en `POST /recursos/upload` | Extensiones permitidas: jpg, jpeg, png, webp, gif y svg. |
| Descarga de imágenes | Aplicación móvil hacia API | HTTPS, `GET /static/{archivo}` | Las imágenes se sirven desde el volumen de la API. |
| Imágenes por URL externa | Aplicación móvil hacia sitios web de terceros | HTTPS | La publicación puede referenciar una imagen alojada fuera del sistema. |
| Persistencia de datos | API hacia PostgreSQL | SQL con SQLAlchemy y psycopg2, red interna `dokploy-network`, puerto 5432 | Host interno `clubsutb-db-2m0uk5`, base de datos `linkclub`. |
| Persistencia de archivos | API hacia volumen `linkclub_uploads` | Sistema de archivos, ruta `/app/uploads` | Decisión documentada en el ADR 0009. |
| Construcción y despliegue | GitHub hacia Dokploy | Build con `Dockerfile` de `./backend`, rama `master` | Ver sección 7. |
| Integración continua | GitHub Actions | pytest, SonarCloud, spectral y oasdiff | Workflows `backend-tests.yml` y `contrato.yml`. |

Mecanismo de autenticación: la API emite tokens JWT firmados con HS256, con vigencia configurable (7 días por defecto). El identificador de usuario en el token es la matrícula. Las operaciones de lectura son públicas en el contrato; toda escritura exige un token válido.

## 3.3. Tecnologías y elementos técnicos

| Elemento | Descripción |
| --- | --- |
| Aplicación móvil | Interfaz principal de LinkClub, desarrollada en Flutter con Material 3. |
| Flutter y Dio | Framework de la interfaz y cliente HTTP con interceptores para el token y la clave de idempotencia. |
| flutter_secure_storage | Almacenamiento seguro del token JWT en el dispositivo. |
| FastAPI | Framework del backend, organizado con arquitectura hexagonal (dominio, aplicación y adaptadores de entrada y salida). |
| SQLAlchemy y psycopg2 | Acceso a datos desde la API hacia PostgreSQL. |
| PostgreSQL 18 | Base de datos relacional que almacena usuarios, clubes, membresías, publicaciones, eventos y asistencias. |
| PyJWT | Emisión y verificación de los tokens de sesión. |
| Docker y Dokploy | Empaquetado de la API y plataforma de despliegue en el servidor del laboratorio. |
| GitHub Actions y SonarCloud | Pruebas automatizadas, verificación del contrato y análisis estático de código. |

## 3.4. Alcance

| Dentro del alcance | Fuera del alcance |
| --- | --- |
| Registro e inicio de sesión con correo institucional y matrícula. | Integración con sistemas académicos o de identidad de la universidad. |
| Catálogo de clubes y feed de publicaciones con imagen. | Notificaciones push o por correo (diferidas, ver ADR 0003 y ADR 0008). |
| Gestión de membresías, eventos y asistencia (en desarrollo según el contrato). | Componentes de inteligencia artificial generativa en ejecución (ver ADR 0005). |
| Despliegue en el servidor del laboratorio con URL pública. | Reemplazo de los canales informales de los clubes fuera de la aplicación. |
# LinkClub — Gestión de Clubes y Grupos UTB

> Repositorio académico: `AS_202620_Clubs_UTB` — Organización `ISCOUTB`
> Proyecto del curso **Arquitectura de Software** (NRC: 1495), 2026-20

## 1. Descripción del proyecto

En la universidad existen varios clubes y grupos estudiantiles (ajedrez, fútbol, música, entre otros), pero no hay una plataforma unificada donde estos puedan publicar avisos, eventos y novedades, ni donde los estudiantes interesados, estén ya vinculados a un grupo o no, puedan enterarse y mantenerse informados sobre lo que sucede en cada uno.

**LinkClub** busca resolver ese vacío: una aplicación que centraliza la gestión de avisos, eventos, grupos y noticias de los clubes universitarios, permitiendo tanto a los miembros como a los interesados externos seguir la actividad de cada club desde un solo lugar.

Este repositorio documenta el diseño y la evolución arquitectónica del proyecto: las decisiones tomadas, sus justificaciones y el contexto en que se aplican, siguiendo arc42, C4 y escenarios de calidad como marco de referencia a lo largo de todo el ciclo de vida del sistema.

## 2. Problema que resuelve

- **Fragmentación de la información:** Cada club comunica sus eventos por canales distintos (grupos de WhatsApp, redes sociales, carteleras físicas), sin un punto central.
- **Baja visibilidad para nuevos interesados:** Un estudiante que quiere unirse a un club no tiene una forma fácil ni directa de descubrir cuáles existen ni qué están haciendo.
- **Falta de trazabilidad institucional:** No hay un historial único de la actividad histórica de los grupos estudiantiles.

## 3. Stack tecnológico

| Componente | Tecnología | Estado |
|---|---|---|
| Frontend / App móvil | Flutter (Material 3), `Dio`, `flutter_secure_storage`, `url_launcher`, `flutter_markdown` | Operativo: registro (con solicitud opcional de admin), inicio de sesión, catálogo de clubes con filtros desde API, feed general y por club, creación de publicaciones con imagen, eventos con confirmación de asistencia, perfil y consola Superadmin. |
| Backend / API | FastAPI (Python 3.12), SQLAlchemy, `psycopg2-binary`, `PyJWT`, `bcrypt` | Operativo: salud con sondeo `SELECT 1` (`200`/`503`), autenticación, perfil y aprobación de solicitudes de admin, clubes, publicaciones, eventos/asistencias y carga de imágenes. |
| Base de datos | PostgreSQL 18 en contenedor | Operativa de extremo a extremo para usuarios, clubes, publicaciones, eventos, asistencias y solicitudes de admin; esquemas en `backend/migrations/001_esquema_inicial.sql` y `002_sincronizar_esquema_orm.sql`, más inicialización idempotente al arrancar. |
| Autenticación | Tokens JWT (`HS256`) emitidos por la propia API y control de roles (RBAC) | Operativa: contraseñas con hash `bcrypt`, `JWT_SECRET` obligatorio (*fail-fast*) y autorización por rol (`ESTUDIANTE`, `ADMIN_CLUB` verificado, `SUPERADMIN` con `403`). |
| Despliegue | Docker y Dokploy en el servidor del laboratorio | Operativo, con dominio HTTPS (`https://api-linkclub.iscoutb.dev`) y volumen persistente `linkclub_uploads` (`/app/uploads`). |
| Integración continua | GitHub Actions y SonarCloud | Pruebas (`pytest`, 38 pruebas), validación del contrato OpenAPI (`v3.1.0`, `Spectral` y `oasdiff`) y análisis estático. |
| Estilo arquitectónico | Hexagonal (puertos y adaptadores) | Aplicado en el backend, con desviaciones declaradas en routers CRUD. |

La decisión de reemplazar Supabase por infraestructura propia está en el [ADR 0007](docs/adr/0007-migracion-dokploy-postgresql.md).

## 4. Estructura del repositorio

```text
.github/workflows/
  backend-tests.yml
  contrato.yml
backend/
  Dockerfile
  requirements.txt
  .env.example
  migrations/
    001_esquema_inicial.sql
    002_sincronizar_esquema_orm.sql
  src/linkclub/
    main.py
    domain/
    application/
      messaging/
      ports/
      use_cases/
    adapters/
      inbound/api/
      outbound/
        auth/
        messaging/
        persistence/
        postgres/
  tests/
deploy/
  compose.lab.yaml
docs/
  aspectos.md
  ficha_problema.md
  ia.md
  mediciones_calidad.md
  adr/
  api/
  arc42/
  c4/
  resilience/
frontend/linkclub/
  pubspec.yaml
  lib/
    main.dart
    core/
      network/
      session/
      theme/
    data/
    presentation/
  windows/
README.md

```

| Ruta | Contenido |
| --- | --- |
| `docs/aspectos.md` | Aspectos de calidad y su trazabilidad hasta el código, las pruebas y la evidencia |
| `docs/ia.md` | Registro de uso de IA en el proyecto |
| `docs/mediciones_calidad.md` | Mediciones y verificaciones de los escenarios de calidad `U1–U3` y `C1–C3` |
| `docs/api/` | Contrato OpenAPI (`openapi.yaml` `v3.1.0`), AsyncAPI, guía del contrato y registro de cambios |
| `docs/arc42/` | Documentación arc42 (secciones 1 a 12), mapa de contextos, tablas de fallos, de garantías de consistencia y de amenazas, análisis de dependencias, privacidad y lista de no conformidades |
| `docs/c4/contexto.md` | Diagramas C4 de contexto, contenedores y componentes |
| `docs/adr/` | Registros de decisiones de arquitectura (0001 a 0010; la numeración repetida está registrada en la [Sección 9 de arc42](https://www.google.com/search?q=docs/arc42/09_decisiones_de_diseno.md)) |
| `docs/resilience/idempotencia.md` | Diseño de idempotencia en la creación de publicaciones |
| `deploy/compose.lab.yaml` | Definición de despliegue para el servidor del laboratorio |

## 5. Equipo

| Integrante | GitHub |
| --- | --- |
| Hollman De Orta | @deortahollman-star |
| Josh Ortega | @Josh4OP |
| Diego Ramos | @devZavod |
| Luis Salas | @Luis-Salas-Reyes |

> Los 4 integrantes están añadidos como colaboradores del repositorio en GitHub.

## 6. Estado del proyecto

**En fase activa de desarrollo, integración y despliegue.** El sistema está desplegado en el servidor del laboratorio con dominio HTTPS. Están operativos el registro (con hash `bcrypt` y solicitud opcional de `ADMIN_CLUB`), el inicio de sesión (JSON y OAuth2) con tokens JWT propios (`HS256`), el control de roles (`ESTUDIANTE`, `ADMIN_CLUB` verificado y `SUPERADMIN`), la gestión de perfil (`/usuarios/me`) y solicitudes de administrador (`/admin/solicitudes`), el catálogo de clubes en PostgreSQL con enlace externo de inscripción (`ms_forms_url`), el feed general y por club de publicaciones (`aviso`, `encuesta`, `noticia`) con imágenes e idempotencia por autor, y la agenda de eventos (`PUBLICO` y `SOLO_CLUB`) con confirmación/cancelación de asistencia. El detalle está en la [Sección 11 de arc42](https://www.google.com/search?q=docs/arc42/11_riesgos_y_deuda_tecnica.md) y en la [lista de no conformidades](https://www.google.com/search?q=docs/arc42/lista_errores.md).

La estrategia de consistencia está documentada en la [Sección 8 de arc42](https://www.google.com/search?q=docs/arc42/08_conceptos_transversales.md): las entidades se guardan en PostgreSQL con consistencia fuerte y no se implementa caché; el diseño de caché queda definido para activarse si la medición de latencia lo exige.

---

*Curso de Arquitectura de Software — Universidad Tecnológica de Bolívar (UTB)*

## 7. Cómo arrancar

### 7.1. Base de datos

Requisitos previos: PostgreSQL accesible y una base vacía. Aplicar el esquema inicial y la sincronización del esquema:

```bash
psql "$DATABASE_URL" -f backend/migrations/001_esquema_inicial.sql
psql "$DATABASE_URL" -f backend/migrations/002_sincronizar_esquema_orm.sql

```

### 7.2. Backend (FastAPI)

Requisitos previos: Python 3.12 y las variables de entorno `DATABASE_URL` y `JWT_SECRET` (obligatoria al arrancar). No se versionan; defínelas en tu entorno local (puedes tomar como referencia `backend/.env.example`).

```bash
cd backend
python -m venv venv
pip install -r requirements.txt

```

Activar el entorno virtual en macOS o Linux:

```bash
source venv/bin/activate

```

Activar el entorno virtual en Windows:

```bash
venv\Scripts\activate

```

Definir las variables y arrancar en macOS o Linux:

```bash
export DATABASE_URL="postgresql://usuario:clave@localhost:5432/linkclub"
export JWT_SECRET="valor-largo-y-aleatorio"
uvicorn linkclub.main:app --app-dir src

```

Verifica en [http://localhost:8000/health](http://localhost:8000/health): debe responder `{"status": "ok", "database": "online"}` (o `503` si la base de datos no responde).

### 7.3. Pruebas del backend

```bash
cd backend
PYTHONPATH=src JWT_SECRET=test DATABASE_URL=sqlite:///./test.db pytest tests/ -v

```

Las pruebas usan una base SQLite en memoria y una autenticación simulada; no requieren PostgreSQL.

### 7.4. Frontend (Flutter)

Requisitos previos: Flutter SDK (Dart 3+). La aplicación declara un archivo `.env` como recurso, por lo que debe existir en `frontend/linkclub/`. Define en él la variable `API_URL`; si se omite, la aplicación usa la API publicada.

```bash
cd frontend/linkclub
flutter pub get
flutter run

```

### 7.5. Limitaciones conocidas

Los ajustes pendientes (como la paridad de versión de PostgreSQL en `deploy/compose.lab.yaml`, el respaldo automatizado de base de datos y volumen, la ausencia de paginación en listados y las desviaciones arquitectónicas declaradas) están registrados en la [lista de no conformidades](https://www.google.com/search?q=docs/arc42/lista_errores.md) y en la [Sección 11 de arc42](https://www.google.com/search?q=docs/arc42/11_riesgos_y_deuda_tecnica.md).

---

## 8. Despliegue y URLs

| Componente | URL | Notas |
| --- | --- | --- |
| API (backend) | `https://api-linkclub.iscoutb.dev` | Dominio institucional con HTTPS, desplegado en Dokploy |
| Comprobación de estado | `https://api-linkclub.iscoutb.dev/health` | Verifica conectividad activa con PostgreSQL (`SELECT 1`); responde `200` (`{"status": "ok", "database": "online"}`) o `503` si la BD no está disponible |
| Interfaz | No aplica | La interfaz es la aplicación móvil Flutter; no existe un sitio web publicado. La aplicación apunta por defecto a la URL de la API |

Verificación desde cualquier equipo:

```bash
curl -i [https://api-linkclub.iscoutb.dev/health](https://api-linkclub.iscoutb.dev/health)

```

### 8.1. Recrear el entorno desplegado

El entorno consta de un contenedor de aplicación, un contenedor PostgreSQL y un volumen de imágenes.

1. Crear un contenedor PostgreSQL (el despliegue vigente usa la versión 18) con una base `linkclub` y un volumen de datos propio. Aplicar `backend/migrations/001_esquema_inicial.sql` y `backend/migrations/002_sincronizar_esquema_orm.sql` (al iniciar, la API también crea tablas faltantes, aplica migraciones idempotentes en PostgreSQL y carga la semilla inicial de clubes).
2. Crear el servicio de la API a partir de este repositorio, rama `master`, con construcción por `Dockerfile` y contexto `backend`. El contenedor escucha en el puerto 8000.
3. Definir en el servicio las variables `DATABASE_URL`, `JWT_SECRET` y `CORS_ORIGINS` (y opcionalmente `JWT_EXPIRES_DAYS` y `UPLOAD_DIR`). Se configuran en la plataforma y nunca se versionan.
4. Montar un volumen persistente (`linkclub_uploads`) en `/app/uploads` para conservar las imágenes subidas.
5. Asociar un dominio con certificado automático al puerto 8000 del servicio.

Alternativa con compose para el servidor del laboratorio: `deploy/compose.lab.yaml` define la base y el backend con las mismas variables. Antes de usarlo debe agregarse el volumen de `/app/uploads`, revisarse la versión de imagen de PostgreSQL y aplicarse las migraciones correspondientes (ver NC-21 en la lista de no conformidades).

---

## 9. Estimación de Costo Mensual y Supuestos

El sistema opera sobre el servidor del laboratorio de la universidad y repositorios públicos, sin proveedores de pago ni tarjeta de crédito.

### 9.1. Desglose de Costos (Fase Académica / Beta / Producción Inicial)

| Componente / Servicio | Plataforma | Costo Estimado (USD / mes) | Supuestos Operativos |
| --- | --- | --- | --- |
| **Backend API (FastAPI)** | Contenedor Docker en Dokploy, servidor del laboratorio | **$0.00** | Una réplica con 1 GB de memoria y 2 CPU, sin arranque en frío. |
| **Base de datos** | Contenedor PostgreSQL en el mismo servidor | **$0.00** | Estimación de 2.000 estudiantes activos, unas 160.000 consultas al mes y unos 50 MB de datos mensuales. |
| **Autenticación** | Implementada en la propia API | **$0.00** | Tokens JWT propios (`HS256`) y hash `bcrypt`; sin cuotas de terceros. |
| **Imágenes subidas** | Volumen Docker en el mismo servidor | **$0.00** | Limitado por el disco asignado. |
| **Dominio y HTTPS** | Subdominio institucional con certificado automático | **$0.00** | Provisto por la plataforma de despliegue. |
| **Integración continua** | GitHub Actions y SonarCloud | **$0.00** | Repositorio público, sin consumo de cuota de minutos. |
| **TOTAL ESTIMADO** | — | **$0.00 USD / mes** | Viable para desarrollo, pruebas y operación académica. |

### 9.2. Punto de quiebre y escalabilidad

No existen cuotas de terceros que se agoten. El límite lo marcan los recursos asignados al servidor (memoria, CPU y disco) y su disponibilidad.

* **Si se superan los recursos asignados:** solicitar al laboratorio mayor memoria, CPU o disco; el despliegue en contenedores permite ajustar los límites sin cambiar el código.
* **Si se necesita otro entorno:** el backend y la base de datos son portables a cualquier host con Docker; basta reconstruir los contenedores y restaurar un volcado de la base. La migración desde Supabase está justificada en el [ADR 0007](https://www.google.com/search?q=docs/adr/0007-migracion-dokploy-postgresql.md).
* **Costos no monetarios:** operación manual del despliegue y de los respaldos, y dependencia de un servidor único (ver la [Sección 11 de arc42](https://www.google.com/search?q=docs/arc42/11_riesgos_y_deuda_tecnica.md)).

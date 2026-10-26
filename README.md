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
| Frontend / App móvil | Flutter (Material 3), Dio, almacenamiento seguro del token | Operativo: registro, inicio de sesión, feed y creación de publicaciones con imagen. El catálogo de clubes usa datos locales. |
| Backend / API | FastAPI (Python 3.12) | Operativo: salud, autenticación, publicaciones, carga de imágenes y consulta de clubes (datos en memoria) |
| Base de datos | PostgreSQL en contenedor | Operativa para usuarios y publicaciones; esquema aplicado desde `backend/migrations/` |
| Autenticación | Tokens JWT emitidos por la propia API | Operativa; la protección de contraseñas con hash está pendiente |
| Despliegue | Docker y Dokploy en el servidor del laboratorio | Operativo, con dominio HTTPS |
| Integración continua | GitHub Actions y SonarCloud | Pruebas, validación del contrato OpenAPI y análisis estático |
| Estilo arquitectónico | Hexagonal (puertos y adaptadores) | Aplicado en el backend, con desviaciones declaradas |

La decisión de reemplazar Supabase por infraestructura propia está en el [ADR 0007](docs/adr/0007-migracion-dokploy-postgresql.md).

## 4. Estructura del repositorio

```text
.github/workflows/
  backend-tests.yml
  contrato.yml
backend/
  Dockerfile
  requirements.txt
  migrations/
    001_esquema_inicial.sql
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
      theme/
    data/
    presentation/
  windows/
README.md
```

| Ruta | Contenido |
|---|---|
| `docs/aspectos.md` | Aspectos de calidad y trazabilidad hasta la evidencia |
| `docs/ia.md` | Registro de uso de IA en el proyecto |
| `docs/api/` | Contrato OpenAPI (`openapi.yaml`), AsyncAPI, guía del contrato y registro de cambios |
| `docs/arc42/` | Documentación arc42 (secciones 1 a 12), mapa de contextos, tablas de fallos y de garantías de consistencia, lista de no conformidades |
| `docs/c4/contexto.md` | Diagramas C4 de contexto, contenedores y componentes |
| `docs/adr/` | Registros de decisiones de arquitectura (0001 a 0009) |
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

**En fase activa de desarrollo, integración y despliegue.** El sistema está desplegado en el servidor del laboratorio con dominio HTTPS. Están operativos el registro y el inicio de sesión con tokens propios, el feed de publicaciones con imágenes y la consulta de clubes en la API. Siguen pendientes la persistencia del catálogo de clubes, las membresías, los eventos y la asistencia, la protección de contraseñas con hash y la autorización por rol. El detalle está en la [Sección 11 de arc42](docs/arc42/11_riesgos_y_deuda_tecnica.md).

---

*Curso de Arquitectura de Software — Universidad Tecnológica de Bolívar (UTB)*

## 7. Cómo arrancar

### 7.1. Base de datos

Requisitos previos: PostgreSQL accesible y una base vacía. Aplicar el esquema:

```bash
psql "$DATABASE_URL" -f backend/migrations/001_esquema_inicial.sql
```

### 7.2. Backend (FastAPI)

Requisitos previos: Python 3.12 y las variables de entorno `DATABASE_URL` y `JWT_SECRET`. No se versionan; defínelas en tu entorno local.

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

Verifica en [http://localhost:8000/health](http://localhost:8000/health): debe responder `{"status": "ok"}`.

### 7.3. Pruebas del backend

```bash
cd backend
PYTHONPATH=src pytest tests/ -v
```

### 7.4. Frontend (Flutter)

Requisitos previos: Flutter SDK (Dart 3+). La aplicación declara un archivo `.env` como recurso, por lo que debe existir en `frontend/linkclub/`. Define en él la variable `API_URL`; si se omite, la aplicación usa la API publicada.

```bash
cd frontend/linkclub
flutter pub get
flutter run
```

### 7.5. Limitaciones conocidas

El esquema de la migración y los modelos del backend, la suite de pruebas y el contrato de inicio de sesión tienen divergencias registradas como deuda técnica en la [Sección 11 de arc42](docs/arc42/11_riesgos_y_deuda_tecnica.md).

---

## 8. Estimación de Costo Mensual y Supuestos

El sistema opera sobre el servidor del laboratorio de la universidad y repositorios públicos, sin proveedores de pago ni tarjeta de crédito.

### 8.1. Desglose de Costos (Fase Académica / Beta / Producción Inicial)

| Componente / Servicio | Plataforma | Costo Estimado (USD / mes) | Supuestos Operativos |
| --- | --- | --- | --- |
| **Backend API (FastAPI)** | Contenedor Docker en Dokploy, servidor del laboratorio | **$0.00** | Una réplica con 1 GB de memoria y 2 CPU, sin arranque en frío. |
| **Base de datos** | Contenedor PostgreSQL en el mismo servidor | **$0.00** | Estimación de 2.000 estudiantes activos, unas 160.000 consultas al mes y unos 50 MB de datos mensuales. |
| **Autenticación** | Implementada en la propia API | **$0.00** | Tokens JWT propios; sin cuotas de terceros. |
| **Imágenes subidas** | Volumen Docker en el mismo servidor | **$0.00** | Limitado por el disco asignado. |
| **Dominio y HTTPS** | Subdominio institucional con certificado automático | **$0.00** | Provisto por la plataforma de despliegue. |
| **Integración continua** | GitHub Actions y SonarCloud | **$0.00** | Repositorio público, sin consumo de cuota de minutos. |
| **TOTAL ESTIMADO** | — | **$0.00 USD / mes** | Viable para desarrollo, pruebas y operación académica. |

### 8.2. Punto de quiebre y escalabilidad

No existen cuotas de terceros que se agoten. El límite lo marcan los recursos asignados al servidor (memoria, CPU y disco) y su disponibilidad.

* **Si se superan los recursos asignados:** solicitar al laboratorio mayor memoria, CPU o disco; el despliegue en contenedores permite ajustar los límites sin cambiar el código.
* **Si se necesita otro entorno:** el backend y la base de datos son portables a cualquier host con Docker; basta reconstruir los contenedores y restaurar un volcado de la base. La migración desde Supabase está justificada en el [ADR 0007](docs/adr/0007-migracion-dokploy-postgresql.md).
* **Costos no monetarios:** operación manual del despliegue y de los respaldos, y dependencia de un servidor único (ver la [Sección 11 de arc42](docs/arc42/11_riesgos_y_deuda_tecnica.md)).
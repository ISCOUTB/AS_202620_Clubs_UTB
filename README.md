# LinkClub — Gestión de Clubes y Grupos UTB

> Repositorio académico: `AS_202620_Clubs_UTB` — Organización `ISCOUTB`[cite: 6]
> Proyecto del curso **Arquitectura de Software** (NRC: 1495), 2026-20[cite: 6]

## 1. Descripción del proyecto

En la universidad existen varios clubes y grupos estudiantiles (ajedrez, fútbol, música, entre otros), pero no hay una plataforma unificada donde estos puedan publicar avisos, eventos y novedades, ni donde los estudiantes interesados, estén ya vinculados a un grupo o no, puedan enterarse y mantenerse informados sobre lo que sucede en cada uno[cite: 6].

**LinkClub** busca resolver ese vacío: una aplicación que centraliza la gestión de avisos, eventos, grupos y noticias de los clubes universitarios, permitiendo tanto a los miembros como a los interesados externos seguir la actividad de cada club desde un solo lugar[cite: 6].

Este repositorio documenta el diseño y la evolución arquitectónica del proyecto: las decisiones tomadas, sus justificaciones y el contexto en que se aplican, siguiendo arc42, C4 y escenarios de calidad como marco de referencia a lo largo de todo el ciclo de vida del sistema[cite: 6].

## 2. Problema que resuelve

- **Fragmentación de la información:** Cada club comunica sus eventos por canales distintos (grupos de WhatsApp, redes sociales, carteleras físicas), sin un punto central[cite: 6].
- **Baja visibilidad para nuevos interesados:** Un estudiante que quiere unirse a un club no tiene una forma fácil ni directa de descubrir cuáles existen ni qué están haciendo[cite: 6].
- **Falta de trazabilidad institucional:** No hay un historial único de la actividad histórica de los grupos estudiantiles[cite: 6].

## 3. Stack tecnológico

| Componente | Tecnología | Estado |
|---|---|---|
| Frontend / App móvil | Flutter (Material 3), Dio, almacenamiento seguro del token (`flutter_secure_storage`) | Operativo: registro, inicio de sesión, feed, creación de publicaciones con imagen y exploración de clubes[cite: 6, 7, 8]. |
| Backend / API | FastAPI (Python 3.12), SQLAlchemy, psycopg2 | Operativo en producción (`https://api-linkclub.iscoutb.dev`) con persistencia en PostgreSQL[cite: 6, 7, 9, 10]. |
| Base de datos | PostgreSQL 18 en contenedor (`clubsutb-db-2m0uk5`) | Operativa para clubes, usuarios, publicaciones y asistencias; esquema gestionado por migraciones y sincronización al arrancar[cite: 6, 7, 8, 9, 10]. |
| Autenticación | Tokens JWT (HS256) emitidos por la propia API y hash de contraseñas (`bcrypt`) | Operativa con JWT propios y hash con `bcrypt`; control de permisos por rol y membresía en evolución[cite: 6, 7, 8]. |
| Despliegue | Docker y Dokploy (`panel.iscoutb.dev`) en el servidor del laboratorio | Operativo en el entorno `production`, con dominio HTTPS (`api-linkclub.iscoutb.dev`) y volumen `linkclub_uploads` (`/app/uploads`)[cite: 6, 7, 8, 9, 10]. |
| Integración continua | GitHub Actions y SonarCloud | Pruebas automatizadas (`pytest`), validación del contrato OpenAPI (`Spectral` / `oasdiff`) y análisis estático[cite: 6, 7]. |
| Estilo arquitectónico | Hexagonal (puertos y adaptadores) | Aplicado en el backend (`domain/`, `application/`, `adapters/`), con desviaciones declaradas en arc42[cite: 6, 7]. |

La decisión de reemplazar Supabase por infraestructura propia está en el [ADR 0007](docs/adr/0007-migracion-dokploy-postgresql.md)[cite: 6].

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
      theme/
    data/
    presentation/
  windows/
sonar-project.properties
README.md
```[cite: 6, 7]

| Ruta | Contenido |
|---|---|
| `docs/aspectos.md` | Aspectos de calidad y su trazabilidad hasta el código, las pruebas y la evidencia[cite: 6] |
| `docs/ia.md` | Registro de uso de IA en el proyecto[cite: 6] |
| `docs/mediciones_calidad.md` | Mediciones y escenarios de calidad del sistema[cite: 7] |
| `docs/api/` | Contrato OpenAPI (`openapi.yaml`), AsyncAPI (`asyncapi.yaml`), guía del contrato y registro de cambios[cite: 6, 7] |
| `docs/arc42/` | Documentación arc42 (secciones 1 a 12), mapa de contextos, tablas de fallos, de garantías de consistencia y de amenazas, análisis de dependencias, privacidad y lista de no conformidades[cite: 6] |
| `docs/c4/contexto.md` | Diagramas C4 de contexto, contenedores y componentes[cite: 6] |
| `docs/adr/` | Registros de decisiones de arquitectura (0001 a 0010; la numeración repetida está registrada en la [Sección 9 de arc42](docs/arc42/09_decisiones_de_diseno.md))[cite: 6, 7] |
| `docs/resilience/idempotencia.md` | Diseño de idempotencia en la creación de publicaciones[cite: 6] |
| `deploy/compose.lab.yaml` | Definición de despliegue para el servidor del laboratorio[cite: 6] |

## 5. Equipo

| Integrante | GitHub |
| --- | --- |
| Hollman De Orta | @deortahollman-star |
| Josh Ortega | @Josh4OP |
| Diego Ramos | @devZavod |
| Luis Salas | @Luis-Salas-Reyes |

> Los 4 integrantes están añadidos como colaboradores del repositorio en GitHub[cite: 6].

## 6. Estado del proyecto

**En fase activa de desarrollo, integración y despliegue.** El sistema está desplegado en el servidor del laboratorio (`panel.iscoutb.dev`, proyecto `clubsutb`, entorno `production`) con dominio HTTPS (`https://api-linkclub.iscoutb.dev`)[cite: 6, 9, 10]. Están operativos el registro y el inicio de sesión con tokens JWT propios, el feed de publicaciones con imágenes, la consulta de clubes en la API y la comprobación de salud[cite: 6, 7, 8]. Las desviaciones, pendientes y mejoras en curso se documentan en la [Sección 11 de arc42](docs/arc42/11_riesgos_y_deuda_tecnica.md) y en la [lista de no conformidades](docs/arc42/lista_errores.md)[cite: 6].

La estrategia de consistencia está documentada en la [Sección 8 de arc42](docs/arc42/08_conceptos_transversales.md): las publicaciones se guardan en PostgreSQL con consistencia fuerte y no se implementa caché; el diseño de caché queda definido para activarse si la medición de latencia lo exige[cite: 6].

---

*Curso de Arquitectura de Software — Universidad Tecnológica de Bolívar (UTB)*[cite: 6]

## 7. Cómo arrancar

### 7.1. Base de datos

Requisitos previos: PostgreSQL accesible y una base vacía[cite: 6]. Aplicar el esquema:

```bash
psql "$DATABASE_URL" -f backend/migrations/001_esquema_inicial.sql
```[cite: 6]

### 7.2. Backend (FastAPI)

Requisitos previos: Python 3.12 y las variables de entorno `DATABASE_URL` y `JWT_SECRET` (puedes tomar como referencia `backend/.env.example`)[cite: 6, 7]. No se versionan; defínelas en tu entorno local[cite: 6].

```bash
cd backend
python -m venv venv
pip install -r requirements.txt
```[cite: 6]

Activar el entorno virtual en macOS o Linux:

```bash
source venv/bin/activate
```[cite: 6]

Activar el entorno virtual en Windows:

```bash
venv\Scripts\activate
```[cite: 6]

Definir las variables y arrancar en macOS o Linux:

```bash
export DATABASE_URL="postgresql://usuario:clave@localhost:5432/linkclub"
export JWT_SECRET="valor-largo-y-aleatorio"
uvicorn linkclub.main:app --app-dir src
```[cite: 6]

Verifica en [http://localhost:8000/health](http://localhost:8000/health): debe responder `{"status": "ok"}`[cite: 6].

### 7.3. Pruebas del backend

```bash
cd backend
PYTHONPATH=src pytest tests/ -v
```[cite: 6]

Las pruebas usan una base SQLite en memoria y una autenticación simulada; no requieren PostgreSQL[cite: 6].

### 7.4. Frontend (Flutter)

Requisitos previos: Flutter SDK (Dart 3+)[cite: 6, 7]. La aplicación declara un archivo `.env` como recurso (`assets: - .env` en `frontend/linkclub/pubspec.yaml`), por lo que debe existir en `frontend/linkclub/`[cite: 6, 7]. Define en él la variable `API_URL`; si se omite, la aplicación usa `https://api-linkclub.iscoutb.dev`[cite: 6, 7].

```bash
cd frontend/linkclub
flutter pub get
flutter run
```[cite: 6]

### 7.5. Limitaciones conocidas

Las divergencias entre el esquema, los modelos, el contrato y la implementación, así como los pendientes de deuda técnica, están registrados en la [lista de no conformidades](docs/arc42/lista_errores.md) y en la [Sección 11 de arc42](docs/arc42/11_riesgos_y_deuda_tecnica.md)[cite: 6].

---

## 8. Despliegue y URLs

| Componente | URL | Notas |
|---|---|---|
| API (backend) | `https://api-linkclub.iscoutb.dev` | Dominio institucional con HTTPS, desplegado en Dokploy (`clubsutb-api-fbpx22`, puerto `8000`)[cite: 6, 8, 9, 10] |
| Comprobación de estado | `https://api-linkclub.iscoutb.dev/health` | Responde estado del servicio y conectividad con PostgreSQL[cite: 6, 8] |
| Interfaz | No aplica | La interfaz es la aplicación móvil Flutter; no existe un sitio web publicado. La aplicación apunta por defecto a la URL de la API[cite: 6, 7] |

Verificación desde cualquier equipo:

```bash
curl -i [https://api-linkclub.iscoutb.dev/health](https://api-linkclub.iscoutb.dev/health)
```[cite: 6, 8]

### 8.1. Recrear el entorno desplegado

El entorno consta de un contenedor de aplicación (`clubsutb-api-fbpx22`), un contenedor PostgreSQL (`clubsutb-db-2m0uk5`) y un volumen de imágenes (`linkclub_uploads`)[cite: 6, 7, 8, 9, 10].

1. Crear un contenedor PostgreSQL (el despliegue vigente usa PostgreSQL 18) con una base `linkclub` y un volumen de datos propio[cite: 6, 7, 8, 9, 10]. Aplicar `backend/migrations/001_esquema_inicial.sql` (y asegurar la codificación URL de caracteres especiales como `#` → `%23` en `DATABASE_URL`)[cite: 6, 8].
2. Crear el servicio de la API a partir de este repositorio, rama `master`, con construcción por `Dockerfile` y contexto `./backend`[cite: 6, 7, 10]. El contenedor escucha en el puerto `8000`[cite: 6, 7, 10].
3. Definir en el servicio las variables `DATABASE_URL`, `JWT_SECRET`, `JWT_EXPIRES_DAYS`, `UPLOAD_DIR` y `CORS_ORIGINS` en **Environment Variables** (sin comillas ni espacios alrededor de `=`)[cite: 6, 7, 8]. Se configuran en la plataforma y nunca se versionan[cite: 6].
4. Montar un volumen persistente (`linkclub_uploads`) en `/app/uploads` para conservar las imágenes subidas[cite: 6, 7, 8, 10].
5. Asociar el dominio `https://api-linkclub.iscoutb.dev` con certificado automático (Let's Encrypt) al puerto `8000` del servicio[cite: 6, 8, 10].

Alternativa con compose para el servidor del laboratorio: `deploy/compose.lab.yaml` define la base y el backend con las variables correspondientes[cite: 6]. Antes de usarlo debe verificarse la configuración del volumen de `/app/uploads` y la aplicación de migraciones según la documentación del proyecto[cite: 6].

---

## 9. Estimación de Costo Mensual y Supuestos

El sistema opera sobre el servidor del laboratorio de la universidad y repositorios públicos, sin proveedores de pago ni tarjeta de crédito[cite: 6].

### 9.1. Desglose de Costos (Fase Académica / Beta / Producción Inicial)

| Componente / Servicio | Plataforma | Costo Estimado (USD / mes) | Supuestos Operativos |
| --- | --- | --- | --- |
| **Backend API (FastAPI)** | Contenedor Docker en Dokploy, servidor del laboratorio[cite: 6] | **$0.00**[cite: 6] | Una réplica con 1 GB de memoria y 2 CPU, sin arranque en frío[cite: 6, 10]. |
| **Base de datos** | Contenedor PostgreSQL en el mismo servidor[cite: 6] | **$0.00**[cite: 6] | Estimación de 2.000 estudiantes activos, unas 160.000 consultas al mes y unos 50 MB de datos mensuales[cite: 6]. |
| **Autenticación** | Implementada en la propia API[cite: 6] | **$0.00**[cite: 6] | Tokens JWT propios; sin cuotas de terceros[cite: 6]. |
| **Imágenes subidas** | Volumen Docker en el mismo servidor[cite: 6] | **$0.00**[cite: 6] | Limitado por el disco asignado[cite: 6]. |
| **Dominio y HTTPS** | Subdominio institucional con certificado automático[cite: 6] | **$0.00**[cite: 6] | Provisto por la plataforma de despliegue[cite: 6]. |
| **Integración continua** | GitHub Actions y SonarCloud[cite: 6] | **$0.00**[cite: 6] | Repositorio público, sin consumo de cuota de minutos[cite: 6]. |
| **TOTAL ESTIMADO** | — | **$0.00 USD / mes**[cite: 6] | Viable para desarrollo, pruebas y operación académica[cite: 6]. |

### 9.2. Punto de quiebre y escalabilidad

No existen cuotas de terceros que se agoten[cite: 6]. El límite lo marcan los recursos asignados al servidor (memoria, CPU y disco) y su disponibilidad[cite: 6].

* **Si se superan los recursos asignados:** solicitar al laboratorio mayor memoria, CPU o disco; el despliegue en contenedores permite ajustar los límites sin cambiar el código[cite: 6].
* **Si se necesita otro entorno:** el backend y la base de datos son portables a cualquier host con Docker; basta reconstruir los contenedores y restaurar un volcado de la base[cite: 6]. La migración desde Supabase está justificada en el [ADR 0007](docs/adr/0007-migracion-dokploy-postgresql.md)[cite: 6].
* **Costos no monetarios:** operación manual del despliegue y de los respaldos, y dependencia de un servidor único (ver la [Sección 11 de arc42](docs/arc42/11_riesgos_y_deuda_tecnica.md))[cite: 6].
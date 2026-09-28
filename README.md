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
| Frontend / App móvil | Flutter (Material 3, Adaptativo) | Implementado y funcional |
| Backend / API | FastAPI (Python) | Implementado (Esqueleto y Health Check) |
| Base de datos & BaaS | Supabase (PostgreSQL) | Configurado y conectado |
| Autenticación | Supabase Auth | Implementado (Login, SignUp y validación institucional) |
| Estilo arquitectónico | Hexagonal (Ports & Adapters) | En aplicación en módulos clave |

## 4. Estructura del repositorio

```text
/docs
  aspectos.md              # Aspectos de calidad, tabla de 8 columnas
  ficha_problema.md
  ia.md                    # Registro de uso de IA en el proyecto
  /api
    CHANGELOG.md
    contrato_api.md
    openapi.yaml

  /arc42
    01_introduccion_y_metas.md
    02_restricciones.md
    03_contexto_y_alcance.md
    04_estrategia_de_solucion.md
    05_vista_de_bloques.md
    06_vista_de_ejecucion.md
    07_vista_de_despliegue.md
    08_conceptos_transversales.md
    09_decisiones_de_diseno.md
    10_requisitos_de_calidad.md     # Árbol de utilidad + escenarios de calidad
    11_riesgos_y_deuda_tecnica.md
    12_glosario.md          # Listado de terminologías y conceptos usados dentro del proyecto
    lista_errores.md
    mapa-contextos-fundamentacion.md
    matriz_comparativa_estilos.md
    tabla_modulo.md
  /c4
    contexto.md            # Diagrama C4: contexto y contenedores
  /adr
    0001-hexagonal.md      # Decisión de estilo arquitectónico
    0002-ajuste-contextos-publicaciones.md
    0003- integacion rest openapi.md
    0003-API.md
    0004-despliegue-base-de-datos.md    

/backend
  requirements.txt
  Dockerfile
  /src/linkclub
    main.py
    /adapters/inbound/api
      health_router.py     # Endpoint /health
    /adapters/outbound/persistence
      in_memory_status_adapter.py
    /application/ports
      inbound_health_port.py
      outbound_status_port.py
    /application/use_cases
      check_health.py
  /tests
    test_health.py

/frontend
  /linkclub
    pubspec.yaml
    .env.example
    /lib
      main.dart
      /core/theme
        theme_controller.dart
      /presentation
        clubs_page.dart
        login_screen.dart
        signup_screen.dart

README.md

```

## 5. Equipo

| Integrante | GitHub |
| --- | --- |
| Hollman De Orta | @deortahollman-star |
| Josh Ortega | @Josh4OP |
| Diego Ramos | @devZavod |
| Luis Salas | @Luis-Salas-Reyes |

> Los 4 integrantes están añadidos como colaboradores del repositorio en GitHub.

## 6. Estado del proyecto

**En fase activa de desarrollo, integración y despliegue.** Se han consolidado los módulos de autenticación segura en Flutter conectados a Supabase Auth, el catálogo de clubes (hardoceado, por ahora) con menú lateral (Drawer) adaptativo, el bloqueo de dependencias en Android para pipelines limpios en SonarCloud, y los adaptadores base en FastAPI.

---

*Curso de Arquitectura de Software — Universidad Tecnológica de Bolívar (UTB)*

## 7. Cómo arrancar

### 7.1. Backend (FastAPI)

Requisitos previos: Python 3.10+

```bash
cd backend
python -m venv venv

# Activar el entorno virtual
source venv/bin/activate     # macOS / Linux
venv\Scripts\activate        # Windows

pip install -r requirements.txt
uvicorn linkclub.main:app --app-dir src

```

Verifica en [http://localhost:8000/health](http://localhost:8000/health?utm_source=gemini) — debe responder `{"status": "ok"}`.

### 7.2. Frontend (Flutter)

Requisitos previos: Flutter SDK (Dart 3+)

```bash
cd frontend/linkclub
# Configura tu archivo .env basado en .env.example con tus credenciales de Supabase
flutter pub get
flutter run

```

---

## 8. Estimación de Costo Mensual y Supuestos

Con base en la estructura de precios oficial de **Supabase** y servicios de infraestructura cloud asociados para la operación del sistema, se presenta la siguiente estimación financiera y técnica:

### 8.1. Desglose de Costos (Fase Académica / Beta / Producción Inicial)

| Componente / Servicio | Proveedor / Plan | Costo Estimado (USD / mes) | Supuestos Operativos |
| --- | --- | --- | --- |
| **Base de Datos y BaaS** | Supabase (Free Tier) | **$0.00** | Hasta 500 MB de base de datos relacional, 1 GB de almacenamiento de archivos, y un límite de 50,000 usuarios activos mensuales (MAU). |
| **Autenticación y Seguridad** | Supabase Auth | **$0.00** | Incluido dentro de las cuotas del plan gratuito del ecosistema BaaS con políticas RLS (Row Level Security) activas. |
| **Backend API (FastAPI)** | Render / Railway (Free Tier) | **$0.00** | Despliegue mediante contenedor Docker en capa gratuita con restricciones de inactividad temporal (*spin-down*) ante ausencia de peticiones. |
| **Dominio y DNS** | GitHub Pages / Vercel | **$0.00** | Uso de subdominios predeterminados provistos por las plataformas de integración continua. |
| **TOTAL ESTIMADO** | — | **$0.00 USD / mes** | **Viabilidad óptima para fases de desarrollo, pruebas y despliegue académico.** |

### 8.2. Supuestos de Escalabilidad a Plan Pro (Escenario de Producción Masiva Institucional)

Si el sistema se despliega a nivel general para toda la comunidad de la Universidad Tecnológica de Bolívar (superando las métricas del plan gratuito), los costos proyectados según la tabla oficial de Supabase y servicios cloud estándar ascienden a:

* **Supabase Pro Plan:** **$25.00 USD / mes** (Base que incluye hasta 8 GB de base de datos, 100 GB de almacenamiento, respaldos diarios automáticos y hasta 100,000 MAU).
* **Hosting Backend Escalado:** **$7.00 USD / mes** (Instancia dedicada pequeña para mantener el servicio de FastAPI activo 24/7 sin latencia de arranque).
* **Costo Proyectado en Escala:** **~$32.00 USD / mes**.

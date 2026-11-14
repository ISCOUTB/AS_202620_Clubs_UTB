# LinkClub - Frontend (Aplicación Móvil)

> Repositorio académico: `AS_202620_Clubs_UTB` — Organización `ISCOUTB`  
> Proyecto del curso **Arquitectura de Software** (NRC: 1495), Universidad Tecnológica de Bolívar (UTB) — 2026-20

Aplicación móvil multiplataforma desarrollada en **Flutter** que constituye la capa de presentación de **LinkClub**, la plataforma centralizada para la gestión y difusión de avisos, eventos, novedades y grupos estudiantiles de la **Universidad Tecnológica de Bolívar (UTB)**.

---

## Equipo de Desarrollo

| Integrante | Usuario GitHub |
| --- | --- |
| Hollman De Orta | `@deortahollman-star` |
| Josh Ortega | `@Josh4OP` |
| Diego Ramos | `@devZavod` |
| Luis Salas | `@Luis-Salas-Reyes` |

---

## Estado y Funcionalidades Implementadas

* **Autenticación Institucional y Sesión Segura (JWT):**
  * Flujos completos de inicio de sesión (`LoginScreen`) y registro (`SignUpScreen`) integrados con la API REST en FastAPI (`/auth/login` y `/auth/registro`).
  * Validación en cliente de correos institucionales (`@utb.edu.co`), códigos estudiantiles (`^T\d{7,8}$`) y contraseñas de mínimo 8 caracteres.
  * Almacenamiento cifrado del token de acceso mediante `flutter_secure_storage` con verificación automática de sesión activa al iniciar la aplicación.
* **Cliente HTTP Centralizado e Idempotencia (`ApiClient`):**
  * Configurado sobre **Dio** apuntando al backend desplegado (`https://api-linkclub.iscoutb.dev`).
  * Interceptores automáticos para adjuntar la cabecera `Authorization: Bearer <token>` y generar cabeceras `Idempotency-Key` (UUID v4) en solicitudes `POST` autenticadas.
* **Feed Institucional y Editor de Publicaciones en Markdown:**
  * Visualización del feed general (`FeedScreen`) con actualización *pull-to-refresh* y renderizado enriquecido mediante `flutter_markdown`.
  * Pantalla de creación (`CreatePublicationScreen`) con barra de herramientas de formato (negrita, cursiva, títulos, hipervínculos, listas), pestaña de **Vista Previa en tiempo real** y carga de imágenes desde dispositivo (`POST /recursos/upload` en móvil y Web) o mediante URL externa.
* **Navegación Principal y Catálogo de Clubes (`ClubsPage`):**
  * Barra de navegación inferior (`BottomNavigationBar`) estructurada en cuatro módulos: **Feed**, **Eventos**, **Clubes** y **Ajustes**.
  * Explorador de clubes estudiantiles (`ClubsListScreen`) con barra de búsqueda y vista detallada (`ClubDetailPage`) con información de miembros, líder, horario y ubicación.
* **Sistema de Diseño Material 3 y Tema Adaptativo:**
  * Paleta personalizada (`AppTheme`) con soporte para modo claro, modo oscuro y detección automática del sistema, persistido localmente con `ThemeController` (`shared_preferences`).

---

## Estructura del Directorio (`frontend/linkclub/`)

```text
frontend/linkclub/
├── .env.example                         # Plantilla de variables de entorno
├── pubspec.yaml                         # Dependencias y configuración de assets
└── lib/
    ├── core/
    │   ├── network/
    │   │   └── api_client.dart          # Instancia Dio, interceptores JWT e Idempotency-Key
    │   └── theme/
    │       ├── app_theme.dart           # Definición de temas Material 3 (Light / Dark)
    │       └── theme_controller.dart    # Gestión y persistencia del modo de tema
    ├── data/
    │   ├── auth_repository.dart         # Consumo de endpoints /auth/login y /auth/registro
    │   └── publication_repository.dart  # Consumo de /publicaciones y /recursos/upload
    ├── presentation/
    │   ├── clubs_details.dart           # Ficha detallada de cada club universitario
    │   ├── clubs_page.dart              # Contenedor principal (BottomNavigationBar), catálogo y ajustes
    │   ├── create_publication_screen.dart # Editor Markdown con vista previa y carga multimedia
    │   ├── feed_screen.dart             # Muro principal de publicaciones institucionales
    │   ├── login_screen.dart            # Pantalla de inicio de sesión
    │   └── signup_screen.dart           # Pantalla de registro de estudiantes UTB
    └── main.dart                        # Punto de entrada, carga de .env y enrutamiento inicial

```

---

## Configuración y Ejecución

### Requisitos Previos

- **Flutter SDK** (compatible con Dart 3+).
- Emulador Android/iOS, navegador Web o dispositivo físico con depuración USB habilitada.

### 1. Variables de Entorno (`.env`)

Crea un archivo `.env` en la raíz del módulo (`frontend/linkclub/.env`) tomando como base `.env.example` (este archivo está ignorado en Git por seguridad):

```env
API_URL=https://api-linkclub.iscoutb.dev
```

> **Nota para desarrollo local:** Si ejecutas el backend FastAPI localmente en el puerto `8000`, puedes apuntar temporalmente a `http://10.0.2.2:8000` (emulador Android) o `http://localhost:8000` (Web/Desktop). Si se omite la variable, la aplicación utiliza por defecto `https://api-linkclub.iscoutb.dev`.

### 2. Instalación de Dependencias

Desde la carpeta `frontend/linkclub/`, ejecuta:

```bash
flutter pub get
```

### 3. Ejecución de la Aplicación

Con tu dispositivo o emulador activo, inicia la aplicación:

```bash
flutter run
```

# LinkClub — Frontend (Aplicación Móvil)

Aplicación móvil desarrollada en **Flutter** para la plataforma centralizada de gestión de clubes estudiantiles de la **Universidad Tecnológica de Bolívar (UTB)**. Este módulo constituye la interfaz de usuario (capa de presentación) del sistema integrado bajo el curso de **Arquitectura de Software (2026-2)**.

---

## 🚀 Características Principales

* **Autenticación Segura con Supabase Auth:** Módulos de inicio de sesión (`LoginScreen`) y registro (`SignUpScreen`) conectados de forma asíncrona a Supabase.
* **Validación de Identidad Institucional:** Validación estricta en formularios para correos institucionales (`@utb.edu.co`) y códigos estudiantiles (formato `T` seguido de 7 u 8 dígitos).
* **Catálogo e Interfaz de Clubes (`ClubsPage`):** Visualización interactiva de los clubes disponibles con buscador en tiempo real.
* **Menú Lateral (Drawer) Adaptativo:** Acceso rápido al perfil, configuraciones, interruptor de modo oscuro/claro y cierre de sesión seguro.
* **Diseño Material 3:** Interfaz limpia, optimizada tanto para modo claro como para modo oscuro, con inputs y componentes adaptativos.

---

## 📁 Estructura del Directorio (`lib/`)

```text
lib/
├── core/
│   └── theme/          # Definición de temas claro y oscuro (AppTheme)
├── presentation/       # Pantallas y vistas de la aplicación
│   ├── clubs_page.dart # Vista principal del catálogo de clubes y Drawer
│   ├── login_screen.dart # Autenticación de usuarios existentes
│   └── signup_screen.dart # Registro y persistencia inicial en base de datos
└── main.dart           # Punto de entrada, inicialización de Supabase y rutas
```

---

## ⚙️ Configuración y Ejecución

### Requisitos Previos
* Tener instalado **Flutter SDK** (versión compatible con Dart 3+).
* Configurar las variables de entorno para la conexión con Supabase.

### 1. Variables de Entorno (`.env`)
Crea un archivo `.env` en la raíz del proyecto (`frontend/linkclub/.env`) especificando tus credenciales (asegúrate de que este archivo no se suba al control de versiones por seguridad):

```env
SUPABASE_URL=tu_url_de_supabase
SUPABASE_ANON_KEY=tu_clave_anonima_de_supabase
```

### 2. Instalación de Dependencias
Ejecuta el siguiente comando en tu terminal dentro de la ruta `frontend/linkclub/`:

```bash
flutter pub get
```

### 3. Ejecución de la Aplicación
Con tu emulador activo o dispositivo físico conectado, ejecuta:

```bash
flutter run
```

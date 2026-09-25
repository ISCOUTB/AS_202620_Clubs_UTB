# LinkClub - Frontend (Módulo Móvil / Web)

Repositorio oficial del frontend de **LinkClub**, plataforma centralizada para la gestión de avisos, eventos y noticias de los clubes estudiantiles de la **Universidad Tecnológica de Bolívar (UTB)**. 

Este módulo forma parte del proyecto integrador del curso **Arquitecturas de Software (NRC: 1495, 2026-2)** de la Facultad de Ingeniería de Sistemas y Computación.

---

## Estado Actual (Lo realizado)

El frontend está desarrollado en **Flutter**, implementando una arquitectura modular basada en vistas y componentes reutilizables con soporte nativo para **Material 3** y adaptabilidad a temas claros y oscuros.

*   **Autenticación y Seguridad con Supabase Auth:**
    *   `LoginScreen`: Pantalla de inicio de sesión con validación de credenciales en tiempo real, manejo de estados de carga y encriptación de errores del servidor a mensajes claros en español.
    *   `SignUpScreen`: Registro de nuevos usuarios estudiantes con validaciones estrictas (formato de correo institucional `@utb.edu.co` y contraseñas seguras de al menos 8 caracteres).
    *   Gestión de variables de entorno mediante `flutter_dotenv` para aislar las credenciales públicas (`publishableKey`) del repositorio.
*   **Interfaz de Usuario Principal (`ClubsPage`):**
    *   Vista interactiva de exploración de clubes universitarios (Programación, Robótica, Música, Deportes, Fotografía) con buscador dinámico y tarjetas adaptativas.
    *   **Drawer de Navegación Integrado:** Panel lateral limpio que incluye el logotipo institucional, control de cambio rápido de modo oscuro/claro, accesos directos a configuraciones y botón de cierre de sesión seguro conectado a la sesión de Supabase.

---

## 🛠️ Tecnologías y Herramientas

*   **Framework:** Flutter (compatible con Web y dispositivos móviles).
*   **Lenguaje:** Dart.
*   **Backend as a Service (BaaS):** Supabase (Autenticación y Base de Datos).
*   **Gestión de Estado y Estilos:** StatefulWidget local, Material 3 Design System.

---

## ⚙️ Configuración y Ejecución Local

Para levantar este entorno de desarrollo localmente de forma segura, sigue estos pasos:

1. **Clonar el repositorio principal y navegar a la ruta del frontend:**
   ```bash
   cd frontend/linkclub

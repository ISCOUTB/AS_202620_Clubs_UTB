### Privacidad y protección de datos personales

Este documento describe qué datos personales trata **LinkClub**, con qué finalidad, dónde se almacenan, quién tiene acceso a ellos y qué controles técnicos existen, manteniéndose alineado con el código vigente y con la [tabla de amenazas](./tabla_amenazas.md).

#### 1. Datos personales que se tratan

| Dato | Origen | Finalidad | Dónde se almacena | Visibilidad |
| ------ | ------ | ------ | ------ | ------ |
| **Nombre completo** | Registro / edición de perfil | Identificar al usuario en su perfil y como autor en publicaciones/eventos | PostgreSQL, tabla `usuarios` | Público (se muestra como `autor_nombre` en publicaciones y eventos) |
| **Matrícula institucional** | Registro | Identificador único del estudiante (`PK`) y sujeto (`sub`) del token JWT | PostgreSQL, tabla `usuarios` | Privado en el feed público (oculto en tarjetas públicas, **NC-18**) |
| **Correo institucional (`@utb.edu.co`)** | Registro | Autenticación y verificación de pertenencia a la comunidad UTB | PostgreSQL, tabla `usuarios` | Privado (visible solo para el propio usuario en `/usuarios/me`) |
| **Contraseña** | Registro / cambio de clave | Autenticación de sesión | PostgreSQL, columna `password_hash` | Privado; almacenado exclusivamente como hash adaptativo `bcrypt` (**NC-05**) |
| **Descripción y foto de perfil** | Edición de perfil (opcional) | Personalización de la cuenta del usuario | PostgreSQL (`usuarios`) y volumen `linkclub_uploads` | Visible en el perfil del usuario |
| **Justificación de solicitud de admin** | Solicitud de rol `ADMIN_CLUB` | Evaluar la legitimidad del solicitante como líder de un club | PostgreSQL, tabla `solicitudes_admin_club` | Privado (visible solo para el solicitante y `SUPERADMIN`) |
| **Token de sesión (JWT)** | Inicio de sesión | Autorizar operaciones protegidas | Almacenamiento cifrado del dispositivo (`flutter_secure_storage`) | Privado en el dispositivo del usuario |
| **Publicaciones, eventos y asistencias** | Creados por usuarios autorizados | Difundir actividades de clubes y gestionar confirmación de asistencia | PostgreSQL (`publicaciones`, `eventos`, `asistencias`) | Público (o restringido a miembros del club si `solo_club = true`) |
| **Imágenes adjuntas** | Subidas por usuarios autorizados | Ilustrar publicaciones o perfil | Volumen Docker `linkclub_uploads`, servidas en `/static/{archivo}` | Público para quien conozca la URL generada con UUIDv4 |
| **Clave de idempotencia** | Generada por la app móvil | Evitar duplicados ante reintentos de red | PostgreSQL, tabla `publicaciones` | Privado; metadato técnico sin valor identificativo directo |

La aplicación móvil solicita permiso de cámara y galería únicamente cuando el usuario decide adjuntar una imagen desde su dispositivo.

#### 2. Principio de minimización

LinkClub solicita únicamente nombre, matrícula, correo institucional (`@utb.edu.co`) y contraseña. No recopila número de teléfono, documento de identidad, ubicación GPS, lista de contactos ni identificadores publicitarios. No integra SDKs de analítica ni publicidad de terceros.

#### 3. Quién accede a los datos

* **Infraestructura propia:** los datos residen en el servidor del laboratorio de la universidad administrado con Dokploy (`panel.iscoutb.dev`). Tras el [ADR 0007](../adr/0007-migracion-dokploy-postgresql.md) no se comparten datos con proveedores externos de base de datos ni de autenticación.
* **Aislamiento de red:** PostgreSQL (`clubsutb-db-2m0uk5`) opera exclusivamente en la red privada interna `dokploy-network` sin puertos expuestos a Internet.
* **Acceso administrativo:** únicamente los 4 integrantes del equipo técnico con credenciales de Dokploy tienen acceso operativo al servidor y a la base de datos.
* **Formularios externos (`ms_forms_url`):** cuando un estudiante decide inscribirse formalmente en un club, la app abre el enlace institucional de Microsoft Forms de la UTB en el navegador del dispositivo, sujeto a las políticas institucionales de la universidad.

#### 4. Seguridad de los datos

| Control | Estado |
| ------ | ------ |
| Cifrado en tránsito mediante HTTPS | **Implementado** (certificado Let's Encrypt en el proxy inverso de Dokploy para `api-linkclub.iscoutb.dev`) |
| Token JWT cifrado en el dispositivo | **Implementado** (`flutter_secure_storage`) |
| Autenticación y control de acceso por rol (RBAC) | **Implementado** (`require_auth`, `ESTUDIANTE`, `ADMIN_CLUB`, `SUPERADMIN`, escenario **U3**) |
| Secretos en variables de entorno sin valores por defecto | **Implementado** (`JWT_SECRET` obligatorio con validación *fail-fast*, **A02**) |
| Hash seguro de contraseñas | **Implementado** (`bcrypt`, **A08**) |
| Validación y límite de carga de imágenes | **Implementado** (`require_auth`, bloqueo de `.svg` y límite de 5 MB en `recurso_router.py`, **A09**) |
| Sanitización de registros de red en cliente móvil | **Implementado** (eliminado volcado de cuerpos HTTP con credenciales, **NC-14**) |
| Límite de intentos de inicio de sesión (*rate-limiting*) | **Pendiente** (**A07**) |
| Respaldo automatizado externo de BD y volumen | **Pendiente** (**A05**) |
| Eliminación automática de metadatos EXIF en imágenes | **Pendiente** (mejora opcional sobre **A09**) |

#### 5. Visibilidad de identificadores

Para proteger la privacidad de los estudiantes en las vistas públicas del feed y de eventos, la API resuelve el nombre del autor (`autor_nombre`) a partir de `usuarios.matricula` y la aplicación móvil muestra únicamente el nombre y el rol/club, evitando exponer la matrícula estudiantil en tarjetas públicas (**A12 / NC-18**).

#### 6. Conservación y derechos del titular (Acceso, Rectificación y Supresión)

* **Acceso y rectificación:** cualquier usuario autenticado puede consultar y actualizar sus datos personales (`nombre`, `descripcion`, `foto_perfil_url` y contraseña) mediante `GET /usuarios/me`, `PATCH /usuarios/me` y `POST /usuarios/me/password` desde la pantalla de perfil en Flutter.
* **Derecho de supresión (eliminación de cuenta):** el usuario puede eliminar su cuenta de forma autónoma mediante `DELETE /usuarios/me`. La integridad referencial de PostgreSQL (`ON DELETE CASCADE`) elimina automáticamente sus publicaciones, eventos, asistencias y solicitudes asociadas.
* **Canal de contacto:** repositorio oficial `ISCOUTB/AS_202620_Clubs_UTB` / equipo responsable del proyecto en la Universidad Tecnológica de Bolívar.

#### 7. Autorización del tratamiento

**Pendiente:** incorporar en la pantalla de registro (`RegisterScreen`) un aviso breve explícito con la finalidad institucional del tratamiento y casilla de aceptación antes de enviar `POST /auth/registro`.

#### 8. Limitaciones conocidas y plan

| Limitación | Amenaza relacionada | Responsable | Estado |
| ------ | ------ | ------ | ------ |
| Contraseñas sin hash | **A08** | Josh Ortega | **Mitigada** (`bcrypt`) |
| Matrícula visible en el feed público | **A12** | Hollman De Orta | **Mitigada** (se expone `autor_nombre`) |
| Subida de imágenes sin autenticación, sin límite o con SVG | **A09** | Hollman De Orta | **Mitigada** (`require_auth`, 5 MB, sin SVG; EXIF pendiente) |
| Sin endpoints de gestión de perfil ni eliminación de cuenta | **A06** | Luis Salas | **Mitigada** (`GET/PATCH/DELETE /usuarios/me`) |
| Sin respaldo automático de base de datos ni volumen | **A05** | Diego Ramos | **Pendiente** |
| Sin límite de intentos de inicio de sesión | **A07** | Josh Ortega | **Pendiente** |
| Sin aviso explícito de aceptación de tratamiento en registro | — | Equipo LinkClub | **Pendiente** |
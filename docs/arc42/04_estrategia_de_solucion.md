### 4. Estrategia de solución

La arquitectura de **LinkClub** prioriza la autonomía operativa, el aislamiento de la lógica de negocio y la coherencia estricta entre el cliente móvil y el servidor mediante un contrato formal verificable.

#### 4.1. Decisiones tecnológicas fundamentales

* **Cliente móvil nativo multiplataforma:** Flutter con Material 3, gestión centralizada de red mediante `Dio` y estado de sesión reactivo (`SessionController`) respaldado por `flutter_secure_storage`.
* **Backend monolítico modular con arquitectura hexagonal ([ADR 0001](../adr/0001-hexagonal.md), [ADR 0008](../adr/0008-no-extraer-publicaciones.md)):** Un único servicio FastAPI organiza el núcleo (`domain/` y `application/`) independiente de los adaptadores HTTP (`adapters/inbound/api/`) y de persistencia/autenticación (`adapters/outbound/`).
* **Infraestructura autónoma en contenedores ([ADR 0007](../adr/0007-migracion-dokploy-postgresql.md)):** PostgreSQL 18 y la API FastAPI operan en contenedores Docker administrados por Dokploy dentro de la red privada del servidor del laboratorio, eliminando dependencias externas (BaaS) y costos recurrentes.
* **Contrato API-first ([ADR 0003](../adr/0003-%20integacion%20rest%20openapi.md)):** `docs/api/openapi.yaml` (`v3.1.0`) gobierna la evolución de todos los endpoints y se valida automáticamente en cada Pull Request.

#### 4.2. Estrategia para alcanzar las metas de calidad

| Meta de calidad | Estrategia arquitectónica aplicada |
| ------ | ------ |
| **Disponibilidad (U2)** | Despliegue en servidor propio con reinicio automático en Dokploy, eliminación de dependencias externas en tiempo de ejecución y endpoint `GET /health` que verifica activamente PostgreSQL mediante `SELECT 1`. |
| **Rendimiento (U1)** | Comunicación interna de baja latencia entre contenedores en `dokploy-network`, ausencia de saltos entre microservicios y filtrado eficiente sobre consultas indexadas en PostgreSQL. |
| **Seguridad (U3)** | Contraseñas almacenadas únicamente con hash `bcrypt`, tokens JWT firmados con `HS256` (`JWT_SECRET` obligatorio al arrancar), autorización basada en roles (`ESTUDIANTE`, `ADMIN_CLUB`, `SUPERADMIN`) y validación estricta de entradas con Pydantic (`extra="forbid"`). |
| **Mantenibilidad (C1, C2, C3)** | Separación de puertos y adaptadores en el núcleo del backend, validación automatizada de esquema con `Draft202012Validator`, `Spectral` y `oasdiff`, y análisis estático continuo con SonarCloud. |
| **Usabilidad y resiliencia (R1, R2)** | Inyección automática de `Idempotency-Key` en peticiones `POST` desde el cliente móvil para evitar duplicados ante reintentos de red, mensajes de error uniformes (`{"detail": "..."}`) y modo de vista previa estudiante para administradores. |

#### 4.3. Descomposición funcional (Contextos delimitados)

El dominio se divide en tres contextos internos bajo la regla de dueño único ([ADR 0002](../adr/0002-ajuste-contextos-publicaciones.md), detallada en [tabla_modulo.md](./tabla_modulo.md)):

1. **Usuarios:** Identidad institucional (matrícula, correo), credenciales, emisión/validación de JWT, perfil personal y solicitudes de rol de administrador.
2. **Clubes:** Directorio de clubes estudiantiles, metadatos públicos, estado de convocatoria y enlace institucional de inscripción (`ms_forms_url`).
3. **Publicaciones y Eventos:** Contenido generado en nombre de un club (`aviso`, `encuesta`, `noticia` y programación de `eventos` con control de asistencia), referenciando `club_id` y `autor_matricula` sin duplicar datos.

#### 4.4. Estado de aplicación de la estrategia

| Aspecto | Estado |
| ------ | ------ |
| **Arquitectura hexagonal** | Aplicada en salud (`CheckHealthUseCase`), creación de publicaciones (`CrearPublicacionUseCase`), dominio de clubes/publicaciones y prototipo de mensajería. Desviaciones declaradas en routers que acceden directamente a la sesión SQLAlchemy para operaciones CRUD y RBAC (ver [Sección 5.3](./05_vista_de_bloques.md)). |
| **Persistencia en PostgreSQL** | Operativa de extremo a extremo para `usuarios`, `clubes` (con semilla inicial idempotente en `main.py` y migraciones `001` y `002`), `publicaciones`, `eventos`, `asistencias` y `solicitudes_admin_club`. |
| **Autenticación y autorización propia** | Operativa: registro con hash `bcrypt`, validación de matrícula única, inicio de sesión JSON y OAuth2, validación de token con `JWT_SECRET` obligatorio y control de permisos por rol (`403 Forbidden`) en clubes, publicaciones, eventos y consola Superadmin. |
| **Contrato OpenAPI** | Verificado en el pipeline (`v3.1.0`) con 100 % de las rutas y esquemas del código alineados con `docs/api/openapi.yaml`. |
| **Despliegue** | Operativo en Dokploy (`[https://api-linkclub.iscoutb.dev](https://api-linkclub.iscoutb.dev)`) con PostgreSQL 18 y volumen persistente `linkclub_uploads`. |
# Tabla de dueño único

El presente documento establece la relación entre los contextos delimitados de LinkClub y los datos que cada uno administra en exclusiva, con el objetivo de evitar duplicidad de responsabilidades y facilitar la organización, el mantenimiento y la evolución del sistema.

> Esta tabla usa los tres contextos vigentes definidos en [`docs/arc42/mapa-contextos-fundamentacion.md`](mapa-contextos-fundamentacion.md) y en la [sección 8 de arc42](08_conceptos_transversales.md). En el corte 1 se habían planteado cuatro módulos (Usuario, Clubes, Actividades, Notificaciones); Actividades y Notificaciones se fusionaron en el contexto **Publicaciones** — el porqué de ese ajuste está documentado en [ADR 0002](../adr/0002-ajuste-contextos-publicaciones.md).

| Contexto | Descripción | Datos administrados (dueño único) | Referencias a otros contextos (no copia) | Operaciones principales |
| --- | --- | --- | --- | --- |
| **Usuarios** | Gestiona la identidad y el perfil de cada persona dentro del sistema. | ID (matrícula), nombre, correo, hash de contraseña (`password_hash`), rol | — (no referencia a otros contextos; es el contexto raíz de identidad) | Registrar usuario, iniciar sesión (emisión/validación JWT), consultar y actualizar perfil |
| **Clubes** | Gestiona la existencia de cada club y su membresía. | ID (`UUID`), nombre, categoría, descripción, imagen, lista de membresías (con rol de administrador de club) | ID de usuario por cada miembro/administrador (identidad, ver Usuarios) | Listar/buscar clubes, consultar detalle, crear/actualizar clubes y gestionar membresía |
| **Publicaciones** | Gestiona avisos, encuestas y noticias emitidos en nombre de un club. | ID (`UUID`), tipo (`aviso` / `encuesta` / `noticia`), título, contenido, opciones, `imagen_url`, clave de idempotencia (`autor_id`, `idempotency_key`), fecha | `club_id` (`UUID` del club, ver Clubes); `autor_id` (matrícula del usuario, ver Usuarios) | Crear (idempotente), consultar y listar publicaciones por club o feed |

## Regla de dueño único

Ningún contexto almacena una copia de un dato que pertenece a otro: solo guarda la referencia (ID) al dueño real. Por ejemplo, Publicaciones no repite el nombre del club ni el perfil del autor; los consulta por referencia cuando los necesita. Esta es la misma regla registrada en el mapa de contextos y es el criterio usado para detectar violaciones en [`lista_errores.md`](lista_errores.md) (p. ej. NC-01: la app móvil hoy tiene datos de clubes hardcodeados en `clubs_page.dart` en vez de consumirlos del contexto Clubes por referencia).

## Cobertura frente al código actual

Los tres contextos delimitados cuentan con representación en el backend bajo `backend/src/linkclub/`:

* **Usuarios:** implementado en `adapters/inbound/api/auth_router.py`, `adapters/inbound/api/auth_dependency.py`, `adapters/outbound/auth/local_jwt_adapter.py` y `adapters/outbound/postgres/usuario_model.py` (registro con hash `bcrypt`, inicio de sesión OAuth2 y emisión/validación de JWT). Pendiente: endpoint `GET /usuarios/me`.
* **Clubes:** implementado con entidad de dominio `domain/club.py`, casos de uso `application/use_cases/consultar_clubes.py` (`ListarClubesUseCase`, `ObtenerClubUseCase`), router `adapters/inbound/api/club_router.py` y modelo ORM `adapters/outbound/postgres/club_model.py` (actualmente servido mediante el adaptador temporal `InMemoryClubAdapter`). Pendiente: persistencia en PostgreSQL de clubes y gestión de membresías.
* **Publicaciones:** implementado de extremo a extremo con entidad `domain/publicacion.py`, caso de uso `application/use_cases/crear_publicacion.py`, router `adapters/inbound/api/publicacion_router.py`, modelo `adapters/outbound/postgres/publicacion_model.py` y repositorio `adapters/outbound/postgres/publicacion_repository.py` (soporta `aviso`, `encuesta`, `noticia`, imágenes asociadas e idempotencia aislada por autor).
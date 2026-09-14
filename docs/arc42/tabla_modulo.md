# Tabla de dueño único

[#tabla-de-dueño-único](#tabla-de-dueño-único)

El presente documento establece la relación entre los contextos delimitados de LinkClub y los datos que cada uno administra en exclusiva, con el objetivo de evitar duplicidad de responsabilidades y facilitar la organización, el mantenimiento y la evolución del sistema.

> Esta tabla usa los tres contextos vigentes definidos en [`docs/arc42/mapa-contextos-fundamentacion.md`](mapa-contextos-fundamentacion.md) y en la [sección 8 de arc42](08_conceptos_transversales.md). En el corte 1 se habían planteado cuatro módulos (Usuario, Clubes, Actividades, Notificaciones); Actividades y Notificaciones se fusionaron en el contexto **Publicaciones** — el porqué de ese ajuste está documentado en [ADR 0002](../adr/0002-ajuste-contextos-publicaciones.md).

| Contexto | Descripción | Datos administrados (dueño único) | Referencias a otros contextos (no copia) | Operaciones principales |
| --- | --- | --- | --- | --- |
| **Usuarios** | Gestiona la identidad y el perfil de cada persona dentro del sistema. | ID, nombre, correo, matrícula, rol | — (no referencia a otros contextos; es el contexto raíz de identidad) | Crear, consultar, actualizar perfil y rol |
| **Clubes** | Gestiona la existencia de cada club y su membresía. | ID, nombre, categoría, descripción, imagen, lista de membresías (con rol de administrador de club) | ID de usuario por cada miembro/administrador (identidad, ver Usuarios) | Crear, actualizar y eliminar clubes; gestionar membresía |
| **Publicaciones** | Gestiona avisos, eventos y noticias emitidos en nombre de un club. | ID, tipo (aviso / evento / noticia), contenido, fecha, lugar (si aplica) | `club_id` (identidad del club, ver Clubes); `autor_id` (identidad del usuario, ver Usuarios) | Crear, consultar, actualizar y eliminar publicaciones |

## Regla de dueño único

Ningún contexto almacena una copia de un dato que pertenece a otro: solo guarda la referencia (ID) al dueño real. Por ejemplo, Publicaciones no repite el nombre del club ni el perfil del autor; los consulta por referencia cuando los necesita. Esta es la misma regla registrada en el mapa de contextos y es el criterio usado para detectar violaciones en [`lista_errores.md`](lista_errores.md) (p. ej. NC-01: la app móvil hoy tiene datos de clubes hardcodeados en `clubs_page.dart` en vez de consumirlos del contexto Clubes por referencia).

## Cobertura frente al código actual

Al momento de esta entrega, el único contexto con entidad de dominio implementada es **Publicaciones** (`backend/src/linkclub/domain/publicacion.py`, `application/use_cases/crear_publicacion.py`). Los contextos **Usuarios** y **Clubes** están definidos en la documentación pero aún no tienen entidades ni endpoints propios en el backend — su implementación queda pendiente para el siguiente corte.

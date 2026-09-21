# Reajuste de límites: fusión de Actividades y Notificaciones en el contexto Publicaciones

## Estado
Aceptado

## Fecha
13/09/2026

## Contexto
En el corte 1 (S5) el equipo pensaba el sistema en cuatro módulos: **Usuario, Clubes, Actividades y Notificaciones** (ver `docs/arc42/tabla_modulo.md`, versión de esa entrega). Al construir el mapa de contextos delimitados para S6 (`docs/arc42/mapa-contextos-fundamentacion.md`, sección 8.2 de arc42), el equipo encontró que **Actividades** y **Notificaciones** no cumplían el criterio de "dueño único de un dato de negocio" que sí cumplen Clubes y Usuarios:

- **Actividades** (avisos, eventos, noticias) no administra ningún dato que no dependa por completo de Club (quién publica) y de Usuario (quién es el autor). No tiene identidad de negocio propia más allá de ser "algo publicado en nombre de un club".
- **Notificaciones**, tal como estaba planteado, no era un dato con dueño propio sino una *proyección de lectura* sobre lo que ya existe en Actividades: no hay una entidad "Notificación" con reglas de negocio propias, sino una forma de consumir publicaciones ya existentes.
- El código real construido hasta la fecha (`backend/src/linkclub/domain/publicacion.py`, `application/use_cases/crear_publicacion.py`) ya había convergido de forma natural hacia una única entidad `Publicacion`, sin que existiera una entidad `Actividad` o `Notificacion` separada. La tabla de módulos de S5 había quedado desactualizada frente a lo que el equipo ya estaba implementando.

Esto generó una inconsistencia entre `tabla_modulo.md` (4 módulos) y el mapa de contextos nuevo (3 contextos: Clubes, Publicaciones, Usuarios), señalada como punto abierto en `docs/arc42/08_conceptos_transversales.md` (sección 8.3).

## Alternativas

### Mantener Actividades y Notificaciones como contextos independientes
Conservaría la fidelidad con la tabla de módulos del corte 1, pero obligaría a inventar una frontera artificial: Notificaciones tendría que declarar como "propios" datos que en realidad pertenecen a Actividades (contenido del aviso/evento), violando la misma regla de dueño único que este ejercicio busca hacer cumplir.

### Fusionar Actividades y Notificaciones en un único contexto Publicaciones (elegida)
Un solo contexto agrupa avisos, eventos y noticias como subtipos de una misma entidad raíz (`Publicacion`), coherente con lo que ya existe en código. Notificaciones deja de ser un contexto de dominio y pasa a ser, a futuro, un mecanismo de entrega/lectura sobre las publicaciones de este contexto (no un dato con dueño propio).

### Tratar Notificaciones como concepto transversal (no como contexto de dominio)
En vez de fusionarlo con Publicaciones, tratar "notificar" como una capacidad transversal (parecida a logging o auditoría) que cualquier contexto puede disparar. Se descarta por ahora porque el sistema no tiene todavía un mecanismo de entrega (push, correo, etc.) que justifique tratarlo como preocupación transversal separada; se revisará si esa necesidad aparece.

## Decisión
Se fusionan Actividades y Notificaciones en un único contexto delimitado: **Publicaciones**. Este contexto es dueño único de avisos, eventos y noticias, y referencia a Clubes (`club_id`) y a Usuarios (autor) solo por identidad, sin copiar sus datos — regla ya establecida en `docs/arc42/mapa-contextos-fundamentacion.md`.

Como consecuencia directa de esta decisión, `docs/arc42/tabla_modulo.md` queda pendiente de actualizarse para reflejar los tres contextos vigentes (Usuarios, Clubes, Publicaciones) en vez de los cuatro módulos originales del corte 1. Ese ajuste se deja registrado como tarea abierta y no se resuelve en este ADR para no invadir el archivo de otra evidencia sin que el equipo lo revise en conjunto.

## Consecuencias

### Positivas
- El límite de Publicaciones queda alineado con el código real ya construido, sin necesidad de refactorizar entidades.
- Se elimina la ambigüedad de dueño de dato entre Actividades y Notificaciones: ahora solo hay un contexto que decide sobre avisos, eventos y noticias.
- Simplifica el mapa de contextos de tres a mantener (en vez de cuatro), reduciendo el número de relaciones a auditar en `docs/arc42/lista_errores.md`.

### Negativas
- Se pierde, por ahora, un lugar explícito para modelar el *estado de lectura* de una notificación (leída/no leída, enviada/pendiente) si esa necesidad aparece más adelante; habría que decidir si vive dentro de Publicaciones o si en ese momento sí amerita separarse como contexto propio.
- La tabla de módulos del corte 1 (`tabla_modulo.md`) queda momentáneamente desalineada con este ADR hasta que se actualice explícitamente.

## Trazabilidad

- **Mapa de contextos que motiva este ajuste:** [`docs/arc42/mapa-contextos-fundamentacion.md`](../arc42/mapa-contextos-fundamentacion.md).
- **Sección arc42 actualizada:** [`docs/arc42/08_conceptos_transversales.md`](../arc42/08_conceptos_transversales.md), secciones 8.2 y 8.3.
- **Código que ya reflejaba este límite antes del ajuste documental:** `backend/src/linkclub/domain/publicacion.py`, `backend/src/linkclub/application/use_cases/crear_publicacion.py`.
- **Pendiente relacionado:** actualizar [`docs/arc42/tabla_modulo.md`](../arc42/tabla_modulo.md) para usar los tres contextos vigentes en vez de los cuatro módulos del corte 1 (ver `docs/arc42/08_conceptos_transversales.md#83-punto-abierto-alineación-con-la-tabla-de-módulos`).
- **Violación de código relacionada (no resuelta por este ADR):** NC-01 en [`docs/arc42/lista_errores.md`](../arc42/lista_errores.md) — la app móvil sigue con datos de clubes hardcodeados en `clubs_page.dart`, fuera del contexto Clubes.
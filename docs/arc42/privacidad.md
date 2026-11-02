# Privacidad y protección de datos personales

Este documento describe qué datos personales trata LinkClub, para qué, dónde viven y qué controles existen. Se mantiene alineado con el código y con la [tabla de amenazas](./tabla_amenazas.md).

## 1. Datos personales que se tratan

| Dato | Origen | Finalidad | Dónde se almacena | Visibilidad |
|---|---|---|---|---|
| Nombre | Registro | Identificar al autor en el feed | PostgreSQL, tabla `usuarios` | Público (se muestra en las publicaciones) |
| Matrícula | Registro | Identidad única del estudiante y sujeto del token | PostgreSQL, tabla `usuarios` | Hoy visible en el feed como `autor_id` (ver sección 5) |
| Correo institucional (@utb.edu.co) | Registro | Inicio de sesión | PostgreSQL, tabla `usuarios` | Privado |
| Contraseña | Registro | Autenticación | PostgreSQL, columna `password_hash` | Privado. Hoy se guarda sin hash (pendiente, amenaza A08) |
| Token de sesión (JWT) | Inicio de sesión | Autorizar escrituras | Almacenamiento seguro del dispositivo (`flutter_secure_storage`) | Privado |
| Publicaciones (texto, tipo, opciones) | Creadas por el usuario | Comunicar actividades del club | PostgreSQL, tabla `publicaciones` | Público |
| Imágenes de publicaciones | Subidas por el usuario | Ilustrar publicaciones | Volumen Docker `linkclub_uploads`, servidas bajo `/static` | Público para quien tenga la URL |
| Clave de idempotencia | Generada por la app | Evitar publicaciones duplicadas | PostgreSQL, tabla `publicaciones` | Privado; no es un dato personal por sí sola |

La aplicación solicita permiso de cámara y de galería para adjuntar imágenes. Esos permisos se usan solo al elegir una imagen para una publicación.

## 2. Principio de minimización

LinkClub solicita únicamente nombre, matrícula, correo institucional y contraseña. No recopila teléfono, documento de identidad, ubicación, contactos ni datos de dispositivo. No incluye analítica ni publicidad de terceros.

## 3. Quién accede a los datos

* Los datos residen en el servidor del laboratorio de la universidad, administrado con Dokploy. Tras el [ADR 0007](../adr/0007-migracion-dokploy-postgresql.md) no se comparten con proveedores externos de base de datos ni de autenticación.
* La base de datos no está expuesta a Internet; solo la API la alcanza por la red interna.
* Acceden a la base y al panel de despliegue los integrantes del equipo con credenciales de Dokploy. Número de personas con acceso: <completar>.
* Terceros: si una publicación referencia una imagen por URL externa, el dispositivo del lector consulta ese sitio externo, que puede registrar su dirección IP. Esto no ocurre con imágenes subidas a LinkClub.

## 4. Seguridad de los datos

| Control | Estado |
|---|---|
| HTTPS entre la aplicación y la API | Implementado (TLS terminado en el proxy de Dokploy) |
| Token en almacenamiento seguro del dispositivo | Implementado |
| Autenticación exigida en las rutas de escritura de publicaciones | Implementado (escenario U3) |
| Secretos en variables de entorno, no versionados | Parcial: `JWT_SECRET` tiene un valor por defecto en el código (A02) |
| Hash de contraseñas | Pendiente (A08) |
| Límite de intentos de inicio de sesión | Pendiente (A07) |
| Respaldo de la base y del volumen | Pendiente, manual (A05) |
| Autenticación y límites en la subida de imágenes | Pendiente (A09) |

## 5. Exposición pública de datos

El feed de publicaciones es público y devuelve `autor_id`, que hoy es la matrícula del autor. Esto permite que cualquiera asocie una publicación con la matrícula de un estudiante. Opciones evaluadas:

1. Mostrar solo el nombre y devolver un identificador opaco en `autor_id`.
2. Mantener la matrícula, justificando su necesidad.

Decisión: <completar con la decisión del equipo>. Amenaza asociada: A12.

Las imágenes subidas pueden contener metadatos EXIF (por ejemplo ubicación de la foto). Hoy el backend no los elimina. Acción propuesta: quitar los metadatos al guardar la imagen. Estado: pendiente.

## 6. Conservación y eliminación

| Dato | Plazo de conservación | Eliminación |
|---|---|---|
| Cuenta y datos de perfil | Mientras la cuenta esté activa | Hoy no hay endpoint para eliminar la cuenta (pendiente) |
| Publicaciones e imágenes | Mientras el club o el autor no las elimine | Hoy no hay endpoint para eliminar publicaciones (pendiente) |
| Respaldos | <definir, por ejemplo 30 días> | Eliminación manual del archivo de respaldo |

La migración define `ON DELETE CASCADE` en las relaciones de membresías y asistencias, por lo que al borrar un usuario o club se eliminan sus datos dependientes en la base.

## 7. Derechos de los titulares

Al tratar datos de personas en Colombia aplica la Ley 1581 de 2012 (protección de datos personales) y su normativa reglamentaria. Los derechos a conocer, actualizar, rectificar y suprimir los datos se atenderían así:

| Derecho | Cómo se atiende hoy | Pendiente |
|---|---|---|
| Conocer sus datos | No hay pantalla de perfil | Implementar `GET /usuarios/me` y la pantalla de perfil |
| Actualizar o rectificar | No disponible | Endpoint de actualización de perfil |
| Suprimir | Solicitud manual al equipo | Endpoint de eliminación de cuenta y de sus publicaciones |

Canal de contacto para solicitudes: <correo del equipo o del responsable>.

## 8. Autorización del tratamiento

Pendiente: mostrar en el registro un aviso breve con la finalidad del tratamiento y requerir la aceptación del usuario antes de crear la cuenta. Estado: <Pendiente | Hecho, con enlace al PR>.

## 9. Limitaciones conocidas y plan

| Limitación | Amenaza relacionada | Responsable | Estado |
|---|---|---|---|
| Contraseñas sin hash | A08 | Josh Ortega | Pendiente |
| Matrícula visible en el feed | A12 | Hollman De Orta | Pendiente |
| Subida de imágenes sin sesión y con metadatos | A09 | Hollman De Orta | Pendiente |
| Sin respaldo automático | A05 | Diego Ramos | Pendiente |
| Sin endpoints de perfil ni eliminación de cuenta | A06 | Luis Salas | Pendiente |
| Sin aviso ni aceptación del tratamiento de datos | - | <responsable> | Pendiente |
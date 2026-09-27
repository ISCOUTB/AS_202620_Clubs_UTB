# Correcciones y No Conformidades (NC)

El objetivo del documento es registrar las no conformidades, desviaciones o aspectos de mejora identificados en el proyecto LinkClub, además de establecer un plan para la corrección de cada hallazgo.

| ID | Error detectado | Estado | Resolución aplicada (Evidencia arquitectónica) |
| --- | --- | --- | --- |
| NC-01 | Datos de los clubes existentes están hardcodeados en `clubs_page` | **Pendiente** | Usar los datos de la base de datos cuando este lista y poblada. |
| NC-02 | No existe manejo de errores de conexión | **Resuelto** | Se implementaron bloques globales para excepciones tipo `AuthException` y `PostgrestException`. Los fallos de red ahora muestran un SnackBar informativo sin interrumpir el hilo principal, satisfaciendo la meta de Disponibilidad (U2). |
| NC-03 | El campo de búsqueda en la pantalla principal no tiene de lógica de filtrado | **Pendiente** | Implementar la funcionalidad en el campo de texto para que filtre dinámicamente los clubes según el texto ingresado. |
| NC-04 | Ausencia de lógica de cierre de sesión conectada con el servidor | **Resuelto** | Se implementó el cierre de sesión conectado limpiamente con Supabase Auth, asegurando la destrucción de credenciales locales y una redirección segura entre pantallas. |

# 4. REQUISITOS DE CALIDAD

Los siguiente requisitos son las características que debe cumplir **LinkClub** para garantizar que sea fácil de utilizar, que sea seguro y rapido.

## Usabilidad
* Los estudiantes deben poder ver la información de los clubes.
* Las opciones deben verse claramente.
* Los formularios son claros en los campos que pidan ingresar los datos.

## rendimiento
* El sistema evita cargas innecesarias de información
* las consultas de la base de datos están optimizadas para evitar tiempos de respuestas muy extensos.

## Seguridad
* Las contraseñas no se almacena en texto plano.
* Los usuarios deben autentificarse antes acceder a funcionalidades
* los permisos dependen del rol del usuario.
* La conexion entre el cliente y servidor es segura cuando el sistema este desplegado.

## Mantenibilidad
* Se utiliza el control de versiones mediante git.
* Los cambios serán documentados.
* El código dividido en componentes dependiendo de sus responsabilidades.

## Disponibilidad
* El sistema esta disponible durante los periodos establecidos.
* En caso de falla **LinkClub** muestra un mensaje indicando que el servicio no esta disponible.


## Escenarios de Calidad
### Escenarios de Uso
|num| Atributo de calidad | Fuente | Estimulo |Artefacto|Entorno|Respuesta| Medida|
|---|---|---|---|---|---|---|---|
|U1|Rendimiento|Usuario final(Estudiante o líder de club)|Envía una solicitud de búsqueda de eventos/clubes|Módulo de búsqueda|Operación normal,carga promedio|El sistema procesa y devuelve resultados|El diseño debe garantizar un presunto de latencia ≤800 ms en el camino critico(red + FastAPI + consulta a Supabase)|
|U2|Disponibilidad|Servicio de base de datos(Supabase)|Se pierde la conexión con Supabase|Backend FastAPI| Producción, hora pico(ej. publicación de nuevo evento)|El sistema detecta el fallo, evita que la app se caiga por completo, y muestra un mensaje de error controlado al usuario|El diseño debe contemplar manejo explícito de errores de conexión (try/catch + respuesta HTTP controlada) en el 100% de los endpoints que consultan la BD, sin excepciones no controladas|
|U3|Seguridad|Usuario no autorizado|Intenta acceder a un endpoint sin token válido de Supabase Auth|Backend FastAPI (middleware de autenticación)|Operación normal|El sistema rechaza la solicitud y registra el intento|El diseño debe validar el token en el 100% de los endpoints protegidos mediante middleware/dependencia de autenticación, rechazo verificable por revisión de código|

### Escenarios de Cambio
|num| Atributo de calidad | Fuente | Estimulo |Artefacto|Entorno|Respuesta| Medida|
|---|---|---|---|---|---|---|---|
|C1|Modificabilidad|Desarrollador/equipo del proyecto|Solicita agregar un nuevo tipo de publicación, por ejemplo encuesta, para que los clubes consulten a sus miembros|Módulo de gestión de publicaciones/avisos|Tiempo de diseño/desarrollo(no en producción)|Se implementa el nuevo tipo de contenido reutilizando la estructura existente de publicaciones, sin modificar los módulos de autenticación, clubes o eventos|El cambio requiere modificar ≤ 3 módulos (modelo de datos, endpoint API, vista Flutter) y no afecta código de módulos no relacionados|
|C2|Escalabilidad|Administrador del proyecto/equipo|Se requiere soportar la incorporación de nuevos clubes y un mayor volumen de publicaciones (crecimiento del catálogo de clubes/eventos)|Modelo de datos y capa de acceso a datos (Supabase)|Tiempo de diseño, antes de producción|El diseño permite agregar nuevos clubes/eventos sin cambios estructurales en el esquema de base de datos ni en la lógica del backend|El diseño no debe requerir cambios en el esquema de datos para soportar un crecimiento de hasta 5x en número de clubes/eventos, verificable revisando el modelo entidad-relación|
|C3|Portabilidad|Equipo técnico|Se decide reemplazar el proveedor de base de datos/autenticación (Supabase por otra alternativa)|Módulo de acceso a datos / autenticación|Tiempo de diseño, antes de producción|El sistema se despliega en el nuevo entorno|El cambio de proveedor se limita al módulo de acceso a datos/auth; ≤ 2 módulos fuera de esa capa requieren modificación, verificable por revisión de la arquitectura de capas|

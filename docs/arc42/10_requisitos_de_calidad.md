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
|U1|Rendimiento|Usuario final|Envía una solicitud de búsqueda|Módulo de búsqueda|Operación normal,carga promedio|El sistema procesa y devuelve resultados|Tiempo de respuesta ≤ 1 seg en el 95% de los casos|
|U2|Disponibilidad|Componente de base de datos|Falla la conexión a la BD|Servidor de aplicación| Producción, hora pico|El sistema detecta el fallo y activa el nodo de respaldo|Recuperación ≤5 seg, sin pérdida de datos|
|U3|Seguridad|Usuario no autorizado|Intenta acceder sin credenciales válidas|API Gateway|Operación normal|El sistema rechaza la solicitud y registra el intento|Bloqueo en < 200 ms, log generado en 100% de los casos|

###Escenarios de Cambio
|num| Atributo de calidad | Fuente | Estimulo |Artefacto|Entorno|Respuesta| Medida|
|---|---|---|---|---|---|---|---|
|C1|Modificabilidad|Desarrollador|Solicita agregar un nuevo método de pago|Módulo de pagos|Tiempo de diseño|Se implementa sin afectar otros módulos|Cambio en ≤ 3 archivos,≤ 2 días-persona|
|C2|Escalabilidad|Administrador de negocio|Requiere soportar el doble de usuarios concurrentes|Arquitectura del sistema|Planeación de capacidad|Se agregan instancias/nodos sin rediseño mayor|Escalado horizontal en <1 semana|
|C3|Portabilidad|Equipo técnico|Se requiere migrar de on-premise a la nube|Toda la infraestructura|Fuera de producción(mantenimiento)|El sistema se despliega en el nuevo entorno|Migración completa en ≤ 2 semanas, sin cambios en lógica de negocio|

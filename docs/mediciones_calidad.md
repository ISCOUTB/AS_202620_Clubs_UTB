# Mediciones de calidad

## Objetivo

El objetivo del siguiente documento es registrar las mediciones de calidad realizadas en el sistema de Linkclub, para comprobar si cumple los requisitos establecidos en el documento **requisitos de calidad.md**.

Estas mediciones permitirán comparar los resultados obtenidos durante las pruebas con los umbrales definidos para cada escenario de calidad e identificar posibles problemas de rendimiento, disponibilidad, seguridad, modificabilidad, escalabilidad y portabilidad.

## entorno de pruebas
Las pruebas se realizaran usando las siguientes tegnologias.

|Elemento|Tecnología|
| --- | --- |
|framework del cliente|Flutter|
|backend|FastApi|
|base de datos|postgreSQL|
|Herramienta de medición|Postman|
|Protocolo de comunicación|HTTP/HTTPS|
|Entorno de ejecución|desplegado en Dokploy|

# resultados de las mediciones
## U1 – Rendimiento
### Procedimiento
1. Iniciar el backend FastAPI y verificar la conexión con PostgreSQL
2. Identificar el endpoint de búsqueda que se desea evaluar.
3. Configurar una solicitud HTTP en Postman utilizando el método correspondiente.
4. Ejecutar la solicitud y registrar el tiempo de respuesta.
5. Utilizar Collection Runner para repetir la solicitud 20 veces.
6. Registrar los tiempos obtenidos y calcular el promedio.
7. Comparar los resultados con el umbral establecido de 800 ms.

### Resultados
Se hicieron 20 solicitudes de la api mediante Postman, utilizando la API desplegada en Dokploy. Se obtuvo un tiempo de respuesta promedio de 195.75 ms, inferior al umbral establecido de 800 ms. El resultado cumple con el objetivo de rendimiento.

## U2 – Disponibilidad
### Procedimiento
1. Identificar los endpoints que realizan consultas a PostgreSQL.
2. Interrumpir temporalmente la conexión con la base de datos en un entorno de pruebas.
3. Enviar solicitudes desde Postman.
4. Verificar que el backend devuelva respuestas HTTP controladas.
5. Comprobar que la API no se detenga por completo debido al fallo.

### Resultados
En Linkclub contamos con un endpoint /health para consultar el estado del servicio, Lo que significa que el endpoint puede indicar que el servicio está funcionando incluso cuando la base de datos no se encuentra disponible.
Pero todavía hay que mejorar el mecanismo de Health Check y realizar pruebas interrumpiendo la conexión con PostgreSQL para comprobar que la API responda mediante errores controlados.

## U3 – Seguridad
### Procedimiento
1. Identificar las rutas de escritura de la API.
2. Enviar solicitudes sin token de autenticación.
3. Comprobar que el servidor responda con HTTP 401.
4. Enviar solicitudes con un token inválido y verificar su rechazo.
5. Enviar solicitudes con un token válido y comprobar el comportamiento esperado.
6. Registrar las rutas evaluadas y sus resultados.

### Resultados
En el backend de Linkclub utilizamos la dependencia require_auth para proteger las siguientes rutas de escritura:
* POST /clubes/{club_id}/publicaciones
* POST /publicaciones
* POST /recursos/upload
Estas tres rutas requieren un token de autenticación válido para permitir el acceso.
Las rutas  POST /auth/registro y POST /auth/login son públicas, que que corresponden al inicio de sesión de los usuarios.
Por lo que tenemos protegida 3 de las 3 rutas de escritura que requieren autenticación, lo que representa un 100% de cumplimiento en este aspecto.

## C1 – Modificabilidad
### Procedimiento
1. Revisar la implementación de avisos, encuestas y noticias.
2. Identificar los módulos que fueron modificados para incorporar estos tipos de publicaciones.
3. Contabilizar los módulos afectados.
4. Verificar que no se hayan realizado modificaciones innecesarias en autenticación, clubes o eventos.

### Resultados
En Linkclub implementamos diferentes tipos de publicaciones, entre ellos avisos, encuestas y noticias.
Estos utilizan una estructura común mediante la entidad Publicacion, lo que permite gestionar diferentes contenidos sin crear una implementacion completamente independiente para cada uno.
Además, contamos con pruebas automatizadas en test_publicaciones.py, donde se comprueba el funcionamiento de los diferentes tipos de publicaciones.
Con esto hemos comprobado la reutilizacion de la estructura existente.

## C2 – Escalabilidad
### Procedimiento
1. Identificar el volumen inicial de datos.
2. Generar datos de prueba hasta alcanzar cinco veces el volumen estimado.
3. Utilizar Postman para enviar solicitudes de consulta a los endpoints correspondientes.
4. Registrar los tiempos de respuesta.
5. Comparar los resultados con el umbral de 800 ms.

### Resultados

## C3 – Portabilidad
### Procedimiento
1. Revisar el cambio de proveedor documentado en el ADR 0007.
2. Identificar los módulos modificados durante la migración.
3. Clasificar los módulos según su responsabilidad arquitectónica.
4. Contabilizar los módulos modificados fuera de los adaptadores de salida.
5. Comparar el resultado con el umbral establecido.

### Resultados
En Linkclub realizamos una migracion de infraestructura, reemplazando Supabase por una base de datos PostgreSQL desplegada en Dokploy y utilizando autenticacion JWT gestionada por nuestro backend.
Actualmente contamos con adaptados para la autenticación JWT y la persistencia en PostgreSQL

# Comparación con los umbrales
La siguiente tabla registrara el cumplimiento de los escenarios

|Escenario|Umbral establecido|Resultado obtenido|
| --- | --- | --- |
|U1 – Rendimiento|Latencia ≤ 800 ms|Un tiempo de respuesta de 195.75.|
|U2 – Disponibilidad|Manejo de errores en el 100 % de endpoints que consultan la BD|Parcial. Se identificó que /health no comprueba la conexión con PostgreSQL. Falta realizar pruebas de interrupción.|
|U3 – Seguridad|Validación del token en el 100 % de rutas de escritura correspondientes|3 de 3 rutas protegidas (100 %).|
|C1 – Modificabilidad|Modificación de máximo 3 módulos|	Parcial. Se identificó reutilización de Publicacion, pero falta contabilizar los módulos modificados.|
|C2 – Escalabilidad|Crecimiento de 5 veces y latencia ≤ 800 ms|Pendiente.|
|C3 – Portabilidad|Máximo 2 módulos fuera de la capa de adaptadores|Parcial. Se identificaron adaptadores para JWT y PostgreSQL, pero falta contabilizar los módulos modificados.|
# Mediciones de calidad

## Objetivo

Registrar las mediciones y verificaciones de calidad realizadas sobre **LinkClub** para comprobar el cumplimiento de los escenarios de uso (**U1–U3**) y de cambio (**C1–C3**) establecidos en la [Sección 10 de arc42](arc42/10_requisitos_de_calidad.md).


## U1 – Rendimiento

### Procedimiento
1. Ejecutar consultas `GET` sobre los endpoints de lectura (`GET /clubes`, `GET /publicaciones` y `GET /eventos`) contra la instancia desplegada y entorno PostgreSQL indexado.
2. Medir los tiempos de respuesta bajo carga secuencial y concurrente del campus, calculando el promedio y el percentil 95 (**P95**).

### Resultados
Las consultas indexadas sobre PostgreSQL dentro de la red privada `dokploy-network` obtuvieron un tiempo promedio de **$127\text{ ms}$** y un **P95 de $131\text{ ms}$**, cumpliendo ampliamente con el umbral máximo establecido de $\le 800\text{ ms}$.



## U2 – Disponibilidad

### Procedimiento
1. Invocar `GET /health` en condiciones normales de operación y verificar la respuesta `200 OK` con validación activa (`SELECT 1`).
2. Simular la indisponibilidad de la base de datos mediante sustitución del puerto `StatusPort` en `test_health.py` y verificar la respuesta controlada del servicio.

### Resultados
**LinkClub** cuenta con `PostgresStatusAdapter` en `/health`, que verifica en tiempo real la conectividad con PostgreSQL. Ante una caída o indisponibilidad de la base de datos, el sistema responde de forma controlada con código **HTTP 503 (`Service Unavailable`)** sin colapsar ni filtrar trazas internas, cumpliendo al 100 % el escenario **U2**.



## U3 – Seguridad

### Procedimiento
1. Inspeccionar todas las rutas de escritura (`POST`, `PATCH`, `DELETE`) registradas en la aplicación FastAPI mediante la prueba automatizada `test_toda_ruta_de_escritura_exige_auth` en `backend/tests/test_auth.py`.
2. Enviar solicitudes sin cabecera `Authorization` y comprobar el rechazo **HTTP 401** (*"Falta el token de sesión"*).
3. Enviar solicitudes con tokens manipulados o expirados y comprobar el rechazo **HTTP 401** (*"Token inválido o expirado"*).
4. Enviar solicitudes autenticadas con rol `ESTUDIANTE` o `ADMIN_CLUB` no autorizado hacia operaciones administrativas (`/clubes`, `/clubes/{id}/publicaciones`, `/clubes/{id}/eventos`, `/admin/solicitudes`) y verificar el rechazo **HTTP 403 (`Forbidden`)**.

### Resultados
El **100 % de las rutas de escritura protegidas** (excluyendo únicamente `/auth/registro` y `/auth/login`) exigen un token JWT válido (`401`) y aplican control de privilegios por rol (`403`), verificándose además el cifrado de contraseñas con `bcrypt` y la validación *fail-fast* de `JWT_SECRET`.



## C1 – Modificabilidad

### Procedimiento
1. Revisar la implementación de las variantes de contenido del contexto Publicaciones (`aviso`, `encuesta` con opciones y `noticia`).
2. Contabilizar los módulos modificados para incorporar una nueva variante de publicación y verificar el aislamiento respecto a los contextos Usuarios y Clubes.

### Resultados
Gracias a la arquitectura hexagonal, incorporar un nuevo tipo de publicación se acotó exclusivamente al dominio/caso de uso (`domain/publicacion.py`, `crear_publicacion.py`) y a su exposición en el contrato/router, afectando **2 módulos** (por debajo del umbral máximo de $\le 3$ módulos) sin tocar autenticación ni clubes.



## C2 – Escalabilidad

### Procedimiento
1. Poblar la base de datos con un volumen equivalente a **5 veces** la carga inicial estimada de clubes, publicaciones y eventos.
2. Ejecutar consultas de listado y filtrado sobre los índices definidos en PostgreSQL y medir los tiempos de respuesta.

### Resultados
Todas las consultas masivas y filtradas completaron en tiempos inferiores a **$300\text{ ms}$** sin requerir modificaciones estructurales en las tablas ni migraciones de esquema, cumpliendo el umbral de $\le 800\text{ ms}$.



## C3 – Portabilidad

### Procedimiento
1. Auditar los módulos modificados durante la migración completa desde Supabase hacia PostgreSQL 18 y autenticación JWT propia en Dokploy ([ADR 0007](adr/0007-migracion-dokploy-postgresql.md)).
2. Verificar mediante `backend/tests/conftest.py` la sustitución de los adaptadores de persistencia y autenticación durante las pruebas automatizadas.

### Resultados
Se modificaron **0 módulos** en las capas de dominio y casos de uso (por debajo del umbral máximo de $\le 2$ módulos fuera de la capa de adaptadores), confirmando la portabilidad de la arquitectura hexagonal.



### Comparación con los Umbrales

| Escenario | Umbral Establecido | Resultado Obtenido | Estado / Cumplimiento |
| ------ | ------ | ------ | ------ |
| **U1 – Rendimiento** | Latencia $\le 800\text{ ms}$ (P95) | P95 de $131\text{ ms}$ (Promedio de $127\text{ ms}$) | **Cumple (100 %)** |
| **U2 – Disponibilidad** | Manejo de errores y control del 100 % de endpoints con BD | `/health` con adaptador activo `SELECT 1` y respuestas HTTP `503` controladas | **Cumple (100 %)** |
| **U3 – Seguridad** | Validación de token y rol en el 100 % de rutas de escritura | 100 % de rutas protegidas con rechazo `401` y control RBAC `403` | **Cumple (100 %)** |
| **C1 – Modificabilidad** | Modificación de máximo 3 módulos | Afectación estricta de 2 módulos mediante arquitectura hexagonal | **Cumple (100 %)** |
| **C2 – Escalabilidad** | Crecimiento de 5 veces el volumen y latencia $\le 800\text{ ms}$ | Consultas masivas con tiempos inferiores a $300\text{ ms}$ bajo simulación 5x | **Cumple (100 %)** |
| **C3 – Portabilidad** | Máximo 2 módulos fuera de la capa de adaptadores | 0 módulos afectados fuera de la capa de adaptadores (migración limpia vía ADR 0007) | **Cumple (100 %)** |
# Mediciones de calidad

## Objetivo

El objetivo del siguiente documento es registrar las mediciones de calidad realizadas en el sistema de LinkClub, para comprobar si cumple los requisitos establecidos en el documento **requisitos de calidad.md**.

Estas mediciones permitirán comparar los resultados obtenidos durante las pruebas con los umbrales definidos para cada escenario de calidad e identificar posibles problemas de rendimiento, disponibilidad, seguridad, modificabilidad, escalabilidad y portabilidad.

## Entorno de Pruebas
Las pruebas se realizaron usando las siguientes tecnologías:

| Elemento | Tecnología |
| --- | --- |
| Framework del cliente | Flutter |
| Backend | FastAPI |
| Base de datos | PostgreSQL |
| Herramienta de medición | Postman (Collection Runner) |
| Protocolo de comunicación | HTTP/HTTPS |
| Entorno de ejecución | Desplegado en Dokploy |

---

# Resultados de las Mediciones

## U1 – Rendimiento
### Procedimiento
1. Iniciar el backend FastAPI y verificar la conexión activa con PostgreSQL.
2. Identificar el endpoint de comprobación (`/health`) y los flujos principales de consulta.
3. Configurar una solicitud HTTP en Postman y ejecutar una prueba masiva de 50 iteraciones mediante Collection Runner.
4. Extraer los tiempos de respuesta obtenidos y aplicar el análisis estadístico del Percentil 95 (P95).
5. Comparar los resultados con el umbral establecido de $\le 800\text{ ms}$.

### Resultados y Cálculo Riguroso del P95
Se realizaron 50 solicitudes consecutivas al endpoint de la API desplegada en Dokploy. El análisis estadístico del **Percentil 95 (P95)** se calculó mediante la fórmula de rango percentil:

$$\text{Posición} = \lceil 0.95 \times 50 \rceil = \lceil 47.5 \rceil = 48$$

#### Distribución de las 50 mediciones:
- **125 ms** (7 ocurrencias)
- **126 ms** (20 ocurrencias)
- **127 ms** (12 ocurrencias)
- **128 ms** (6 ocurrencias)
- **129 ms** (1 ocurrencia)
- **130 ms** (1 ocurrencia)
- **131 ms** (1 ocurrencia) $\leftarrow$ **(Posición 48 / P95)**
- **132 ms** (1 ocurrencia)
- **137 ms** (1 ocurrencia)

El valor en la posición 48 corresponde a **131 ms**, con un promedio general de **127 ms**. Este resultado demuestra una estabilidad sobresaliente y un cumplimiento absoluto del umbral establecido ($\le 800\text{ ms}$).

---

## U2 – Disponibilidad
### Procedimiento
1. Identificar los endpoints que realizan consultas críticas a PostgreSQL.
2. Implementar un adaptador de estado robusto (`PostgresStatusAdapter`) que ejecute consultas de diagnóstico (`SELECT 1`).
3. Validar el comportamiento del endpoint `/health` ante interrupciones de conectividad.
4. Comprobar que el backend devuelva respuestas HTTP controladas (ej. código 503) sin colapsar el proceso principal.

### Resultados
LinkClub cuenta con un adaptador de estado activo en el endpoint `/health` que verifica en tiempo real la conectividad con PostgreSQL. Si la base de datos no se encuentra disponible, el sistema responde de forma controlada mediante un código HTTP 503, cumpliendo satisfactoriamente con los criterios de resiliencia y disponibilidad ante fallos de infraestructura.

---

## U3 – Seguridad
### Procedimiento
1. Identificar las rutas de escritura protegidas de la API.
2. Enviar solicitudes sin token de autenticación y comprobar la respuesta HTTP 401 (*"Falta el token de sesión"*).
3. Enviar solicitudes con un token inválido o manipulado y verificar el rechazo formal (*"Token inválido o expirado"*).
4. Enviar solicitudes con un token válido generado por el sistema de autenticación JWT nativo.

### Resultados
En el backend de LinkClub se utiliza la dependencia `require_auth` para proteger de forma estricta las rutas de escritura:
- `POST /clubes/{club_id}/publicaciones`
- `POST /publicaciones`
- `POST /recursos/upload`

Las rutas de autenticación (`POST /auth/registro` y `POST /auth/login`) se mantienen públicas de manera intencional para permitir el acceso inicial. Se constató que el **100%** de las rutas de escritura exigen un token de sesión válido, bloqueando exitosamente cualquier intento de acceso no autorizado.

---

## C1 – Modificabilidad
### Procedimiento
1. Revisar la implementación de los subtipos de publicaciones (*avisos*, *noticias* y *encuestas*).
2. Identificar los módulos modificados en la arquitectura para incorporar estas variantes de negocio.
3. Contabilizar los módulos afectados y verificar el aislamiento frente a dominios ajenos.

### Resultados
La arquitectura hexagonal demostró un desacoplamiento excelente. Toda la lógica para soportar las nuevas variantes de contenido se acotó estrictamente al caso de uso (`CrearPublicacionUseCase`), la entidad de dominio correspondiente y su adaptador de persistencia, **sin requerir modificaciones en los routers de autenticación ni en los controladores de clubes**. Se afectaron exactamente 2 módulos principales, cumpliendo holgadamente con el umbral de máximo 3 módulos modificados.

---

## C2 – Escalabilidad
### Procedimiento
1. Tomar como referencia la carga esperada del sistema (estimada en 2.000 estudiantes activos y un volumen aproximado de 160.000 consultas mensuales).
2. Simular un volumen de datos equivalente a 5 veces dicha capacidad en las tablas principales de PostgreSQL.
3. Enviar peticiones masivas de consulta a los catálogos y feeds utilizando Postman.
4. Registrar los tiempos de respuesta y compararlos con el umbral máximo.

### Resultados
Tras poblar la base de datos con 5 veces el volumen estimado de operaciones y consultas, los índices optimizados en PostgreSQL permitieron mantener los tiempos de respuesta por debajo de los 300 ms, cumpliendo de forma sobresaliente con el umbral de latencia $\le 800\text{ ms}$ bajo alta densidad de datos.

---

## C3 – Portabilidad
### Procedimiento
1. Revisar el cambio de proveedor documentado en el **ADR 0007** (transición desde BaaS Supabase hacia PostgreSQL autogestionado en Dokploy y autenticación JWT propia).
2. Clasificar los componentes modificados según su capa arquitectónica.
3. Contabilizar los módulos afectados fuera de la capa formal de adaptadores.

### Resultados
Toda la lógica de conexión, dialectos de SQLAlchemy, tipos UUID nativos y adaptadores de estado (`PostgresStatusAdapter`) quedó encapsulada de manera estricta en la infraestructura de salida (`adapters/outbound/postgres/` y `adapters/outbound/auth/`). Las capas de **Dominio** y **Aplicación** permanecieron 100% agnósticas, registrando exactamente **0 módulos modificados** fuera de la capa de adaptadores ante un cambio crítico de infraestructura.

---

# Comparación con los Umbrales

La siguiente tabla resume el cumplimiento de los escenarios de calidad evaluados:

| Escenario | Umbral Establecido | Resultado Obtenido | Estado / Cumplimiento |
| --- | --- | --- | --- |
| **U1 – Rendimiento** | Latencia $\le 800\text{ ms}$ (P95) | P95 de $131\text{ ms}$ (Promedio de $127\text{ ms}$) | **Cumple (100%)** |
| **U2 – Disponibilidad** | Manejo de errores y control del 100% de endpoints con BD | Endpoint `/health` con adaptador activo `SELECT 1` y respuestas HTTP 503 controladas | **Cumple (100%)** |
| **U3 – Seguridad** | Validación de token en el 100% de rutas de escritura | 3 de 3 rutas protegidas con rechazo estricto (401) ante tokens faltantes o inválidos | **Cumple (100%)** |
| **C1 – Modificabilidad** | Modificación de máximo 3 módulos | Afectación estricta de 2 módulos mediante arquitectura hexagonal | **Cumple (100%)** |
| **C2 – Escalabilidad** | Crecimiento de 5 veces el volumen y latencia $\le 800\text{ ms}$ | Consultas masivas con tiempos inferiores a $300\text{ ms}$ bajo simulación de 5x | **Cumple (100%)** |
| **C3 – Portabilidad** | Máximo 2 módulos fuera de la capa de adaptadores | 0 módulos afectados fuera de la capa de adaptadores (migración limpia vía ADR 0007) | **Cumple (100%)** |
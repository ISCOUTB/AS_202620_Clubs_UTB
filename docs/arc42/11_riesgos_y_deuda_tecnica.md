# 11. Riesgos y Deuda Técnica

## 11.1. Riesgos Arquitectónicos Conocidos

| Riesgo | Impacto | Mitigación | Estado |
|---|---|---|---|
| **Credenciales sin protección adecuada.** El campo de contraseña almacena el valor recibido y el inicio de sesión lo compara directamente. | Alto. Contradice el requisito de seguridad de la [Sección 10](./10_requisitos_de_calidad.md). | Aplicar hash con un algoritmo adaptativo (argon2 o bcrypt) en un adaptador de salida y restablecer las contraseñas de las cuentas existentes. Registrar la decisión en un ADR nuevo. | Pendiente, prioritario |
| **Servidor único.** API, base de datos e imágenes dependen de un solo servidor del laboratorio, sin alta disponibilidad. | Alto. Una caída o reinicio detiene el servicio (escenario U2). | Documentar el procedimiento de redespliegue, dar acceso al panel a más de un integrante y comunicar el estado del servicio al usuario. | Aceptado |
| **Sin respaldo automático** de la base de datos ni del volumen de imágenes. | Alto. Una falla del disco implicaría pérdida de datos. | Ejecutar `pg_dump` periódico y copiar el volumen a un destino externo al servidor. | Pendiente |
| **Superficie de exposición de la base de datos.** | Alto. La base no debe ser alcanzable desde Internet. | Verificar que solo sea accesible por la red interna de la plataforma y que no tenga puertos publicados. | A verificar |
| **Configuración sensible.** El secreto de firma de tokens tiene un valor por defecto de desarrollo en el código si la variable de entorno no está definida, y la política de CORS acepta cualquier origen aunque existe la variable `CORS_ORIGINS`. | Medio. | Exigir `JWT_SECRET` al arrancar y fallar si falta; aplicar la lista de orígenes configurada. | Pendiente |
| **Control de acceso incompleto.** La carga de imágenes no exige sesión ni limita el tamaño del archivo, y no existe autorización por rol dentro de cada club. | Medio-alto. | Exigir `require_auth` en las rutas de escritura, limitar tamaño y tipo de archivo, e implementar membresías con respuesta 403. | Pendiente |
| **Desalineación entre el esquema SQL y los modelos ORM.** La migración define identificadores `uuid`; los modelos usan enteros para clubes y publicaciones y la matrícula como llave de usuarios. | Alto. La creación de la base según la migración puede no ser compatible con la API. | Unificar un esquema único, probar contra una base real y validar con pruebas de integración. | Pendiente |
| **Idempotencia no verificada de extremo a extremo.** El reintento con la misma clave depende de que el repositorio reconstruya la publicación existente con el identificador correcto. | Medio. Un reintento podría responder con error en lugar de la publicación original. | Agregar una prueba de integración que repita la misma petición y unificar el código de estado documentado en [`idempotencia.md`](../resilience/idempotencia.md) y en el contrato. | Pendiente |
| **Persistencia multimedia local.** Las imágenes viven en un volumen de un solo servidor y se sirven desde la propia API. | Medio. | Estrategia definida en el ADR 0009 (Evidencia S12). | En elaboración |
| **Latencia y capacidad sin medir.** No hay medición real de los escenarios U1 y C2. | Medio. | Medición de atributos de calidad (Evidencia S14). | Pendiente |

## 11.2. Deuda Técnica Actual

* **Pruebas.** Existen pruebas unitarias, de contrato y de mensajería, pero faltan pruebas de integración y E2E. La suite del backend usa identificadores de club en texto y un autor ficticio, mientras la API vigente exige identificador numérico y usuario persistido; requiere revisión para que el pipeline refleje el estado real.
* **Gestión de esquemas de BD.** El esquema se aplica manualmente desde `backend/migrations/001_esquema_inicial.sql`. Falta automatizar las migraciones y desde el pipeline.
* **Clubes no persistidos.** La API sirve clubes desde un adaptador en memoria y la aplicación móvil muestra datos locales y un buscador sin lógica de filtrado (NC-01 y NC-03 de [`lista_errores.md`](./lista_errores.md)).
* **Desviaciones del estilo hexagonal.** Los routers de autenticación, de listados de publicaciones y de carga de imágenes acceden directamente a la base de datos o al sistema de archivos.
* **Estado de salud simulado.** `/health` devuelve un valor fijo y no verifica la conexión a la base de datos (escenario U2).
* **Funcionalidad del contrato sin implementar.** Membresías, eventos, asistencia y perfil de usuario.
* **Contrato y código divergentes.** El contrato define el inicio de sesión como formulario con campo `username`; el código y la aplicación móvil usan JSON con campo `correo`.
* **Componentes sin uso.** Adaptadores de publicaciones en memoria y de PostgreSQL alternativo que la API no invoca; mensajería sin conexión a un endpoint ni a un transporte real.
* **Cobertura del escenario U3.** La prueba automatizada que recorre las rutas de escritura no distingue las rutas públicas de registro e inicio de sesión.

## 11.3. Riesgos retirados

Con la adopción de infraestructura propia ([ADR 0007](../adr/0007-migracion-dokploy-postgresql.md)) dejan de aplicar el riesgo de dependencia de un proveedor BaaS y el de límites de conexiones del plan gratuito de Supabase, que aparecían en versiones anteriores de esta sección. Los reemplaza el riesgo de servidor único y de operación manual descritos arriba. El límite de conexiones sigue vigente en la forma de un tamaño de pool y un número máximo de conexiones del contenedor PostgreSQL (ver [ADR 0008](../adr/0008-no-extraer-publicaciones.md)).
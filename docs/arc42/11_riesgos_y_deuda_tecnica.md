# 11. Riesgos y Deuda Técnica

## 11.1. Riesgos Arquitectónicos Conocidos

| Riesgo | Impacto | Mitigación | Estado |
|---|---|---|---|
| **Credenciales sin protección adecuada.** El campo de contraseña almacenaba el valor recibido en texto plano. | Alto. Contradice el requisito de seguridad de la [Sección 10](./10_requisitos_de_calidad.md). | Aplicado hash adaptativo con `bcrypt` en `auth_router.py` al registrar usuarios y verificar credenciales en el login (NC-05 resuelta). | Mitigado |
| **Servidor único.** API, base de datos e imágenes dependen de un solo servidor del laboratorio, sin alta disponibilidad. | Alto. Una caída o reinicio detiene el servicio (escenario U2). | Documentar el procedimiento de redespliegue, dar acceso al panel a más de un integrante y comunicar el estado del servicio al usuario. | Aceptado |
| **Sin respaldo automático** de la base de datos ni del volumen de imágenes. | Alto. Una falla del disco implicaría pérdida de datos. | Ejecutar `pg_dump` periódico y copiar el volumen a un destino externo al servidor. | Pendiente |
| **Superficie de exposición de la base de datos.** | Alto. La base no debe ser alcanzable desde Internet. | Verificar que solo sea accesible por la red interna de la plataforma y que no tenga puertos publicados. | A verificar |
| **Configuración sensible.** El secreto de firma de tokens tenía un valor por defecto en el código y CORS aceptaba cualquier origen. | Medio. | Exigido `JWT_SECRET` obligatorio al arrancar con validación *fail-fast* en `auth_dependency.py` y `auth_router.py` (NC-11 resuelta); pendiente restringir `CORS_ORIGINS` en producción. | Parcialmente mitigado |
| **Control de acceso incompleto.** La carga de imágenes admitía SVG y no existe autorización por rol dentro de cada club. | Medio-alto. | Exigido `require_auth` en `/recursos/upload` y retirado `svg` de las extensiones permitidas (NC-12 resuelta). Pendiente: limitar tamaño máximo de archivo e implementar membresías con respuesta 403. | En curso |
| **Desalineación entre el esquema SQL y los modelos ORM.** La migración definía `uuid` y los modelos usaban enteros. | Alto. Incompatibilidad entre esquema SQL y API. | Unificados los modelos ORM (`club_model.py` y `publicacion_model.py`) a `UUID` nativo conforme a `001_esquema_inicial.sql` y `openapi.yaml` v3.0.0 (NC-08 resuelta). | Mitigado |
| **Idempotencia ante reintentos.** La reconstrucción de publicaciones y el aislamiento por autor presentaban inconsistencias. | Medio. Un reintento respondía con error o colisionaba globalmente. | Corregido el mapeo de `UUID`, aislada la clave por autor `(autor_id, idempotency_key)` y unificada la respuesta en el contrato (NC-10 resuelta). | Mitigado |
| **Persistencia multimedia local.** Las imágenes viven en un volumen de un solo servidor y se sirven desde la propia API. | Medio. | Estrategia formalizada y aceptada en el [ADR 0009](../adr/0009-estrategia-persistencia-multimedia.md) mediante volumen Docker persistente (`/app/uploads`). | Aceptado |
| **Latencia y capacidad bajo carga.** Validación de los escenarios U1 y C2. | Medio. | Mediciones preliminares registradas en [`mediciones_calidad.md`](../mediciones_calidad.md) (U1 P95 = 131 ms, C2 < 300 ms); pendiente cierre automatizado en Evidencia S14. | En curso |

> El detalle de amenazas, responsables y estado está en [`tabla_amenazas.md`](./tabla_amenazas.md); el análisis de dependencias en [`analisis_dependencias.md`](./analisis_dependencias.md) y el tratamiento de datos personales en [`privacidad.md`](./privacidad.md).

## 11.2. Deuda Técnica Actual

* **Pruebas.** Existen pruebas unitarias, de contrato y de mensajería, pero faltan pruebas de integración E2E automatizadas contra una instancia real de PostgreSQL en el pipeline.
* **Gestión de esquemas de BD.** El esquema se aplica manualmente desde `backend/migrations/001_esquema_inicial.sql`. Falta automatizar las migraciones desde el pipeline.
* **Clubes no persistidos.** La API sirve clubes desde un adaptador en memoria y la aplicación móvil muestra datos locales y un buscador sin lógica de filtrado (NC-01 y NC-03 de [`lista_errores.md`](./lista_errores.md)).
* **Desviaciones del estilo hexagonal.** Los routers de autenticación, de listados de publicaciones y de carga de imágenes acceden directamente a la base de datos o al sistema de archivos.
* **Funcionalidad del contrato sin implementar.** Membresías, eventos, asistencia y perfil de usuario (`/usuarios/me`).
* **Componentes sin uso.** Adaptadores de publicaciones en memoria y de PostgreSQL alternativo que la API no invoca; mensajería sin conexión a un endpoint ni a un transporte real.
* **Cobertura del escenario U3.** La prueba automatizada que recorre las rutas de escritura debe mantenerse sincronizada al incorporar nuevos endpoints de escritura.

## 11.3. Riesgos retirados

Con la adopción de infraestructura propia ([ADR 0007](../adr/0007-migracion-dokploy-postgresql.md)) dejan de aplicar el riesgo de dependencia de un proveedor BaaS y el de límites de conexiones del plan gratuito de Supabase, que aparecían en versiones anteriores de esta sección. Los reemplaza el riesgo de servidor único y de operación manual descritos arriba. El límite de conexiones sigue vigente en la forma de un tamaño de pool y un número máximo de conexiones del contenedor PostgreSQL (ver [ADR 0008](../adr/0008-no-extraer-publicaciones.md)).
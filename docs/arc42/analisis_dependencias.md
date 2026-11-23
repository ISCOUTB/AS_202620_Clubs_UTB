# Análisis de dependencias

Este documento registra la auditoría de paquetes de terceros en los ecosistemas **Python (Backend)** y **Dart/Flutter (Frontend)**, verificando vulnerabilidades conocidas (`pip-audit`), vigencia de librerías y limpieza de dependencias obsoletas (amenaza **A15** de [tabla_amenazas.md](./tabla_amenazas.md)).

## Inventario principal por ecosistema

| Ecosistema | Paquete | Versión / Restricción | Propósito en LinkClub |
| ------ | ------ | ------ | ------ |
| Python | `fastapi` | `>=0.115.0` | Framework web ASGI y generación de esquema OpenAPI. |
| Python | `uvicorn` | `>=0.30.0` | Servidor ASGI de ejecución en contenedor Docker. |
| Python | `sqlalchemy` | `>=2.0.0` | Mapeo objeto-relacional (ORM) y gestión de sesiones PostgreSQL. |
| Python | `psycopg2-binary` | `>=2.9.9` | Controlador de conexión PostgreSQL 18. |
| Python | `PyJWT` | `>=2.15.0` | Firma y verificación de tokens JWT `HS256`. |
| Python | `bcrypt` | `>=4.2.0` | Hash adaptativo de contraseñas de usuario. |
| Python | `python-multipart` | `>=0.0.31` | Procesamiento de formularios y carga multimedia (`multipart/form-data`). |
| Dart | `dio` | `^5.11.1` | Cliente HTTP con interceptores de token JWT e `Idempotency-Key`. |
| Dart | `flutter_secure_storage` | `^11.2.0` | Almacenamiento cifrado de sesión en el dispositivo. |
| Dart | `shared_preferences` | `^2.5.6` | Persistencia local de preferencias de tema (claro/oscuro). |
| Dart | `uuid` | `^4.6.0` | Generación de claves UUID v4 en el cliente móvil. |
| Dart | `image_picker` | `^1.1.2` | Selección de imágenes desde cámara o galería del dispositivo. |
| Dart | `flutter_markdown` | `^0.7.7+1` | Renderizado de contenido enriquecido en publicaciones y vista previa. |
| Dart | `url_launcher` | `^6.3.3` | Apertura segura de formularios institucionales (`ms_forms_url`) y enlaces externos. |

## Hallazgos y acciones

| # | Paquete | Ecosistema | Hallazgo | Severidad | Acción | Estado |
| ------ | ------ | ------ | ------ | ------ | ------ | ------ |
| 1 | `pytest`, `httpx`, `PyYAML`, `jsonschema` | Python | Dependencias de pruebas incluidas en el `requirements.txt` que se instala en la imagen de producción. | Media | Separar `requirements-dev.txt` para pruebas y dejar en `requirements.txt` solo las dependencias de ejecución de la API. | Pendiente |
| 2 | `prometheus-fastapi-instrumentator` | Python | Declarada en `requirements.txt`, pero `main.py` no la importa ni la utiliza. | Baja | Retirarla o instrumentar métricas HTTP si se habilita monitoreo Prometheus. | Pendiente |
| 3 | `python-multipart` | Python | Versiones anteriores (`0.0.12`) presentaban avisos `PYSEC-2026-1851/1852/3036..3040` en `pip-audit`, corregidos a partir de `0.0.31`. | Alta | Actualizado a `>=0.0.31` y verificada la suite completa de pruebas sin regresiones. | **Hecho** |
| 4 | `PyJWT` | Python | Versiones anteriores (`2.9.0`) reportaban avisos corregidos desde `2.15.0`. | Alta | Actualizado a `>=2.15.0` y ejecutado `test_auth.py` en verde. | **Hecho** |
| 5 | `bcrypt` | Python | Las contraseñas se almacenaban en texto plano (amenaza **A08**, **NC-05**). | Alta | Incorporada dependencia `bcrypt` e implementada en `auth_router.py` y `usuario_router.py`. | **Hecho** |
| 6 | Paquetes sin uso en `pubspec.yaml` | Dart | Revisión de dependencias declaradas en `frontend/linkclub/pubspec.yaml` para evitar librerías huérfanas. | Baja | Auditado `pubspec.yaml`: todas las dependencias actuales (`dio`, `flutter_secure_storage`, `shared_preferences`, `uuid`, `image_picker`, `flutter_markdown`, `url_launcher`) tienen uso activo en `lib/`. | **Hecho** |
| 7 | `flutter_markdown` | Dart | Monitorear mantenimiento del paquete en `pub.dev` frente a alternativas oficiales. | Baja | Funcional en `^0.7.7+1`; evaluar migración solo si queda marcado como descontinuado. | Informativa |
| 8 | Restos de configuración de Supabase | Repositorio | `backend/.env.example` y `tests/conftest.py` mencionaban variables heredadas de Supabase tras el [ADR 0007](../adr/0007-migracion-dokploy-postgresql.md). | Baja | Limpiados `.env.example` y `conftest.py` para usar exclusivamente `DATABASE_URL`, `JWT_SECRET`, `JWT_EXPIRES_DAYS`, `CORS_ORIGINS` y `UPLOAD_DIR`. | **Hecho** |
| 9 | Verificación de existencia de paquetes | Python / Dart | Prevención de dependencias alucinadas o *typosquatting* al incorporar librerías propuestas por IA ([docs/ia.md](../ia.md)). | Informativa | Verificar cada paquete contra PyPI / `pub.dev` antes de instalarlo. | **Hecho** |
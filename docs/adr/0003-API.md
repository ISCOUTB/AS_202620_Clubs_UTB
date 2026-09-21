# ADR 0003: Estrategia de integración: API REST síncrona con contrato OpenAPI

## Estado
Aceptado

## Fecha
20/09/2026

## Contexto
La app Flutter necesita consultar clubes y eventos, inscribirse en un club, confirmar asistencia y publicar avisos, encuestas y noticias (personas descritas en `docs/c4/contexto.md`). Cada una de estas operaciones requiere una respuesta inmediata: la confirmación de que se realizó o un error claro.

El equipo tiene 4 integrantes y el cronograma del curso no contempla adoptar tecnologías nuevas (restricción de tiempo C2, sección 2.3 de arc42). Además, el proyecto sigue un enfoque API-first: el contrato se define antes que el código y se verifica automáticamente en el pipeline.

Una versión anterior de este contrato planteaba también un flujo asíncrono de notificaciones (evento `publicacion.creada`, descrito con AsyncAPI). Se dejó fuera de esta decisión porque hoy no existe ningún consumidor de notificaciones, no se ha elegido un mecanismo de transporte, y la entrega admite un único contrato (OpenAPI o AsyncAPI).

## Alternativas

### Mensajería asíncrona con contrato AsyncAPI para notificaciones (diferida)
Permitiría avisar a miembros e interesados sin bloquear la creación de la publicación. Se difiere porque no hay consumidores (servicio de notificaciones push), no se ha elegido broker ni cola, y agregaría infraestructura desconocida para el equipo. Si las notificaciones se implementan, se registrará un ADR nuevo con su contrato AsyncAPI.

### Todo asíncrono (descartada)
El cliente no recibiría confirmación inmediata de operaciones como crear una publicación o inscribirse en un club.

### Consulta periódica (polling) desde la app (descartada)
Consume más recursos y no aporta ventaja sobre REST para las consultas de clubes y eventos.

### GraphQL (descartada)
No hay una necesidad de consultas flexibles que la justifique y el equipo no tiene experiencia previa con esa tecnología.

## Decisión
- Toda la integración entre la app Flutter y el backend es REST síncrono sobre HTTPS, con cuerpos JSON.
- El contrato vive en `docs/api/openapi.yaml` (OpenAPI 3.1) y se versiona con SemVer propio, independiente de la versión del código. Los cambios se registran en `docs/api/CHANGELOG.md`.
- El formato de error es uniforme: `{"detail": "mensaje legible"}` en `401`, `403`, `404`, `409` y `422`.
- La autenticación es Bearer JWT emitido por Supabase Auth; las consultas son públicas y toda escritura requiere sesión.
- El pipeline verifica el contrato en cada Pull Request: lint del archivo, prueba de que el código lo cumple y detección de cambios incompatibles frente a `master`.

## Consecuencias

### Positivas
- Un solo contrato que mantener y probar.
- Coherente con FastAPI, que ya expone su propio OpenAPI y permite comparar las rutas del código con las del contrato.
- El contrato es la fuente de verdad: si el código y el contrato divergen, el pipeline falla.
- Un cambio incompatible en el contrato no se puede mezclar sin subir la versión mayor.

### Negativas
- Las notificaciones a miembros e interesados no existen todavía.
- Si se agregan después, el flujo de creación de publicaciones se extenderá y habrá que decidir el mecanismo de transporte (nuevo ADR).
- La mayor parte del contrato describe endpoints aún no implementados; el estado por endpoint se mantiene en la sección 5 de `docs/api/contrato_api.md`.

## Verificación
El workflow [`contrato.yml`](../../.github/workflows/contrato.yml) ejecuta tres jobs:
- `lint-contrato`: valida `openapi.yaml` con spectral.
- `prueba-contrato`: [`test_contrato_openapi.py`](../../backend/tests/test_contrato_openapi.py) comprueba que las respuestas reales del backend cumplen los esquemas del contrato y que las rutas del código existen en él.
- `cambios-incompatibles`: compara el contrato del PR contra `master` con oasdiff.

## Trazabilidad
- **Contrato:** [`docs/api/openapi.yaml`](../api/openapi.yaml), explicado en [`docs/api/contrato_api.md`](../api/contrato_api.md).
- **Escenarios de calidad relacionados:** U3 (validación de token en endpoints protegidos) y C1 (nuevo tipo de publicación), en [Sección 10](../arc42/10_requisitos_de_calidad.md); también el escenario de portabilidad de proveedor, por el uso de identificadores como `string` en las rutas.
- **Restricciones:** T2 (FastAPI) y C2 de tiempo (sin tecnologías nuevas), en [Sección 2](../arc42/02_restricciones.md).
- **Decisiones relacionadas:** [ADR 0001](0001-hexagonal.md) (los routers son adaptadores de entrada) y [ADR 0002](0002-ajuste-contextos-publicaciones.md) (contexto Publicaciones).
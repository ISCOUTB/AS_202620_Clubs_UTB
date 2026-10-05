# ADR 0005: Validación de tokens de sesión con JWT asimétrico (JWKS) en el backend

## Estado
Propuesto

## Fecha
04/10/2026

## Contexto
El escenario U3 (Seguridad) exige que toda operación protegida valide el token de sesión emitido por Supabase Auth (restricción T4). Hoy cualquier cliente puede crear publicaciones sin sesión: la prueba `test_publicar_sin_token_devuelve_401` falló con `201 == 401` antes de este cambio.

El contrato (ADR 0003) define las lecturas como públicas y toda escritura como protegida con Bearer JWT. Por eso la medida de U3 se interpreta como "100% de las rutas de escritura" y no como "100% de las rutas".

El proyecto de Supabase publica claves asimétricas: su JWKS (`/auth/v1/.well-known/jwks.json`) devuelve una clave `EC` / `P-256` con `alg: ES256`.

Este ADR cubre solo la **autenticación** (401). La autorización por rol (403) depende de la membresía del contexto Clubes, que aún no está implementado.

## Alternativas

### A. Validar el JWT localmente con la clave pública del JWKS (elegida)
El backend descarga y cachea las claves públicas, verifica firma, expiración, emisor y audiencia sin llamar a Supabase en cada petición.
**A favor:** no agrega una llamada de red por request (favorece U1); el backend no guarda ningún secreto; el formato del token queda aislado en un adaptador (capa anticorrupción del mapa de contextos).
**En contra:** no detecta tokens revocados antes de que expiren; depende de poder descargar el JWKS (si no es alcanzable, el backend responde 503).

### B. Llamar a `auth.get_user(token)` de Supabase en cada petición (descartada)
**A favor:** más simple; detecta sesiones revocadas.
**En contra:** suma una llamada de red a cada escritura (latencia, U1) y consume capacidad del proveedor con un límite de conexiones en capa gratuita (ADR 0004).

### C. Validar con el secreto compartido HS256 (descartada)
**En contra:** el proyecto ya usa claves asimétricas; obligaría a guardar un secreto en el backend, cuya filtración permitiría falsificar sesiones.

## Decisión
- Se adopta la alternativa A con la librería `PyJWT` (`pyjwt[crypto]`), aceptando solo el algoritmo `ES256`.
- Se valida firma, `exp`, `sub`, emisor (`<SUPABASE_URL>/auth/v1`) y audiencia (`authenticated`).
- Estructura hexagonal:
  - Puerto de salida `AuthPort` (`application/ports/outbound_auth_port.py`), que devuelve únicamente el `autor_id` (el `sub`), nunca claims, correo ni rol.
  - Adaptador `SupabaseJwtAuthAdapter` (`adapters/outbound/auth/`), la única pieza que conoce el formato del token de Supabase.
  - Dependencia de entrada `require_auth` (`adapters/inbound/api/auth_dependency.py`), aplicada a toda ruta de escritura.
- Respuestas de error con el formato uniforme `{"detail": "..."}`: `401` si falta el token o es inválido, `503` si el JWKS no es alcanzable (coherente con U2).
- `autor_id` viene siempre del token, nunca del cuerpo de la petición. `CrearPublicacionRequest` usa `extra="forbid"`, así que enviarlo en el cuerpo da 422.
- La entidad `Publicacion` guarda solo `autor_id` (identidad), según la regla de dueño único de `tabla_modulo.md`. El contrato sube a 1.1.0 (cambio aditivo): `autor_id` opcional en la respuesta `Publicacion`. **Decisión a confirmar por el equipo:** se expone en las lecturas públicas.

## Consecuencias

### Positivas
- Toda escritura exige sesión; la medida de U3 es automatizable (ver Verificación).
- Cambiar de proveedor de autenticación afecta solo al adaptador (escenario C2/C3, portabilidad).
- Los tests no dependen de la red: se sustituye `get_auth_port` con un `AuthFalso`.

### Negativas / costos asumidos
- Sin autorización por rol: cualquier usuario autenticado puede publicar en cualquier club. Se resolverá cuando exista la membresía del contexto Clubes (403).
- Un token revocado sigue siendo válido hasta su expiración.
- Exponer `autor_id` en lecturas públicas identifica a quien publicó por su UUID de Supabase.
- El adaptador real fue validado con un doble de prueba y contra la configuración del JWKS; **la prueba con un token de sesión real está pendiente** (ver Verificación).
- La latencia del camino de escritura no se ha medido todavía (U1).

### Riesgos y qué los dispararía
- Rotación o cambio de algoritmo de las claves en Supabase: el adaptador rechazaría tokens válidos. Habría que revisar `algorithms` y la caché de claves.
- Caída del JWKS: las escrituras responden 503.

## Verificación
- Rojo → verde: `test_publicar_sin_token_devuelve_401` (de `201 == 401` a 401).
- `backend/tests/test_auth.py`: sin token, token inválido, token válido, lectura pública, autor tomado del token.
- Medición de U3: `test_toda_ruta_de_escritura_exige_auth` recorre `app.routes` y reporta "1 de 1 rutas de escritura protegidas". Se comprobó que detecta el defecto al quitar `Depends(require_auth)` del router.
- JWKS del proyecto: clave `ES256`, curva `P-256`, solo clave pública.
- Suite completa: 21 pruebas en verde.
- Pendiente: prueba manual con un `access_token` real de Supabase (201 con su `sub` como `autor_id`; 401 con un token alterado).

## Trazabilidad
- **Escenarios:** U3 (token en endpoints protegidos), U2 (503 si el proveedor no responde), C2/C3 (portabilidad), C1 (sin tocar auth al agregar tipos).
- **Restricción:** T4 (Supabase Auth).
- **Código:** `backend/src/linkclub/application/ports/outbound_auth_port.py`, `adapters/outbound/auth/supabase_jwt_adapter.py`, `adapters/inbound/api/auth_dependency.py`, `adapters/inbound/api/publicacion_router.py`.
- **Pruebas:** `backend/tests/test_auth.py`, `backend/tests/test_contrato_openapi.py`.
- **Contrato:** `docs/api/openapi.yaml` v1.1.0.
- **Decisiones relacionadas:** ADR 0001 (hexagonal), ADR 0003 (REST + OpenAPI), ADR 0004 (Supabase).
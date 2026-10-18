# Contrato de API — LinkClub (diseño objetivo)

> **Qué es este documento:** el contrato de cómo **debería** comportarse la API
> de LinkClub una vez cubra las tres personas descritas en el
> [C4 de contexto](../c4/contexto.md) (Estudiante interesado, Miembro de club,
> Administrador de club), siguiendo el enfoque **API-first**: el contrato se
> define primero, en formato ejecutable, y el código se implementa y se prueba
> contra él — no al revés.
>
> **Qué NO es:** una descripción estática. Este contrato evoluciona. 
> La tabla de la sección 5 marca, endpoint por endpoint, qué está implementado 
> y qué es la meta a construir.

## 1. Alcance: de las personas del C4 a las operaciones

| Persona (C4 contexto) | Necesita poder... | Operaciones de este contrato |
|---|---|---|
| Estudiante interesado | Buscar y consultar clubes y eventos | `GET /clubes`, `GET /clubes/{club_id}`, `GET /clubes/{club_id}/eventos`, `GET /eventos/{evento_id}` |
| Estudiante interesado | Registrarse en la plataforma | `POST /auth/registro` |
| Estudiante interesado | Inscribirse en un club | `POST /clubes/{club_id}/miembros` |
| Miembro de club | Consultar el calendario y confirmar asistencia | `GET /clubes/{club_id}/eventos`, `POST /eventos/{evento_id}/asistencia` |
| Miembro / Administrador de club | Publicar avisos, eventos y noticias | `POST /clubes/{club_id}/eventos`, `POST /clubes/{club_id}/publicaciones` |
| Administrador de club | Ver y gestionar los miembros de su club | `GET /clubes/{club_id}/miembros` |
| (Todos) Autenticación | Iniciar sesión y obtener token JWT | `POST /auth/login` y `Authorization: Bearer <token JWT local>` en cada operación privada |

**Decisión de modelado:** *evento* y *publicación* son recursos separados, no
un mismo `tipo` reutilizado. Un evento tiene fecha y lugar (campos que no
tienen sentido en un aviso o una encuesta) y responde a una pregunta distinta
("¿qué va a pasar y cuándo?" vs. "¿qué necesito saber ahora mismo?"). Dentro
de *publicación* sí se reutiliza una sola entidad para `aviso`, `encuesta` y
`noticia`, porque esos tres SÍ comparten forma (título + contenido) y es
exactamente el escenario de cambio **C1** del árbol de utilidad: agregar un
tipo nuevo de publicación sin tocar clubes ni eventos.

## 2. Convenciones del contrato

- **Autenticación:** Bearer JWT nativo, emitido por el propio backend (FastAPI), validado contra PostgreSQL (Supabase fue descartado). Las operaciones de solo lectura son públicas (un interesado no necesita sesión para explorar clubes); toda escritura requiere sesión, y algunas además requieren un rol específico dentro de ese club (escenario **U3**).
- **Idempotencia:** Las operaciones críticas de escritura (ej. crear publicaciones) exigen una cabecera `Idempotency-Key` (UUID v4 generado por el cliente) para mitigar fallos parciales de red y evitar registros duplicados.
- **Formato de error uniforme:** toda respuesta de error usa `{"detail": "mensaje legible"}`, igual en `401`, `403`, `404`, `409` y `422`, para que el cliente maneje errores con un único shape.
- **Identificadores:** `string` con formato `uuid` en las respuestas. En la URL se aceptan como `string` simple.
- **Versionado:** `info.version` sigue SemVer sobre el propio contrato, independiente de la versión del código.

## 3. Contrato síncrono (REST) — OpenAPI 3.1

```yaml
openapi: 3.1.0
info:
  title: LinkClub API
  summary: Contrato objetivo de la API de LinkClub (diseño API-first).
  description: >
    Fuente única de verdad del contrato entre el backend de LinkClub y sus
    consumidores (app Flutter). Cubre las tres personas descritas en el C4 de
    contexto. Se gestiona de forma autónoma sin depender de BaaS externos.
  version: 1.2.0
servers:
  - url: [https://api-linkclub.iscoutb.dev](https://api-linkclub.iscoutb.dev)
    description: Entorno de Producción (Dokploy)
  - url: http://localhost:8000
    description: Entorno local de desarrollo

tags:
  - name: health
  - name: auth
  - name: clubes
  - name: membresias
  - name: eventos
  - name: publicaciones

security:
  - bearerAuth: []

paths:
  /health:
    get:
      operationId: getHealth
      tags: [health]
      summary: Estado de salud del backend.
      security: []
      responses:
        "200":
          description: El servicio está operativo.
          content:
            application/json:
              schema: { $ref: "#/components/schemas/HealthStatus" }

  /auth/login:
    post:
      operationId: loginUsuario
      tags: [auth]
      summary: Iniciar sesión y obtener token JWT.
      description: Implementa el estándar OAuth2 usando Form Data.
      security: []
      requestBody:
        required: true
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              required: [username, password]
              properties:
                username: { type: string, description: "Correo del usuario" }
                password: { type: string }
      responses:
        "200":
          description: Token JWT emitido.
          content:
            application/json:
              schema:
                type: object
                properties:
                  access_token: { type: string }
                  token_type: { type: string, example: "bearer" }
        "401":
          $ref: "#/components/responses/CredencialesInvalidas"

  /auth/registro:
    post:
      operationId: registrarUsuario
      tags: [auth]
      summary: Crear una nueva cuenta de usuario.
      security: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [nombre, matricula, email, password]
              properties:
                nombre: { type: string }
                matricula: { type: string }
                email: { type: string, format: email }
                password: { type: string, minLength: 8 }
      responses:
        "201":
          description: Cuenta creada (opcionalmente devuelve token).
        "409":
          description: El correo o la matrícula ya existen.
          content:
            application/json:
              schema: { $ref: "#/components/schemas/ErrorResponse" }

  /clubes:
    get:
      operationId: listarClubes
      tags: [clubes]
      summary: Lista y busca clubes.
      description: Consulta abierta al público objetivo.
      security: []
      parameters:
        - name: q
          in: query
          schema: { type: string }
          description: Búsqueda por nombre o descripción.
        - name: categoria
          in: query
          schema: { type: string }
      responses:
        "200":
          description: Clubes que coinciden con el filtro.
          content:
            application/json:
              schema:
                type: array
                items: { $ref: "#/components/schemas/Club" }

  /clubes/{club_id}:
    get:
      operationId: obtenerClub
      tags: [clubes]
      summary: Detalle de un club.
      security: []
      parameters:
        - $ref: "#/components/parameters/ClubId"
      responses:
        "200":
          description: Club encontrado.
          content:
            application/json:
              schema: { $ref: "#/components/schemas/Club" }
        "404":
          $ref: "#/components/responses/NoEncontrado"

  /clubes/{club_id}/miembros:
    get:
      operationId: listarMiembros
      tags: [membresias]
      summary: Lista los miembros de un club.
      parameters:
        - $ref: "#/components/parameters/ClubId"
      responses:
        "200":
          description: Miembros del club.
          content:
            application/json:
              schema:
                type: array
                items: { $ref: "#/components/schemas/Membresia" }
        "401":
          $ref: "#/components/responses/NoAutenticado"
        "403":
          $ref: "#/components/responses/SinPermiso"
    post:
      operationId: unirseAClub
      tags: [membresias]
      summary: Un estudiante autenticado se inscribe en un club.
      parameters:
        - $ref: "#/components/parameters/ClubId"
      responses:
        "201":
          description: Membresía creada.
          content:
            application/json:
              schema: { $ref: "#/components/schemas/Membresia" }
        "401":
          $ref: "#/components/responses/NoAutenticado"
        "409":
          description: El usuario ya es miembro de este club.
          content:
            application/json:
              schema: { $ref: "#/components/schemas/ErrorResponse" }

  /clubes/{club_id}/eventos:
    get:
      operationId: listarEventosDeClub
      tags: [eventos]
      summary: Lista los eventos de un club.
      security: []
      parameters:
        - $ref: "#/components/parameters/ClubId"
      responses:
        "200":
          description: Eventos del club.
          content:
            application/json:
              schema:
                type: array
                items: { $ref: "#/components/schemas/Evento" }
    post:
      operationId: crearEvento
      tags: [eventos]
      summary: Publica un nuevo evento del club.
      parameters:
        - $ref: "#/components/parameters/ClubId"
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: "#/components/schemas/CrearEventoRequest" }
      responses:
        "201":
          description: Evento creado.
          content:
            application/json:
              schema: { $ref: "#/components/schemas/Evento" }
        "401":
          $ref: "#/components/responses/NoAutenticado"
        "403":
          $ref: "#/components/responses/SinPermiso"
        "422":
          $ref: "#/components/responses/DatosInvalidos"

  /eventos/{evento_id}:
    get:
      operationId: obtenerEvento
      tags: [eventos]
      summary: Detalle de un evento.
      security: []
      parameters:
        - $ref: "#/components/parameters/EventoId"
      responses:
        "200":
          description: Evento encontrado.
          content:
            application/json:
              schema: { $ref: "#/components/schemas/Evento" }
        "404":
          $ref: "#/components/responses/NoEncontrado"

  /eventos/{evento_id}/asistencia:
    post:
      operationId: confirmarAsistencia
      tags: [eventos]
      summary: Confirma o cancela la asistencia a un evento.
      parameters:
        - $ref: "#/components/parameters/EventoId"
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: "#/components/schemas/ConfirmarAsistenciaRequest" }
      responses:
        "200":
          description: Estado de asistencia actualizado.
          content:
            application/json:
              schema: { $ref: "#/components/schemas/Asistencia" }
        "401":
          $ref: "#/components/responses/NoAutenticado"
        "404":
          $ref: "#/components/responses/NoEncontrado"

  /clubes/{club_id}/publicaciones:
    get:
      operationId: listarPublicaciones
      tags: [publicaciones]
      summary: Lista los avisos, encuestas y noticias de un club.
      security: []
      parameters:
        - $ref: "#/components/parameters/ClubId"
      responses:
        "200":
          description: Publicaciones del club.
          content:
            application/json:
              schema:
                type: array
                items: { $ref: "#/components/schemas/Publicacion" }
    post:
      operationId: crearPublicacion
      tags: [publicaciones]
      summary: Crea un aviso, una encuesta o una noticia para el club.
      parameters:
        - $ref: "#/components/parameters/ClubId"
        - name: Idempotency-Key
          in: header
          required: true
          schema: { type: string, format: uuid }
          description: Llave única para mitigar fallos parciales de red (Idempotencia).
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: "#/components/schemas/CrearPublicacionRequest" }
      responses:
        "201":
          description: Publicación creada.
          content:
            application/json:
              schema: { $ref: "#/components/schemas/Publicacion" }
        "401":
          $ref: "#/components/responses/NoAutenticado"
        "403":
          $ref: "#/components/responses/SinPermiso"
        "409":
          description: Conflicto - Petición duplicada interceptada por Idempotencia.
          content:
            application/json:
              schema: { $ref: "#/components/schemas/ErrorResponse" }
        "422":
          $ref: "#/components/responses/DatosInvalidos"

  /publicaciones/{publicacion_id}:
    get:
      operationId: obtenerPublicacion
      tags: [publicaciones]
      summary: Detalle de una publicación.
      security: []
      parameters:
        - $ref: "#/components/parameters/PublicacionId"
      responses:
        "200":
          description: Publicación encontrada.
          content:
            application/json:
              schema: { $ref: "#/components/schemas/Publicacion" }
        "404":
          $ref: "#/components/responses/NoEncontrado"

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: Token de sesión nativo emitido por FastAPI (Reemplaza a Supabase).

  parameters:
    ClubId:
      name: club_id
      in: path
      required: true
      schema: { type: string }
    EventoId:
      name: evento_id
      in: path
      required: true
      schema: { type: string }
    PublicacionId:
      name: publicacion_id
      in: path
      required: true
      schema: { type: string }

  responses:
    NoAutenticado:
      description: Falta un token JWT válido.
      content:
        application/json:
          schema: { $ref: "#/components/schemas/ErrorResponse" }
    CredencialesInvalidas:
      description: Correo o contraseña incorrectos.
      content:
        application/json:
          schema: { $ref: "#/components/schemas/ErrorResponse" }
    SinPermiso:
      description: El usuario autenticado no tiene el rol requerido para esta acción.
      content:
        application/json:
          schema: { $ref: "#/components/schemas/ErrorResponse" }
    NoEncontrado:
      description: El recurso no existe.
      content:
        application/json:
          schema: { $ref: "#/components/schemas/ErrorResponse" }
    DatosInvalidos:
      description: El cuerpo de la petición no cumple las reglas del recurso.
      content:
        application/json:
          schema: { $ref: "#/components/schemas/ErrorResponse" }

  schemas:
    HealthStatus:
      type: object
      required: [status]
      properties:
        status: { type: string, example: ok }
      additionalProperties: false

    ErrorResponse:
      type: object
      required: [detail]
      properties:
        detail: { type: string }
      additionalProperties: false

    Club:
      type: object
      required: [id, nombre, descripcion, categoria, creado_en]
      properties:
        id: { type: string, format: uuid }
        nombre: { type: string }
        descripcion: { type: string }
        categoria: { type: string, example: deportes }
        creado_en: { type: string, format: date-time }
      additionalProperties: false

    Membresia:
      type: object
      required: [id, club_id, usuario_id, rol, creada_en]
      properties:
        id: { type: string, format: uuid }
        club_id: { type: string }
        usuario_id: { type: string }
        rol:
          type: string
          enum: [miembro, administrador]
        creada_en: { type: string, format: date-time }
      additionalProperties: false

    CrearEventoRequest:
      type: object
      required: [titulo, descripcion, fecha_inicio, lugar]
      properties:
        titulo: { type: string, minLength: 1 }
        descripcion: { type: string, minLength: 1 }
        fecha_inicio: { type: string, format: date-time }
        fecha_fin: { type: [string, "null"], format: date-time }
        lugar: { type: string, minLength: 1 }
      additionalProperties: false

    Evento:
      type: object
      required: [id, club_id, titulo, descripcion, fecha_inicio, lugar, creado_en]
      properties:
        id: { type: string, format: uuid }
        club_id: { type: string }
        titulo: { type: string }
        descripcion: { type: string }
        fecha_inicio: { type: string, format: date-time }
        fecha_fin: { type: [string, "null"], format: date-time }
        lugar: { type: string }
        creado_en: { type: string, format: date-time }
      additionalProperties: false

    ConfirmarAsistenciaRequest:
      type: object
      required: [estado]
      properties:
        estado:
          type: string
          enum: [confirmado, cancelado]
      additionalProperties: false

    Asistencia:
      type: object
      required: [id, evento_id, usuario_id, estado, actualizado_en]
      properties:
        id: { type: string, format: uuid }
        evento_id: { type: string }
        usuario_id: { type: string }
        estado:
          type: string
          enum: [confirmado, cancelado]
        actualizado_en: { type: string, format: date-time }
      additionalProperties: false

    TipoPublicacion:
      type: string
      description: >
        Enum extensible: agregar un nuevo tipo no debe requerir modificar más
        de 3 módulos (escenario de cambio C1).
      enum: [aviso, encuesta, noticia]

    CrearPublicacionRequest:
      type: object
      required: [titulo, contenido]
      properties:
        titulo: { type: string, minLength: 1 }
        contenido: { type: string, minLength: 1 }
        tipo:
          allOf: [{ $ref: "#/components/schemas/TipoPublicacion" }]
          default: aviso
        opciones:
          type: [array, "null"]
          items: { type: string }
          description: Obligatorio y no vacío cuando tipo = "encuesta".
      additionalProperties: false
      if:
        properties: { tipo: { const: encuesta } }
        required: [tipo]
      then:
        required: [opciones]
        properties:
          opciones: { type: array, minItems: 1, items: { type: string } }

    Publicacion:
      type: object
      required: [id, club_id, titulo, contenido, tipo, creado_en]
      properties:
        id: { type: string, format: uuid }
        club_id: { type: string }
        autor_id: { type: string}
        titulo: { type: string }
        contenido: { type: string }
        tipo: { $ref: "#/components/schemas/TipoPublicacion" }
        opciones:
          type: [array, "null"]
          items: { type: string }
        creado_en: { type: string, format: date-time }
      additionalProperties: false
```

## 4. Estado de implementación (a la fecha de este contrato)

| Operación | En el contrato | Implementado en `backend/` |
| --- | --- | --- |
| `GET /health` | ✅ | ✅ |
| Autenticación (`bearerAuth`) nativa | ✅ | ✅ Completamente migrado a FastAPI nativo (Supabase eliminado). |
| `POST /auth/login`, `POST /auth/registro` | ✅ | ✅ Rutas implementadas conectadas a BD propia. |
| `POST /clubes/{club_id}/publicaciones` (`tipo: aviso`, `encuesta`) | ✅ | ✅ Implementado, con diseño de Idempotencia activo. |
| `GET /clubes/{club_id}/publicaciones` | ✅ | ✅ Implementado y anidado correctamente. |
| `tipo: noticia` | ✅ | ❌ pendiente (enum actual solo tiene `aviso`, `encuesta`) |
| `GET /clubes`, `GET /clubes/{club_id}` | ✅ | ❌ pendiente |
| `POST /clubes/{club_id}/miembros`, `GET .../miembros` | ✅ | ❌ pendiente |
| `GET/POST /clubes/{club_id}/eventos`, `GET /eventos/{evento_id}` | ✅ | ❌ pendiente |
| `POST /eventos/{evento_id}/asistencia` | ✅ | ❌ pendiente |

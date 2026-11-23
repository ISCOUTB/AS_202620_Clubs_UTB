# 6. Vista de ejecución

Esta sección documenta, mediante diagramas de secuencia, cómo se comporta **LinkClub** en tiempo de ejecución en sus recorridos principales implementados de extremo a extremo: comprobación de salud, autenticación y carga de sesión, creación idempotente de publicaciones y gestión de eventos/asistencia.

## 6.1. Escenario: consulta de estado (`GET /health`)

```mermaid
sequenceDiagram
    actor C as Cliente / Operador
    participant R as health_router<br/>(Adaptador de entrada)
    participant UC as CheckHealthUseCase<br/>(Aplicación)
    participant P as StatusPort<br/>(Puerto de salida)
    participant A as PostgresStatusAdapter<br/>(Adaptador de salida)
    participant DB as PostgreSQL 18

    C->>R: GET /health
    R->>UC: check()
    UC->>P: get_status()
    P->>A: get_status()
    A->>DB: SELECT 1
    alt Base de datos disponible
        DB-->>A: 1
        A-->>P: "ok"
        P-->>UC: "ok"
        UC-->>R: {"status": "ok", "database": "online"}
        R-->>C: 200 OK {"status": "ok", "database": "online"}
    else Base de datos no disponible
        DB-->>A: Error de conexión
        A-->>P: "error"
        P-->>UC: "error"
        UC-->>R: ServicioNoDisponible
        R-->>C: 503 Service Unavailable {"detail": "Base de datos no disponible"}
    end
```

## 6.2. Escenario: inicio de sesión y resolución de rol (`POST /auth/login` + `GET /usuarios/me`)

```mermaid
sequenceDiagram
    actor U as Usuario (Flutter)
    participant UI as LoginScreen / SessionController
    participant API as auth_router / usuario_router
    participant DB as PostgreSQL 18 (usuarios)

    U->>UI: Ingresa correo/matrícula y contraseña
    UI->>API: POST /auth/login (JSON o form-urlencoded)
    API->>DB: Consulta usuario por correo o matrícula
    DB-->>API: Registro UsuarioModel (password_hash, rol, verificado, estado_cuenta)
    API->>API: Verifica hash bcrypt y estado_cuenta == "ACTIVO"
    alt Credenciales válidas
        API-->>UI: 200 OK {"access_token": "<JWT HS256>", "token_type": "bearer"}
        UI->>UI: Guarda JWT en flutter_secure_storage
        UI->>API: GET /usuarios/me (Authorization: Bearer <JWT>)
        API->>DB: Consulta perfil, club administrado y solicitud pendiente
        DB-->>API: Datos de perfil
        API-->>UI: 200 OK PerfilUsuario
        UI-->>U: Navega a ClubsPage con permisos según rol
    else Credenciales inválidas o cuenta inactiva
        API-->>UI: 401 Unauthorized / 403 Forbidden {"detail": "..."}
        UI-->>U: Muestra mensaje de error
    end
```

## 6.3. Escenario: creación idempotente de una publicación (`POST /clubes/{club_id}/publicaciones`)

```mermaid
sequenceDiagram
    actor A as Admin de Club (Flutter)
    participant UI as CreatePublicationScreen / ApiClient
    participant R as publicacion_router
    participant AUTH as auth_dependency
    participant UC as CrearPublicacionUseCase
    participant REPO as PublicacionRepositoryPostgres
    participant DB as PostgreSQL 18

    A->>UI: Redacta aviso/encuesta/noticia y confirma
    UI->>UI: Interceptor inyecta Bearer JWT e Idempotency-Key (UUID v4)
    UI->>R: POST /clubes/{club_id}/publicaciones
    R->>AUTH: require_auth(Bearer token)
    AUTH-->>R: autor_id (matrícula)
    R->>DB: Verifica rol (ADMIN_CLUB verificado del club o SUPERADMIN)
    alt Sin permisos sobre el club
        R-->>UI: 403 Forbidden {"detail": "..."}
    else Autorizado
        R->>UC: ejecutar(club_id, autor_id, titulo, contenido, tipo, opciones, idempotency_key)
        UC->>REPO: obtener_por_idempotencia(autor_id, idempotency_key)
        REPO->>DB: SELECT en publicaciones por (autor_matricula, idempotency_key)
        alt Clave ya usada con mismo payload
            DB-->>REPO: PublicacionModel existente
            REPO-->>UC: Publicacion existente
            UC-->>R: Publicacion existente
            R-->>UI: 201 Created (respuesta idempotente sin duplicar)
        else Clave ya usada con distinto payload
            UC-->>R: PublicacionDuplicada
            R-->>UI: 409 Conflict {"detail": "..."}
        else Nueva publicación
            UC->>REPO: guardar(publicacion)
            REPO->>DB: INSERT INTO publicaciones
            DB-->>REPO: Registro persistido
            REPO-->>UC: Publicacion
            UC-->>R: Publicacion
            R-->>UI: 201 Created PublicacionResponse
        end
    end
    UI-->>A: Actualiza feed y muestra confirmación
```

## 6.4. Escenario: programación de evento y confirmación de asistencia (`POST /eventos` y `POST /eventos/{evento_id}/asistencia`)

```mermaid
sequenceDiagram
    actor E as Estudiante / Admin (Flutter)
    participant UI as App Flutter (EventRepository)
    participant R as evento_router
    participant AUTH as auth_dependency
    participant DB as PostgreSQL 18

    E->>UI: Pulsa "Asistir" en un evento
    UI->>R: POST /eventos/{evento_id}/asistencia (Bearer JWT + Idempotency-Key)
    R->>AUTH: get_current_user()
    AUTH->>DB: Valida JWT y usuario activo
    DB-->>AUTH: UsuarioModel
    R->>DB: Consulta registro en asistencias (evento_id, usuario_matricula)
    alt No estaba confirmado
        R->>DB: INSERT INTO asistencias (estado="confirmado")
        R-->>UI: 200 OK {"usuario_asiste": true, "total_asistentes": N+1}
    else Ya estaba confirmado
        R->>DB: DELETE FROM asistencias
        R-->>UI: 200 OK {"usuario_asiste": false, "total_asistentes": N-1}
    end
    UI-->>E: Actualiza botón y contador en tiempo real
```
-- 001_esquema_inicial.sql
-- SQL estándar de PostgreSQL (>= 13, gen_random_uuid() es nativo). Sin extensiones.
-- Regla de dueño único: las tablas se relacionan solo por id (FK), sin copiar datos.

CREATE TABLE usuarios (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    matricula     text NOT NULL UNIQUE CHECK (matricula ~ '^T[0-9]{7,8}$'),
    nombre        text NOT NULL CHECK (length(btrim(nombre)) > 0),
    correo        text NOT NULL CHECK (correo ~ '^[^@[:space:]]+@utb\.edu\.co$'),
    password_hash text NOT NULL,
    rol           text NOT NULL DEFAULT 'estudiante' CHECK (rol IN ('estudiante')),
    creado_en     timestamptz NOT NULL DEFAULT now()
);
-- Correo único sin distinguir mayúsculas.
CREATE UNIQUE INDEX usuarios_correo_unico ON usuarios (lower(correo));

CREATE TABLE clubes (
    id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre               text NOT NULL CHECK (length(btrim(nombre)) > 0),
    descripcion          text NOT NULL,
    descripcion_completa text,
    categoria            text NOT NULL,
    icono                text,
    horario              text,
    lugar                text,
    creado_en            timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX clubes_nombre_unico ON clubes (lower(nombre));
CREATE INDEX clubes_categoria_idx ON clubes (categoria);

CREATE TABLE membresias (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id    uuid NOT NULL REFERENCES clubes (id) ON DELETE CASCADE,
    usuario_id uuid NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    rol        text NOT NULL DEFAULT 'miembro' CHECK (rol IN ('miembro', 'administrador')),
    creada_en  timestamptz NOT NULL DEFAULT now(),
    UNIQUE (club_id, usuario_id)
);
CREATE INDEX membresias_usuario_idx ON membresias (usuario_id);

CREATE TABLE publicaciones (
    id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id   uuid NOT NULL REFERENCES clubes (id) ON DELETE CASCADE,
    autor_id  uuid NOT NULL REFERENCES usuarios (id),
    titulo    text NOT NULL CHECK (length(btrim(titulo)) > 0),
    contenido text NOT NULL CHECK (length(btrim(contenido)) > 0),
    tipo      text NOT NULL DEFAULT 'aviso' CHECK (tipo IN ('aviso', 'encuesta', 'noticia')),
    opciones  jsonb,
    creado_en timestamptz NOT NULL DEFAULT now(),
    CHECK (tipo <> 'encuesta' OR (opciones IS NOT NULL AND jsonb_array_length(opciones) > 0))
);
CREATE INDEX publicaciones_club_idx ON publicaciones (club_id, creado_en DESC);

CREATE TABLE eventos (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id      uuid NOT NULL REFERENCES clubes (id) ON DELETE CASCADE,
    autor_id     uuid NOT NULL REFERENCES usuarios (id),
    titulo       text NOT NULL CHECK (length(btrim(titulo)) > 0),
    descripcion  text NOT NULL,
    fecha_inicio timestamptz NOT NULL,
    fecha_fin    timestamptz,
    lugar        text NOT NULL,
    creado_en    timestamptz NOT NULL DEFAULT now(),
    CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);
CREATE INDEX eventos_club_idx ON eventos (club_id, fecha_inicio);

CREATE TABLE asistencias (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    evento_id      uuid NOT NULL REFERENCES eventos (id) ON DELETE CASCADE,
    usuario_id     uuid NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    estado         text NOT NULL CHECK (estado IN ('confirmado', 'cancelado')),
    actualizado_en timestamptz NOT NULL DEFAULT now(),
    UNIQUE (evento_id, usuario_id)
);

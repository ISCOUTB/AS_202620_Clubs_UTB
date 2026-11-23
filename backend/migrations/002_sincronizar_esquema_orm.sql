ALTER TABLE clubes
    ADD COLUMN IF NOT EXISTS descripcion_completa TEXT,
    ADD COLUMN IF NOT EXISTS icono VARCHAR,
    ADD COLUMN IF NOT EXISTS logo_url TEXT,
    ADD COLUMN IF NOT EXISTS horario VARCHAR,
    ADD COLUMN IF NOT EXISTS lugar VARCHAR,
    ADD COLUMN IF NOT EXISTS lider VARCHAR,
    ADD COLUMN IF NOT EXISTS redes_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS inscripciones_abiertas BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS ms_forms_url TEXT,
    ADD COLUMN IF NOT EXISTS aviso_inscripcion TEXT,
    ADD COLUMN IF NOT EXISTS creado_en TIMESTAMPTZ NOT NULL DEFAULT now();

DO $$
BEGIN
    ALTER TABLE usuarios DROP CONSTRAINT IF EXISTS usuarios_rol_check;
EXCEPTION
    WHEN undefined_table THEN NULL;
END $$;

ALTER TABLE usuarios
    ADD COLUMN IF NOT EXISTS rol VARCHAR(20) NOT NULL DEFAULT 'ESTUDIANTE',
    ADD COLUMN IF NOT EXISTS verificado BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN IF NOT EXISTS club_administrado_id UUID REFERENCES clubes(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS descripcion TEXT,
    ADD COLUMN IF NOT EXISTS foto_perfil_url TEXT,
    ADD COLUMN IF NOT EXISTS estado_cuenta VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
    ADD COLUMN IF NOT EXISTS creado_en TIMESTAMPTZ NOT NULL DEFAULT now();

ALTER TABLE publicaciones
    ADD COLUMN IF NOT EXISTS autor_matricula VARCHAR,
    ADD COLUMN IF NOT EXISTS tipo VARCHAR NOT NULL DEFAULT 'aviso',
    ADD COLUMN IF NOT EXISTS opciones JSONB,
    ADD COLUMN IF NOT EXISTS imagen_url TEXT,
    ADD COLUMN IF NOT EXISTS creado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
    ADD COLUMN IF NOT EXISTS idempotency_key VARCHAR;

CREATE UNIQUE INDEX IF NOT EXISTS uq_publicaciones_autor_idempotency
    ON publicaciones (autor_matricula, idempotency_key);

DO $$
BEGIN
    ALTER TABLE publicaciones ALTER COLUMN autor_id DROP NOT NULL;
EXCEPTION
    WHEN undefined_column THEN NULL;
END $$;

ALTER TABLE eventos
    ADD COLUMN IF NOT EXISTS autor_matricula VARCHAR,
    ADD COLUMN IF NOT EXISTS visibilidad VARCHAR(20) NOT NULL DEFAULT 'PUBLICO',
    ADD COLUMN IF NOT EXISTS enlace_registro_ms TEXT,
    ADD COLUMN IF NOT EXISTS imagen_url TEXT,
    ADD COLUMN IF NOT EXISTS creado_en TIMESTAMPTZ NOT NULL DEFAULT now();

DO $$
BEGIN
    ALTER TABLE eventos ALTER COLUMN autor_id DROP NOT NULL;
EXCEPTION
    WHEN undefined_column THEN NULL;
END $$;

ALTER TABLE asistencias
    ADD COLUMN IF NOT EXISTS usuario_matricula VARCHAR,
    ADD COLUMN IF NOT EXISTS estado VARCHAR(20) NOT NULL DEFAULT 'confirmado',
    ADD COLUMN IF NOT EXISTS actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now();

CREATE UNIQUE INDEX IF NOT EXISTS uq_asistencias_evento_usuario
    ON asistencias (evento_id, usuario_matricula);

DO $$
BEGIN
    ALTER TABLE asistencias ALTER COLUMN usuario_id DROP NOT NULL;
EXCEPTION
    WHEN undefined_column THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS solicitudes_admin_club (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_matricula VARCHAR(20) NOT NULL REFERENCES usuarios(matricula) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES clubes(id) ON DELETE CASCADE,
    justificacion TEXT NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    revisado_por VARCHAR(20),
    creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE solicitudes_admin_club
    ADD COLUMN IF NOT EXISTS revisado_por VARCHAR(20),
    ADD COLUMN IF NOT EXISTS creado_en TIMESTAMPTZ NOT NULL DEFAULT now();
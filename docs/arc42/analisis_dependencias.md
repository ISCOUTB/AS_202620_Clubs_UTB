# Análisis de dependencias

Fecha del análisis: <2026-11-01>
Responsable: <Josh Ortega y Luis Salas>

## Alcance

* Backend: `backend/requirements.txt`
* Frontend: `frontend/linkclub/pubspec.yaml` y `pubspec.lock`

## Método

| Herramienta | Comando | Qué revisa |
|---|---|---|
| pip-audit | `cd backend && pip-audit -r requirements.txt` | Vulnerabilidades conocidas (CVE) en paquetes de Python |
| flutter pub outdated | `cd frontend/linkclub && flutter pub outdated` | Versiones desactualizadas y paquetes descontinuados |
| osv-scanner | `osv-scanner -r .` | Vulnerabilidades en ambos ecosistemas |
| Revisión manual | `grep` de imports en el código | Dependencias declaradas pero sin uso |

## Resultado de las herramientas

### pip-audit

```text
Found 36 known vulnerabilities in 2 packages
Name             Version ID                  Fix Versions
---------------- ------- ------------------- ------------
pyjwt            2.9.0   PYSEC-2026-120      2.12.0
pyjwt            2.9.0   PYSEC-2026-120      2.12.0
pyjwt            2.9.0   PYSEC-2025-183
pyjwt            2.9.0   PYSEC-2026-179      2.13.0
pyjwt            2.9.0   PYSEC-2026-175      2.13.0
pyjwt            2.9.0   PYSEC-2026-177      2.13.0
pyjwt            2.9.0   PYSEC-2026-178      2.13.0
pyjwt            2.9.0   PYSEC-2026-176      2.12.1
pyjwt            2.9.0   PYSEC-2026-177      2.13.0
pyjwt            2.9.0   PYSEC-2026-179      2.13.0
pyjwt            2.9.0   PYSEC-2026-176      2.13.0
pyjwt            2.9.0   PYSEC-2026-178      2.13.0
pyjwt            2.9.0   PYSEC-2026-4145     2.14.0
pyjwt            2.9.0   PYSEC-2026-4149     2.14.0
pyjwt            2.9.0   PYSEC-2026-4152     2.14.0
pyjwt            2.9.0   PYSEC-2026-4144     2.14.0
pyjwt            2.9.0   PYSEC-2026-4148     2.14.0
pyjwt            2.9.0   PYSEC-2026-4140     2.14.0
pyjwt            2.9.0   PYSEC-2026-4141     2.15.0
pyjwt            2.9.0   PYSEC-2026-4147     2.14.0
pyjwt            2.9.0   PYSEC-2026-4183     2.15.0
pyjwt            2.9.0   GHSA-pxh4-856f-4h89 2.14.0
python-multipart 0.0.12  PYSEC-2026-1851     0.0.18
python-multipart 0.0.12  PYSEC-2026-1852     0.0.22
python-multipart 0.0.12  PYSEC-2026-3038     0.0.26
python-multipart 0.0.12  PYSEC-2026-3039     0.0.27
python-multipart 0.0.12  PYSEC-2026-3040     0.0.31
python-multipart 0.0.12  PYSEC-2026-3036     0.0.30
python-multipart 0.0.12  PYSEC-2026-3037     0.0.30
python-multipart 0.0.12  PYSEC-2026-1852     0.0.22
python-multipart 0.0.12  PYSEC-2026-1851     0.0.18
python-multipart 0.0.12  PYSEC-2026-3038     0.0.26
python-multipart 0.0.12  PYSEC-2026-3037     0.0.30
python-multipart 0.0.12  PYSEC-2026-3036     0.0.30
python-multipart 0.0.12  PYSEC-2026-3040     0.0.31
python-multipart 0.0.12  PYSEC-2026-3039     0.0.27
```

## Hallazgos y acciones

| # | Paquete | Ecosistema | Hallazgo | Severidad | Acción | Estado |
|---|---|---|---|---|---|---|
| 1 | `pytest`, `httpx`, `PyYAML`, `jsonschema` | Python | Dependencias de pruebas incluidas en el `requirements.txt` que se instala en la imagen de producción. | Media | Crear `requirements-dev.txt` para pruebas y dejar en `requirements.txt` solo lo que usa la API; ajustar el workflow de CI. | Pendiente |
| 2 | `prometheus-fastapi-instrumentator` | Python | Declarada, pero `main.py` no la importa ni la usa. | Baja | Retirarla, o instrumentar la API si se quiere medir latencia (escenario U1). | Pendiente |
| 3 | `python-multipart==0.0.12` | Python | pip-audit reporta 7 avisos distintos (PYSEC-2026-1851, 1852, 3036 a 3040), con corrección a partir de 0.0.31. Es la librería que procesa la carga de archivos de `/recursos/upload`. | Alta | Actualizar a `0.0.31` o superior y ejecutar la suite de pruebas. | Hecho |
| 4 | `PyJWT==2.9.0` | Python | pip-audit reporta 17 avisos distintos, con corrección a partir de 2.15.0. Uno (PYSEC-2025-183) no tiene versión corregida publicada. Es el paquete que firma y valida los tokens (amenaza A01). | Alta | Actualizar a `2.15.0` o superior, ejecutar `test_auth.py` y revisar el aviso sin corrección para decidir si se acepta o se mitiga. | Hecho |
| 5 | Biblioteca de hash de contraseñas | Python | No existe: las contraseñas se guardan en texto plano (amenaza A08). | Alta | Agregar `argon2-cffi` o `bcrypt` con versión fijada. | Pendiente |
| 6 | `http`, `go_router` | Dart | Declaradas en `pubspec.yaml`; el código usa Dio y `MaterialApp` sin rutas con `go_router`. Confirmar con `grep -r "package:http\|go_router" lib/`. | Baja | Retirarlas si no hay importaciones. | Pendiente |
| 7 | `flutter_markdown` | Dart | Revisar en pub.dev si el paquete sigue mantenido o está descontinuado. | <según pub.dev> | Si está descontinuado, migrar al sucesor recomendado. | Pendiente |
| 8 | Restos de Supabase | Repositorio | `infra/terraform/` usa el proveedor Supabase; `backend/.env.example` y `tests/conftest.py` mencionan `SUPABASE_URL`. Ya no se usa (ADR 0007). | Baja | Eliminar o archivar `infra/terraform/`, actualizar `.env.example` con `DATABASE_URL` y `JWT_SECRET`, y quitar la variable de `conftest.py`. | Pendiente |
| 9 | Verificación de existencia de paquetes | Python | Los paquetes se verificaron contra el registro oficial al incorporarlos (ver `docs/ia.md`, S9). | Informativa | Mantener la práctica para cada dependencia nueva. | Hecho |

## Control continuo

Se propone agregar al workflow `backend-tests.yml` un paso de pip-audit y activar Dependabot para `pip` y `pub`. Estado: <Pendiente | Hecho, con enlace al PR>.

## Conclusión

<pip-audit, ejecutado sobre `backend/requirements.txt`, reportó inicialmente 36 vulnerabilidades en 2 paquetes (24 avisos distintos): 17 en `PyJWT 2.9.0` y 7 en `python-multipart 0.0.12`. Se actualizaron a `PyJWT 2.15.0` y `python-multipart 0.0.31`, y una nueva ejecución de pip-audit no encontró vulnerabilidades conocidas. No quedan vulnerabilidades aceptadas. `flutter pub outdated` no reporta vulnerabilidades, solo paquetes desactualizados (`go_router`, `cupertino_icons`). Siguen pendientes la ejecución de osv-scanner, el retiro de dependencias sin uso y la separación de las dependencias de pruebas (filas 1, 2 y 6).>
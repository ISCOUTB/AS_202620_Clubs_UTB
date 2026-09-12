# LinkClub - Gestión de Clubes y Grupos UTB

> Repositorio académico: `AS_202620_Clubs_UTB` — Organización `ISCOUTB`
> Proyecto del curso **Arquitectura de Software** (NRC: 1495), 2026-20

## 1. Descripción del proyecto

En la universidad existen varios clubes y grupos estudiantiles (ajedrez, fútbol, música, entre otros), pero no hay una plataforma unificada donde estos puedan publicar avisos, eventos y novedades, ni donde los estudiantes interesados, estén ya vinculados a un grupo o no, puedan enterarse y mantenerse informados sobre lo que sucede en cada uno.

**LinkClub** busca resolver ese vacío: una aplicación que centraliza la gestión de avisos, eventos, grupos y noticias de los clubes universitarios, permitiendo tanto a los miembros como a los interesados externos seguir la actividad de cada club desde un solo lugar.

Este repositorio documenta el diseño y la evolución arquitectónica del proyecto: las decisiones tomadas, sus justificaciones y el contexto en que se aplican, siguiendo arc42, C4 y escenarios de calidad como marco de referencia a lo largo de todo el ciclo de vida del sistema.

## 2. Problema que resuelve

- **Fragmentación de la información:** Cada club comunica sus eventos por canales distintos (grupos de WhatsApp, redes sociales, carteleras físicas), sin un punto central.
- **Baja visibilidad para nuevos interesados:** Un estudiante que quiere unirse a un club no tiene una forma fácil ni directa de descubrir cuáles existen ni qué están haciendo.
- **Falta de trazabilidad institucional:** No hay un historial único de la actividad histórica de los grupos estudiantiles.

## 3. Stack tecnológico

| Componente | Tecnología | Estado |
|---|---|---|
| Frontend / App móvil | Flutter | Definido (requisito de la materia) |
| Backend / API | FastAPI | Definido (continuidad de la materia anterior) |
| Base de datos | Supabase | Definido (continuidad de la materia anterior) |
| Autenticación | Supabase Auth | Definido (continuidad de la materia anterior) |
| Metodología / arquitectura | Hexagonal | Definido (en fase de desarrollo bajo arquitectura) |

## 4. Estructura del repositorio

```
/docs
  aspectos.md          # Aspectos de calidad, tabla de 8 columnas (ID, Aspecto, Escenario, Requisito, C4, ADR, Código, Pruebas)
  ficha_problema.md
  ia.md                 # Registro de uso de IA en el proyecto
  /arc42
    01_introduccion_y_metas.md
    02_restricciones.md
    03_contexto_y_alcance.md
    04_estrategia_de_solucion.md
    05_vista_de_bloques.md
    06_vista_de_ejecucion.md
    09_decisiones_de_diseno.md      # Enlaza el ADR con el escenario que lo motiva
    10_requisitos_de_calidad.md   # Árbol de utilidad + escenarios de calidad
    12_glosario.md                # Listado de terminologías y conceptos usados dentro del proyecto
    matriz_comparativa_estilos.md
  /c4
    contexto.md          # Diagrama C4: contexto (nivel 1) y contenedores (nivel 2), en el mismo archivo
  /adr
    0001-hexagonal.md    # Decisión de estilo arquitectónico (aceptado)

/backend
  requirements.txt
  /src/linkclub
    main.py                                          # Punto de entrada de la API
    /adapters/inbound/api
      health_router.py                                # Endpoint /health
    /adapters/outbound/persistence
      in_memory_status_adapter.py                      # Adaptador de salida (implementación actual de StatusPort)
    /application/ports
      inbound_health_port.py                           # Puerto de entrada (HealthPort)
      outbound_status_port.py                          # Puerto de salida (StatusPort)
    /application/use_cases
      check_health.py                                  # Caso de uso: CheckHealthUseCase
    /domain
      (vacío — sin entidades de negocio todavía)
  /tests
    test_health.py                                     # Prueba automatizada del esqueleto ejecutable

README.md
```

## 5. Equipo

| Integrante | GitHub |
| ---|---|
| Hollman De Orta | @deortahollman-star |
| Josh Ortega | @Josh4OP |
| Diego Ramos | @devZavod |
| Luis Salas | @Luis-Salas-Reyes |

> Los 4 integrantes están añadidos como colaboradores del repositorio en GitHub.


## 6. Estado del proyecto

**En fase de planeación, dearrollo y documentación.** Se está desarrollando y probando código activamente entre pruebas y decisión de diseño y funcionalidades. Este README y la documentación de [`/docs`](docs/) sirven como línea base para la comprensión del proyecto y muestra de avance en retos semanales de curso.

---
*Curso de Arquitectura de Software — Universidad Tecnológica de Bolívar (UTB)*

## 7. Cómo arrancar

Requisitos previos: Python 3.10+

```bash
cd backend
python -m venv venv

# Activar el entorno virtual
source venv/bin/activate      # macOS / Linux
venv\Scripts\activate         # Windows

pip install -r requirements.txt
uvicorn linkclub.main:app --app-dir src
```

Verifica en <http://localhost:8000/health> — debe responder `{"status": "ok"}`.

### Correr las pruebas

```bash
PYTHONPATH=src pytest tests/ -v
```

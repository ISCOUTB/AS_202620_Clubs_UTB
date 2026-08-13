# LinkClub — Gestión de Clubes y Grupos UTB

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
| Base de datos | Supabase (o alternativa en evaluación) | En evaluación |
| Autenticación | Supabase Auth (o alternativa en evaluación) | En evaluación |
| Metodología / arquitectura | Por definir | Pendiente (se define en fase de arquitectura) |

> Nota: la elección de base de datos y autenticación no está cerrada aún. Esta tabla se actualiza en cuanto el equipo confirme la decisión — debe reflejarse también en `docs/arc42/02_restricciones.md` una vez definida.

## 4. Estructura del repositorio

```
/docs
  aspectos.md          # Aspectos de calidad declarados
  ia.md                 # Registro de uso de IA en el proyecto
  /arc42
    01_introduccion_y_metas.md
    02_restricciones.md
    03_contexto_y_alcance.md
    10_requisitos_de_calidad.md   # Árbol de utilidad + escenarios de calidad
  /c4
    contexto.md          # Diagrama C4 de contexto + lectura
  /adr
    (decisiones de arquitectura — se irán agregando)
README.md
```

## 5. Equipo

| Integrante | GitHub |
| ---|---|
| Hollman De Orta | @deortahollman-star |
| Josh Ortega | @Josh4OP |
| Diego Ramos | @devZavod |
| Luis Salas | @Luis-Salas-Reyes |

> Los 4 integrantes ya están añadidos como colaboradores del repositorio en GitHub.


## 6. Estado del proyecto

🟡 **En fase de planeación y documentación.** No hay desarrollo de código activo; el equipo está a la espera de la orden de inicio del docente. Este README y la documentación de `/docs` sirven como línea base para el siguiente reto de corte.

---
*Curso de Arquitectura de Software — Universidad Tecnológica de Bolívar (UTB)*

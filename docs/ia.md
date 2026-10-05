# Inteligencia Artificial

Las herramientas de IA se usan con contexto del proyecto (problema, decisiones ya tomadas, tipo de entrega del curso y lineamientos generales de la materia) — no como generador aislado sin conocimiento del repositorio.

## Registro de uso de IA

| Semana | Integrante | Para qué | Herramienta | Cómo se usó | Motivo |
|---|---|---|---|---|---|
| S9 | Josh Ortega | Elección y verificación de la dependencia para validar el JWT de Supabase Auth (U3), y borrador del adaptador `SupabaseJwtAuthAdapter`. | Claude | La herramienta propuso `pyjwt[crypto]` y advirtió que el paquete `jwt` es otro distinto. Se verificó en PyPI antes de instalarlo (`pip index versions pyjwt`, versión instalada: X.Y.Z). Se incorporó con ajustes. | La validación de tokens es una pieza de seguridad: un paquete homónimo equivocado podría ser inseguro o inexistente para este fin. La verificación se hizo contra el registro oficial, no contra la respuesta del modelo. El código del adaptador venía escrito de memoria sobre PyJWT 2.x, por lo que se probó antes de aceptarlo. |
| S9 | Diego Ramos / Equipo | Verificación de código generado (Health Check), auditoría de erosión arquitectónica y análisis de dependencias alucinadas. | Gemini | Auditoría crítica y mutación de pruebas. | Cumplir con la trazabilidad del aspecto S9: el volumen de código generado requiere verificación estricta para evitar cruce de contextos y dependencias falsas. |
| S8 | Diego Ramos | Redacción del ADR 0004 y Vista de Despliegue (arc42 Sec. 7) para la BD. | Gemini | Generación de opciones estructuradas y contraste de supuestos, aceptado con ajustes al volumen de tráfico UTB. | Se utilizó para formatear la decisión bajo la plantilla exigida y calcular el punto de quiebre de la capa gratuita frente a las restricciones de recursos del proyecto. |
| S6 | Hollman De Orta | Información de componentes de c4 nivel 3, como lo enfoco de acuerdo el diagrama que te anexo | Claude | Incorporado, con ajustes y correcciones propias | Se usó como asistente de redacción técnica; las decisiones de contenido (prioridades, atributos evaluados, alcance del sistema) partieron de la documentación que el equipo ya había producido |
| S4 | Hollman De Orta | Conversión exploratoria de un diagrama a código Mermaid siguiendo la especificación del modelo C4 | Claude | Se usó como prueba, no incorporado | Fue una consulta previa para validar el enfoque; el C4 nivel 2 final del repositorio se construyó por otra vía |
| S3-S4 | Josh Ortega | Organización del esqueleto del proyecto (estructura de carpetas hexagonal) y reparación de links rotos | Claude | Se usó parcialmente | Se ajustó a mano antes de incorporarlo al repositorio |
| S3 | Luis Salas | Guía sobre estructura y contenido de arc42 Sección 5, con ejemplo aplicado a LinkClub (niveles 1-3, diferencia con el ADR) | ChatGPT | Se usó parcialmente | La guía advirtió explícitamente no inventar componentes que no existen en el código; se usó como estructura, el contenido se ajusta al backend real |
| S3 | Diego Ramos | Corrección de enlaces rotos entre `04_estrategia_de_solucion.md` y el ADR (nombre de archivo inconsistente) | Claude | Se usó | Corrección puntual verificada contra el repositorio antes de aplicarse |
| S2 | Josh Ortega | Redacción de los escenarios de calidad (U1–U3, C1–C3), a partir de la guía de contenido de escenarios (uso/cambio, ATAM) | Claude | Se usó parcialmente | Contenido generado como base, corroborado y ajustado contra las metas de la Sección 1 |
| S1–S4 | Diego Ramos | Guía y esqueleto de `.md` para las distintas secciones de arc42, de forma recurrente | Claude | Se usó parcialmente | Contenido generado como punto de partida en cada sección; siempre modificado a mano antes de aceptarse |

---

## Semana 9 - Generación con IA: Verificación y Erosión

**Contexto:** Se auditó la porción de código correspondiente al Health Check y la conexión del backend (FastAPI) hacia la base de datos (Supabase), la cual fue construida parcialmente con asistencia de IA. El objetivo fue verificar la legitimidad del código, proteger los límites de contexto y comprobar que las pruebas no heredan el punto ciego del recurso generador.

### 1. Decisiones sobre el Código Generado
* **Qué aceptamos:** La estructura base del endpoint de FastAPI (`health_router.py`) y el uso de `pytest`. Se aceptó porque cumple con los estándares técnicos del framework y favorece el escenario de disponibilidad (U2).
* **Qué corregimos (Erosión Arquitectónica detectada):** El modelo sugirió inicialmente instanciar el cliente de base de datos (`supabase`) directamente dentro de la capa de red del router[cite: 11]. Esto constituye **erosión arquitectónica** porque viola el límite de contexto de la arquitectura hexagonal ([ADR-0001](adr/0001-hexagonal.md)). **Corrección:** Se eliminó ese import y se delegó la conexión estrictamente a los puertos y adaptadores de salida (`in_memory_status_adapter.py`).
* **Qué rechazamos (Dependencias Alucinadas y Secretos):** La IA propuso importar una librería llamada `supabase-fastapi-health-checker` e inyectar la URL y la Key estáticamente en el código. **Rechazo total:** Se verificó en PyPI que la dependencia no existe (alucinación). Además, quemar secretos en un repositorio público expone credenciales; se implementó el uso estricto de un archivo `.env`.

### 2. Verificación y Prueba (Rompiendo el código a propósito)
Para evitar el error de aceptar pruebas que comparten el punto ciego del código generado, se aplicó una mutación intencional. Se alteró el código de producción del health check para que devolviera `{"status": "caido_por_error"}` en lugar del estado real. Al ejecutar `pytest`, **la prueba falló (lanzando un AssertionError)**, lo que demuestra que la prueba automatizada verdaderamente vigila la lógica y protege la funcionalidad. *(Evidencia alojada en la fila U2 de aspectos.md).*

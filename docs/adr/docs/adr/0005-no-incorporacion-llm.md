# ADR 0005: Decisión de no incorporar un componente generativo (LLM) en el sistema

## Estado
Aceptado

## Fecha
04/10/2026

## Contexto
Como parte de la evolución de LinkClub, se evaluó la posibilidad de integrar un modelo fundacional generativo (LLM, como OpenAI o Anthropic vía API) dentro del flujo de ejecución del sistema. El caso de uso propuesto era generar resúmenes automáticos de los eventos de los clubes o implementar un chatbot de búsqueda semántica para los estudiantes. 
De acuerdo con las restricciones del proyecto y el análisis de viabilidad, se debe tomar una decisión evaluando tres ejes críticos: costo por operación, latencia (p95) y riesgo de seguridad.

## Alternativas consideradas

### A. Incorporar una API de LLM externo (ej. OpenAI GPT-4o-mini)
* **Descripción:** Conectar el backend de FastAPI a una API externa de IA generativa para procesar texto de los clubes en tiempo real.
* **A favor:** Mejora la experiencia de usuario con búsquedas en lenguaje natural y automatiza la redacción para los líderes de clubes.
* **En contra:** Introduce un costo por token impredecible, añade latencia de red de terceros y abre nuevos vectores de ataque.

### B. No incorporar IA generativa en tiempo de ejecución
* **Descripción:** Mantener la arquitectura actual donde las operaciones de texto y búsqueda se manejan mediante consultas SQL estándar en Supabase (PostgreSQL), sin modelos generativos.
* **A favor:** Mantiene el costo estrictamente en $0, respeta el presupuesto de latencia y aísla el sistema de alucinaciones y vulnerabilidades de LLMs.
* **En contra:** Los líderes de clubes deben redactar sus resúmenes manualmente; búsqueda por coincidencias exactas y no semánticas.

## Decisión
Se decide **Alternativa B: NO incorporar ningún componente generativo en el núcleo del sistema**.

### Justificación Técnica y de Negocio
1. **Impacto en Latencia (p95):** Nuestro escenario de calidad fundamental **U1** establece una latencia de respuesta ≤ 800 ms. La invocación a una API de LLM externa implica un tiempo de generación de tokens que fluctúa habitualmente entre 1.5 y 4 segundos en su percentil 95 (p95), lo cual rompería por completo nuestro SLA de rendimiento.
2. **Costo por Operación:** El sistema opera bajo una restricción de infraestructura gratuita (Free Tier). Los LLMs facturan por volumen de entrada/salida de tokens por cada petición. Con un tráfico proyectado de 2,000 usuarios activos institucionales, el costo operativo escalaría de $0 a gastos recurrentes impredecibles.
3. **Riesgo y Seguridad:** Inyectar un modelo generativo expone la aplicación a vulnerabilidades no contempladas actualmente, como Prompt Injection y envenenamiento del contexto de la base de datos. Mitigar estos riesgos requeriría capas de validación adicionales que sobrecomplejizan la arquitectura sin un retorno de valor justificable para un simple directorio estudiantil.

## Consecuencias
- **Positivas:** 
  - Se protege y garantiza el cumplimiento del escenario de rendimiento (U1).
  - La arquitectura preserva su viabilidad económica (costo mensual estimado de $0).
  - Se evita la erosión del sistema mediante dependencias de red inestables o vendor lock-in con proveedores de IA de pago.
- **Negativas / Costos asumidos:** Se renuncia a funcionalidades de vanguardia (IA) que podrían resultar atractivas visualmente, priorizando la robustez, estabilidad y economía de la arquitectura central.

## Trazabilidad
- **Requisito / Aspecto:** Rendimiento (U1) y Restricción de Costos.
- **Elementos C4 afectados:** API (Backend). Se protege de dependencias externas incontrolables.
- **Relacionado con:** Semana 9 (Evaluación de componente generativo y riesgos de ejecución).

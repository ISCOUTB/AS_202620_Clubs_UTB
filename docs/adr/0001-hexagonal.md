# Arquitectura hexagonal
## Estado
Aceptado
## Fecha
23/08/2026

## Contexto
Linkclub al ser un gestor de clubes, que interactuara con diferentes componentes, se usara una arquitectura que se base en separar la base de datos, la interfaz de usuario y los servicion externos, esto para que los cambios de las tecnologias externas no afecten a la logica de la aplicacion. Para facilitar el mantenimiento y hacer cambios de tecnologia que no altere la logica de la aplicacion.

## Alternativas
### Arquitectura por capas
Aun siendo sencilla y mas facil, generaria el problema de depender mas en la logica de negocio y la infraestructura.
### Monolito modular
Permite dividir la aplicacion por modulos, pero no permite la misma separacion entre la logica de negocio y las tecnologias externas.
### Arquitectura hexagonal
Al mantener la logica de negocio aislada de la infraestructura y de otras tecnologias externas, se selecciona esta alternativa

## Decision
La logica se separa por una estructura dividida en. 
* Dominio: que es el contiene las entidades y la logica del negocio. 
* Aplicacion: contiene los casos de uso. 
* Infraestructura: es la que comunica la base de datos con la API y los servicios externos. 
* Presentacion: es la interfaz que ve el usuario.
La comunicacion se realizara  con los puertos y adaptadores

## Consecuencias
### Positivas
* El codigo estara organizado en diferentes archivos dependiendo de la responsabilidad de cada componente.
* Permitiria cambiar tecnologias sin llegar a tener un mayor impacto en el codigo.
* Es mas facil hacer mantenimiento y hacerle cambios a la aplicacion.

### Negativas
* Es mas compleja que la arquitectura por capas sencilla.
* Se usaran muchos archivos para conectar las diferentes partes.

## Trazabilidad

- **Aspecto de calidad:** [`docs/aspectos.md`](../aspectos.md) — filas U2, C1 y C3.
- **Escenario que motiva esta decisión:** [Escenario de uso U2 — Disponibilidad](../arc42/10_requisitos_de_calidad.md#escenarios-de-uso). La separación en puertos y adaptadores permite manejar fallos de conexión con el proveedor externo (Supabase) sin que la lógica de negocio se vea afectada, que es justo lo que exige U2.
- **También sostiene:** [Escenario de cambio C1 — Modificabilidad](../arc42/10_requisitos_de_calidad.md#escenarios-de-cambio) y [Escenario de cambio C3 — Portabilidad](../arc42/10_requisitos_de_calidad.md#escenarios-de-cambio), ambos citados como consecuencia directa de aislar la infraestructura del dominio.
- **Restricción relacionada:** [T4](../arc42/02_restricciones.md) — el proveedor de base de datos/autenticación aún está en evaluación; esta arquitectura es lo que permite posponer esa decisión sin bloquear el resto del sistema.
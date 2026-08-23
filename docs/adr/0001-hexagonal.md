# arquitectura hexagonal
## estado
en revisión
## fecha
23/08/2026

## contexto
Linkclub al ser un gestor de clubes, se usara una arquitectura que se base en separar la base de datos, la interfaz de usuario y los servicion externos.

## decisión
la lógica se separa por una estructura dividida en dominio, aplicación, infraestructura y presentación

## consecuencia
### positivas
* El código estará organizado en diferentes archivos dependiendo de la responsabilidad de cada componente.
* Permitiría cambiar tecnologías sin llegar a tener un mayor impacto en el código.
* Es mas fácil hacer mantenimiento y hacerle cambios a la aplicación.

### negativas
* Es mas compleja que la arquitectura por capas sencilla.
* Se usaran muchos archivos para conectar las diferentes partes.

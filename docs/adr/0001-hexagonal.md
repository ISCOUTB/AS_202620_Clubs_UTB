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

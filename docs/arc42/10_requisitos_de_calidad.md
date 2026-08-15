# 4. REQUISITOS DE CALIDAD

Los siguiente requisitos son las características que debe cumplir **LinkClub** para garantizar que sea fácil de utilizar, que sea seguro y rapido.

## Usabilidad
* Los estudiantes deben poder ver la información de los clubes.
* Las opciones deben verse claramente.
* Los formularios son claros en los campos que pidan ingresar los datos.

## rendimiento
* El sistema evita cargas innecesarias de información
* las consultas de la base de datos están optimizadas para evitar tiempos de respuestas muy extensos.

## Seguridad
* Las contraseñas no se almacena en texto plano.
* Los usuarios deben autentificarse antes acceder a funcionalidades
* los permisos dependen del rol del usuario.
* La conexion entre el cliente y servidor es segura cuando el sistema este desplegado.

## Mantenibilidad
* Se utiliza el control de versiones mediante git.
* Los cambios seran documentados.
* El codigo dividido en componentes dependiendo de sus responsabilidades.

## Disponibilidad
* El sistema esta disponible durante los periodos establecidos.
* En caso de falla **LinkClub** muestra un mensaje indicando que el servicio no esta disponible.

# Tabla de dueño unico

El presente documento establece la relacion de los modulos y los datos unicos que administran cada uno, con el objetivo de evitar duplicado de responsabilidades y facilitar la organizacion, el mantenimiento y la evolucion del sistema.

|Módulo|Descripcion|Datos administrados|Operaciones principales|
| --- | --- | --- | --- |
|Usuario| Gestiona la informacion de los usuarios y sus roles|ID,nombre, correo, rol|Crear, consultar, actualizar y gestionar|
|Clubes|Gestiona la informacion de los clubes|ID,nombre,categoria,descripcion,imagen|Crear, actualizar y eliminar clubes|
|Actividades|Gestiona las actividades, eventos o reuniones asociadas a los clubes|ID,nombre de la actividad, descripcion, fecha, lugar|Crear, consultar, actualizar y eliminar actividades|
|Notificaciones|Gestiona los mensajes dirigidos a los usuarios|ID, mensaje, fecha|Crear,enviar,consultar notificaciones|
# Tabla de dueño unico y datos con duelo unico

EL presente documento establece la relacion de los modulos y los datos unicos que administran cada uno, con el objetivo de evitar duplicado de responsabilidades y facilitar la organizacion, el mantenimiento y la evolucion del sistema.

|módulo|descripcion|datos administrados|operaciones principales|
| --- | --- | --- | --- |
|usuario| gestiona la informacion de los usuarios y sus roles|ID,nombre, correo, rol|crear, consultar, actualizar y gestionar|
|clubes|gestiona la informacion de los clubes|ID,nombre,categoria,descripcion,imagen|crear, actualizar y eliminar clubes|
|actividades|gestiona las actividades, eventos o reuniones asociadas a los clubes|id,nombre de la actividad, descripcion, fecha, lugar|crear, consultar, actualizar y eliminar actividades|
|notificaciones|gestiona los mensajes dirigidos a los usuarios|id, mensaje, fecha|crear,enviar,consultar notificaciones|
# Tabla de amenazas

La siguiente tabla mostrará las amenazas que pueden poner en peligro la seguridad de la aplicación, se determinará la probabilidad, el impacto y la prioridad de las amenazas, y se explicara como se solucionara o mitigara.

|Amenaza|Probabilidad|Impacto|Prioridad|Mitigación|
| --- | --- | --- | --- | --- |
|Acceso no autorizado a cuentas|Media|Alta|Alta|Autenticación mediante JWT y validacion de credenciales.|
|Exposicion de claves secretas y variables de entorno|Baja|Alta|Alta|Almacenar las credenciales en variables de entorno y evitar subir archivos sensibles al repositorio.|
|Envío de datos incompletos o incorrectos a la base de datos|Alta|Medio|Media|Implementar validaciones en la aplicacion y restricciones de integridad en la base de datos.|
|Acceso no autorizado a las funciones administrativas|Baja|Alta|Alta|Implementar controles de autorización por roles y validar cada operación administrativa.|
|Perdida de informacion de la base de datos|Baja|Alta|Alta|Realizar copias de seguridad y procedimientos de restauración.|
|Estudiante accede a la informacion privada de otro estudiante|Baja|Alta|Alta|Verificar propiedad de los recursos y los permisos del usuario autenticado|
|Ataques de fuerza bruta contra el inicio de sesión|Media|Media|Alta|Implementar un límite de intentos para iniciar sesión y un tiempo de espera.|
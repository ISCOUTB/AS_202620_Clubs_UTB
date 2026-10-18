# Tabla de fallos

La siguiente tabla mostrara los posibles fallos durante la ejecución de LinkClub, presentaremos los fallos, las posibles causas y como lo mitigaremos para reducir su impacto o facilitar la recuperacion del sistema.

|Modo de fallo|Causa posible|Impacto|Mitigación|
|---|---|---|---|
|API no responde|Caída del contenedor, error de ejecución o un despliegue fallido|Los usuarios no pueden consultar ni gestionar los clubes|registrar errores y mostrar mensajes de indisponibilidad en Flutter|
|Perdida de conexion durante una operacion|Interrupcion de la red entre Flutter y FastAPI|El usuario desconoce si la operacion se completo|consultar el estado de la operación antes de repetirla para evitar duplicar operaciones al repetir solicitudes|
|Acceso a funciones de lider no autorizado|error al validar los datos de permisos|Un estudiante tendria acceso a permisos no correspondiente para su rol|validar la identidad, el rol y los permisos en FastAPI con cada operacion|
|Respuesta lenta de la API|Consultas ineficientes o aumento de solicitudes|La interfaz tarda en mostrar la infomacion de los clubes|Medir los tiempos de respuesta y optimizar las consultas|
|Credenciales expuestas|configuración errónea de las variables de entorno o publicacion de secretos|Acceso no autorizado a la base de datos o de información sensible|Utilizar variables de entorno y secretos de Dokploy y excluir archivos sensibles de Git|
|Perdida de datos|Eliminacion accidental, corrupción de los datos o información|Perdida de información de los clubes|Hacer copias de seguridad periodicas|
|Fallos al iniciar sesión|Credenciales incorrectas o error en el proceso de autenticación|El usuario no puede acceder a su cuenta|validar las credenciales mediante el backend y devolver mensajes controlados|
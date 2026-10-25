# garantias de consistencia 

La siguiente tabla mostrará los posibles problemas de consistencia y las garantías propuestas para mantener la integridad de la informacion almacenada.

|Operación|Riesgo de inconsistencia|Garentia de consistencia|
| --- | --- | --- |
|Consultar clubes|Mostrar informacion desactualizada|Consultar la API y aplicar una politica de caché con tiempo de expiración definido.|
|Crear un club|Que se guarde un club con datos inválidos o incompletos|validar los datos y establecer restricciones de integridad.|
|Inscribir un estudiante|Que un estudiante se registre en el mismo club más de una ves|Establecer una restricción de inscripcion unica para los estudiantes evitar que se registren mas de una ves en el mismo club|
|Modificar el rol de un usuario|Asignar permisos incompatibles|Validar la operacion en FastAPI y aplicar reglas de autorización en el backend|
|Cambiar el líder de un club|Asignar un líder inexistente o dejar el club en un estado inválido|Validar la existencia del estudiante antes de confirmar el cambio|
|Cambiar el estado de un club|Se permite inscripciones cuando el club esta cerrado|Validar el estado del club dentro de la operacion que registra la inscripcion|
|Consultar datos desactualizados|Flutter muestra información anterior|invalidar la caché afectada o revalidar la informacion con el backend|
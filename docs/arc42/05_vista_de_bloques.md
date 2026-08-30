# 5. Vista de bloques
## 5.1 Nivel 1:Sistema
Linkclub esta organizado por diferentes bloques que separa la lógica del negocio con los detalles técnicos y los sistemas externos.
Se usara la arquitectura hexagonal, por lo que el núcleo de la aplicación contiene la lógica principal del negocio y se comunica con el exterior mediante puertos y adpatadores.
Los bloques principales del sistema son presentación, aplicación, dominio, infraestructura.

## 5.2 Nivel 2: bloques principales
### Presentación
Este bloque proporciona la interfaz la cual usaran los usuario para interactuar con linkclub.
su responsabilidad principal es:
* Mostrar la información de los clubes.
* Recibir las acciones realizadas por los usuarios.
* consultar las actividades de los clubes.
### Aplicación
Este bloque contiene los casos de uso de Linkclub y coordina las operaciones que puede realizar el sistema.
Las responsabilidades principales son:
* Coordinar las acciones solicitadas por los usuarios.
* Ejecutar los casos de uso.
* Comunicarse con el dominio.
* Utilizar los puertos definidos por la aplicación para acceder a recursos externos.
### Dominio
Este bloque están los elementos que están relacionados con el negocio de gestion de clubes universitario.
sus responsabilidades principales son:
* Representar las entidades principales del sistema.
* Contener las reglas de negocio.
* Mantener la lógica independiente de frameworks, bases de datos y servicios externos.
### Infraestructura
Este bloque tiene detalles técnicos para la comunicación entre aplicación y servicios externos.
Sus responsabilidades principales son:
* Implementar los puertos definidos por la aplicación.
* Gestionar la comunicación con la base de datos.
* Realizar las operaciones de persistencia.
* Gestionar la comunicación con servicios externos cuando sean necesarios.

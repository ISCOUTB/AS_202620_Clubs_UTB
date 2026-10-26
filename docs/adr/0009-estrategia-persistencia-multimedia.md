# ADR 0009: Almacenamiento local de archivos multimedia vía volúmenes Docker en lugar de Object Storage externo

## Estado
Aceptado

## Fecha
25/10/2026

## Contexto
El sistema LinkClub permite a los estudiantes subir imágenes, afiches y recursos gráficos al crear publicaciones. Necesitamos definir dónde se almacenarán físicamente estos binarios y cómo se referenciarán en la base de datos. 

Restricciones que pesan en la decisión:
- **F1:** Costo cero mensual en producción. No se pueden contratar servicios pagos de nube como AWS S3, Google Cloud Storage o Cloudinary.
- **C2:** El cronograma y la arquitectura no contemplan la complejidad de SDKs de terceros para almacenamiento externo si se puede resolver a nivel de infraestructura local.
- **Infraestructura (ADR 0007):** Un único servidor de despliegue (Dokploy) con almacenamiento persistente en disco disponible mediante volúmenes Docker.

## Alternativas

### A. Utilizar Cloud Object Storage externo (AWS S3 / Supabase Storage / Cloudinary)
Permitiría descargar el tráfico de imágenes del servidor de la aplicación y escalar infinitamente. 
- **Desventaja principal:** Incumple la restricción F1 (costo cero o requiere capas gratuitas con tarjetas de crédito y límites estrictos que pueden expirar o bloquear la operación académica).
- **Desventaja técnica:** Añade latencia de red externa y dependencia directa de proveedores de nube para el despliegue local o de la universidad.

### B. Guardar los archivos en la base de datos como blobs (Base64 o binarios)
- **Desventaja principal:** Hincha rápidamente el tamaño de la base de datos PostgreSQL, degrada el rendimiento de las consultas del feed y satura el pool de conexiones con datos pesados innecesarios.

### C. Almacenamiento local en disco con montaje de Volumen Docker persistente y FastAPI StaticFiles (Elegida)
Guardar los archivos multimedia directamente en un directorio local del contenedor (`/app/uploads`), protegido con control de permisos del sistema operativo y enlazado a un volumen físico del servidor Dokploy, exponiéndolos mediante un servidor de archivos estáticos integrado en FastAPI (`/static/...`).

## Decisión
**Se adopta el almacenamiento local en disco mediante volúmenes Docker persistentes.** 
1. Los archivos se procesan en el backend (`recurso_router.py`), se validan extensiones, se les asigna un nombre único mediante UUIDv4 para evitar colisiones y se almacenan en el directorio mapeado al volumen.
2. La base de datos solo almacena la URL absoluta pública del recurso (`https://api-linkclub.iscoutb.dev/static/<uuid>.<ext>`), desacoplando la ruta física interna del servidor de la lógica de dominio de las publicaciones.

### Condiciones que reabrirían esta decisión
- Si el volumen de imágenes supera la capacidad física en disco del servidor actual de la universidad o Dokploy.
- Si el proyecto pasa a un entorno multi-nodo (cluster) donde varios servidores deban compartir el almacenamiento de archivos simultáneamente sin un sistema de archivos de red compartido (NFS).

## Consecuencias

### Positivas
- Cumple estrictamente con la restricción de costo cero (F1).
- Cero dependencias de SDKs de terceros o credenciales de nube complejas.
- Las imágenes se sirven de forma ultra rápida directamente desde el servidor web local de FastAPI con `StaticFiles`.

### Negativas / costos asumidos
- Si el contenedor o el servidor físico falla sin un respaldo adecuado del volumen Docker, los archivos se pierden (mitigado por las copias de seguridad de volúmenes que provee Dokploy).
- El escalado horizontal de la aplicación queda atado al disco del servidor actual.

## Trazabilidad
- **Escenarios de calidad:** U1 y U2 (rendimiento de carga y disponibilidad de recursos gráficos).
- **Restricciones:** F1, C2 y ADR 0007.
- **Código afectado:** `backend/src/linkclub/adapters/inbound/api/recurso_router.py`, `backend/src/linkclub/main.py`, `backend/Dockerfile`.
- **Infraestructura:** Volumen persistente configurado en Dokploy (`/app/uploads`).
# ADR 0004: Usar Supabase como servicio gestionado de base de datos

## Estado
aceptado

## Fecha
27/09/2026


## Contexto

Debemos definir la plataforma de despliegue de nuestra base de datos relacional. El sistema requiere persistencia de datos (usuarios, clubes, publicaciones, eventos) con alta disponibilidad y la capacidad de integrarse de manera fluida con un servicio de autenticación. Debemos mantener el costo mensual en cero durante el desarrollo y operación académica, evaluando opciones que soporten un volumen estimado de 2,000 usuarios activos y 160,000 transacciones mensuales.
- **Escenario de calidad relacionado:** U2 (Disponibilidad y manejo de fallos), T4 (Integración con directorio activo / Auth)
  
## Alternativas consideradas

### A. Supabase (BaaS / PostgreSQL Gestionado - Capa Gratuita)
Descripción breve: Usar el servicio en la nube de Supabase en su región US East, que ofrece PostgreSQL gestionado, pool de conexiones y autenticación integrada.
**A favor:** Configuración inmediata, backups automáticos, incluye el adaptador de autenticación necesario para el escenario T4, escalabilidad sin intervención del equipo.
**En contra:** Límite estricto de 500MB en la base de datos y 60 conexiones directas concurrentes en la capa gratuita.

### B. Contenedor PostgreSQL en el Servidor del Laboratorio
Descripción breve: Levantar nuestra propia imagen de Docker con PostgreSQL en el servidor físico provisto por la UTB.
**A favor:** Sin límites de almacenamiento ni usuarios artificiales; control total sobre la instancia; cumple al 100% con la restricción de costo cero infinito.
**En contra:** Alta carga operativa; el equipo debe gestionar copias de seguridad a mano; si el servidor de la universidad se reinicia, requiere intervención humana para recuperar el servicio; concentra la operación en pocas personas del equipo.

## Decisión

Se elige **Supabase (Alternativa A)**, porque garantiza nuestro escenario de calidad de disponibilidad (U2) mediante una infraestructura robusta y gestionada, eliminando el riesgo operativo de mantener un servidor en el laboratorio de la universidad. Además, nuestro volumen de datos estimado (50MB/mes) se encuentra muy por debajo del límite de quiebre de la capa gratuita (500MB), manteniendo el costo financiero en cero.

## Consecuencias

- **Positivas:** Reducción drástica del tiempo de operaciones; ganamos la gestión de usuarios (Auth) sin codificarla desde cero; despliegues rápidos. El proyecto queda descrito como código en infra/terraform/.
- **Negativas / costos asumidos:** Dependencia de la política de precios de un proveedor externo (Vendor Lock-in moderado).
- **Riesgos y qué los dispararía:** Agotar el número de conexiones simultáneas si hay un pico de tráfico, lo cual tumbara la base de datos.
- **Qué habría que revisar si cambia Y:** Si Supabase elimina su plan gratuito, ejecutaremos el plan de reversión exportando los datos migrando a un contenedor PostgreSQL estándar en el servidor del laboratorio.

## Trazabilidad

- Requisito / aspecto: Persistencia de datos y Autenticación.
- Elementos C4 afectados: C2: Base de Datos.
- Pruebas que lo cubren: Health Check asíncrono implementado en el backend que verifica la conexión real al proveedor.

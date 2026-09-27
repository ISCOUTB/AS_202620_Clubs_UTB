# 11. Riesgos y Deuda Técnica

## 11.1. Riesgos Arquitectónicos Conocidos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| **Dependencia de Proveedor (Vendor Lock-in)** | Medio. Dependemos de la capa gratuita de Supabase para la base de datos y Auth. Si cambian sus políticas, el costo podría dispararse. | Mantener las consultas en SQL estándar de PostgreSQL. Evitar usar funciones propietarias de Supabase (RPCs) en la lógica central para facilitar una posible migración al servidor del laboratorio. |
| **Límites de Concurrencia (Connection Pooling)** | Alto. El plan gratuito de Supabase permite un máximo de 60 conexiones directas simultáneas. Si la base de estudiantes activos genera un pico de tráfico, los nuevos intentos de conexión fallarán, violando el escenario de disponibilidad (U2). | Conectar la API Backend a Supabase utilizando el puerto de *Connection Pooler* (Supavisor) en modo *Transaction* (puerto 6543) en lugar del puerto directo, lo que permite encolar miles de solicitudes sin agotar las conexiones físicas de PostgreSQL. |

## 11.2. Deuda Técnica Actual

*   **Pruebas de Integración y End-to-End (E2E):** Contamos con pruebas de contrato y unitarias, pero falta automatizar pruebas que recorran el sistema completo desde el frontend hasta la base de datos.
*   **Gestión de Esquemas de BD:** Actualmente las tablas en Supabase se crearon manualmente. Existe deuda técnica en la automatización de migraciones de base de datos desde el pipeline CI/CD.

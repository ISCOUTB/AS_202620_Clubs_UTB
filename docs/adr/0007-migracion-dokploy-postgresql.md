# ADR 0007: Migración de infraestructura externa (Supabase) a despliegue autónomo (Dokploy + PostgreSQL)

**Fecha:** 2026-10-18  
**Estado:** Aceptado  
**Contexto de la Decisión:** Arquitectura de Despliegue y Persistencia (Resolución Evidencia S10)

## 1. Contexto y Problema

Durante el cierre del segundo corte (S10), la evaluación de la arquitectura reveló una **deriva arquitectónica crítica**: la documentación declaraba una dependencia directa del BaaS Supabase para la persistencia de datos y la autenticación, pero el código utilizaba adaptadores en memoria y devolvía un estado de salud (`/health`) fijo, sin comprobar la disponibilidad real del proveedor externo.

Además, el uso de un servicio Backend-as-a-Service (BaaS) de terceros para un proyecto universitario con recursos acotados introdujo fricciones imprevistas:
- Dependencia de la red externa de Supabase, aumentando la latencia general.
- Dificultades para alinear la autenticación de Flutter con los roles de dominio internos del sistema.
- Riesgo de indisponibilidad si el proveedor externo aplicaba límites de capa gratuita (rate limits) durante las pruebas o demostraciones.

Se contaba ya con acceso a un servidor de despliegue propio de la universidad provisto mediante **Dokploy** (`iscoutb.dev`), el cual tiene la capacidad de levantar contenedores de bases de datos de forma local y segura.

## 2. Alternativas Evaluadas

1. **Mantener Supabase (Status Quo Corregido):** 
   - **Descripción:** Conservar la infraestructura en Supabase, escribiendo adaptadores HTTP/SDK definitivos en FastAPI para la persistencia e integrando Supabase Auth explícitamente en el backend para validar el estado real en el endpoint `/health`.
   - **Desventajas:** Mantiene una alta latencia de red (API en Dokploy -> BD en Supabase). Obliga a manejar dos fuentes de verdad separadas (la tabla interna de `auth.users` de Supabase vs. la tabla `usuarios` del sistema).

2. **Migración a Infraestructura Autónoma (Dokploy + PostgreSQL nativo):**
   - **Descripción:** Erradicar totalmente Supabase. Desplegar un contenedor de PostgreSQL dentro de la misma red virtual de Dokploy donde reside FastAPI. Asignar a FastAPI la responsabilidad total de gestionar la base de datos y emitir/validar sus propios tokens JWT.
   - **Ventajas:** Latencia de red interna cercana a 0ms. Control absoluto sobre los datos, los esquemas (SQL puro) y el ciclo de vida de la autenticación. Facilita las pruebas de integración (Liveness/Readiness) sin depender de servicios web externos.

## 3. Decisión

Se adopta la **Alternativa 2**. Se descarta definitivamente Supabase como proveedor de infraestructura, persistencia y autenticación para LinkClub. 

A partir de este punto, el sistema opera bajo una arquitectura de infraestructura autónoma desplegada en Dokploy:
- **Base de Datos:** Contenedor nativo de PostgreSQL aprovisionado en Dokploy, accesible internamente por el backend a través de la red de Docker (`clubsutb-db-2m0uk5`).
- **Autenticación:** Gestión propietaria. FastAPI validará las credenciales contra la tabla `usuarios` y emitirá sus propios tokens JWT utilizando el estándar `OAuth2PasswordRequestForm`.
- **Cliente (Flutter):** Dejará de poseer lógica de base de datos o SDKs de autenticación. Se convertirá en un cliente HTTP puro (usando `Dio`) que almacenará los tokens JWT en el almacenamiento seguro del dispositivo (`flutter_secure_storage`).

## 4. Consecuencias

### Positivas
- **Resolución de la Deriva (S10):** El código y la documentación se alinean perfectamente con una infraestructura real, comprobable y bajo el control del equipo.
- **Rendimiento:** Al estar la API y la Base de Datos en el mismo host de Dokploy, las latencias de lectura/escritura se reducen a fracciones de milisegundo.
- **Cohesión:** La autenticación y las reglas de negocio ahora conviven en el mismo dominio, eliminando la duplicidad de la entidad `Usuario`.
- **Independencia:** Inmunidad ante caídas o límites de capa gratuita de BaaS externos.

### Negativas / Costos de adopción
- **Aumento de Responsabilidad Operativa:** El equipo asume la carga de ejecutar los scripts SQL de creación de tablas directamente (vía DBeaver o pgAdmin) y de la correcta configuración de las variables de entorno (`DATABASE_URL`).
- **Desarrollo Adicional:** Exige codificar de cero los adaptadores de cifrado de contraseñas y la lógica de validación JWT en los puertos de autenticación del backend.

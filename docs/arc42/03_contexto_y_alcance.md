# 3. Contexto y alcance

**LinkClub** tiene como objetivo facilitar la gestión de los clubes, para centralizar la información y los avisos en un solo lugar.

## Contexto del sistema

| Socio de comunicación | Entendimiento |
| --- | --- |
| Estudiante | Podrá consultar los clubes disponibles, además de su información. |
| Miembro del club | Son los que ya están vinculados y podrán publicar los eventos. |
| Administrador del club | Encargado de supervisar y administrar la información del club y su contenido. |

## 3.1. Contexto del negocio

Se mostrarán las principales interacciones que hay entre la aplicación y las personas que utilizan el sistema.

**Estudiante:** puede usar LinkClub para consultar los clubes disponibles, visualizar su información, además de inscribirse en un club.

**Miembro del club:** es quien puede publicar los eventos, avisos y noticias.

**Administrador:** es el encargado de gestionar los usuarios del club, las actividades y los eventos.

## 3.2. Contexto técnico

LinkClub será desarrollado con Flutter para que los usuarios puedan acceder al sistema desde sus dispositivos móviles; Flutter proporcionará la interfaz para interactuar con la aplicación, la cual se comunicará mediante una API con el backend, que procesará las solicitudes y almacenará la información.

## Tecnologías y elementos técnicos

| Elemento | Descripción |
| --- | --- |
| Aplicación móvil | LinkClub será desarrollado en Flutter, que proporcionará la interfaz principal. |
| Flutter | Framework utilizado para desarrollar el frontend de LinkClub. |
| FastAPI | framework sobre el que se construye el backend de LinkClub (aplicación, dominio, infraestructura, presentación). |
| Supabase | Almacenará la información de LinkClub. |

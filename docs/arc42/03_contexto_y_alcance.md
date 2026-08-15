# 3. CONTEXTO Y ALCANCE
LinkClub tiene como objetivo facilitar la gestión de los clubes, para centralizar la información y avisos en un solo lugar.

## contexto del sistema

| socio de comunicación | entendimiento |
| --- | --- |
| Estudiante | podrá consultar los clubes disponibles, además de su información. |
| miembro del club | Son los que ya están vinculados y podrán publicar los eventos. |
| Administrador del club | Encargado de supervisar y administrar la información del club y su contenido |
|base de datos| almacenar la información de LinkClub, usuarios, clubes, actividades, etc.|

## contexto del negocio
Se mostrara las principales interacciones que hay entre la aplicación y las personas que utilizan el sistema.

Estudiante: utiliza puede usar LinkClub para consultar los clubes disponibles, visualizar la información, además de inscribirse en un club.

Miembro del club: Es quien puede publicar los eventos, avisos y noticias.

Administrador: es el encargado de gestionar los usuarios del club, de las actividades y eventos.

## contexto técnico
LinkClub será desarrollado con flutter para que los usuarios puedan acceder al sistema desde sus dispositivos móviles, además flutter proporcionara la interfaz para interactuar con la aplicación, la cual se comunicara mediante una API al backend que procesara las solicitudes y almacenara la información.

## tecnologías y elementos técnicos

| Elemento | Descripción|
| --- | --- |
| Aplicación móvil | LinkClub será desarrollado por flutter que proporcionara la interfaz principal |
| flutter | Framework utilizado para desarrollar el frontend de LinkClub |
| Fastapi | medio de comunicacion entre la aplicacion y la base de datos |
| Supabase | Almacenara la informacion de LinkClub |

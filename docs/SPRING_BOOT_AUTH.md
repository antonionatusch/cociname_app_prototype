# Roadmap De Backend Y Autenticacion

Este documento resume una posible evolucion tecnica de CocinaME si el prototipo pasa de validar casos de uso principales a requerir un backend propio.

## Estado actual

El prototipo usa Supabase como backend principal:

- Supabase Auth para registro, inicio de sesion y verificacion.
- PostgreSQL para persistencia.
- RPCs SQL para reglas transaccionales del negocio.
- Supabase Storage para fotos de platos y evidencia asociada.

Esta decision reduce complejidad durante la validacion del flujo de negocio y evita introducir un backend adicional antes de que sea necesario.

## Casos cubiertos por Supabase Auth

- Registro con correo o telefono.
- Verificacion de identidad.
- Inicio de sesion.
- Recuperacion de contrasena por correo.
- Persistencia de sesion en el cliente Flutter.

## Configuracion local

Para ejecutar el prototipo, usa `.env.template` como referencia y crea un archivo `.env` local con tus propios valores de Supabase.

El entorno local puede usar OTP de prueba y bandeja de correo de desarrollo. Estas ayudas deben mantenerse desactivadas para una revision publica usando:

```env
SHOW_DEV_AUTH_HELP=false
```

## Motivos para introducir Spring Boot despues

Un backend propio podria ser conveniente si aparecen necesidades como:

- Reglas de negocio mas complejas que no conviene mantener en RPCs.
- Autorizacion granular fuera del alcance de RLS y claims simples.
- Integraciones externas que no deben exponerse al cliente.
- Auditoria centralizada.
- Procesos asincronos o jobs programados.
- Agregacion de datos desde multiples fuentes.

## Estrategia sugerida

La migracion deberia ser gradual, no un reemplazo brusco.

1. Mantener Flutter desacoplado mediante repositories y servicios propios.
2. Crear un backend Spring Boot minimo con health check y endpoint protegido.
3. Validar JWT emitidos por Supabase Auth desde Spring Boot.
4. Mover reglas de negocio especificas al backend cuando aporten valor claro.
5. Mantener Supabase como Auth provider, base de datos y storage mientras sea suficiente.

## Arquitectura objetivo posible

Etapa actual:

```text
Flutter -> Supabase Auth
Flutter -> Supabase Database/RPC/Storage
```

Etapa intermedia:

```text
Flutter -> Supabase Auth
Flutter -> Spring Boot API
Spring Boot -> PostgreSQL/Supabase
```

Etapa avanzada:

```text
Flutter -> Spring Boot API
Spring Boot -> Auth provider, PostgreSQL, Storage e integraciones externas
```

## Criterio de decision

No conviene agregar Spring Boot solo por estructura. Conviene hacerlo cuando simplifique seguridad, reglas de negocio, integraciones o mantenibilidad frente a la implementacion actual con Supabase.

# Roadmap De Backend Y Autenticación

Este documento resume una posible evolución técnica de CocinaME si el prototipo pasa de validar casos de uso principales a requerir un backend propio.

## Estado actual

El prototipo usa Supabase como backend principal:

- Supabase Auth para registro, inicio de sesión y verificación.
- PostgreSQL para persistencia.
- RPCs SQL para reglas transaccionales del negocio.
- Supabase Storage para fotos de platos y evidencia asociada.

Esta decisión reduce complejidad durante la validación del flujo de negocio y evita introducir un backend adicional antes de que sea necesario.

## Casos cubiertos por Supabase Auth

- Registro con correo o teléfono.
- Verificación de identidad.
- Inicio de sesión.
- Recuperación de contraseña por correo.
- Persistencia de sesión en el cliente Flutter.

## Configuración local

Para ejecutar el prototipo, usa `.env.template` como referencia y crea un archivo `.env` local con tus propios valores de Supabase.

El entorno local puede usar OTP de prueba y bandeja de correo de desarrollo. Estas ayudas deben mantenerse desactivadas para una revisión pública usando:

```env
SHOW_DEV_AUTH_HELP=false
```

## Motivos para introducir Spring Boot después

Un backend propio podría ser conveniente si aparecen necesidades como:

- Reglas de negocio más complejas que no conviene mantener en RPCs.
- Autorización granular fuera del alcance de RLS y claims simples.
- Auditoría centralizada.
- Procesos asíncronos o jobs programados.
- Agregación de datos desde múltiples fuentes.

## Estrategia sugerida

La migración debería ser gradual, no un reemplazo brusco.

1. Mantener Flutter desacoplado mediante repositories y servicios propios.
2. Crear un backend Spring Boot mínimo con health check y endpoint protegido.
3. Validar JWT emitidos por Supabase Auth desde Spring Boot.
4. Mover reglas de negocio específicas al backend cuando aporten valor claro.
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

## Criterio de decisión

No conviene agregar Spring Boot solo por estructura. Conviene hacerlo cuando simplifique seguridad, reglas de negocio, integraciones o mantenibilidad frente a la implementación actual con Supabase.

# Arquitectura

CocinaME está organizado como un prototipo Flutter por features. La meta de la arquitectura es separar UI, estado de pantalla, acceso a datos y servicios externos sin introducir complejidad innecesaria.

## Capas principales

- `views`: pantallas y widgets de Flutter.
- `viewmodels`: estado de pantalla, validaciones y coordinación de acciones.
- `repositories`: acceso a Supabase Auth, tablas, RPCs y Storage.
- `models`: estructuras de datos usadas por cada feature.
- `services`: integraciones específicas como ubicación, permisos e inferencia TFLite.

## Features principales

- `auth`: registro, login, verificación y recuperación de cuenta.
- `onboarding`: selección de rol y perfiles de consumidor/cocinero.
- `dish_publication`: publicación, edición y gestión de platos.
- `dish_inference`: captura de imagen e inferencia local.
- `consumer`: búsqueda geolocalizada y solicitudes de consumidor.
- `offers`: ofertas de cocineros y detalle para consumidor.
- `orders`: pedido activo y sincronización de estado.
- `maps`: selección de ubicación y visualización con OpenStreetMap.

## Backend

El prototipo usa Supabase como backend principal:

- Supabase Auth para identidad.
- PostgreSQL para datos transaccionales.
- RPCs SQL para operaciones de negocio que requieren validaciones o transacciones.
- Supabase Storage para fotos de platos.
- Migraciones versionadas en `supabase/migrations`.

## Inferencia visual

La inferencia se ejecuta localmente con TFLite. El modelo clasifica una foto del plato dentro de un conjunto cerrado de clases y devuelve sugerencias de ingredientes. Cuando la confianza es baja o el alimento no está contemplado, el flujo permite corrección manual.

## Sincronización

Algunos flujos usan polling para mantener la demostración simple y reproducible. Esto aplica principalmente a solicitudes, ofertas y pedido activo. En una evolución productiva, esos flujos podrían migrarse a Supabase Realtime o a un backend propio.

## Decisiones de prototipo

- Priorizar casos de uso principales del negocio por encima de completitud productiva.
- Mantener reglas críticas en RPCs para evitar inconsistencias entre clientes.
- Usar OpenStreetMap para mapas sin depender de billing externo.
- Mantener fallback manual para que la demo no dependa por completo del modelo visual.

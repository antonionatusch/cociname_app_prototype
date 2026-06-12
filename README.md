# CocinaME

CocinaME es un prototipo funcional desarrollado para validar los casos de uso principales de una plataforma que conecta consumidores con cocineros locales.

El proyecto implementa flujos clave del negocio: registro y onboarding, publicación de platos, búsqueda geolocalizada, ofertas entre consumidor y cocinero, pedido activo, advertencias preventivas de alérgenos e inferencia visual local con TFLite.

## Estado del proyecto

- Tipo: prototipo funcional.
- Enfoque: validación de casos de uso principales del negocio.
- Alcance: demostración técnica y académica, no producto en producción.
- Reconocimiento: proyecto ganador de primer lugar compartido en la [TecnoUPSA 2026](https://www.linkedin.com/posts/antonionatusch_estos-d%C3%ADas-he-estado-pensando-en-volver-ugcPost-7471217891678314496-rWA2/?utm_source=share&utm_medium=member_desktop&rcm=ACoAAEKdH_QB2qd2N1w1t3i5CaTD_fBFI1-PQ8s).

## Funcionalidades principales

- Registro, inicio de sesión y verificación con Supabase Auth.
- Onboarding por rol para consumidor, cocinero y administrador.
- Publicación de platos con foto, precio, cantidad, ubicación y estado de disponibilidad.
- Clasificación visual local con un modelo TFLite y fallback manual asistido.
- Sugerencia y confirmación de ingredientes.
- Advertencias preventivas de alérgenos derivadas de ingredientes.
- Búsqueda geolocalizada de consumidores con mapa OpenStreetMap.
- Flujo de solicitudes, ofertas y aceptación de pedidos.
- Vista de pedido activo para consumidor y cocinero.
- Persistencia en Supabase con PostgreSQL, RPCs y Storage.

## Stack técnico

- Flutter y Dart.
- Provider para inyección simple de dependencias y estado.
- Supabase Auth, Database, RPCs y Storage.
- PostgreSQL mediante migraciones versionadas.
- TFLite para inferencia local en dispositivo.
- OpenStreetMap mediante `flutter_map`.
- Arquitectura por features con ViewModels y repositories.

## Estructura relevante

- `lib/src/features/`: casos de uso separados por dominio.
- `lib/src/core/`: servicios y tema compartido.
- `lib/src/config/`: lectura de variables de entorno.
- `assets/models/`: modelo TFLite y labels del clasificador.
- `supabase/migrations/`: esquema, RPCs e invariantes del backend.
- `supabase/seed.sql`: datos ficticios de desarrollo.
- `docs/`: documentación pública del prototipo.

## Configuración local

Requisitos:

- Flutter SDK compatible con Dart `^3.7.2`.
- Una instancia de Supabase local o remota.
- Android Studio, emulador o dispositivo físico si se quiere probar la app móvil.

Pasos básicos:

```bash
flutter pub get
cp .env.template .env
```

Luego completa `.env` con tus parámetros de Supabase:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
```

Aplica las migraciones de `supabase/migrations` en tu proyecto Supabase y, si lo necesitas, carga los datos ficticios de `supabase/seed.sql`.

Para más detalle revisa `docs/SUPABASE_SETUP.md`.

## Ejecución

```bash
flutter run
```

Para verificar el proyecto:

```bash
flutter analyze
flutter test
```

## Documentación

- `docs/ARCHITECTURE.md`: arquitectura del prototipo.
- `docs/DEMO.md`: flujo sugerido para revisar los casos de uso.
- `docs/SUPABASE_SETUP.md`: configuración de Supabase y variables de entorno.
- `docs/COLOR_THEME.md`: identidad visual y paleta base.
- `docs/SPRING_BOOT_AUTH.md`: notas de evolución técnica hacia backend propio.

## Limitaciones

- El proyecto es un prototipo funcional, no una aplicación productiva.
- Los datos semilla son ficticios y están pensados para desarrollo/demostración.
- La configuración real de Supabase no se incluye en el repositorio.
- Algunos flujos usan polling para reducir complejidad durante la demostración.
- La inferencia visual se limita a clases cerradas y usa fallback manual cuando la confianza es baja o el plato no está contemplado.

## Privacidad y seguridad

Este repositorio no debe incluir archivos `.env`, credenciales reales, tokens, datos personales, documentos académicos privados ni configuraciones locales generadas. Usa `.env.template` como referencia y crea tu propio `.env` local.

## Licencia

Este proyecto está publicado bajo la licencia Apache 2.0. Ver `LICENSE`.

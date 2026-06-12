# CocinaME

CocinaME es un prototipo funcional desarrollado para validar los casos de uso principales de una plataforma que conecta consumidores con cocineros locales.

El proyecto implementa flujos clave del negocio: registro y onboarding, publicacion de platos, busqueda geolocalizada, ofertas entre consumidor y cocinero, pedido activo, advertencias preventivas de alergenos e inferencia visual local con TFLite.

## Estado del proyecto

- Tipo: prototipo funcional.
- Enfoque: validacion de casos de uso principales del negocio.
- Alcance: demostracion tecnica y academica, no producto en produccion.
- Reconocimiento: proyecto ganador de primer lugar compartido en una feria academica/de innovacion.

## Funcionalidades principales

- Registro, inicio de sesion y verificacion con Supabase Auth.
- Onboarding por rol para consumidor, cocinero y administrador.
- Publicacion de platos con foto, precio, cantidad, ubicacion y estado de disponibilidad.
- Clasificacion visual local con un modelo TFLite y fallback manual asistido.
- Sugerencia y confirmacion de ingredientes.
- Advertencias preventivas de alergenos derivadas de ingredientes.
- Busqueda geolocalizada de consumidores con mapa OpenStreetMap.
- Flujo de solicitudes, ofertas y aceptacion de pedidos.
- Vista de pedido activo para consumidor y cocinero.
- Persistencia en Supabase con PostgreSQL, RPCs y Storage.

## Stack tecnico

- Flutter y Dart.
- Provider para inyeccion simple de dependencias y estado.
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
- `docs/`: documentacion publica del prototipo.

## Configuracion local

Requisitos:

- Flutter SDK compatible con Dart `^3.7.2`.
- Una instancia de Supabase local o remota.
- Android Studio, emulador o dispositivo fisico si se quiere probar la app movil.

Pasos basicos:

```bash
flutter pub get
cp .env.template .env
```

Luego completa `.env` con tus parametros de Supabase:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
```

Aplica las migraciones de `supabase/migrations` en tu proyecto Supabase y, si lo necesitas, carga los datos ficticios de `supabase/seed.sql`.

Para mas detalle revisa `docs/SUPABASE_SETUP.md`.

## Ejecucion

```bash
flutter run
```

Para verificar el proyecto:

```bash
flutter analyze
flutter test
```

## Documentacion

- `docs/ARCHITECTURE.md`: arquitectura del prototipo.
- `docs/DEMO.md`: flujo sugerido para revisar los casos de uso.
- `docs/SUPABASE_SETUP.md`: configuracion de Supabase y variables de entorno.
- `docs/COLOR_THEME.md`: identidad visual y paleta base.
- `docs/SPRING_BOOT_AUTH.md`: notas de evolucion tecnica hacia backend propio.

## Limitaciones

- El proyecto es un prototipo funcional, no una aplicacion productiva.
- Los datos semilla son ficticios y estan pensados para desarrollo/demostracion.
- La configuracion real de Supabase no se incluye en el repositorio.
- Algunos flujos usan polling para reducir complejidad durante la demostracion.
- La inferencia visual se limita a clases cerradas y usa fallback manual cuando la confianza es baja o el plato no esta contemplado.

## Privacidad y seguridad

Este repositorio no debe incluir archivos `.env`, credenciales reales, tokens, datos personales, documentos academicos privados ni configuraciones locales generadas. Usa `.env.template` como referencia y crea tu propio `.env` local.

## Licencia

Este proyecto esta publicado bajo la licencia Apache 2.0. Ver `LICENSE`.

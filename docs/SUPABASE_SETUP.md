# Configuracion De Supabase

Este prototipo requiere una instancia de Supabase configurada con las migraciones del repositorio.

## Variables de entorno

Copia el archivo de ejemplo:

```bash
cp .env.template .env
```

Completa los valores principales:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
```

Variables opcionales para desarrollo local:

```env
SUPABASE_TEST_PHONE=+59170000000
SUPABASE_TEST_OTP=123456
SHOW_DEV_AUTH_HELP=false
SIMULATE_SLOW_CONNECTION=false
SUPABASE_AUTH_SMS_TWILIO_AUTH_TOKEN=REPLACE_ME
```

No publiques tu archivo `.env`.

## Migraciones

Las migraciones estan en:

```text
supabase/migrations
```

Aplicalas en orden sobre tu proyecto Supabase. Si usas Supabase CLI, puedes vincular tu proyecto y ejecutar las migraciones segun tu entorno local/remoto.

## Seed opcional

El archivo `supabase/seed.sql` contiene datos ficticios de desarrollo. Usalo solo en entornos de prueba.

## Auth

El prototipo usa Supabase Auth para registro e inicio de sesion. Si habilitas verificacion por email o telefono, ajusta tu configuracion de Auth en Supabase segun el entorno que uses.

Para desarrollo local, `SHOW_DEV_AUTH_HELP=true` permite mostrar ayudas como OTP de prueba y bandeja local de correo. Mantenerlo en `false` para una revision publica mas limpia.

## Storage

Algunas migraciones preparan buckets y politicas para fotos de platos. Verifica en Supabase que los buckets requeridos existan despues de aplicar las migraciones.

## Seguridad

- Usa solo anon keys publicables en clientes Flutter.
- No incluyas service role keys en la app.
- No publiques `.env`.
- No cargues datos personales reales en seeds o screenshots.

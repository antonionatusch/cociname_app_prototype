# Librerias, CLI Y Red

## Librerias Flutter

Dependencias principales:

```yaml
dependencies:
  supabase_flutter: ^2.8.0
  image_picker: ^1.1.2
  tflite_flutter: ^0.11.0
  image: ^4.2.0
  geolocator: ^13.0.2
  permission_handler: ^11.3.1
  flutter_map: ^7.0.2
  latlong2: ^0.9.1
```

Opcional si se usa Google Maps:

```yaml
dependencies:
  google_maps_flutter: ^2.9.0
```

Opcional para UI:

```yaml
dependencies:
  shimmer: ^3.0.0
```

## Mapas

### Opcion Recomendada: OpenStreetMap

Usar:

- `flutter_map`
- `latlong2`

Ventajas:

- Costo cero.
- Sin billing.
- Rapido para demo.

Riesgos:

- No abusar de tiles publicos.
- Para demo local es suficiente.

### Opcion Alternativa: Google Maps

Usar solo si:

- Existe API key.
- Billing esta habilitado.
- Se configuran restricciones de API key.

Ventajas:

- Mejor experiencia visual.
- Mas familiar para tribunal.

Riesgos:

- Puede requerir billing.
- Configuracion extra en Android.

## CLI Necesarios

Instalar o verificar:

- Flutter SDK.
- Android Studio.
- Android SDK.
- Supabase CLI.
- Git.
- Python 3.
- pip.
- Opcional: Netron para inspeccionar modelos `.tflite`.
- Opcional: Tailscale para acceder a servicios locales si aparecen despues.

Comandos utiles:

```bash
flutter doctor
flutter pub get
flutter run
supabase status
supabase db reset
supabase migration new <nombre>
```

## Configuracion Android

Permisos esperados:

- Camara.
- Galeria/fotos segun version Android.
- Ubicacion aproximada o precisa.
- Internet.

Archivos probables:

- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle`

## Supabase

Usar Supabase Cloud para evitar problemas de red.

Necesario:

- URL Supabase.
- Anon key.
- Bucket para fotos de platos.
- Politicas RLS.
- Migraciones versionadas.

El repo ya usa `.env`; mantener esa estrategia.

Variables esperadas:

```env
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

## Tailscale

Tailscale no es necesario si todo usa Supabase Cloud.

Usarlo solo si:

- Se levanta backend local.
- Se usa un servidor local para modelos.
- Se necesita exponer una maquina dev al celular fisico.

Para esta demo, no depender de Tailscale salvo emergencia.

## Red Entre Emulador Y Celular

Ambos deben conectarse a Supabase Cloud.

Recomendaciones:

- Probar con la misma red Wi-Fi.
- Probar con datos moviles antes del evento.
- Mantener polling cada 2 a 5 segundos.
- No depender de localhost.

## Polling

Usar polling por simplicidad.

Intervalos:

- Consumidor buscando ofertas: cada 2 segundos.
- Emprendedor buscando solicitudes: cada 3 segundos.
- Pedido activo: cada 5 segundos.

Evitar:

- Polling menor a 1 segundo.
- Consultas sin filtros.
- Reconsultar imagenes grandes.

## Storage De Imagenes

Bucket sugerido:

- `dish-photos`

Path sugerido:

```text
dish-photos/<user_id>/<publication_id>/<timestamp>.jpg
```

Regla:

- Subir imagen comprimida si es posible.
- Guardar path en `dish_photos`.

## Riesgos Y Mitigaciones

Riesgo: Google Maps exige billing.

Mitigacion: usar `flutter_map`.

Riesgo: TFLite falla en dispositivo.

Mitigacion: mantener mock con misma interfaz.

Riesgo: red lenta durante demo.

Mitigacion: datos semilla y cuentas preparadas.

Riesgo: permisos de camara/ubicacion fallan.

Mitigacion: permitir seleccionar imagen de galeria y ubicacion manual.

# Plan De Implementacion - 19/05

Objetivo: completar el prototipo TecnoUPSA con mapa OpenStreetMap, seleccion manual/automatica de ubicacion, flujo de inferencia segmentado y experiencia consumidor tipo hibrido inDrive/PedidosYa. El implementador debe avanzar por etapas y detenerse al final de cada una para verificar.

## Decisiones Confirmadas

- Mapas: usar `flutter_map` + OpenStreetMap + `latlong2`.
- Geocoding: soportar ubicacion actual, pin movible/tappable y busqueda escrita.
- Ubicacion de platos: asociada a cada publicacion, editable despues.
- `ConsumerHomeScreen`: queda como home/resumen con ultimas solicitudes y mini mapa.
- `ConsumerMapHomeScreen`: pantalla principal de mapa grande.
- Mapa consumidor: mostrar cocineros disponibles, no publicaciones individuales.
- Marcadores de cocineros: apareceran con delay para simular acomodacion/carga.
- Publicacion con IA: nueva vista obligatoria para primera foto e inferencia.
- Inferencia: inmediata al tomar/elegir la primera foto.
- Inferencia: una sola vez por intento confirmado.
- Fotos adicionales: hasta 2, camara o galeria, sin re-ejecutar inferencia.
- Si se elimina la primera foto despues: permitirlo, advertir que no habra nueva inferencia.
- Estado temporal de inferencia: manejar en memoria por ahora.
- Futuro: documentar que luego podria persistirse un draft/log antes de publicar.
- Distancias/radio: implementar lo mas rapido validable para demo, aunque sea aproximado/client-side.
- Forma de trabajo: no avanzar de etapa sin verificar.

## Etapa 0: Preparacion Y Auditoria

Objetivo: confirmar el estado real del repo antes de modificar.

Tareas:

1. Revisar `pubspec.yaml` para confirmar si ya existen `flutter_map`, `latlong2`, `geolocator`, `geocoding`, `permission_handler`.
2. Revisar la estructura actual de features, especialmente:
   - `dish_publication`
   - `cook_dashboard`
   - `consumer_home`
   - navegacion/rutas
   - servicios de ubicacion existentes
3. Revisar migraciones Supabase actuales para confirmar:
   - `dish_publications.latitude`
   - `dish_publications.longitude`
   - `dish_publications.zone_label`
   - `cook_profiles.is_available`
   - RPCs existentes de publicacion/edicion.
4. Identificar si ya existe un patron de navegacion para crear pantallas nuevas.
5. Identificar si el proyecto usa `provider`, `ChangeNotifier`, repositorios y ViewModels segun MVVM actual.

Verificacion:

- Reportar dependencias faltantes.
- Reportar archivos exactos que se tocaran.
- No implementar todavia si hay ambiguedad estructural.

## Etapa 1: Infraestructura De Mapas Y Ubicacion

Objetivo: crear una base reutilizable para seleccionar coordenadas mediante ubicacion actual, busqueda escrita o pin en mapa.

Tareas:

1. Agregar dependencias si faltan:
   - `flutter_map`
   - `latlong2`
2. Crear o extender un feature/shared module de mapas, por ejemplo:
   - `lib/src/features/maps/services/location_picker_service.dart`
   - `lib/src/features/maps/views/location_picker_screen.dart`
   - `lib/src/features/maps/models/selected_location.dart`
3. Implementar `SelectedLocation` con:
   - `latitude`
   - `longitude`
   - `addressLabel`
   - `source`: `gps`, `search`, `manual_pin`
4. Implementar `LocationPickerScreen`:
   - abre centrada en ubicacion actual si hay permiso
   - si falla permiso, usa coordenadas fallback de demo
   - muestra mapa OpenStreetMap
   - muestra pin central movible o marker actualizable
   - permite tocar en mapa para mover pin
   - permite confirmar ubicacion
   - permite escribir direccion/zona
5. Implementar busqueda escrita:
   - opcion rapida para prototipo: usar `geocoding.locationFromAddress`
   - si falla, mostrar error claro y permitir mover pin manualmente
6. Implementar reverse geocoding:
   - al mover pin o tocar mapa, intentar resolver `addressLabel`
   - si falla, mostrar `Ubicacion seleccionada`
7. Manejar permisos:
   - ubicacion concedida
   - ubicacion denegada
   - ubicacion desactivada
   - fallback manual

Criterios de aceptacion:

- El usuario puede abrir un mapa centrado en ubicacion actual.
- El usuario puede mover/tocar el pin y confirmar coordenadas.
- El usuario puede escribir una ubicacion y centrar el pin.
- La pantalla devuelve `SelectedLocation`.
- No depende de Google Maps ni API key.

Verificacion obligatoria:

- `flutter analyze`
- prueba manual en emulador o dispositivo
- confirmar que el mapa carga tiles
- confirmar que se devuelven coordenadas validas

Pausa:

- No avanzar a Etapa 2 hasta confirmar que el selector de ubicacion funciona.

## Etapa 2: Edicion De Ubicacion En Publicaciones

Objetivo: asociar y modificar ubicacion por publicacion.

Tareas:

1. Integrar `LocationPickerScreen` en el flujo actual de publicacion.
2. Reemplazar o complementar el boton actual de obtener ubicacion con:
   - `Usar mi ubicacion actual`
   - `Elegir en mapa`
   - `Buscar direccion`
3. Guardar en publicacion:
   - `latitude`
   - `longitude`
   - `zone_label`
4. Agregar edicion posterior de ubicacion desde detalle/edicion de publicacion.
5. Extender RPC de edicion si actualmente solo modifica nombre, descripcion, precio y cantidad.
6. Validar que publicar siga bloqueando si no hay ubicacion, salvo fallback explicito si ya existia esa regla.

Criterios de aceptacion:

- Al crear una publicacion, el emprendedor puede elegir ubicacion por mapa.
- La ubicacion queda guardada en `dish_publications`.
- El emprendedor puede cambiar la ubicacion despues.
- La tarjeta/detalle de publicacion muestra una referencia de zona o ubicacion.

Verificacion obligatoria:

- Crear publicacion nueva con ubicacion elegida en mapa.
- Editar ubicacion de publicacion existente.
- Confirmar en Supabase que cambian `latitude`, `longitude`, `zone_label`.
- `flutter analyze`
- `flutter test` si existen tests.

Pausa:

- No avanzar a Etapa 3 hasta verificar creacion y edicion de ubicacion.

## Etapa 3: Flujo Segmentado De Primera Foto E Inferencia

Objetivo: evitar multiples inferencias y separar el primer paso en una vista nueva obligatoria.

Nueva navegacion esperada:

```text
CookDashboardScreen
-> DishInferenceCaptureScreen
-> PublishDishScreen
-> CookDashboardScreen
```

Tareas:

1. Crear nueva vista:
   - `DishInferenceCaptureScreen`
2. Crear o extender ViewModel:
   - `DishInferenceCaptureViewModel`
   - o separar responsabilidades dentro de `PublishDishViewModel` si es mas simple, pero manteniendo vista nueva.
3. La nueva vista debe permitir:
   - tomar una foto
   - seleccionar una foto de galeria
   - ejecutar inferencia inmediatamente
   - mostrar estado de carga
   - mostrar resultado detectado
   - mostrar confianza
   - mostrar estado: reconocido, baja confianza, desconocido
   - permitir reemplazar foto antes de continuar
   - permitir continuar cuando el usuario confirme el intento
4. Regla clave:
   - si el usuario reemplaza la primera foto antes de confirmar, se permite una nueva inferencia.
   - cuando toca `Continuar`, el resultado queda congelado en memoria.
5. Pasar a `PublishDishScreen`:
   - primera foto
   - resultado de inferencia
   - `vision_status`
   - `detected_label`
   - `vision_confidence`
   - `top_predictions`
   - ingredientes sugeridos iniciales
6. Modificar `PublishDishScreen`:
   - ya no debe disparar inferencia al agregar fotos.
   - debe recibir la inferencia ya resuelta.
   - debe permitir agregar hasta 2 fotos adicionales.
   - total maximo: 3 fotos.
7. Si el usuario elimina la primera foto:
   - permitir eliminacion.
   - mostrar advertencia: `La inferencia ya fue realizada para la foto inicial. Si cambias la portada, no se ejecutara un nuevo analisis automatico.`
   - no re-ejecutar clasificacion.
   - mantener `vision_status` y log original.
8. Guardar como portada:
   - idealmente, la primera foto confirmada sigue siendo `position = 1`.
   - si se elimina, la siguiente foto pasa a portada visual, pero no cambia el resultado de inferencia.
9. Documentar consideracion futura:
   - el resultado se mantiene en memoria hasta publicar.
   - en una version posterior puede persistirse como draft para recuperacion si la app se cierra.

Criterios de aceptacion:

- Existe una vista nueva obligatoria antes de publicar.
- La inferencia ocurre inmediatamente al tomar/elegir la primera foto.
- Se permite reemplazar antes de confirmar.
- Despues de confirmar, no se vuelve a inferir.
- Las fotos adicionales no disparan IA.
- Eliminar la foto inicial no dispara IA y muestra advertencia.

Verificacion obligatoria:

- Caso 1: tomar foto inicial, inferencia, continuar, agregar 2 fotos, publicar.
- Caso 2: reemplazar foto inicial antes de continuar, confirmar que se infiere de nuevo.
- Caso 3: agregar fotos extra, confirmar que no se infiere de nuevo.
- Caso 4: eliminar foto inicial despues, confirmar advertencia y no inferencia.
- `flutter analyze`
- `flutter test`

Pausa:

- No avanzar a Etapa 4 hasta verificar que el flujo de IA no re-ejecuta inferencia indebidamente.

## Etapa 4: ConsumerHomeScreen Como Resumen

Objetivo: convertir `ConsumerHomeScreen` en una pantalla tipo PedidosYa ligera, con entrada clara al mapa.

Tareas:

1. Mantener `ConsumerHomeScreen` como pantalla de inicio del consumidor.
2. Agregar:
   - direccion actual o zona seleccionada
   - buscador visual
   - boton principal `Buscar comida en el mapa`
   - mini apartado de mapa
   - ultimas solicitudes realizadas
   - estado de solicitud activa si existe
3. El mini mapa:
   - puede ser una tarjeta estatica inicialmente si acelera el prototipo.
   - idealmente usa `flutter_map` con ubicacion del consumidor.
4. Al tocar mapa/buscador/boton:
   - navegar a `ConsumerMapHomeScreen`.

Criterios de aceptacion:

- El consumidor entra al home y ve una entrada clara al mapa.
- `ConsumerHomeScreen` no contiene toda la logica del flujo de busqueda.
- Las ultimas solicitudes pueden ser placeholder si aun no existe `consumer_requests`, pero deben estar preparadas para datos reales.

Verificacion obligatoria:

- Login como consumidor.
- Navegacion correcta hacia `ConsumerMapHomeScreen`.
- No romper onboarding ni rol de cocinero.
- `flutter analyze`.

Pausa:

- No avanzar a Etapa 5 hasta verificar navegacion consumidor.

## Etapa 5: ConsumerMapHomeScreen Tipo InDrive/PedidosYa

Objetivo: crear el mapa grande del consumidor con panel inferior.

Tareas:

1. Crear:
   - `ConsumerMapHomeScreen`
   - `ConsumerMapHomeViewModel`
2. UI base:
   - mapa full screen
   - boton ubicacion actual
   - marcador/pin del consumidor
   - panel inferior draggable o fijo
   - input/prompt: `Que quieres comer y por cuanto?`
   - accesos rapidos: `Empanada`, `Pizza`, `Hamburguesa`, `Cunape`
   - presupuesto
   - radio maximo
   - alergenos/restricciones
3. Al abrir:
   - centrar en ubicacion actual o ultima seleccionada
   - esperar un delay breve, por ejemplo 700-1200 ms
   - luego mostrar cocineros disponibles
4. Marcadores:
   - representar cocineros disponibles, no platos.
   - coordenada inicial: usar publicaciones activas de cocineros disponibles como proxy si no existe ubicacion de perfil.
   - si un cocinero tiene varias publicaciones, agrupar en un solo marker.
5. Para demo:
   - usar calculo client-side aproximado de distancia con `latlong2`.
   - filtrar por disponibilidad `is_available = true`.
   - opcionalmente filtrar si tiene al menos una publicacion activa.
6. Visual:
   - estilo oscuro o semioscuro inspirado en inDrive si encaja con el diseno actual.
   - panel inferior inspirado en PedidosYa: claro, grande, con busqueda y chips.
7. Al tocar un cocinero:
   - mostrar bottom sheet con nombre, disponibilidad, cantidad de platos activos y distancia aproximada.
   - todavia no hace match; eso va en etapa posterior.

Criterios de aceptacion:

- El consumidor ve mapa grande al entrar.
- Los cocineros disponibles aparecen con delay.
- Los markers representan cocineros.
- El panel inferior permite preparar una busqueda.
- No se crean solicitudes todavia si la etapa 6 no esta implementada.

Verificacion obligatoria:

- Login consumidor.
- Abrir mapa.
- Ver ubicacion propia.
- Ver aparicion retardada de cocineros si existen datos.
- Tocar marker y ver bottom sheet.
- `flutter analyze`.

Pausa:

- No avanzar a Etapa 6 hasta validar experiencia visual del mapa.

## Etapa 6: Solicitudes Del Consumidor

Objetivo: crear una solicitud real desde el panel del mapa.

Tareas:

1. Crear migracion si falta:
   - enum `request_status`
   - tabla `consumer_requests`
2. Crear RPC:
   - `create_consumer_request(payload jsonb)`
3. Payload minimo:
   - `query_text`
   - `target_price`
   - `allergen_filters`
   - `max_radius_km`
   - `current_radius_km`
   - `latitude`
   - `longitude`
4. Crear:
   - `ConsumerRequest`
   - `ConsumerRequestRepository`
5. Conectar `ConsumerMapHomeViewModel`:
   - crear solicitud
   - mostrar estado `Buscando cocineros cerca...`
   - animar o incrementar radio visual
   - mantener polling simple si aplica.
6. Para validacion rapida:
   - radio puede ser visual/client-side.
   - no requiere PostGIS.

Criterios de aceptacion:

- El consumidor crea una solicitud.
- La solicitud queda en Supabase.
- La pantalla muestra estado de busqueda y radio.

Verificacion obligatoria:

- Crear solicitud desde app.
- Confirmar fila en Supabase.
- Confirmar `status = searching`.
- `flutter analyze`
- prueba manual completa.

Pausa:

- No avanzar a Etapa 7 hasta verificar solicitud real.

## Etapa 7: Solicitudes Entrantes Para Emprendedor

Objetivo: que el cocinero disponible vea solicitudes activas.

Tareas:

1. Extender `CookDashboardViewModel`.
2. Implementar polling cada 3 segundos.
3. Crear repositorio si falta:
   - `CookRequestRepository`
4. Crear consulta/RPC para solicitudes activas:
   - filtrar `status = searching`
   - filtrar por distancia aproximada si hay coordenadas
   - filtrar compatible de forma basica por texto/plato
   - alergenos pueden mostrarse primero sin filtrado estricto si acelera demo.
5. Crear componente:
   - `IncomingRequestCard`
6. Mostrar en dashboard:
   - plato buscado
   - presupuesto
   - alergenos/restricciones
   - distancia aproximada
   - boton `Ofertar`
   - boton `Ignorar`

Criterios de aceptacion:

- El emprendedor cambia a `Libre`.
- Ve solicitudes activas del consumidor.
- Puede abrir accion para ofertar.

Verificacion obligatoria:

- Consumidor crea solicitud.
- Emprendedor disponible la ve sin tocar Supabase manualmente.
- `flutter analyze`.

Pausa:

- No avanzar a Etapa 8 hasta validar polling emprendedor.

## Etapa 8: Ofertas Del Emprendedor

Objetivo: permitir que el emprendedor responda con una oferta.

Tareas:

1. Crear migracion si falta:
   - enum `offer_status`
   - tabla `cook_offers`
2. Crear RPC:
   - `create_cook_offer(payload jsonb)`
3. Crear:
   - `CookOffer`
   - `CreateOfferSheet`
4. El bottom sheet debe pedir:
   - publicacion asociada
   - precio ofertado
   - minutos estimados
   - mensaje opcional
5. Validar:
   - publicacion activa
   - cocinero disponible
   - solicitud activa
6. Guardar oferta con `status = pending`.

Criterios de aceptacion:

- El emprendedor puede crear una oferta sobre una solicitud.
- La oferta queda en Supabase.
- Incluye plato/publicacion, precio y tiempo.

Verificacion obligatoria:

- Crear oferta desde app emprendedor.
- Confirmar fila en `cook_offers`.
- `flutter analyze`.

Pausa:

- No avanzar a Etapa 9 hasta validar oferta real.

## Etapa 9: Ofertas Para Consumidor

Objetivo: mostrar ofertas recibidas y detalle.

Tareas:

1. Extender `ConsumerRequestRepository`:
   - `fetchOffersForRequest(requestId)`
2. En `ConsumerMapHomeScreen`:
   - hacer polling cada 2 segundos cuando hay solicitud activa.
   - mostrar contador/lista compacta de ofertas.
3. Crear o implementar:
   - `ConsumerOffersScreen`
   - `OfferDetailScreen`
4. Tarjeta de oferta:
   - foto principal
   - plato
   - emprendedor
   - rating si existe
   - precio
   - distancia aproximada
   - advertencias de alergenos
5. Detalle:
   - fotos
   - descripcion
   - ingredientes declarados
   - `CONTIENE`
   - `PUEDE CONTENER`
   - estado de vision
   - mensaje si analisis visual fue inconcluso
   - boton `Aceptar oferta`

Criterios de aceptacion:

- El consumidor recibe ofertas sin refrescar manualmente.
- Puede abrir detalle.
- Ve foto, precio, distancia y alergenos.

Verificacion obligatoria:

- Crear solicitud.
- Crear oferta desde emprendedor.
- Ver oferta en consumidor.
- Abrir detalle.
- `flutter analyze`.

Pausa:

- No avanzar a Etapa 10 hasta validar recepcion de oferta.

## Etapa 10: Pedido En Curso

Objetivo: cerrar el match y mostrar pedido activo.

Tareas:

1. Crear migracion si falta:
   - enum `order_status`
   - tabla `orders`
2. Crear RPC:
   - `accept_cook_offer(offer_id uuid)`
3. La RPC debe:
   - validar consumidor dueno de solicitud
   - marcar oferta aceptada
   - opcionalmente rechazar/expirar otras ofertas
   - marcar solicitud como `matched`
   - crear `orders`
4. Crear:
   - `Order`
   - `OrderRepository`
   - `ActiveOrderScreen`
5. Pantalla:
   - mapa
   - consumidor
   - emprendedor
   - plato
   - precio acordado
   - estado `Pedido en curso`
   - botones placeholder `Contactar` y `Abrir navegacion`

Criterios de aceptacion:

- Consumidor acepta oferta.
- Se crea pedido.
- Ambos usuarios pueden ver pedido activo.

Verificacion obligatoria:

- Flujo completo:
  - consumidor crea solicitud
  - emprendedor oferta
  - consumidor acepta
  - se crea pedido
  - ambos ven pedido en curso
- Confirmar filas en Supabase.
- `flutter analyze`
- `flutter test`.

Pausa:

- No avanzar a pulido hasta completar flujo end-to-end.

## Etapa 11: Pulido De Demo Y Datos

Objetivo: que el prototipo sea presentable y repetible.

Tareas:

1. Preparar cuentas:
   - consumidor demo
   - emprendedor demo
2. Preparar publicaciones activas con ubicacion cercana.
3. Preparar al menos un cocinero disponible.
4. Preparar imagenes:
   - pizza
   - empanada
   - hamburguesa
   - cunape
   - alimento desconocido
5. Pulir textos:
   - IA no certifica alergenos.
   - ingredientes declarados por emprendedor.
   - ubicacion aproximada.
6. Pulir estados vacios:
   - sin cocineros disponibles
   - sin ofertas todavia
   - ubicacion denegada
   - mapa no cargo
7. Ensayar 3 veces:
   - plato reconocido
   - plato desconocido
   - red alternativa/datos moviles

Verificacion final:

- `flutter analyze`
- `flutter test`
- prueba manual completa consumidor/emprendedor
- prueba en celular fisico y emulador
- confirmar Supabase Cloud si aplica
- confirmar permisos Android

## Documentacion Que Debe Actualizarse

Agregar o modificar docs despues de implementar:

1. `docs/tecnoupsa/04-flutter-mvvm-screens.md`
   - anadir `LocationPickerScreen`
   - anadir `DishInferenceCaptureScreen`
   - anadir `ConsumerMapHomeScreen`
   - aclarar que `ConsumerHomeScreen` redirige al mapa grande
2. `docs/tecnoupsa/02-implementation-stages.md`
   - insertar etapas nuevas de mapas, ubicacion e inferencia segmentada
3. `docs/tecnoupsa/05-computer-vision.md`
   - documentar una inferencia por intento confirmado
   - documentar que fotos adicionales no disparan inferencia
   - documentar advertencia al eliminar la foto inicial
4. Nuevo documento recomendado:
   - `docs/tecnoupsa/09-map-location-and-inference-plan.md`

Contenido minimo del nuevo documento:

```text
- OpenStreetMap/flutter_map confirmado.
- Ubicacion por GPS, busqueda escrita y pin movible.
- Ubicacion asociada a dish_publications.
- ConsumerMapHomeScreen como mapa principal.
- Markers representan cocineros disponibles.
- Delay visual antes de mostrar cocineros.
- Inferencia en memoria hasta publicar.
- Futuro: persistir draft de inferencia si se necesita recuperacion.
```

## Orden Recomendado Para Big Pickle/Qwen/MiniMax

1. Etapa 0: auditar.
2. Etapa 1: mapa selector reutilizable.
3. Etapa 2: ubicacion editable por publicacion.
4. Etapa 3: separar inferencia en vista nueva.
5. Etapa 4: adaptar `ConsumerHomeScreen`.
6. Etapa 5: crear `ConsumerMapHomeScreen`.
7. Etapa 6: crear solicitudes.
8. Etapa 7: solicitudes entrantes al emprendedor.
9. Etapa 8: ofertas.
10. Etapa 9: recepcion/detalle de ofertas.
11. Etapa 10: pedido en curso.
12. Etapa 11: pulido y ensayo.

Regla para el implementador:

```text
No avanzar a la siguiente etapa sin ejecutar la verificacion indicada y reportar resultado.
```

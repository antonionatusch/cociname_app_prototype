# Estado Del Proyecto - 22/05

Este documento reemplaza a `21-05-PROJECT-STATE.md` y resume el estado actual del codigo frente al plan en `docs/tecnoupsa/`. Actualizado tras revisar `01-demo-flow.md`, `02-implementation-stages.md`, `03-supabase-schema.md`, `04-flutter-mvvm-screens.md`, `07-demo-data-and-testing.md` y el estado real de `consumer_map_home_screen.dart`, `consumer_map_home_viewmodel.dart`, `active_order_screen.dart` y migraciones Supabase.

## Resumen Ejecutivo

- Etapa 1 (publicacion con vision, ingredientes y alergenos): **completa para demo**. Persistencia, fotos, ingredientes, vision/fallback manual y advertencias enriquecidas estan implementadas.
- Etapa 2 (busqueda consumidor y sondeo): **parcial**. La solicitud se crea con ubicacion, cantidad, presupuesto, radio y filtros en el payload, pero la UI todavia no conecta chips reales de alergenos ni muestra radio expansivo tipo inDrive.
- Etapa 3 (disponibilidad emprendedor y solicitudes entrantes): **parcial/avanzada**. Libre/Ocupado, polling, tarjetas, oferta e inhabilitacion automatica al aceptar pedido existen; faltan filtros robustos por compatibilidad, alergenos y distancia real.
- Etapa 4 (ofertas y pedido): **avanzada pero incompleta**. Oferta enriquecida, detalle, aceptacion, pedido activo, cancelacion sincronizada y restauracion funcionan. Falta el flujo de finalizacion del pedido con estados, temporizadores y foto obligatoria de entrega.
- Etapa 5 (datos semilla, pulido visual y ensayo): **pendiente/parcial**. Hay datos manuales para desarrollo, pero falta set semilla repetible y guia de ensayo final.

## Cambios Y Hallazgos Del 22/05

- El codigo ya incluye migraciones posteriores al estado del 21/05: `20260521120000_ui_ux_quantity_photos_ratings.sql` y `20260521220000_auto_toggle_cook_availability.sql`.
- `consumer_requests` ya soporta `requested_quantity` y `create_consumer_request` recibe `allergen_filters`, `max_radius_km`, `current_radius_km`, latitud y longitud.
- `create_cook_offer` valida cantidad disponible y enlaza oferta con publicacion activa del emprendedor.
- `accept_cook_offer` ahora marca la solicitud como `matched`, rechaza ofertas competidoras y pone al cocinero como no disponible.
- `cancel_active_order` cancela pedido, sincroniza solicitud/ofertas pendientes y vuelve a dejar disponible al cocinero.
- `ConsumerMapHomeViewModel` obtiene ubicacion actual, crea solicitudes con latitud/longitud, restaura solicitud activa, hace polling de ofertas y de marcadores de cocineros reales disponibles.
- `ConsumerMapHomeScreen` sigue mostrando chips de restricciones solo visuales (`Sin gluten`, `Sin lacteos`, `Sin huevo`, `Sin mani`) sin estado seleccionado ni envio a `createSearchRequest`.
- `_DefaultChips` sigue siendo de platos rapidos (`Empanada`, `Pizza`, `Hamburguesa`, `Cunape`); falta agregar chips rapidos de alergenos/preferencias o conectarlos al panel de busqueda.
- El mapa consumidor no se recentra explicitamente al crear solicitud ni anima circulos de radio incrementales. Solo usa `initialCenter` con la ubicacion actual y un marcador.
- `ActiveOrderScreen` continua como pantalla compartida de pedido activo con polling de estado y cancelacion, pero no distingue roles ni tiene acciones de preparacion, plato hecho, entrega, evidencia fotografica o completado.

## Comparacion Con `docs/tecnoupsa/`

### `01-demo-flow.md`

Cubre:
- Consumidor inicia busqueda con mapa.
- Emprendedor publica plato con foto, vision/fallback, ingredientes y advertencias.
- Emprendedor se marca libre y recibe solicitud.
- Emprendedor envia oferta.
- Consumidor recibe oferta con foto, rating, precio, distancia cuando hay datos, y alergenos.
- Consumidor abre detalle y acepta oferta.
- Ambos ven pedido en curso.

Falta frente al guion:
- Paso 4: restriccion `sin gluten` aun no queda conectada desde chips UI a `allergen_filters`.
- Paso 6: radio incrementando cada 10 segundos y circulo de busqueda en mapa aun no existen visualmente.
- Paso 25: pedido en curso existe, pero no hay cierre exitoso; solo cancelacion.

### `02-implementation-stages.md`

- Etapa 1 cumple los criterios principales.
- Etapa 2 cumple creacion de solicitud, mapa y polling; no cumple radio visual incremental ni filtros de alergenos desde UI.
- Etapa 3 cumple disponibilidad y solicitud entrante; no cumple filtros robustos por distancia, categoria/plato y alergenos.
- Etapa 4 cumple match, oferta, detalle, aceptacion y pedido activo; no cubre aun el subflujo de finalizacion requerido ahora.
- Etapa 5 sigue pendiente en seeds, pulido, ensayo repetible y fallbacks documentados.

### `03-supabase-schema.md`

Implementado o cubierto por migraciones:
- Publicaciones, fotos, ingredientes, alergenos, relaciones ingrediente-alergeno, logs de vision.
- `consumer_requests`, `cook_offers`, `orders` base.
- RPCs principales con `security definer`.
- Cantidad solicitada, ratings basicos y disponibilidad automatica.

Brechas actuales:
- `order_status` propuesto solo contempla `active`, `completed`, `cancelled`; el nuevo flujo necesita estados intermedios.
- Falta tabla/bucket o convencion para fotos de entrega.
- Falta guardar timestamps de confirmacion de preparacion, inicio/fin de preparacion, plato hecho, ventana de entrega y entrega confirmada.
- Falta RPC transaccional para avanzar estados de pedido segun rol y reglas de tiempo.

### `04-flutter-mvvm-screens.md`

Implementado:
- `ConsumerMapHomeScreen` cumple el rol de `ConsumerSearchScreen`.
- `CookDashboardScreen`, `PublishDishScreen`, `CreateOfferSheet`, `OfferDetailScreen` y `ActiveOrderScreen` existen o estan representadas.
- Repositorios principales existen.

Brechas actuales:
- `ConsumerSearchViewModel`/`ConsumerMapHomeViewModel` todavia no mantiene radio visual progresivo.
- `MapPreviewService` sugerido no existe como abstraccion; la logica de mapa esta embebida en pantallas.
- `ActiveOrderScreen` no tiene estados operativos ni UI por rol para preparar, plato hecho, entrega y recepcion.

### `07-demo-data-and-testing.md`

Cubre:
- Flujo manual de publicacion reconocida/desconocida.
- Creacion de busqueda.
- Oferta y pedido activo.

Falta:
- Seeds formales de alergenos, ingredientes, categorias, usuarios y publicaciones.
- Ensayo documentado de 3 corridas.
- Pruebas de finalizacion de pedido y subida de foto a Storage.

## Supabase

### Migraciones Existentes

| Version        | Nombre                                       | Estado |
|----------------|----------------------------------------------|--------|
| 20260427110000 | create_user_accounts_and_role_profiles       | OK     |
| 20260427111000 | add_cook_base_subscription                   | OK     |
| 20260429100000 | add_auth_identifier_availability_rpc         | OK     |
| 20260518100000 | create_dish_publication_schema               | OK     |
| 20260519120000 | create_dish_photos_storage_bucket            | OK     |
| 20260519123000 | fix_create_dish_publication_photo_jsonb      | OK     |
| 20260519124500 | add_publication_photos_and_cook_availability | OK     |
| 20260519131500 | add_publication_management_rpcs              | OK     |
| 20260519132500 | allow_null_vision_confidence                 | OK     |
| 20260519133000 | skip_json_null_vision_log                    | OK     |
| 20260519140000 | extend_update_publication_with_location      | OK     |
| 20260519141000 | create_consumer_requests                     | OK     |
| 20260519142000 | create_offers_and_orders                     | OK     |
| 20260520100000 | fix_tecnoupsa_flow_gaps                      | OK     |
| 20260521100000 | add_order_cancellation                       | OK     |
| 20260521110000 | add_offer_detail_and_order_status            | OK/NUEVA |
| 20260521120000 | ui_ux_quantity_photos_ratings                | OK/NUEVA |
| 20260521220000 | auto_toggle_cook_availability                | OK/NUEVA |

### RPCs Clave

- `create_dish_publication`
- `update_dish_publication`
- `delete_paused_dish_publication`
- `set_cook_availability`
- `create_consumer_request`
- `cancel_consumer_request`
- `create_cook_offer`
- `get_offers_for_request`
- `accept_cook_offer`
- `get_active_order`
- `cancel_active_order`
- `get_order_status`

### Supabase Pendiente Para El Nuevo Flujo De Cierre

- Extender `order_status` o agregar enum paralelo con estados: `awaiting_preparation_confirmation`, `preparing`, `ready`, `delivering`, `delivered`, `completed`, `cancelled`.
- Agregar columnas a `orders`: `preparation_confirmed_at`, `preparation_deadline_at`, `ready_at`, `delivery_deadline_at`, `delivered_at`, `completed_at`.
- Guardar `estimated_preparation_minutes` en `orders` al aceptar oferta, desde `cook_offers.estimated_minutes`.
- Crear bucket de Storage para evidencia de entrega, por ejemplo `order-delivery-photos`.
- Crear tabla `order_delivery_photos` con `order_id`, `storage_path`, `public_url`, `uploaded_by_profile_id`, `created_at`.
- Crear RPCs: `confirm_order_preparation`, `mark_order_ready`, `upload/register_delivery_photo`, `confirm_order_delivery`, `complete_order_if_delivered`.

## Flutter Y Arquitectura

### Archivos Clave

| Feature             | Archivos principales |
|---------------------|----------------------|
| Consumer search     | `consumer_map_home_screen.dart`, `consumer_map_home_viewmodel.dart`, `consumer_request_repository.dart`, `consumer_request.dart` |
| Consumer home       | `consumer_home_screen.dart` |
| Cook dashboard      | `cook_dashboard_screen.dart`, `cook_dashboard_viewmodel.dart`, `cook_request_repository.dart` |
| Offers              | `create_offer_sheet.dart`, `consumer_offers_screen.dart`, `offer_repository.dart`, `cook_offer.dart` |
| Offer detail        | `offer_detail_screen.dart`, `allergen_warnings_section.dart` |
| Orders              | `active_order_screen.dart`, `order_repository.dart`, `order.dart` |
| Dish publication    | `publish_dish_screen.dart`, `publish_dish_viewmodel.dart`, `dish_publication_repository.dart`, `dish_publication.dart` |
| Vision              | `dish_inference_capture_screen.dart`, `dish_inference_capture_viewmodel.dart`, `tflite_vision_classifier_service.dart` |
| Maps                | `location_picker_screen.dart`, `location_picker_viewmodel.dart`, `location_service.dart` |

## Estado Por Etapa

### Etapa 1: Nucleo De Publicacion, Vision Y Alergenos - COMPLETA

Hecho:
- Captura/seleccion de foto.
- Inferencia TFLite local con fallback manual.
- Ingredientes sugeridos, confirmados y manuales.
- Advertencias de alergenos derivadas.
- Persistencia en Supabase con fotos en Storage.
- Dashboard con publicaciones, edicion, pausado/activado y borrado seguro.
- Alergenos enriquecidos con `CONTIENE` / `PUEDE CONTENER` segun `is_confirmed_by_cook` y `certainty`.

Pendiente menor:
- `allergen_summary` agregado en `dish_publications` no esta implementado exactamente como fue propuesto; se resuelve por joins y JSON enriquecido en RPCs.

### Etapa 2: Busqueda Del Consumidor Y Sondeo - PARCIAL

Hecho:
- `ConsumerMapHomeScreen` con OpenStreetMap.
- Panel de busqueda con plato, presupuesto, cantidad, radio maximo y restricciones visuales.
- Creacion de solicitud por RPC `create_consumer_request`.
- Envio tecnico de `allergenFilters` soportado en ViewModel/repositorio.
- Cancelacion de busqueda por RPC `cancel_consumer_request`.
- Polling de ofertas cada 2 segundos.
- Restauracion de solicitud activa/ofertas al entrar al mapa.
- Marcadores de cocineros disponibles desde Supabase mediante polling.

Falta:
- Chips de alergenos seleccionables en UI y envio real a `allergen_filters`.
- Chips rapidos de alergenos/restricciones en `consumer_map_home_screen.dart`, no solo platos rapidos.
- Centrar y animar el mapa hacia la ubicacion del consumidor al crear solicitud.
- Expansion visual real del radio durante la busqueda, con circulos tipo inDrive.
- Persistir o sincronizar `current_radius_km` si se decide que el radio incremental sea tambien backend, no solo visual.
- Expiracion automatica visible de solicitudes vencidas.

### Etapa 3: Disponibilidad Del Emprendedor Y Solicitudes Entrantes - PARCIAL/AVANZADA

Hecho:
- Toggle Libre/Ocupado.
- Polling de solicitudes activas.
- Tarjeta de solicitud entrante con presupuesto, radio y alergenos.
- Boton `Ignorar` local.
- Boton `Ofertar` con `CreateOfferSheet`.
- Emprendedor restaura pedido activo al cargar su dashboard.
- Al aceptar oferta, el cocinero queda no disponible; al cancelar pedido, vuelve a disponible.

Falta:
- Estado `No disponible` separado de `Ocupado` en toda la UI/logica.
- Filtrado real por distancia con ubicacion del emprendedor.
- Filtrado por alergenos y categoria/plato compatible.
- Distancia aproximada robusta visible en tarjeta.

### Etapa 4: Ofertas, Pedido En Curso Y Cierre - AVANZADA/INCOMPLETA

Hecho:
- Tablas `cook_offers` y `orders`.
- RPCs para crear oferta, listar ofertas enriquecidas, aceptar oferta, consultar pedido activo y cancelar pedido.
- Consumidor ve ofertas con foto, plato, cocinero, precio, minutos, distancia/rating cuando existen, y alergenos enriquecidos.
- Tarjeta de oferta tappable y `OfferDetailScreen` completa para aceptar.
- Consumidor y emprendedor restauran pedido activo desde home/mapa/dashboard.
- `ActiveOrderScreen` compartida con mapa, marcadores de consumidor/cocinero, datos del pedido, placeholders y boton cancelar.
- Polling de estado del pedido cada 3 segundos para detectar cancelacion remota.

Falta para el nuevo cierre solicitado:
- Al concretarse el pedido, estado inicial para el cocinero: hasta 5 minutos para pulsar `Confirmar preparacion`.
- Al confirmar preparacion, iniciar temporizador segun `estimated_minutes` de la oferta/publicacion.
- Si el tiempo de preparacion se acaba, permitir o forzar transicion a estado listo para `Plato hecho`.
- Boton `Plato hecho` para pasar a entrega.
- Ventana maxima de 45 minutos para entregar desde `Plato hecho`.
- Antes de confirmar entrega, exigir al menos una foto tomada con camara.
- Subir foto de entrega a Supabase Storage y registrar metadata.
- Flujo analogo para consumidor: ver estados, temporizadores, evidencia/confirmacion de entrega y cierre `completed`.
- Diferenciar UI por rol en `ActiveOrderScreen` o dividir en pantalla/controlador por rol.

### Etapa 5: Datos Semilla, Pulido Visual Y Ensayo - PENDIENTE/PARCIAL

Hecho:
- La app puede probarse manualmente con cuentas y publicaciones creadas durante desarrollo.
- Flujo consumidor-emprendedor ya es demostrable hasta pedido activo/cancelacion.

Falta:
- Seeds formales para ingredientes, alergenos, usuarios demo y publicaciones demo.
- Script/guia de reset para repetir la demo.
- Ensayo documentado en red real y celular fisico.
- Pulido de estados vacios, errores, permisos y fallback sin internet.
- Prueba especifica de foto de entrega en Supabase Storage.

## Problemas Conocidos

1. Los chips de alergenos/restricciones en busqueda no estan conectados al payload real aunque el ViewModel acepta `allergenFilters`.
2. Falta agregar chips rapidos de alergenos en `ConsumerMapHomeScreen`; los chips rapidos actuales son de platos.
3. El mapa no se recentra explicitamente al solicitar ni muestra circulos expansivos de radio.
4. `current_radius_km` se guarda al crear solicitud pero no se incrementa visual ni funcionalmente.
5. Las solicitudes entrantes no filtran por compatibilidad real de plato/alergenos/distancia.
6. `ActiveOrderScreen` cancela pedidos y detecta cancelacion remota, pero aun no permite completar pedido.
7. No existe bucket/tabla/RPC para evidencia fotografica de entrega.
8. `Abrir navegacion` y `Contactar` no ejecutan acciones reales.
9. Falta set de datos semilla repetible para defensa/demo.

## Proximo Paso Recomendado

1. Implementar Etapa 2 pendiente: chips de alergenos y radio expansivo tipo inDrive centrado en consumidor.
2. Implementar extension de Etapa 4: estados de pedido, temporizadores, foto obligatoria y cierre `completed`.
3. Completar filtros de Etapa 3 por distancia, categoria/plato y alergenos.
4. Crear seeds y checklist de ensayo para Etapa 5.

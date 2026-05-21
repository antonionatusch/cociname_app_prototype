# Estado Del Proyecto - 21/05

Este documento reemplaza a `20-05-PROJECT-STATE.md` y resume el estado actual del codigo frente al plan en `docs/tecnoupsa/`.

## Resumen Ejecutivo

- Etapa 1 (publicacion con vision, ingredientes y alergenos): **completa** para demo.
- Etapa 2 (busqueda consumidor y sondeo): **parcial**. La solicitud se crea y se restaura, pero el radio visual sigue pendiente.
- Etapa 3 (disponibilidad emprendedor y solicitudes entrantes): **parcial**. Libre/Ocupado, polling, tarjetas e ignorar solicitud funcionan; faltan filtros reales.
- Etapa 4 (ofertas y pedido): **parcial avanzada**. Ambos roles pueden ver/restaurar pedido activo, aceptar ofertas y cancelar pedido; faltan detalle completo de oferta y acciones reales de contacto/navegacion.
- Etapa 5 (datos semilla, pulido visual y ensayo): **pendiente/parcial**. Hay datos manuales de prueba, pero falta set semilla repetible documentado.

## Cambios Del 21/05

- Corregida restauracion del pedido activo para consumidor tras reconstruccion/hot restart: `ConsumerHomeScreen` consulta `get_active_order` y redirige a `ActiveOrderScreen`.
- `ConsumerMapHomeViewModel` ahora intenta restaurar pedido activo y solicitud activa con ofertas al inicializar.
- Agregada cancelacion de pedido activo con RPC `cancel_active_order` y metodo `OrderRepository.cancelOrder`.
- `ActiveOrderScreen` ahora incluye boton `Cancelar pedido` con confirmacion.
- La cancelacion marca `orders.status = cancelled`, cancela la solicitud asociada y rechaza ofertas pendientes de esa solicitud.
- Mejorada la visibilidad del cocinero con marcador/etiqueta en pedido activo y fila con icono de cocinero en ofertas.
- Se mantiene la pantalla compartida `ActiveOrderScreen` para consumidor y emprendedor con destino de retorno segun rol.

## Supabase

### Migraciones Existentes

| Version        | Nombre                                      | Estado |
|----------------|---------------------------------------------|--------|
| 20260427110000 | create_user_accounts_and_role_profiles      | OK     |
| 20260427111000 | add_cook_base_subscription                  | OK     |
| 20260429100000 | add_auth_identifier_availability_rpc        | OK     |
| 20260518100000 | create_dish_publication_schema              | OK     |
| 20260519120000 | create_dish_photos_storage_bucket           | OK     |
| 20260519123000 | fix_create_dish_publication_photo_jsonb     | OK     |
| 20260519124500 | add_publication_photos_and_cook_availability| OK     |
| 20260519131500 | add_publication_management_rpcs             | OK     |
| 20260519132500 | allow_null_vision_confidence                | OK     |
| 20260519133000 | skip_json_null_vision_log                   | OK     |
| 20260519140000 | extend_update_publication_with_location     | OK     |
| 20260519141000 | create_consumer_requests                    | OK     |
| 20260519142000 | create_offers_and_orders                    | OK     |
| 20260520100000 | fix_tecnoupsa_flow_gaps                     | OK     |
| 20260521100000 | add_order_cancellation                      | NUEVA  |

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

### Estado De Persistencia

- `get_active_order` ya soportaba consumidor y emprendedor; el problema era que el consumidor no lo invocaba al reconstruir su flujo.
- `cancel_active_order` valida que el usuario autenticado sea consumidor o emprendedor participante antes de cancelar.
- `request_status`, `offer_status` y `order_status` ya cubren los estados principales para demo.

## Flutter Y Arquitectura

### Archivos Clave

| Feature             | Archivos principales |
|---------------------|----------------------|
| Consumer search     | `consumer_map_home_screen.dart`, `consumer_map_home_viewmodel.dart`, `consumer_request_repository.dart`, `consumer_request.dart` |
| Consumer home       | `consumer_home_screen.dart` |
| Cook dashboard      | `cook_dashboard_screen.dart`, `cook_dashboard_viewmodel.dart`, `cook_request_repository.dart` |
| Offers              | `create_offer_sheet.dart`, `consumer_offers_screen.dart`, `offer_repository.dart`, `cook_offer.dart` |
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

Pendiente menor:
- `allergen_summary` como campo agregado en `dish_publications` sigue sin implementarse exactamente como fue propuesto en `03-supabase-schema.md`; se resuelve por joins de ingredientes/alergenos.

### Etapa 2: Busqueda Del Consumidor Y Sondeo - PARCIAL

Hecho:
- `ConsumerMapHomeScreen` con OpenStreetMap.
- Panel de busqueda con plato, presupuesto, radio maximo y restricciones visuales.
- Creacion de solicitud por RPC `create_consumer_request`.
- Cancelacion de busqueda por RPC `cancel_consumer_request`.
- Polling de ofertas cada 2 segundos.
- Restauracion de solicitud activa/ofertas al entrar al mapa.

Falta:
- Expansion visual real del radio durante la busqueda.
- Reemplazar cocineros demo hardcodeados por datos reales.
- Chips de restricciones todavia no envian filtros reales desde UI.
- Expiracion automatica de solicitudes vencidas.

### Etapa 3: Disponibilidad Del Emprendedor Y Solicitudes Entrantes - PARCIAL

Hecho:
- Toggle Libre/Ocupado.
- Polling de solicitudes activas.
- Tarjeta de solicitud entrante con presupuesto, radio y alergenos.
- Boton `Ignorar` local.
- Boton `Ofertar` con `CreateOfferSheet`.
- Emprendedor restaura pedido activo al cargar su dashboard.

Falta:
- Filtrado por distancia real con ubicacion del emprendedor.
- Filtrado por alergenos y categoria/plato compatible.
- Distancia aproximada visible en tarjeta.
- Estado `No disponible` separado de `Ocupado`.

### Etapa 4: Ofertas Y Pedido En Curso - PARCIAL AVANZADA

Hecho:
- Tablas `cook_offers` y `orders`.
- RPCs para crear oferta, listar ofertas enriquecidas, aceptar oferta y consultar pedido activo.
- Consumidor ve ofertas con foto si existe, plato, cocinero, precio, minutos, distancia/rating si existen y alergenos.
- Consumidor acepta oferta y entra a `ActiveOrderScreen`.
- Emprendedor entra automaticamente a `ActiveOrderScreen` al detectar pedido activo.
- Consumidor ahora tambien restaura pedido activo desde home/mapa.
- `ActiveOrderScreen` muestra mapa, consumidor, cocinero, plato y precio.
- Marcadores de mapa distinguen consumidor y cocinero cuando existen coordenadas.
- Boton `Cancelar pedido` funcional para ambos participantes.

Falta:
- `OfferDetailScreen` dedicado no esta implementado; el detalle vive dentro de tarjetas/lista.
- Botones `Abrir navegacion` y `Contactar` siguen como placeholders.
- Estados `completed` y seguimiento de cierre exitoso no tienen UI.
- Rating/distancia dependen de datos disponibles; no hay sistema completo de ratings.

### Etapa 5: Datos Semilla, Pulido Visual Y Ensayo - PENDIENTE/PARCIAL

Hecho:
- La app puede probarse manualmente con cuentas y publicaciones creadas durante desarrollo.
- Flujo consumidor-emprendedor ya es demostrable de punta a punta.

Falta:
- Seeds formales para ingredientes, alergenos, usuarios demo y publicaciones demo.
- Script/guia de reset para repetir la demo.
- Ensayo documentado en red real y celular fisico.
- Pulido de estados vacios, errores y fallback sin internet.

## Problemas Conocidos

1. Los marcadores de cocineros cercanos del mapa consumidor siguen siendo demo/hardcodeados.
2. El radio de busqueda no se expande visualmente aun.
3. Los chips de alergenos en busqueda no estan conectados al payload.
4. Las solicitudes entrantes no filtran por compatibilidad real de plato/alergenos/distancia.
5. `ActiveOrderScreen` cancela pedidos, pero aun no permite completar pedido.
6. `Abrir navegacion` y `Contactar` no ejecutan acciones reales.
7. Falta set de datos semilla repetible para defensa/demo.

## Proximo Paso Recomendado

1. Aplicar la migracion `20260521100000_add_order_cancellation.sql` en Supabase local/remoto.
2. Probar el flujo completo con dos sesiones: consumidor crea solicitud, emprendedor oferta, consumidor acepta, ambos restauran pedido tras hot restart, cualquiera cancela.
3. Implementar datos semilla y guia de ensayo para Etapa 5.
4. Reemplazar cocineros demo por publicaciones/cocineros reales de Supabase.

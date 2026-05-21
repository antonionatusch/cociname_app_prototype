# Estado Del Proyecto - 21/05

Este documento reemplaza a `20-05-PROJECT-STATE.md` y resume el estado actual del codigo frente al plan en `docs/tecnoupsa/`. Actualizado tras completar detalle de oferta, alergenos enriquecidos y polling de cancelacion remota.

## Resumen Ejecutivo

- Etapa 1 (publicacion con vision, ingredientes y alergenos): **completa** para demo.
- Etapa 2 (busqueda consumidor y sondeo): **parcial**. La solicitud se crea y se restaura, pero el radio visual sigue pendiente.
- Etapa 3 (disponibilidad emprendedor y solicitudes entrantes): **parcial**. Libre/Ocupado, polling, tarjetas e ignorar solicitud funcionan; faltan filtros reales.
- Etapa 4 (ofertas y pedido): **avanzada**. Detalle de oferta completo, negociacion y pedido en curso con cancelacion remota sincronizada. Pendiente: acciones reales de contacto/navegacion y cierre exitoso.
- Etapa 5 (datos semilla, pulido visual y ensayo): **pendiente/parcial**. Hay datos manuales de prueba, pero falta set semilla repetible documentado.

## Cambios Del 21/05 (Segunda Ronda)

- Nuevos modelos `OfferIngredientItem` y `OfferAllergenWarning` con distincion `CONTIENE` / `PUEDE CONTENER` segun logica del TFG: ingrediente confirmado por cocinero + certeza `contains` -> `CONTIENE`; otro caso -> `PUEDE CONTENER`.
- `CookOffer.fromMap` ahora parsea `dish_ingredient_items` y `allergen_warnings` desde `get_offers_for_request`.
- Nueva pantalla `OfferDetailScreen`: foto, plato, cocinero, precio, tiempo, distancia, ingredientes (confirmados/sugeridos) y seccion de advertencias de alergenos enriquecida.
- Nuevo widget `AllergenWarningsSection` reutilizable con bloques `CONTIENE` / `PUEDE CONTENER`, chip por alergeno-ingrediente, y disclaimer preventivo.
- Tarjetas de oferta en `ConsumerMapHomeScreen`: ahora tienen resumen inline de alergenos (`CONTIENE: Gluten`), boton `Detalle` que abre `OfferDetailScreen`, y toda la tarjeta es tappable.
- `ActiveOrderScreen` convertido a `StatefulWidget` con polling cada 3s via `fetchOrderStatus`; si el otro participante cancela, sale del pedido automaticamente con SnackBar.
- `OrderRepository.fetchOrderStatus` expone el RPC `get_order_status`.
- Nueva migracion `20260521110000_add_offer_detail_and_order_status.sql` que agrega `get_order_status` y enriquece `get_offers_for_request` con `dish_ingredient_items` y `allergen_warnings` como JSONB, manteniendo `allergen_codes` para compatibilidad.

### Detalle De Logica De Alergenos

- `dish_ingredients.is_confirmed_by_cook = true` + `ingredient_allergens.certainty = 'contains'` -> `warning_type = 'contains'` (CONTIENE).
- Otro caso (no confirmado, certeza distinta) -> `warning_type = 'may_contain'` (PUEDE CONTENER).
- Si la migracion nueva no esta aplicada, `CookOffer.fromMap` genera advertencias `PUEDE CONTENER` desde `allergen_codes` como fallback.
- Advertencia preventiva, no certificacion medica/sanitaria (alineado con docs/tfg-v2-latest.pdf).

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
| 20260521100000 | add_order_cancellation                      | OK     |
| 20260521110000 | add_offer_detail_and_order_status           | NUEVA  |

### RPCs Clave

- `create_dish_publication`
- `update_dish_publication`
- `delete_paused_dish_publication`
- `set_cook_availability`
- `create_consumer_request`
- `cancel_consumer_request`
- `create_cook_offer`
- `get_offers_for_request` (enriquecida con `dish_ingredient_items` y `allergen_warnings`)
- `accept_cook_offer`
- `get_active_order`
- `cancel_active_order`
- `get_order_status`

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

### Etapa 4: Ofertas Y Pedido En Curso - AVANZADA

Hecho:
- Tablas `cook_offers` y `orders`.
- RPCs para crear oferta, listar ofertas enriquecidas, aceptar oferta, consultar pedido activo y cancelar pedido.
- Consumidor ve ofertas con foto si existe, plato, cocinero, precio, minutos, distancia/rating si existen, alergenos enriquecidos y resumen inline `CONTIENE`/`PUEDE CONTENER`.
- Tarjeta de oferta tappable para abrir detalle y boton `Detalle` explicito.
- `OfferDetailScreen` dedicada con foto, plato, cocinero, precio, tiempo, distancia, rating, ubicacion, descripcion, mensaje del cocinero, ingredientes (confirmados/sugeridos), advertencias de alergenos enriquecidas, y boton `Aceptar oferta`.
- Consumidor puede aceptar desde detalle o desde tarjeta directamente.
- Consumidor y emprendedor restauran pedido activo desde home/mapa/dashboard.
- `ActiveOrderScreen` compartida con mapa, marcadores de consumidor/cocinero, datos del pedido, boton `Cancelar pedido`.
- Polling de estado del pedido cada 3s: si el otro participante cancela, la pantalla muestra SnackBar y navega al destino correspondiente automaticamente.
- Cancelacion desde `ActiveOrderScreen` tambien navega al destino de retorno reutilizando la misma logica.

Cubre los pasos 21-24 del flujo de demo (`docs/tecnoupsa/01-demo-flow.md`):
- Oferta recibida con foto, nombre, rating, precio, distancia y alergenos.
- Consumidor abre detalle.
- Consumidor acepta oferta.
- Pedido en curso con mapa y datos principales.
- Cancelacion sincronizada en ambos participantes.

Falta:
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
5. `ActiveOrderScreen` cancela pedidos y detecta cancelacion remota, pero aun no permite completar pedido.
6. `Abrir navegacion` y `Contactar` no ejecutan acciones reales.
7. Falta set de datos semilla repetible para defensa/demo.

## Proximo Paso Recomendado

1. Aplicar la migracion `20260521110000_add_offer_detail_and_order_status.sql` en Supabase WSL (pendiente).
2. Probar el flujo completo con dos sesiones: oferta con detalle/alergenos, aceptacion, cancelacion sincronizada.
3. Implementar datos semilla y guia de ensayo para Etapa 5.
4. Reemplazar cocineros demo por publicaciones/cocineros reales de Supabase.

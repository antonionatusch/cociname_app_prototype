# Estado Del Proyecto - 20/05

Este documento resume el avance al 20/05 comparado con el plan en `docs/tecnoupsa/`.
Sirve como punto de partida para retomar el trabajo.

## Resumen Ejecutivo

- Etapa 1 (publicacion con vision): **completa**.
- Etapa 2 (busqueda consumidor): **parcial**. Solicitud se crea, pero falta expansion visual del radio y pulido.
- Etapa 3 (disponibilidad emprendedor + solicitudes entrantes): **parcial**. Toggle Libre/Ocupado funciona, polling de solicitudes existe, tarjetas se muestran.
- Etapa 4 (ofertas + pedido): **parcial**. Tablas/RPCs existen, consumidor ve ofertas y acepta, pantalla de pedido existe. Faltan detalles de alergenos en oferta, distancia real, rating.
- Etapa 5 (datos semilla + ensayo): **pendiente**.

## Supabase

### Migraciones aplicadas (local)

| Version          | Nombre                                      | Estado  |
|------------------|---------------------------------------------|---------|
| 20260427110000   | create_user_accounts_and_role_profiles      | OK      |
| 20260427111000   | add_cook_base_subscription                  | OK      |
| 20260429100000   | add_auth_identifier_availability_rpc        | OK      |
| 20260518100000   | create_dish_publication_schema              | OK      |
| 20260519120000   | create_dish_photos_storage_bucket           | OK      |
| 20260519123000   | fix_create_dish_publication_photo_jsonb     | OK      |
| 20260519124500   | add_publication_photos_and_cook_availability| OK      |
| 20260519131500   | add_publication_management_rpcs             | OK      |
| 20260519132500   | allow_null_vision_confidence                | OK      |
| 20260519133000   | skip_json_null_vision_log                   | OK      |
| 20260519140000   | extend_update_publication_with_location     | OK      |
| 20260519141000   | create_consumer_requests                    | OK      |
| 20260519142000   | create_offers_and_orders                    | OK      |

### Fix aplicado en migracion 141000

- `allergen_filters` usaba casteo inválido `(payload -> 'allergen_filters')::text[]`.
- Se reemplazo por `public.jsonb_text_array(payload -> 'allergen_filters')`.

### Tablas clave (conteo local), en laptop

| Tabla               | Filas |
|---------------------|-------|
| profiles            | 19    |
| consumer_profiles   | 10    |
| cook_profiles       | 8     |
| dish_publications   | 3     |
| dish_photos         | 3     |
| consumer_requests   | 1     |
| cook_offers         | 0     |
| orders              | 0     |

### RPCs existentes

- `create_dish_publication`
- `update_dish_publication`
- `delete_paused_dish_publication`
- `set_cook_availability`
- `create_consumer_request`
- `create_cook_offer`
- `accept_cook_offer`

### Lo que falta en Supabase

- Politica de update para `consumer_requests` (cancelRequest hace update directo sin politica explicita; puede fallar en RLS).
- RPC o trigger para expirar solicitudes automaticamente (`expires_at` existe pero no se usa).
- Campo `allergen_summary` en `dish_publications` (mencionado en schema propuesto pero no implementado).
- Datos semilla/demo para ensayo.

## Flutter Y Arquitectura

### Archivos clave implementados

| Feature              | Archivos principales                                      |
|----------------------|-----------------------------------------------------------|
| Consumer search      | `consumer_map_home_screen.dart`, `consumer_map_home_viewmodel.dart`, `consumer_request_repository.dart`, `consumer_request.dart` |
| Cook dashboard       | `cook_dashboard_screen.dart`, `cook_dashboard_viewmodel.dart`, `cook_request_repository.dart` |
| Offers               | `create_offer_sheet.dart`, `offer_repository.dart`, `cook_offer.dart` |
| Orders               | `active_order_screen.dart`, `order_repository.dart`, `order.dart` |
| Dish publication     | `publish_dish_screen.dart`, `publish_dish_viewmodel.dart`, `dish_publication_repository.dart`, `dish_publication.dart` |
| Vision               | `dish_inference_capture_screen.dart`, `dish_inference_capture_viewmodel.dart`, `tflite_vision_classifier_service.dart` |
| Maps                 | `location_picker_screen.dart`, `location_picker_viewmodel.dart`, `location_service.dart` |

### Estado por Etapa

#### Etapa 1: Nucleo De Publicacion, Vision Y Alergenos - COMPLETA

- Emprendedor toma/selecciona foto.
- Inferencia TFLite con labels locales.
- Ingredientes sugeridos por categoria.
- Ingredientes manuales y personalizados.
- Advertencias de alergenos derivadas.
- Publicacion persiste en Supabase con fotos en Storage.
- Dashboard con Libre/Ocupado, lista de publicaciones, toggle Activo/Pausado, edicion y borrado seguro.

#### Etapa 2: Busqueda Del Consumidor Y Sondeo - PARCIAL

**Hecho:**
- Pantalla `ConsumerMapHomeScreen` con mapa OpenStreetMap.
- Panel de busqueda con plato, presupuesto, radio maximo y restricciones.
- Creacion de solicitud via RPC `create_consumer_request`.
- Polling de ofertas cada 2 segundos.
- UI de estado de busqueda y ofertas recibidas.
- Boton cancelar busqueda.

**Falta:**
- Expansion visual del radio durante la busqueda (circulo animado en mapa).
- Marcadores de cocineros son datos demo hardcodeados, no vienen de DB.
- Validacion de alergenos del consumidor vs ofertas.
- Limite de tiempo de busqueda / expiracion automatica.
- Feedback de error visible (parcialmente corregido el 20/05, pero falta pulido).

#### Etapa 3: Disponibilidad Del Emprendedor Y Solicitudes Entrantes - PARCIAL

**Hecho:**
- Toggle Libre/Ocupado en dashboard.
- Polling de solicitudes activas cada 3 segundos.
- Tarjeta de solicitud entrante con plato, presupuesto, radio y alergenos.
- Boton "Ofertar" abre `CreateOfferSheet`.

**Falta:**
- Filtrado por distancia real (coordenadas del emprendedor no se pasan al repositorio).
- Filtrado por alergenos (no se cruzan alergenos de solicitud vs ingredientes del plato).
- Filtrado por categoria/plato compatible.
- Boton "Ignorar" solicitud.
- Indicador de distancia aproximada en tarjeta.

#### Etapa 4: Ofertas Y Pedido En Curso - PARCIAL

**Hecho:**
- Tablas `cook_offers` y `orders` creadas.
- RPC `create_cook_offer` y `accept_cook_offer` funcionan.
- Consumidor ve ofertas recibidas con precio, minutos y mensaje.
- Boton "Aceptar" crea orden y navega a `ActiveOrderScreen`.
- Pantalla de pedido en curso con mapa y resumen.

**Falta:**
- Oferta debe mostrar foto del plato, nombre del emprendedor, rating y distancia.
- Advertencias de alergenos en detalle de oferta.
- Emprendedor ve estado del pedido aceptado.
- Botones "Abrir navegación" y "Contactar" no funcionales.
- Estados de orden (completado, cancelado) no tienen UI.

#### Etapa 5: Datos Semilla, Pulido Visual Y Ensayo - PENDIENTE

- Sin datos semilla para demo rapida.
- Sin cuentas pre-configuradas consumidor/emprendedor.
- Sin ensayo documentado.
- Estados vacios y errores necesitan pulido.

## Problemas Conocidos

1. **RLS en consumer_requests**: `cancelRequest` hace update directo sin politica de update para el consumidor. Puede fallar.
2. **Cooks demo hardcodeados**: Los marcadores en el mapa del consumidor son datos ficticios, no reflejan cocineros reales de la DB.
3. **Sin filtrado por distancia real**: `CookRequestRepository.fetchActiveRequests` recibe coordenadas pero el dashboard no las pasa.
4. **Sin filtrado por alergenos**: Las solicitudes entrantes no se filtran por compatibilidad de alergenos.
5. **Oferta sin detalle rico**: Falta foto, nombre, rating y distancia en la oferta que ve el consumidor.
6. **Expiracion no implementada**: `expires_at` existe en schema pero no se usa en ninguna logica.
7. **Chat/navegacion no funcionales**: Botones placeholder en `ActiveOrderScreen`.

## Cambios Del 20/05

- Corregido casteo de `allergen_filters` en migracion 141000.
- Aplicadas 3 migraciones pendientes (140000, 141000, 142000).
- Agregada visualizacion de errores en panel de busqueda del consumidor.
- Agregadas validaciones de formulario (plato vacio, presupuesto invalido).
- Verificado que `consumer_requests`, `cook_offers`, `orders` y sus RPCs existen en DB local.
- `flutter analyze` sin errores nuevos. `flutter test` pasa.

## Proximo Paso Recomendado

Priorizar Etapa 5 (datos semilla + ensayo) para tener demo repetible, luego pulir:
1. Filtrado por distancia real en solicitudes entrantes.
2. Filtrado por alergenos.
3. Detalle rico de oferta (foto, nombre, rating, distancia).
4. Politica de update para cancelar solicitudes.
5. Reemplazar cooks demo por datos reales de DB.

# Pantallas Flutter MVVM

Este documento define las pantallas y clases esperadas. Mantener la estructura existente por feature.

## Convencion Recomendada

Estructura por feature:

```text
lib/src/features/<feature>/
  models/
  repositories/
  services/
  viewmodels/
  views/
```

## Features Nuevos

- `dish_publication`
- `consumer_search`
- `cook_requests`
- `offers`
- `orders`
- `vision`
- `allergens`
- `maps`

## Pantallas Existentes A Reutilizar

- `LoginScreen`
- `RegisterScreen`
- `VerifyIdentityScreen`
- `OnboardingFlowScreen`
- `ConsumerHomeScreen`
- `CookDashboardScreen`
- `RoleHubScreen`

## Extension Del Onboarding Consumidor

Agregar preguntas utiles para la demo:

1. Presupuesto habitual por plato.
2. Radio maximo de busqueda.
3. Severidad de alergia.
4. Tolerancia a advertencias `PUEDE CONTENER`.
5. Platos buscados frecuentemente.

No eliminar preguntas existentes. Agregar solo las necesarias y adaptar el payload.

## Pantallas Emprendedor

### `CookDashboardScreen`

Debe evolucionar desde placeholder a hub operativo.

Elementos:

- Estado de suscripcion base.
- Boton `Publicar plato`.
- Toggle `Libre / Ocupado / No disponible`.
- Tarjeta de solicitudes entrantes.
- Acceso a publicaciones activas.

ViewModel:

- `CookDashboardViewModel`

Responsabilidades:

- Cargar perfil emprendedor.
- Leer/actualizar disponibilidad.
- Polling de solicitudes activas.
- Navegar a publicar plato.

### `PublishDishScreen`

Pantalla principal de etapa 1.

Elementos:

- Selector/toma de foto.
- Vista previa de imagen.
- Estado de inferencia.
- Etiqueta detectada.
- Confianza.
- Campo editable de nombre del plato.
- Precio.
- Descripcion breve.
- Cantidad disponible.
- Ingredientes sugeridos.
- Ingredientes manuales.
- Advertencias de alergenos.
- Boton `Publicar`.

ViewModel:

- `PublishDishViewModel`

Responsabilidades:

- Manejar imagen.
- Ejecutar clasificacion.
- Resolver `vision_status`.
- Cargar ingredientes sugeridos por categoria.
- Confirmar/eliminar/agregar ingredientes.
- Calcular alergenos.
- Subir imagen a Storage.
- Guardar publicacion.

### `IncomingRequestCard`

Componente dentro del panel emprendedor.

Elementos:

- Texto buscado por consumidor.
- Precio objetivo.
- Alergenos a evitar.
- Distancia aproximada.
- Botones `Ofertar` y `Ignorar`.

### `CreateOfferSheet`

Bottom sheet para responder solicitud.

Campos:

- Publicacion asociada.
- Precio ofertado.
- Minutos estimados.
- Mensaje opcional.

## Pantallas Consumidor

### `ConsumerHomeScreen`

Debe redirigir o contener entrada a busqueda.

Elementos:

- Saludo.
- Resumen de restricciones.
- Boton `Buscar plato ahora`.
- Acceso a solicitudes activas.

### `ConsumerSearchScreen`

Pantalla tipo inDrive.

Elementos:

- Mapa.
- Campo `Que quieres comer?`.
- Presupuesto.
- Chips de alergenos.
- Radio maximo.
- Boton `Buscar plato`.
- Estado de sondeo.
- Circulo/radio de busqueda.

ViewModel:

- `ConsumerSearchViewModel`

Responsabilidades:

- Obtener ubicacion.
- Crear solicitud.
- Mantener polling.
- Actualizar radio visual.
- Consultar ofertas recibidas.

### `ConsumerOffersScreen`

Muestra ofertas recibidas.

Elementos:

- Lista de tarjetas.
- Foto principal.
- Nombre del plato.
- Precio.
- Emprendedor.
- Rating.
- Distancia.
- Advertencias de alergenos.

### `OfferDetailScreen`

Detalle de una oferta.

Elementos:

- Imagen grande.
- Nombre del plato.
- Descripcion.
- Ingredientes declarados.
- `CONTIENE`.
- `PUEDE CONTENER`.
- Estado de vision: reconocido, baja confianza, desconocido o manual.
- Emprendedor y rating.
- Boton `Aceptar oferta`.

## Pantallas Compartidas

### `ActiveOrderScreen`

Pantalla final de la demo.

Elementos:

- Mapa.
- Emprendedor.
- Consumidor.
- Plato.
- Precio acordado.
- Estado `Pedido en curso`.
- Boton placeholder `Abrir navegacion`.
- Boton placeholder `Contactar`.

## Modelos Dart Sugeridos

- `DishPublication`
- `DishPhoto`
- `Ingredient`
- `Allergen`
- `DishIngredient`
- `AllergenWarning`
- `VisionPrediction`
- `VisionInferenceResult`
- `ConsumerRequest`
- `CookOffer`
- `Order`
- `CookAvailability`

## Repositorios

### `DishPublicationRepository`

Metodos:

- `createPublication(...)`
- `uploadDishPhoto(...)`
- `fetchOwnPublications()`
- `fetchPublicationDetail(id)`

### `AllergenRepository`

Metodos:

- `fetchIngredients()`
- `fetchAllergens()`
- `fetchIngredientAllergenMap()`
- `resolveWarnings(ingredients)`

### `ConsumerRequestRepository`

Metodos:

- `createRequest(...)`
- `fetchActiveRequest()`
- `fetchOffersForRequest(requestId)`
- `cancelRequest(requestId)`

### `CookRequestRepository`

Metodos:

- `updateAvailability(...)`
- `fetchActiveRequests()`
- `createOffer(...)`

### `OrderRepository`

Metodos:

- `acceptOffer(offerId)`
- `fetchActiveOrder()`

## Servicios

### `VisionClassifierService`

Responsabilidades:

- Cargar modelo TFLite o mock.
- Preprocesar imagen.
- Ejecutar inferencia.
- Devolver top predictions.
- Resolver etiqueta y confianza.

### `LocationService`

Responsabilidades:

- Solicitar permisos.
- Obtener ubicacion.
- Manejar fallback manual.

### `MapPreviewService`

Responsabilidades:

- Preparar marcadores.
- Preparar radio/circulo.
- Calcular distancia aproximada si no se usa PostGIS.

## Navegacion Minima

Flujo emprendedor:

`CookDashboardScreen -> PublishDishScreen -> CookDashboardScreen -> CreateOfferSheet -> ActiveOrderScreen`

Flujo consumidor:

`ConsumerHomeScreen -> ConsumerSearchScreen -> ConsumerOffersScreen -> OfferDetailScreen -> ActiveOrderScreen`

# Etapas De Implementacion

Este archivo define el orden de trabajo. Un LLM implementador debe completar una etapa, verificarla y reportar el resultado antes de pasar a la siguiente.

## Etapa 1: Nucleo De Publicacion, Vision Y Alergenos

Esta es la etapa mas dificil. Debe implementarse primero.

### Objetivo

Permitir que el emprendedor publique un plato con foto, inferencia visual, fallback manual, ingredientes, alergenos y persistencia en Supabase.

### Tareas

1. Crear migraciones Supabase para:
   - `dish_categories`
   - `dish_publications`
   - `dish_photos`
   - `ingredients`
   - `allergens`
   - `ingredient_allergens`
   - `dish_ingredients`
   - `vision_inference_logs`
2. Crear bucket de Supabase Storage para fotos de platos.
3. Agregar RLS minima para que el emprendedor gestione sus publicaciones.
4. Crear modelos Dart de publicacion, ingrediente, alergeno e inferencia.
5. Crear repositorio Flutter para publicaciones.
6. Crear `CookPublishDishViewModel`.
7. Crear pantalla `PublishDishScreen`.
8. Integrar `image_picker` o `camera`.
9. Integrar servicio `VisionClassifierService` con una de estas opciones:
   - TFLite real si el modelo ya esta disponible.
   - Mock temporal con salida deterministica para avanzar la UI.
10. Implementar umbrales:
   - `recognized` si confianza `>= 0.75`.
   - `low_confidence` si confianza `>= 0.45` y `< 0.75`.
   - `unknown` si confianza `< 0.45`.
11. Implementar modo manual asistido para alimentos desconocidos.
12. Implementar mapeo ingrediente-alergeno.
13. Guardar publicacion con foto, ingredientes, estado de vision y alergenos derivados.
14. Mostrar vista previa antes de publicar.

### Criterios De Aceptacion

- El emprendedor puede tomar o elegir una foto.
- La app muestra una prediccion o indica que no reconoce el alimento.
- La app permite corregir el nombre del plato.
- La app permite confirmar, eliminar y agregar ingredientes.
- La app muestra `CONTIENE` y `PUEDE CONTENER` segun la fuente del ingrediente.
- La publicacion queda guardada en Supabase.
- La foto queda guardada en Supabase Storage.
- El caso `unknown_food` no bloquea la publicacion.

### Pausa Obligatoria

Al completar esta etapa, el LLM debe detenerse y preguntar:

> Ya esta implementado el nucleo de publicacion con vision computacional, fallback manual, alergenos y persistencia en Supabase. Lo siguiente es implementar el flujo consumidor-emprendedor en tiempo real. ¿Quieres proceder?

No continuar sin confirmacion.

## Etapa 2: Busqueda Del Consumidor Y Sondeo

### Objetivo

Crear una experiencia tipo inDrive donde el consumidor emite una solicitud y ve que la app busca emprendedores cercanos.

### Tareas

1. Crear migracion para `consumer_requests`.
2. Agregar campos utiles al perfil consumidor si no existen:
   - radio maximo preferido.
   - presupuesto habitual.
   - tolerancia a `puede contener`.
   - severidad de alergia.
3. Crear pantalla `ConsumerSearchScreen`.
4. Crear `ConsumerSearchViewModel`.
5. Agregar mapa costo cero con `flutter_map`.
6. Crear solicitud con plato, precio, alergenos, ubicacion y radio.
7. Mostrar estado de busqueda con polling.
8. Incrementar radio visualmente hasta el maximo configurado.

### Criterios De Aceptacion

- El consumidor puede crear una solicitud.
- La solicitud queda en Supabase.
- La pantalla muestra mapa, radio y estado de sondeo.
- El radio aumenta o aparenta aumentar durante la busqueda.

## Etapa 3: Disponibilidad Del Emprendedor Y Solicitudes Entrantes

### Objetivo

Permitir que el emprendedor se marque como disponible y reciba solicitudes compatibles.

### Tareas

1. Crear migracion para `cook_availability` o campos equivalentes en `cook_profiles`.
2. Crear pantalla o seccion `CookAvailabilityPanel`.
3. Mostrar estado `Libre`, `Ocupado`, `No disponible`.
4. Implementar polling de solicitudes activas.
5. Filtrar solicitudes por radio aproximado, categoria/plato y alergenos.
6. Mostrar tarjeta de solicitud entrante.

### Criterios De Aceptacion

- El emprendedor puede cambiar a `Libre`.
- Una solicitud activa del consumidor aparece en el celular del emprendedor.
- El emprendedor puede ver plato solicitado, presupuesto, alergias y distancia aproximada.

## Etapa 4: Ofertas Y Pedido En Curso

### Objetivo

Completar el match entre consumidor y emprendedor.

### Tareas

1. Crear migraciones para `cook_offers` y `orders`.
2. Permitir al emprendedor aceptar o contraofertar.
3. Crear polling de ofertas del lado consumidor.
4. Crear pantalla `ConsumerOffersScreen`.
5. Crear pantalla `OfferDetailScreen`.
6. Mostrar foto, precio, rating, distancia y alergenos.
7. Permitir aceptar oferta.
8. Crear pedido.
9. Crear pantalla `ActiveOrderScreen` compartida.

### Criterios De Aceptacion

- El emprendedor emite una oferta.
- El consumidor recibe la oferta.
- El consumidor puede ver detalle y aceptar.
- Se crea un pedido en Supabase.
- Ambos usuarios pueden ver pedido en curso.

## Etapa 5: Datos Semilla, Pulido Visual Y Ensayo

### Objetivo

Hacer que la demo se vea profesional y repetible.

### Tareas

1. Crear datos semilla para ingredientes y alergenos.
2. Crear publicaciones demo opcionales.
3. Mejorar textos, colores, estados vacios y errores.
4. Preparar cuentas consumidor/emprendedor.
5. Ensayar con red real y celular fisico.
6. Preparar fallback por si falla internet.

### Criterios De Aceptacion

- La demo puede repetirse al menos 3 veces.
- Existen datos semilla consistentes.
- Los estados visuales se entienden sin explicacion larga.

## Etapa 6: Mejoras Opcionales

Solo implementar si queda tiempo.

- Supabase Realtime en vez de polling.
- Chat basico.
- Analitica simple del emprendedor.
- Mapa con Google Maps.
- Exportar logs de inferencia para defensa academica.

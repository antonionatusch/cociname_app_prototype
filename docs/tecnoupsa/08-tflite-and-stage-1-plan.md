# TFLite Y Plan Solido De Etapa 1

Este documento explica como crear el modelo `.tflite` para la demo TecnoUPSA y redefine un plan de implementacion concreto para la Etapa 1: publicacion de plato con foto, vision computacional, fallback manual, ingredientes, alergenos y persistencia en Supabase.

## Que Es Un Modelo `.tflite`

Un archivo `.tflite` es un modelo de TensorFlow convertido a TensorFlow Lite. TensorFlow Lite esta optimizado para ejecutar inferencia en celulares, con menor peso y menor consumo que un modelo TensorFlow completo.

Para esta demo, el modelo sera un clasificador de imagen completa. La app le entrega una foto de un plato y el modelo devuelve probabilidades por clase.

Ejemplo de salida esperada:

```text
pizza: 0.92
empanada_queso: 0.04
brownie_normal: 0.02
unknown_food: 0.02
```

La app no usara el resultado como certificacion sanitaria. Solo lo usara para sugerir ingredientes probables. El emprendedor confirma, elimina o agrega ingredientes, y recien entonces el sistema genera advertencias preventivas de alergenos.

## Clases Del Modelo

El modelo inicial debe tener estas clases cerradas:

```text
empanada_queso
empanada_queso_integral
pizza
brownie_keto
brownie_normal
unknown_food
```

La clase `unknown_food` es importante porque permite que la app no invente resultados cuando el plato no esta dentro del alcance del modelo.

## Umbrales De Confianza

La app debe traducir la confianza del modelo a un estado funcional:

```text
recognized      -> confianza >= 0.75
low_confidence  -> confianza >= 0.45 y < 0.75
unknown         -> confianza < 0.45
manual_only     -> el usuario salta la inferencia o el modelo falla
```

Comportamiento esperado:

```text
recognized      -> mostrar plato detectado y sugerir ingredientes
low_confidence  -> mostrar resultado como probable y permitir correccion clara
unknown         -> activar modo manual asistido
manual_only     -> activar modo manual asistido
```

## Forma Recomendada De Crear El `.tflite`

La opcion recomendada para esta demo es Teachable Machine porque permite entrenar y exportar un modelo TFLite rapidamente sin escribir codigo de entrenamiento.

Sitio:

```text
https://teachablemachine.withgoogle.com/
```

Pasos:

1. Crear un proyecto nuevo.
2. Elegir `Image Project`.
3. Elegir `Standard image model`.
4. Crear las seis clases definidas para la demo.
5. Subir fotos por clase.
6. Entrenar el modelo.
7. Probar el modelo con fotos reales desde webcam o archivos.
8. Exportar como `TensorFlow Lite`.
9. Descargar `model.tflite` y `labels.txt`.
10. Agregar ambos archivos al proyecto Flutter como assets.

## Cantidad De Fotos Recomendada

Minimo aceptable para prototipo:

```text
30 a 50 fotos por clase real
50 a 100 fotos para unknown_food
```

Recomendado para una demo mas estable:

```text
80 a 150 fotos por clase real
150 a 300 fotos para unknown_food
```

La clase `unknown_food` debe contener alimentos fuera del alcance del modelo, por ejemplo:

```text
sopa
sandwich
ensalada
arroz
pollo
hamburguesa
pasta
torta
frutas
bebidas
mesa sin plato
foto borrosa
objeto que no sea comida
```

## Recomendaciones Para Tomar Fotos

Las fotos de entrenamiento deben parecerse a las fotos que se tomaran durante la demo.

Buenas practicas:

```text
usar celular real
variar iluminacion
variar angulos
variar fondos
tomar fotos cercanas y medianas
incluir platos completos y parcialmente visibles
incluir algunas fotos imperfectas
usar comida real similar a la del evento
```

Evitar:

```text
usar solo imagenes perfectas de internet
usar fondos identicos en todas las fotos
tomar todas las fotos desde el mismo angulo
mezclar clases ambiguas sin criterio
entrenar con muy pocas fotos de unknown_food
```

## Exportacion Desde Teachable Machine

En Teachable Machine:

1. Presionar `Export Model`.
2. Seleccionar `TensorFlow Lite`.
3. Elegir inicialmente `Floating point`.
4. Descargar el paquete generado.

Archivos esperados:

```text
model.tflite
labels.txt
```

El archivo `labels.txt` debe conservar el orden exacto de las clases del modelo. Ejemplo:

```text
0 empanada_queso
1 empanada_queso_integral
2 pizza
3 brownie_keto
4 brownie_normal
5 unknown_food
```

## Ubicacion En Flutter

Ruta sugerida:

```text
assets/models/tecnoupsa_food_classifier.tflite
assets/models/tecnoupsa_labels.txt
```

Entrada esperada en `pubspec.yaml`:

```yaml
flutter:
  assets:
    - .env
    - assets/models/tecnoupsa_food_classifier.tflite
    - assets/models/tecnoupsa_labels.txt
```

## Estrategia De Integracion En La App

La implementacion debe separar la interfaz del clasificador de sus implementaciones concretas.

Estructura recomendada:

```text
VisionClassifierService
MockVisionClassifierService
TfliteVisionClassifierService
```

Responsabilidad de `VisionClassifierService`:

```text
recibir una imagen
devolver predicciones ordenadas
devolver etiqueta principal
devolver confianza
resolver estado de vision
no conocer detalles de UI ni Supabase
```

Durante la primera implementacion, el mock debe estar disponible siempre. El servicio TFLite puede activarse cuando existan los assets del modelo.

Regla practica:

```text
si existe modelo TFLite y carga correctamente -> usar TFLite
si falta el modelo o falla la carga -> usar mock
```

Esto reduce el riesgo para la demo. Si el modelo falla en el celular, la app sigue permitiendo publicar mediante el mock o el modo manual asistido.

## Mock Compatible Con TFLite

El mock debe tener la misma interfaz que el servicio real.

Reglas iniciales:

```text
si el nombre del archivo contiene pizza -> pizza con 0.92
si el nombre del archivo contiene brownie -> brownie_normal con 0.90
si el nombre del archivo contiene empanada -> empanada_queso con 0.88
si no coincide -> unknown_food con 0.20
```

El mock no reemplaza al modelo real, pero permite construir y probar todo el flujo de negocio sin bloquearse por entrenamiento.

## Plan Solido De Implementacion De Etapa 1

La Etapa 1 debe entregar un flujo completo para el emprendedor:

```text
CookDashboardScreen
-> PublishDishScreen
-> tomar o elegir foto
-> ejecutar vision o mock
-> corregir plato
-> confirmar ingredientes
-> calcular alergenos
-> publicar
-> guardar en Supabase
-> volver al dashboard
```

Al completar esta etapa, no se debe avanzar a la Etapa 2 sin confirmacion explicita.

## Decisiones Confirmadas Para Etapa 1

Estas decisiones quedan fijadas para implementar:

```text
usar camara y galeria
crear migraciones e intentar aplicarlas con Supabase CLI
crear bucket local dish-photos con Supabase CLI si es posible
persistir mediante RPC
usar RLS estrictas
capturar ubicacion al publicar
ingredientes personalizados quedan marcados como requiere revision manual
exigir precio y cantidad disponible
agregar boton Publicar plato en CookDashboardScreen
crear semillas en migracion
crear feature lib/src/features/dish_publication con MVVM
```

## Alcance Funcional De Etapa 1

Incluido:

```text
migraciones Supabase para catalogos, publicaciones, fotos, ingredientes, alergenos y logs de vision
semillas minimas de categorias, ingredientes, alergenos y relaciones
bucket dish-photos para Storage
RLS para que cada emprendedor gestione solo sus publicaciones
RPC create_dish_publication(payload jsonb)
modelos Dart de publicacion, foto, ingrediente, alergeno e inferencia
repositorios de publicacion y alergenos
servicio de vision con mock y punto de extension para TFLite
servicio de ubicacion para capturar coordenadas al publicar
pantalla PublishDishScreen
integracion desde CookDashboardScreen
subida de imagen a Supabase Storage
guardado atomico de publicacion mediante RPC
vista previa de alergenos antes de publicar
estado unknown/manual que no bloquea publicacion
```

Excluido de Etapa 1:

```text
busqueda del consumidor
mapa del consumidor
polling de solicitudes
ofertas
pedidos
pantalla de detalle de oferta
pedido en curso
chat
pagos
Supabase Realtime
```

## Migraciones Supabase

Crear una migracion nueva para:

```text
vision_status enum
ingredient_source enum
```

Agregar triggers de `updated_at` donde corresponda usando la funcion existente `public.set_updated_at()`.

Insertar semillas minimas:

```text
categorias: empanada_queso, empanada_queso_integral, pizza, brownie_keto, brownie_normal, unknown_food
alergenos: gluten, lacteos, huevo, frutos secos, mani, soya
ingredientes: harina de trigo, harina integral, queso, leche, mantequilla, huevo, cacao, almendra, nuez, mani, tomate, levadura, aceite, edulcorante
relaciones ingrediente-alergeno segun docs/tecnoupsa/07-demo-data-and-testing.md
```

## RPC `create_dish_publication`

Crear una RPC `public.create_dish_publication(payload jsonb)` con `security definer`.

Responsabilidades:

```text
validar usuario autenticado
resolver cook_profile_id del usuario actual
validar titulo, precio y cantidad
crear dish_publications
crear dish_photos si viene storage_path
crear dish_ingredients
crear vision_inference_logs
calcular o guardar allergen_summary
devolver id de publicacion creada
```

El payload debe contener, como minimo:

```json
{
  "title": "Pizza familiar",
  "description": "Masa casera con queso",
  "price": 35,
  "available_quantity": 2,
  "category_code": "pizza",
  "vision_status": "recognized",
  "vision_confidence": 0.92,
  "detected_label": "pizza",
  "manual_food_name": null,
  "latitude": -17.7833,
  "longitude": -63.1821,
  "zone_label": "Equipetrol",
  "photo": {
    "storage_path": "dish-photos/user-id/temp-or-publication-id/file.jpg",
    "public_url": null
  },
  "ingredients": [
    {
      "code": "harina_trigo",
      "source": "cook_confirmed",
      "is_confirmed_by_cook": true
    }
  ],
  "custom_ingredients": [
    {
      "name": "salsa especial",
      "source": "custom_manual"
    }
  ],
  "vision_log": {
    "model_version": "mock-demo-v1",
    "top_predictions": []
  }
}
```

## RLS Estrictas

Politicas esperadas:

```text
usuarios autenticados pueden leer catalogos activos
emprendedor puede leer publicaciones propias
emprendedor puede crear publicaciones solo para su cook_profile_id
emprendedor puede actualizar publicaciones propias
emprendedor puede leer fotos de publicaciones propias
emprendedor puede crear fotos asociadas a publicaciones propias
emprendedor puede leer ingredientes de publicaciones propias
emprendedor puede crear ingredientes asociados a publicaciones propias
emprendedor puede leer logs de vision propios
```

Para operaciones compuestas, la escritura principal debe pasar por la RPC. Las politicas directas deben seguir impidiendo que un usuario modifique publicaciones de otro emprendedor.

## Storage `dish-photos`

Bucket sugerido:

```text
dish-photos
```

Ruta sugerida:

```text
<user_id>/<timestamp>.jpg
```

Aunque el documento original proponia incluir `publication_id` en el path, en Etapa 1 conviene subir la foto antes de crear la publicacion. Por eso la ruta inicial puede usar usuario y timestamp. La tabla `dish_photos` vincula luego la foto con la publicacion creada.

Politicas de Storage esperadas:

```text
usuario autenticado puede subir dentro de su carpeta user_id
usuario autenticado puede leer fotos necesarias para la demo
usuario no puede sobrescribir archivos de otro usuario
```

Si Supabase CLI permite crear el bucket localmente, se intentara hacerlo. Si el proyecto apunta a Supabase Cloud, puede ser necesario crearlo desde Dashboard o mediante SQL/CLI segun permisos disponibles.

## Flutter: Dependencias

Agregar dependencias necesarias:

```yaml
dependencies:
  image_picker: ^1.1.2
  tflite_flutter: ^0.11.0
  image: ^4.2.0
  geolocator: ^13.0.2
  permission_handler: ^11.3.1
```

Si `tflite_flutter` causa bloqueo de build, mantener el mock funcionando y dejar el servicio TFLite preparado para integracion posterior.

## Flutter: Feature Nueva

Crear estructura:

```text
lib/src/features/dish_publication/
  models/
  repositories/
  services/
  viewmodels/
  views/
```

Modelos minimos:

```text
DishPublication
DishPhoto
Ingredient
Allergen
DishIngredient
AllergenWarning
VisionPrediction
VisionInferenceResult
```

Repositorios:

```text
DishPublicationRepository
AllergenRepository
```

Servicios:

```text
VisionClassifierService
MockVisionClassifierService
LocationService
```

ViewModel:

```text
PublishDishViewModel
```

Vista:

```text
PublishDishScreen
```

## UI De `PublishDishScreen`

La pantalla debe incluir:

```text
boton tomar foto
boton elegir de galeria
preview de imagen
estado de inferencia
etiqueta detectada
confianza
campo editable nombre del plato
campo descripcion
campo precio obligatorio
campo cantidad obligatoria
estado de ubicacion
boton obtener ubicacion
lista de ingredientes sugeridos
accion confirmar ingrediente
accion eliminar ingrediente
campo para agregar ingrediente personalizado
advertencias CONTIENE
advertencias PUEDE CONTENER
mensaje de revision manual para ingredientes personalizados
boton publicar
estado de carga y errores
```

## Reglas De Ingredientes Y Alergenos

Reglas:

```text
ingrediente confirmado por emprendedor -> CONTIENE
ingrediente agregado manualmente conocido -> CONTIENE
ingrediente sugerido pero no confirmado -> PUEDE CONTENER
ingrediente eliminado -> no genera advertencia
ingrediente personalizado desconocido -> requiere revision manual
```

Los ingredientes personalizados no deben bloquear publicacion. Deben quedar guardados con:

```text
ingredient_id = null
custom_name = nombre ingresado
source = custom_manual
is_known_ingredient = false
requires_manual_allergen_review = true
```

## Flujo De Publicacion

Flujo esperado:

```text
1. emprendedor entra al dashboard
2. toca Publicar plato
3. toma foto o elige de galeria
4. app ejecuta mock o TFLite
5. app resuelve vision_status
6. app sugiere ingredientes por categoria
7. emprendedor corrige nombre del plato si hace falta
8. emprendedor confirma, elimina o agrega ingredientes
9. app calcula alergenos
10. emprendedor ingresa precio y cantidad
11. app obtiene ubicacion
12. app sube foto a Storage
13. app llama RPC create_dish_publication
14. app muestra exito
15. app vuelve al CookDashboardScreen
```

## Validaciones Minimas

Bloquear publicacion si falta:

```text
foto
nombre del plato
precio valido mayor a 0
cantidad valida mayor a 0
ubicacion o confirmacion explicita de fallback
al menos un ingrediente o ingrediente personalizado
usuario autenticado con perfil emprendedor
```

No bloquear si:

```text
vision_status es unknown
vision_status es manual_only
modelo TFLite falla
ingrediente personalizado requiere revision manual
```

## Verificacion De Etapa 1

Comandos y pruebas esperadas:

```text
flutter pub get
supabase db reset o aplicacion de migraciones segun entorno disponible
flutter analyze
flutter test si existen tests
prueba manual con foto reconocida por mock
prueba manual con foto desconocida
verificacion de filas en Supabase
verificacion de archivo subido a Storage
```

Casos manuales obligatorios:

```text
foto con nombre pizza -> recognized -> ingredientes sugeridos -> CONTIENE gluten/lacteos tras confirmar -> publica
foto desconocida -> unknown -> modo manual asistido -> ingrediente personalizado -> publica con revision manual
precio vacio -> bloquea
cantidad vacia -> bloquea
sin foto -> bloquea
```

## Pausa Obligatoria Al Final

Al terminar y verificar la Etapa 1, se debe detener la implementacion y preguntar:

```text
Ya esta implementado el nucleo de publicacion con vision computacional, fallback manual, alergenos y persistencia en Supabase. Lo siguiente es implementar el flujo consumidor-emprendedor en tiempo real. ¿Quieres proceder?
```

No se debe implementar busqueda, solicitudes, ofertas ni pedidos hasta recibir confirmacion.

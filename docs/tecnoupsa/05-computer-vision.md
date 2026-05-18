# Vision Computacional

## Decision Principal

Para la demo TecnoUPSA, usar un clasificador liviano de plato completo compatible con TFLite. No usar YOLOv8 en la primera iteracion.

## Por Que No YOLOv8 Primero

YOLOv8 es util para deteccion de objetos con cajas delimitadoras. En esta demo, el problema no es solo detectar objetos visibles. Los ingredientes de empanadas, hamburguesas, cunapes y pizzas pueden estar ocultos o mezclados.

Entrenar YOLOv8 requiere:

- Recolectar imagenes por clase.
- Anotar cajas si se detectan ingredientes u objetos.
- Entrenar y validar.
- Convertir a formato movil.
- Probar rendimiento en telefono.

Estimacion realista:

- Clasificador liviano: 0.5 a 2 dias.
- YOLOv8 entrenado: 3 a 7 dias minimo, con riesgo alto.

Por plazo de dos semanas, usar clasificador liviano.

## Clases Del Modelo

Clases iniciales:

- `empanada_queso_frita`
- `empanada_queso_integral`
- `pizza`
- `hamburguesa`
- `cunape`
- `unknown_food`

Si no se entrena `unknown_food`, resolver desconocido por umbral de confianza.

## Umbrales

- `recognized`: confianza `>= 0.75`.
- `low_confidence`: confianza `>= 0.45` y `< 0.75`.
- `unknown`: confianza `< 0.45`.
- `manual_only`: si el usuario salta la inferencia o el modelo falla.

## Flujo De Inferencia

1. El emprendedor toma o selecciona foto.
2. La app preprocesa imagen.
3. El modelo devuelve predicciones.
4. La app calcula `vision_status`.
5. La app muestra resultado al emprendedor.
6. El emprendedor confirma o corrige.
7. La app carga ingredientes sugeridos segun la etiqueta final.
8. El emprendedor confirma, elimina o agrega ingredientes.
9. La app mapea ingredientes a alergenos.
10. La publicacion guarda el resultado visual y la decision humana.

## Manejo De Alimentos No Contemplados

Este comportamiento es obligatorio.

Si el alimento no esta contemplado:

- No bloquear publicacion.
- Mostrar `Alimento no reconocido por el modelo`.
- Activar modo manual asistido.
- Exigir nombre manual del plato.
- Exigir al menos un ingrediente o nota de alergenos.
- Marcar `vision_status = unknown` o `manual_only`.
- Mostrar al consumidor que el analisis visual no fue concluyente.

Texto recomendado para UI:

> Este plato no fue reconocido automaticamente. La advertencia de alergenos dependera de los ingredientes declarados por el emprendedor.

## Ingredientes Sugeridos Por Clase

### `empanada_queso_frita`

- harina de trigo
- queso
- mantequilla o aceite
- huevo posible

Alergenos:

- gluten
- lacteos
- huevo posible

### `empanada_queso_integral`

- harina integral
- queso
- mantequilla o aceite
- huevo posible

Alergenos:

- gluten
- lacteos
- huevo posible

### `pizza`

- harina de trigo
- queso
- tomate
- levadura

Alergenos:

- gluten
- lacteos

### `hamburguesa`

- pan de hamburguesa
- carne
- queso posible
- huevo posible
- salsas

Alergenos:

- gluten
- lacteos posible
- huevo posible

### `cunape`

- almidon de yuca
- queso
- huevo posible
- leche o mantequilla posible

Alergenos:

- lacteos
- huevo posible

## Reglas De Advertencia

Usar dos niveles:

- `CONTIENE`: ingrediente confirmado por el emprendedor o agregado manualmente.
- `PUEDE CONTENER`: ingrediente sugerido por vision o regla preventiva no confirmada.

Ejemplo:

- El modelo detecta `pizza` y sugiere `harina de trigo`.
- Si el emprendedor confirma `harina de trigo`, mostrar `CONTIENE: gluten`.
- Si el emprendedor no confirma ni elimina una sugerencia, mostrar `PUEDE CONTENER: gluten`.

## Implementacion Inicial Con Mock

Para no bloquear la etapa 1, se permite implementar un mock:

- Si el nombre de archivo contiene `pizza`, devolver `pizza` con `0.92`.
- Si contiene `hamburguesa`, devolver `hamburguesa` con `0.90`.
- Si contiene `cunape`, devolver `cunape` con `0.90`.
- Si contiene `empanada`, devolver `empanada_queso_frita` con `0.88`.
- Si no coincide, devolver `unknown_food` con `0.20`.

El mock debe tener la misma interfaz que el servicio TFLite real.

## Entrenamiento Rapido Sin Costo

Opciones:

1. Teachable Machine:
   - Recolectar imagenes por clase.
   - Entrenar clasificador.
   - Exportar TFLite.
   - Integrar en Flutter.
2. TensorFlow local:
   - Usar transfer learning con MobileNet.
   - Exportar `.tflite`.
   - Mayor control, mas tiempo.

Recomendacion:

- Primero implementar mock.
- Luego reemplazar por TFLite exportado.

## Evidencia Para Defensa

Guardar en `vision_inference_logs`:

- version del modelo.
- top predictions.
- confianza.
- estado final.
- imagen asociada.

Esto permite explicar que la app usa IA, pero no promete certificacion sanitaria.

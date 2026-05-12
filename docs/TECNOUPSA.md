# Plan Maestro TecnoUPSA

Este documento describe el plan de implementacion del prototipo TecnoUPSA para CocinaME. La meta es construir una demo convincente en aproximadamente dos semanas, enfocada en oferta y demanda en tiempo real de comida casera con geolocalizacion y advertencias preventivas de alergenos apoyadas por vision computacional.

## Objetivo De La Demo

Mostrar un flujo de dos usuarios reales:

1. Un consumidor usa el emulador de Android Studio para buscar un plato, por ejemplo: `milanesa a Bs. 35 sin gluten`.
2. Un emprendedor usa un celular fisico para publicar un plato real, tomarle foto y recibir inferencias de vision computacional.
3. El sistema sugiere ingredientes, permite corregirlos y mapea ingredientes a alergenos.
4. El emprendedor publica el plato y se marca como disponible.
5. La solicitud del consumidor aparece en el celular del emprendedor.
6. El emprendedor responde con una oferta.
7. El consumidor recibe la oferta con foto, nombre del emprendedor, rating, precio, distancia y advertencias preventivas.
8. La demo termina en una pantalla de pedido en curso con mapa y datos principales.

## Enfoque Tecnico

- Usar Flutter bajo patron MVVM.
- Usar Supabase como backend unico durante esta iteracion.
- Usar Supabase Auth con cuentas reales distintas para consumidor y emprendedor.
- Usar Supabase Database para publicaciones, solicitudes, ofertas, pedidos, ingredientes y alergenos.
- Usar Supabase Storage para fotos de platos.
- Usar polling cada 2 a 5 segundos para reducir complejidad frente a realtime.
- Usar clasificador liviano TFLite o mock compatible con TFLite durante la primera implementacion.
- Usar base de conocimiento local o tabla Supabase para mapear ingredientes a alergenos.
- Priorizar `flutter_map` con OpenStreetMap para costo cero. Usar Google Maps solo si existe API key configurada y billing aceptado.

## Documentos Del Plan

- `docs/tecnoupsa/01-demo-flow.md`: guion exacto de la demostracion.
- `docs/tecnoupsa/02-implementation-stages.md`: etapas de implementacion y pausas obligatorias.
- `docs/tecnoupsa/03-supabase-schema.md`: migraciones Supabase necesarias.
- `docs/tecnoupsa/04-flutter-mvvm-screens.md`: pantallas, modelos, repositorios y ViewModels.
- `docs/tecnoupsa/05-computer-vision.md`: estrategia de vision computacional y alimentos desconocidos.
- `docs/tecnoupsa/06-libraries-cli-network.md`: librerias, CLI, mapas y red.
- `docs/tecnoupsa/07-demo-data-and-testing.md`: datos semilla, pruebas y criterios de aceptacion.

## Regla Para LLM Implementador

El LLM que implemente este plan debe trabajar por etapas. La primera etapa es la mas compleja: publicacion de plato con foto, clasificacion visual, fallback manual, ingredientes, alergenos y persistencia.

Al terminar la primera etapa, el LLM debe detenerse y preguntar:

> Ya esta implementado el nucleo de publicacion con vision computacional, fallback manual, alergenos y persistencia en Supabase. Lo siguiente es implementar el flujo consumidor-emprendedor en tiempo real. ¿Quieres proceder?

No debe continuar a la etapa 2 sin confirmacion del usuario.

## Alcance Del MVP TecnoUPSA

Incluido:

- Registro, login y onboarding existente.
- Extension del cuestionario del consumidor con datos utiles para la demo.
- Publicacion de plato por emprendedor.
- Foto real del plato.
- Vision computacional local o mock temporal reemplazable.
- Mapeo ingrediente-alergeno.
- Solicitud de consumidor con sondeo tipo inDrive.
- Emprendedor disponible/libre.
- Oferta del emprendedor al consumidor.
- Detalle de oferta con alergenos y foto.
- Pedido en curso basico con mapa.

Excluido:

- Pagos dentro de la app.
- Recuperacion avanzada de contrasena.
- Chat real completo.
- Analitica avanzada.
- Panel administrativo completo.
- Delivery tercerizado real.
- Certificacion sanitaria de alergenos.

## Decision Sobre Vision Computacional

No entrenar YOLOv8 para la primera demo. Para este caso, YOLOv8 agrega complejidad sin resolver el problema principal, porque muchos ingredientes no son visualmente detectables dentro de empanadas, brownies o pizzas.

Usar un clasificador liviano de plato completo con clases cerradas:

- `empanada_queso`
- `empanada_queso_integral`
- `pizza`
- `brownie_keto`
- `brownie_normal`
- `unknown_food`

Si el alimento no esta contemplado o la confianza es baja, la app debe activar modo manual asistido. Este comportamiento es obligatorio para que la demo sea robusta cuando alguien presente un plato fuera del modelo.

## Orden De Implementacion

1. Etapa 1: nucleo de publicacion, vision computacional, fallback manual y alergenos.
2. Etapa 2: busqueda del consumidor y sondeo con mapa.
3. Etapa 3: disponibilidad del emprendedor y recepcion de solicitudes.
4. Etapa 4: ofertas, detalle de oferta y pedido en curso.
5. Etapa 5: datos semilla, pulido visual y ensayo de demo.
6. Etapa 6: mejoras opcionales si queda tiempo.

Ver `docs/tecnoupsa/02-implementation-stages.md` para instrucciones detalladas.

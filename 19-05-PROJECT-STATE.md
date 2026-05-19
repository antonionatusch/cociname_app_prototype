# Estado Del Proyecto - 19/05

Este documento resume el avance realizado desde la creacion de `docs/TECNOUPSA.md`.

## Base Del Plan TecnoUPSA

- Se definio el objetivo de demo: conectar consumidor y emprendedor para comida casera con publicacion de platos, geolocalizacion, advertencias preventivas de alergenos y flujo tipo inDrive.
- Se separo el plan en documentos bajo `docs/tecnoupsa/`, incluyendo flujo de demo, etapas, esquema Supabase, pantallas MVVM, vision computacional, librerias/red y datos de prueba.
- Se establecio que la Etapa 1 debia priorizar publicacion de plato con foto, vision computacional, ingredientes, alergenos y persistencia.

## Supabase

- Se agrego esquema para publicaciones de platos: categorias, publicaciones, fotos, ingredientes, alergenos, relacion ingrediente-alergeno, ingredientes por plato y logs de inferencia visual.
- Se agregaron datos base para categorias de platos, ingredientes y alergenos.
- Se creo el bucket `dish-photos` en Supabase Storage con politicas para que cada usuario suba fotos a su carpeta.
- Se implemento la RPC `create_dish_publication` para crear una publicacion completa con fotos, ingredientes y log de vision.
- Se corrigio el bug de `record` vs `jsonb` en la RPC de publicacion.
- Se amplio la publicacion para soportar entre 1 y 3 fotos ordenadas por `position`; la primera foto funciona como portada.
- Se agrego `cook_profiles.is_available` para estado Libre/Ocupado del emprendedor.
- Se agregaron RPCs de gestion: actualizar disponibilidad, modificar datos basicos de publicacion y borrar publicaciones pausadas.
- La RPC de borrado devuelve las rutas de fotos para que la app elimine tambien los archivos del bucket `dish-photos`.
- Se ajusto `create_dish_publication` para aceptar confianza de vision nula y omitir logs cuando `vision_log` llega como JSON `null`.

## Flutter Y Arquitectura

- Se mantuvo el patron MVVM con repositorios para Supabase y ViewModels por flujo.
- Se integro `flutter_dotenv` para `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
- Se integro `supabase_flutter`, `provider`, `image_picker`, `tflite_flutter`, `image`, `geolocator`, `geocoding` y `permission_handler`.
- Se agrego `TfliteVisionClassifierService` usando assets locales `assets/models/tecnoupsa_food_classifier.tflite` y `assets/models/tecnoupsa_labels.txt`.
- Se agrego gestion de permisos de ubicacion y captura de direccion aproximada para publicaciones.
- Se agregaron modelos de lectura para publicaciones y fotos (`DishPublication`, `DishPublicationPhoto`) con ordenamiento por `position`.

## Publicacion De Platos

- El emprendedor puede tomar foto o seleccionar desde galeria.
- La galeria permite seleccion multiple y se limita a 3 fotos por plato.
- La camara permite agregar fotos de una en una hasta 3.
- La primera foto clasifica el plato y queda como portada.
- Si se elimina la foto portada, la siguiente foto pasa a ser portada y se vuelve a ejecutar la clasificacion.
- La app muestra plato detectado, confianza y estado de vision.
- Se sugieren ingredientes por categoria detectada.
- El emprendedor puede confirmar, eliminar o agregar ingredientes manuales.
- El ingreso manual de ingredientes intenta mapear nombres conocidos a codigos existentes y, si no reconoce el texto, lo guarda como ingrediente personalizado.
- Se valida minimo 1 foto, nombre, precio, cantidad e ingredientes.
- La publicacion guarda fotos en Storage y metadatos en Supabase.

## Dashboard Del Emprendedor

- Se reemplazo el dashboard inicial por un panel con estado Libre/Ocupado.
- El dashboard lista las publicaciones propias del cocinero.
- Cada tarjeta muestra la foto portada, nombre, precio, cantidad y estado Activo/Pausado.
- Se agrego toggle para activar o pausar platos usando `dish_publications.is_active`.
- Se agrego detalle de publicacion con hasta 3 fotos.
- Se agrego modificacion de nombre, descripcion, precio y cantidad.
- Se agrego borrado de publicaciones, bloqueado si la publicacion sigue activa; primero debe pausarse.
- Al borrar una publicacion pausada se elimina el registro en base de datos y luego sus fotos asociadas en Storage.
- Se agrego recarga del dashboard despues de publicar y soporte de pull-to-refresh.

## Autenticacion Y Perfiles

- Se mantiene Supabase Auth con login/registro por correo o telefono segun el flujo existente.
- Se mantiene onboarding por rol: consumidor, cocinero y administrador.
- El dashboard de cocinero se muestra cuando el perfil activo es de tipo `cook`.

## Problemas Detectados Y Soluciones

- Error de conexion hacia `100.x.x.x`: se identifico como problema de conectividad/Tailscale o Supabase local detenido.
- Error al publicar plato: se encontro que la RPC usaba `record` para datos JSON; se corrigio usando `jsonb`.
- Error al cambiar Libre/Ocupado: se corrigio moviendo la actualizacion a una RPC que resuelve el perfil del usuario autenticado en base de datos.
- Error con publicacion manual o sin confianza de vision: se corrigio casteando `vision_confidence` con `nullif`.
- Error con `vision_log` enviado como JSON `null`: se corrigio validando `jsonb_typeof(v_vision_log) <> 'null'` antes de insertar el log.

## Estado Actual

- Etapa 1 esta funcional: publicacion con fotos, inferencia visual, ingredientes y persistencia.
- Parte de Etapa 3 esta adelantada: Libre/Ocupado, platos Activo/Pausado, edicion basica y borrado seguro de publicaciones pausadas.
- Aun falta implementar el flujo consumidor-emprendedor completo: busqueda, solicitudes, ofertas y pedido en curso.

## Validacion Ejecutada

- Se aplicaron migraciones locales con Supabase CLI durante el desarrollo.
- Se verificaron RPCs clave desde la base local.
- `flutter test` paso.
- `flutter analyze` no reporto errores nuevos; mantiene advertencias existentes de API deprecada en `onboarding_flow_screen.dart`.

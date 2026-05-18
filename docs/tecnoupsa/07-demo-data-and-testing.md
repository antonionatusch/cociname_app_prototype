# Datos Semilla Y Pruebas

## Datos Semilla Minimos

### Alergenos

- gluten
- lacteos
- huevo
- frutos secos
- mani
- soya

### Ingredientes

- harina de trigo -> gluten
- harina integral -> gluten
- pan de hamburguesa -> gluten
- carne -> sin alergeno principal por defecto
- almidon de yuca -> sin alergeno principal por defecto
- queso -> lacteos
- leche -> lacteos
- mantequilla -> lacteos
- huevo -> huevo
- cacao -> sin alergeno principal por defecto
- almendra -> frutos secos
- nuez -> frutos secos
- mani -> mani
- tomate -> sin alergeno principal por defecto
- levadura -> sin alergeno principal por defecto
- aceite -> sin alergeno principal por defecto
- edulcorante -> sin alergeno principal por defecto

### Categorias De Plato

- empanada_queso_frita
- empanada_queso_integral
- pizza
- hamburguesa
- cunape
- unknown_food

## Cuentas De Demo

Crear dos cuentas reales:

- Consumidor: `consumidor.demo@...`
- Emprendedor: `emprendedor.demo@...`

Configurar onboarding:

Consumidor:

- Zona: Equipetrol o zona cercana a la demo.
- Alergenos: gluten.
- Presupuesto habitual: Bs. 35.
- Radio maximo: 4 km.
- Tolerancia: ocultar o advertir `PUEDE CONTENER`.

Emprendedor:

- Nombre visible: `Cocina de prueba` o marca real.
- Zona: misma zona aproximada.
- Rating inicial: 5.0.
- Suscripcion: Base.
- Estado inicial: offline.

## Imagenes De Prueba

Preparar imagenes locales en el celular:

- Empanada de queso.
- Empanada de queso integral.
- Pizza.
- Hamburguesa.
- Cunape.
- Un alimento desconocido, por ejemplo sopa o sandwich.

## Pruebas De Etapa 1

### Publicacion Reconocida

1. Iniciar sesion como emprendedor.
2. Ir a `Publicar plato`.
3. Subir foto de pizza.
4. Ver prediccion `pizza` con confianza alta.
5. Confirmar ingredientes.
6. Ver `CONTIENE: gluten` y `CONTIENE: lacteos`.
7. Publicar.
8. Ver registro en Supabase.

Criterio de exito:

- Publicacion y foto existen.
- Ingredientes existen.
- Alergenos se muestran correctamente.

### Publicacion Desconocida

1. Subir foto de alimento fuera del modelo.
2. Ver `Alimento no reconocido`.
3. Escribir nombre manual.
4. Agregar ingredientes manuales.
5. Publicar.
6. Ver estado `unknown` o `manual_only`.

Criterio de exito:

- La app no bloquea.
- El consumidor podra ver que el analisis visual no fue concluyente.

## Pruebas De Etapa 2

1. Iniciar sesion como consumidor.
2. Crear busqueda con plato y presupuesto.
3. Ver mapa.
4. Ver estado de sondeo.
5. Confirmar que `consumer_requests` tiene una fila activa.

## Pruebas De Etapa 3

1. Iniciar sesion como emprendedor.
2. Cambiar estado a `Libre`.
3. Esperar polling.
4. Ver solicitud del consumidor.

## Pruebas De Etapa 4

1. Emprendedor crea oferta.
2. Consumidor recibe oferta.
3. Consumidor abre detalle.
4. Consumidor acepta.
5. Confirmar creacion de `orders`.
6. Ambos ven pedido activo.

## Ensayo De Demo

Hacer al menos tres ensayos completos:

1. Ensayo con plato reconocido.
2. Ensayo con plato desconocido.
3. Ensayo con red distinta o datos moviles.

Registrar problemas:

- Permisos de camara.
- Permisos de ubicacion.
- Latencia de Supabase.
- Imagen que no sube.
- Polling que no actualiza.

## Fallbacks Para El Dia Del Evento

Si falla camara:

- Usar galeria.

Si falla modelo:

- Usar mock local.

Si falla ubicacion:

- Usar coordenadas fijas configuradas para la demo.

Si falla polling:

- Tener solicitud y publicacion semilla listas.

Si falla internet:

- Mostrar flujo local hasta antes del match y explicar que Supabase coordina la sincronizacion.

## Checklist Final

- App instalada en celular fisico.
- Emulador configurado.
- Dos cuentas verificadas.
- Supabase con migraciones aplicadas.
- Bucket creado.
- Imagenes listas.
- Modelo o mock funcionando.
- Permisos concedidos.
- Red probada.
- Guion ensayado.

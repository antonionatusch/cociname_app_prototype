# Flujo De Demo TecnoUPSA

## Preparacion

Dispositivos:

- Emulador Android Studio: consumidor.
- Celular fisico: emprendedor.

Cuentas:

- Cuenta consumidor real en Supabase Auth.
- Cuenta emprendedor real en Supabase Auth.

Datos recomendados:

- Consumidor: alergico a gluten, presupuesto Bs. 35, radio inicial 1 km, radio maximo 4 km.
- Emprendedor: negocio visible, rating inicial 5.0, estado `available`.

## Escenario Principal

1. El consumidor abre la app en el emulador.
2. El consumidor inicia sesion.
3. La app muestra la pantalla de busqueda con mapa.
4. El consumidor escribe o selecciona:
   - Plato: `empanada`, `pizza`, `brownie` o busqueda libre.
   - Presupuesto: `35`.
   - Restriccion: `sin gluten`.
   - Radio maximo: `4 km`.
5. El consumidor toca `Buscar plato`.
6. La app crea una solicitud y muestra estado de sondeo:
   - `Buscando emprendedores cerca...`
   - Radio incrementando cada 10 segundos.
   - Marcadores o circulo de busqueda en el mapa.
7. En el celular fisico, el emprendedor inicia sesion.
8. El emprendedor entra a `Panel emprendedor`.
9. El emprendedor toca `Publicar plato`.
10. El emprendedor toma foto de un plato real.
11. La app ejecuta inferencia visual.
12. La app muestra una de estas salidas:
   - Plato reconocido con confianza alta.
   - Plato posiblemente reconocido con confianza media.
   - Plato no reconocido por el modelo.
13. El emprendedor confirma o corrige el plato.
14. La app sugiere ingredientes.
15. El emprendedor confirma, elimina o agrega ingredientes.
16. La app genera advertencias preventivas:
   - `CONTIENE: gluten`, si el ingrediente confirmado implica gluten.
   - `PUEDE CONTENER: huevo`, si proviene de una regla preventiva no confirmada.
17. El emprendedor publica el plato.
18. El emprendedor se marca como `Libre` o `Disponible`.
19. La app del emprendedor detecta la solicitud activa del consumidor.
20. El emprendedor responde con una oferta:
   - Precio.
   - Tiempo estimado.
   - Plato asociado.
21. El consumidor recibe la oferta.
22. La oferta muestra:
   - Foto del plato.
   - Nombre del emprendedor.
   - Rating.
   - Precio.
   - Distancia aproximada.
   - Advertencias de alergenos.
23. El consumidor abre el detalle.
24. El consumidor acepta la oferta.
25. Ambos ven una pantalla de pedido en curso con mapa, resumen y estado.

## Escenario Robusto: Plato Fuera Del Modelo

Este escenario debe estar soportado aunque no sea el flujo principal.

1. El emprendedor toma foto de un alimento no contemplado, por ejemplo una sopa, sandwich o plato traido por un visitante.
2. El modelo devuelve baja confianza o `unknown_food`.
3. La app muestra: `Alimento no reconocido por el modelo`.
4. La app no bloquea la publicacion.
5. La app activa modo manual asistido:
   - Nombre manual del plato.
   - Seleccion de ingredientes desde lista conocida.
   - Agregado de ingredientes personalizados.
   - Declaracion manual de alergenos si el ingrediente no esta en la base de conocimiento.
6. La publicacion queda marcada como `vision_status = unknown` o `manual_only`.
7. El consumidor ve: `Analisis visual no concluyente. Alergenos basados en declaracion del emprendedor`.

## Guion Verbal Sugerido

Frase clave al mostrar VC:

> La vision computacional no certifica alergenos. Sirve como apoyo para sugerir ingredientes probables; el emprendedor confirma y el sistema traduce esos ingredientes a advertencias preventivas.

Frase clave al mostrar alimento desconocido:

> Si el modelo no reconoce el plato, la app no inventa resultados. Pasa a un modo manual asistido y deja trazado que la inferencia visual no fue concluyente.

## Criterio De Exito De Demo

La demo es exitosa si se logra mostrar, sin intervencion de base de datos en vivo:

- Consumidor buscando en mapa.
- Emprendedor publicando plato con foto.
- Inferencia visual o fallback manual.
- Advertencia de alergenos generada.
- Oferta recibida por consumidor.
- Detalle de oferta con foto y rating.
- Pedido en curso.

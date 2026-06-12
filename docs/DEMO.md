# Demo Del Prototipo

Este flujo permite revisar los casos de uso principales implementados en CocinaME.

## Flujo sugerido

1. Registrar o iniciar sesion con un usuario consumidor.
2. Completar onboarding del consumidor.
3. Registrar o iniciar sesion con un usuario cocinero en otro dispositivo, emulador o sesion.
4. Completar onboarding del cocinero.
5. Publicar un plato con foto, precio, cantidad y ubicacion.
6. Revisar la inferencia visual TFLite y confirmar o corregir ingredientes.
7. Confirmar advertencias preventivas de alergenos.
8. Desde consumidor, crear una busqueda geolocalizada.
9. Desde cocinero, revisar la solicitud entrante y enviar una oferta.
10. Desde consumidor, abrir el detalle de la oferta y aceptarla.
11. Revisar la pantalla de pedido activo en ambos roles.

## Resultado esperado

- El cocinero puede publicar platos disponibles.
- El consumidor puede solicitar comida desde una ubicacion.
- El cocinero puede responder con una oferta.
- El consumidor puede aceptar la oferta.
- Ambos roles pueden visualizar el pedido activo.
- Las advertencias de alergenos se muestran como informacion preventiva.

## Datos de prueba

El repositorio incluye `supabase/seed.sql` con datos ficticios. Puedes usarlo como punto de partida para preparar una instancia local o remota de Supabase.

## Alcance

Esta demo valida los casos de uso principales del negocio. No representa una aplicacion productiva ni cubre todos los flujos necesarios para operar comercialmente.

# SPRING_BOOT_AUTH.md

## Objetivo

Documentar la estrategia de implementacion inicial con `Supabase Auth` para los casos de uso 1-4 de CocinaME y definir una ruta de migracion controlada hacia `Spring Boot` para futuras necesidades de backend, seguridad y reglas de negocio.

## Estado actual

### Frontend
- El proyecto Flutter estaba en estado inicial.
- `lib/main.dart` correspondia al ejemplo base de contador.
- No existia estructura de routing, feature modules, ni integracion con Supabase.

### Backend
- No existe aun un backend Spring Boot dentro de este repositorio.
- La decision actual es comenzar con `Supabase Auth` como proveedor de autenticacion para acelerar el desarrollo del MVP.

### Supabase local
- La instancia local esta operativa.
- La base PostgreSQL esta disponible en `127.0.0.1:42692`.
- El proyecto URL expuesto por Supabase es `http://127.0.0.1:42691`.

### Restriccion detectada en configuracion inicial
La configuracion original de `supabase/config.toml` tenia:

- `[auth.email].enable_confirmations = false`
- `[auth.sms].enable_signup = false`

Esto no era consistente con los casos de uso 1-4 descritos en el documento funcional, porque dichos casos contemplan:
- registro con verificacion de identidad
- validacion por OTP o enlace de activacion
- reinicio de contrasena
- soporte por correo o telefono en el registro

## Decision de implementacion inmediata

Se implementa primero la autenticacion usando `Supabase Auth` directamente desde Flutter para cubrir los siguientes casos de uso del MVP:

1. Solicitar creacion de cuenta
2. Verificar identidad
3. Iniciar sesion
4. Solicitar reinicio de contrasena

Esta decision se toma porque:
- reduce tiempo de arranque del MVP
- evita bloquear el avance visual y funcional por la ausencia actual de backend Spring Boot
- aprovecha la infraestructura local ya disponible
- permite postergar la complejidad de validacion JWT y orquestacion de reglas de negocio del lado servidor

## Cambio requerido en `supabase/config.toml`

Antes de implementar los casos de uso 1-4 se requiere alinear la configuracion de Supabase local con los flujos funcionales.

### Cambios aplicados

#### 1. Confirmacion por correo habilitada
Se cambia:

- `[auth.email].enable_confirmations = false`

por:

- `[auth.email].enable_confirmations = true`

Esto alinea el registro por correo con:
- CU-1 Solicitar Creacion de Cuenta
- CU-2 Verificar Identidad

#### 2. Signup por SMS habilitado
Se cambia:

- `[auth.sms].enable_signup = false`

por:

- `[auth.sms].enable_signup = true`

Esto habilita el registro por numero telefonico y OTP, alineandose con:
- CU-1 Solicitar Creacion de Cuenta
- CU-2 Verificar Identidad

#### 3. Confirmacion por SMS habilitada
Se cambia:

- `[auth.sms].enable_confirmations = false`

por:

- `[auth.sms].enable_confirmations = true`

Esto permite que el alta por telefono quede conectada con el flujo de verificacion OTP.

#### 4. OTP de prueba local configurado
Se habilita un numero de prueba local para desarrollo:

- `59170000001 = "123456"`

Esto permite probar CU-2 localmente sin depender de un proveedor SMS real.

#### 5. URLs malformadas corregidas
Se corrigen `site_url` y `additional_redirect_urls` para evitar problemas con enlaces de autenticacion y reseteo.

## Alcance funcional inicial con Supabase Auth

### Caso de uso 1: Solicitar Creacion de Cuenta
Se implementa una pantalla de registro con:
- selector de metodo de registro: correo o telefono
- nombres
- apellidos
- contrasena
- confirmar contrasena
- validaciones de campos
- manejo de errores de cuenta existente
- navegacion al flujo de verificacion

### Caso de uso 2: Verificar Identidad
Se implementa una pantalla adaptable segun medio:
- verificacion por OTP para telefono
- instrucciones de confirmacion por correo para email
- reenvio de codigo o referencia visual para pruebas locales
- estados de expiracion y error

### Caso de uso 3: Iniciar Sesion
Se implementa una pantalla con:
- login por correo o telefono
- contrasena
- recuperacion de errores
- acceso a registro
- acceso a reinicio de contrasena

### Caso de uso 4: Solicitar Reinicio de Contrasena
Se implementa inicialmente sobre correo electronico, porque es el flujo estandar y mas robusto en Supabase Auth para esta etapa del MVP.

Incluye:
- entrada de correo
- envio de instrucciones de restablecimiento
- confirmacion visual del envio
- manejo de errores y reintentos

### Nota sobre recuperacion por telefono
El documento funcional contempla correo o telefono, pero en esta implementacion inicial se prioriza `reset password via email` para mantener compatibilidad clara con Supabase Auth y evitar una UX engañosa en telefono mientras no exista backend propio o flujo alternativo definido.

## Plan tecnico de implementacion inmediata en Flutter

### Fase 1. Base tecnica
- agregar dependencias de Supabase para Flutter
- definir inicializacion segura del cliente
- incorporar manejo de variables de entorno
- establecer estructura base por features

### Fase 2. Diseño visual y theming
- aplicar los tokens definidos en `docs/COLOR_THEME.md`
- construir tema calido coherente con CocinaME
- establecer componentes base reutilizables para auth

### Fase 3. Routing y navegacion
- definir flujo de navegacion para:
  - login
  - registro
  - verificacion
  - reinicio de contrasena
- preparar navegacion futura hacia onboarding y perfil gastronomico

### Fase 4. Implementacion de UI
- construir las cuatro pantallas principales
- agregar estados de loading, error y success
- reflejar UX consistente con el documento funcional

### Fase 5. Integracion con Supabase Auth
- signup con correo
- signup con telefono
- verificacion por OTP telefonico
- confirmacion por email
- sign in
- reset password via email
- persistencia de sesion inicial

### Fase 6. Verificacion local
- probar flujo por correo con Mailpit local
- probar OTP con el numero de prueba local
- validar errores esperados
- validar navegacion y mensajes de recuperacion

## Riesgos y consideraciones

### 1. Diferencia entre diseño funcional y capacidades reales de Supabase
El documento funcional habla en terminos de OTP o hipervinculo de activacion. Supabase soporta estos patrones, pero la UX exacta debe adaptarse al proveedor para no forzar comportamientos artificiales.

### 2. SMS local de desarrollo
Aunque el signup por SMS queda habilitado, el uso de OTP real en local se apoya en el numero de prueba configurado.

### 3. Verificacion por correo es viable localmente
Como el entorno local expone una bandeja de correo de desarrollo, el flujo por email puede implementarse y verificarse desde el inicio.

### 4. No acoplar la UI al proveedor
Aunque la implementacion inicial usa Supabase Auth, la arquitectura del frontend debe encapsular auth en servicios propios para facilitar migracion futura.

## Plan de migracion futura hacia Spring Boot

La migracion a Spring Boot no se plantea como reemplazo inmediato, sino como evolucion progresiva.

### Objetivo de la migracion
Introducir un backend propio cuando el proyecto necesite:
- reglas de negocio complejas
- autorizacion mas rica
- agregacion de datos desde multiples fuentes
- auditoria centralizada
- servicios no cubiertos elegantemente por Supabase directo
- control mas fino sobre integraciones externas

### Enfoque recomendado
Adoptar una migracion gradual, no un reemplazo brusco.

## Estrategia de migracion por fases

### Fase A. Frontend desacoplado
Mientras se usa Supabase Auth directamente:
- encapsular auth en una capa propia de servicios o repositories
- evitar que las pantallas dependan directamente del SDK en cada widget
- centralizar modelos de sesion y errores

### Fase B. Spike tecnico Spring Boot
Crear luego un backend minimo con:
- conexion a PostgreSQL de Supabase local
- endpoint health
- endpoint protegido
- lectura de tabla simple
- validacion de JWT emitido por Supabase

### Fase C. Backend como consumidor de Supabase Auth
Spring Boot no reemplaza aun a Supabase Auth; simplemente:
- acepta JWT emitidos por Supabase
- valida firma y claims
- traduce roles o claims a autorizacion interna
- protege endpoints propios

### Fase D. Reglas de negocio en backend
Mover a Spring Boot:
- logica de perfiles
- publicaciones
- solicitudes
- coordinacion de pedidos
- auditoria y trazabilidad
- politicas de acceso mas avanzadas

### Fase E. Evaluacion de ownership de autenticacion
Solo en una etapa posterior evaluar si conviene:
- mantener Supabase Auth como proveedor principal
- o migrar a autenticacion orquestada por Spring Security

La recomendacion inicial es **mantener Supabase Auth como IdP** incluso cuando Spring Boot entre en operacion.

## Arquitectura objetivo recomendada

### Etapa inicial
Flutter -> Supabase Auth  
Flutter -> Supabase DB o APIs segun necesidad inicial

### Etapa intermedia
Flutter -> Supabase Auth  
Flutter -> Spring Boot API  
Spring Boot -> PostgreSQL Supabase  
Spring Boot -> valida JWT de Supabase

### Etapa madura
Flutter -> Supabase Auth  
Flutter -> Spring Boot API como backend principal  
Spring Boot -> PostgreSQL, Storage y otros servicios

Supabase queda como:
- Auth provider
- base de datos
- storage
- realtime, si aplica

## Validacion JWT en Spring Boot

Cuando llegue el momento de integrar Spring Boot:

### Se debera verificar
- issuer del token
- audiencia si aplica
- expiracion
- subject
- claims relevantes del usuario

### Spring Boot debera mapear
- usuario autenticado
- rol funcional interno
- permisos por operacion
- metadatos necesarios para trazabilidad

## Consideraciones de conectividad con base de datos

### En local
La conexion seria contra Postgres directo:
- host: `127.0.0.1`
- puerto: `42692`

### Sobre pooler
Actualmente el pooler local esta desactivado:
- `[db.pooler].enabled = false`

Por lo tanto, para el spike inicial de Spring Boot se usaria la conexion directa local. Mas adelante, en ambientes donde exista pooler disponible, podra reevaluarse el uso de conexion pooled.

## Criterios para empezar la migracion a Spring Boot

Conviene iniciar la integracion real con Spring Boot cuando ocurra al menos una de estas condiciones:
- necesidad de endpoints propios para logica de negocio
- necesidad de control de autorizacion mas fino que RLS mas cliente
- necesidad de auditoria centralizada
- necesidad de integrar terceros desde backend
- necesidad de ocultar operaciones sensibles del cliente

## Decision actual

Se aprueba avanzar primero con `Supabase Auth` para construir las pantallas y flujos funcionales de los casos de uso 1-4.

La integracion con `Spring Boot` queda planificada como evolucion posterior, con enfoque incremental y sin desechar Supabase como proveedor de autenticacion desde el inicio.

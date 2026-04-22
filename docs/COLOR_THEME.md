# COLOR_THEME.md

## Tema visual recomendado para CocinaME

Esta especificación define una paleta cálida, energética y cercana para CocinaME. No se basa únicamente en el color del logo, sino también en el significado que quieres proyectar con la marca: **energía, entusiasmo, creatividad, calidez, sociabilidad, diversión y transformación**. Por eso, el sistema visual gira en torno a un naranja protagonista, acompañado por tonos crema, durazno y neutros cálidos que ayuden a transmitir comida casera, cercanía humana y dinamismo urbano.

---

## 1. Principios de la paleta

La paleta debe comunicar lo siguiente:

- **Energía y acción:** para reforzar la idea de pedidos en tiempo real y movimiento.
- **Calidez y cercanía:** para que la app se sienta humana, hogareña y confiable.
- **Sociabilidad y juventud:** para reflejar una experiencia moderna, amigable y accesible.
- **Creatividad y transformación:** para acompañar la propuesta innovadora de CocinaME como marketplace de comida casera.

En la práctica, esto significa evitar una interfaz fría o demasiado corporativa. La app debe sentirse **viva, apetecible, amable y moderna**.

---

## 2. Paleta principal

### Brand Primary
- **Hex:** `#ED6E1F`
- **Uso:** color principal de marca.
- **Aplicaciones:** botones principales, app bar, FAB, iconos activos, chips seleccionados, tabs activas, switches activos, indicadores de carga, CTAs.

### Brand Primary Dark
- **Hex:** `#C95714`
- **Uso:** pressed state, headers con más contraste, gradientes o énfasis fuerte.

### Brand Primary Light
- **Hex:** `#F59B52`
- **Uso:** hover, highlights, estados suaves, elementos promocionales, ilustraciones secundarias.

### Brand Soft
- **Hex:** `#FFD7B5`
- **Uso:** fondos cálidos, contenedores destacados, badges suaves, tarjetas promocionales.

### Brand Accent Warm
- **Hex:** `#FFB067`
- **Uso:** acentos complementarios cuando se necesite mayor sensación de entusiasmo y vitalidad.

---

## 3. Neutros cálidos

### Background
- **Hex:** `#FFF9F2`
- **Uso:** fondo general de pantallas.

### Surface
- **Hex:** `#FFFDF9`
- **Uso:** cards, sheets, modals, contenedores principales, campos de formulario.

### Surface Variant
- **Hex:** `#F7E8DA`
- **Uso:** filtros, bloques secundarios, secciones agrupadas, estados inactivos suaves.

### Outline
- **Hex:** `#D9B89B`
- **Uso:** bordes de inputs, divisores y contornos suaves.

### Outline Variant
- **Hex:** `#E8D4C2`
- **Uso:** divisores muy sutiles y separación de tarjetas sobre fondos claros.

### Text Primary
- **Hex:** `#2F241C`
- **Uso:** títulos, encabezados y contenido principal.

### Text Secondary
- **Hex:** `#6B5848`
- **Uso:** subtítulos, descripciones, metadata, etiquetas auxiliares.

### Text Disabled
- **Hex:** `#A58A75`
- **Uso:** estados deshabilitados o contenido de baja prioridad.

### On Primary
- **Hex:** `#FFF8E2`
- **Uso:** texto e iconografía sobre fondos naranjas.

---

## 4. Colores semánticos

Estos colores no deben competir con el naranja de marca, pero sí convivir bien con él.

### Success
- **Hex:** `#2E7D32`
- **On Success:** `#FFFFFF`
- **Uso:** pedidos confirmados, disponibilidad, publicaciones activas, validaciones exitosas.

### Warning
- **Hex:** `#D9822B`
- **On Warning:** `#FFFFFF`
- **Uso:** alertas moderadas, stock bajo, recordatorios, atención sobre tiempos de entrega.

### Error
- **Hex:** `#C62828`
- **On Error:** `#FFFFFF`
- **Uso:** errores de validación, fallas de red, pedidos cancelados.

### Info
- **Hex:** `#3A7CA5`
- **On Info:** `#FFFFFF`
- **Uso:** banners informativos, ayuda contextual, seguimiento del pedido.

---

## 5. Reglas de uso visual

### Proporción sugerida
- **60%** neutros cálidos y fondos claros.
- **30%** superficies y contenedores suaves.
- **10%** naranja de marca y acentos.

Esto evita que la interfaz se vea saturada o agresiva.

### Qué transmitir visualmente
- Usa el naranja para guiar acciones importantes, no para pintar toda la pantalla.
- Prioriza fondos claros y respirables para que la comida, las fotos y los platos sean protagonistas.
- Mantén contraste suficiente entre texto y fondo.
- Prefiere sombras suaves y bordes redondeados para reforzar la sensación de cercanía.

### Evitar
- Negros puros como color principal de texto si no es necesario.
- Grises fríos azulados que rompan la calidez de marca.
- Exceso de naranja en cards, listas y fondos completos.

---

## 6. Recomendaciones de UX para CocinaME

### Pantallas principales
- **Home:** fondo `#FFF9F2`, cards `#FFFDF9`, CTA principal en `#ED6E1F`.
- **Listado de platos:** chips activas en `#ED6E1F`, chips inactivas en `#F7E8DA`.
- **Detalle de plato:** precio, disponibilidad y CTA destacados con naranja; metadata en neutros cálidos.
- **Carrito/pedido:** usar success para confirmaciones y warning para tiempos o restricciones.
- **Mapa/geolocalización:** mantener el naranja para pins activos o seleccionados.

### Estados emocionales de la app
La app debe sentirse:
- **Alegre**, no infantil.
- **Cálida**, no pesada.
- **Moderna**, no fría.
- **Enérgica**, no agresiva.

---

## 7. Tokens sugeridos para Flutter

```md
brandPrimary = #ED6E1F
brandPrimaryDark = #C95714
brandPrimaryLight = #F59B52
brandSoft = #FFD7B5
brandAccentWarm = #FFB067

background = #FFF9F2
surface = #FFFDF9
surfaceVariant = #F7E8DA
outline = #D9B89B
outlineVariant = #E8D4C2

textPrimary = #2F241C
textSecondary = #6B5848
textDisabled = #A58A75
onPrimary = #FFF8E2

success = #2E7D32
warning = #D9822B
error = #C62828
info = #3A7CA5
```

---

## 8. Prompt corto para OpenCode

Usa una identidad visual cálida y moderna para la app Flutter de CocinaME. El color principal de marca es `#ED6E1F`. La interfaz debe transmitir energía, entusiasmo, creatividad, calidez, sociabilidad y juventud. Usa fondos claros cálidos (`#FFF9F2`, `#FFFDF9`), texto en marrones oscuros cálidos (`#2F241C`, `#6B5848`) y reserva el naranja para acciones clave, elementos activos y acentos de marca. Evita una estética fría o corporativa; debe sentirse cercana, apetecible, dinámica y humana.

---

## 9. Decisión de diseño

La lógica de esta paleta no es solo “usar naranja porque el logo es naranja”, sino construir una identidad coherente con el significado psicológico y simbólico que quieres proyectar. CocinaME debe verse como una app de comida casera con movimiento, calidez social y energía positiva.

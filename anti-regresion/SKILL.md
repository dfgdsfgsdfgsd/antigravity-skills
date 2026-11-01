---
name: anti-regresion
description: Guía de ingeniería y protocolo de seguridad para evitar regresiones, bucles infinitos de eventos y roturas en código funcional durante refactorizaciones o agregado de funciones, con checklist especializado para video y multimedia web.
---

# Anti-Regresión & Refactor Seguro (Protocolo Universal)

Esta skill establece las directivas obligatorias de seguridad que el asistente debe respetar antes de modificar código funcional en cualquier proyecto, evitando que optimizaciones o nuevas características rompan lo que ya anda bien.

---

## 🛡️ PARTE 1: Las 4 Leyes Universales contra Regresiones

### 1. El Principio del Núcleo Intocable
- Si un componente, reproductor, pipeline o función ya funciona y cumple su objetivo: **NO modificar su lógica interna** salvo que el usuario lo pida explícitamente como objetivo principal.
- Si una tarea consiste en arreglar un detalle estético o secundario (ej. "mostrar el fotograma 1"), **no reescribir el bucle principal de ejecución**.

### 2. Refactorizaciones y Modularizaciones 1 a 1
- Cuando se divida un archivo grande en módulos (ej. separar backend, HTML y cliente JS):
  - La extracción debe ser **idéntica y pura (1:1)**.
  - **PROHIBIDO** aprovechar la extracción para introducir nuevas "mejoras", cambiar intervalos, agregar listeners o reescribir funciones al mismo tiempo.
  - Primero se modulariza y se prueba que todo siga andando exactamente igual; luego, en un paso separado, se introducen mejoras.

### 3. Detección Preventiva de Bucles de Eventos (Event Thrashing)
- **Regla de causalidad circular:** Si dentro del listener de un evento `X` modificas una propiedad que internamente vuelve a disparar `X`, se creará un bucle infinito que saturará el CPU al 100%.
- Todo listener que reaccione a eventos de estado o carga debe:
  - Usar banderas de control de ejecución única (`let yaEjecutado = false;`).
  - O usar la opción nativa `{ once: true }`.

### 4. Cambios Atómicos y Verificación de Línea Base
- Realizar solo **un cambio conceptual por paso**.
- Si un cambio causa lentitud, tirones o comportamientos inesperados, **no acumular parches encima**: revisar inmediatamente el commit anterior (`git diff`) y volver al estado limpio.

---

## 🎬 PARTE 2: Checklist Crítico para Video, Audio y Multimedia Web

Cuando el proyecto involucre elementos HTML5 (`<video>`, `<audio>`), streaming o Web Audio API, se aplican estas reglas inviolables:

### 1. Manejo del elemento `<video>`
- **Jamás alterar `currentTime` en listeners de carga:**
  - NUNCA modificar `video.currentTime` dentro de `canplay`, `loadeddata` o `seeked` sin `{ once: true }`. Hacerlo reinicia el decodificador de video indefinidamente.
- **Cumplimiento estricto de la política de Autoplay:**
  - Asignar siempre `video.muted = true` **antes** de llamar a `video.play()`. Si se llama a `.play()` con audio sin interacción previa, el navegador rechaza la promesa y congela el video silenciosamente.
- **Respetar la fluidez nativa del decodificador:**
  - El decodificador de video corre por hardware a 25/30/60 FPS nativos.
  - NUNCA usar un `setInterval` de JavaScript para forzar `video.currentTime = ...` en cada cuadro durante la reproducción normal. Eso vacía el búfer de fotogramas y genera micro-congelamientos ("tirones").
  - Usar la propiedad nativa `video.loop = true` para bucles continuos sin cortes.
  - Solo corregir `currentTime` si el usuario arrastra manualmente la barra de tiempo o si el desfase supera un umbral holgado.

### 2. Streaming de Audio y Archivos Locales en Node.js
- **Protección contra `EMFILE` (Too many open files):**
  - Los archivos de audio que se reproduzcan en bucle continuo o reciban múltiples peticiones por rangos (`Range: bytes=...`) deben servirse desde un **búfer en memoria RAM** (`fs.readFileSync`), no abriendo `fs.createReadStream` en cada petición.
  - Esto reduce el consumo de CPU de Node a 0% y elimina los cuelgues en Windows.

### 3. Rendimiento CSS sobre Reproductores de Video
- **Evitar capas de composición pesadas:**
  - NUNCA superponer animaciones infinitas (`animate-ping`, `animate-pulse`) combinadas con filtros `backdrop-filter: blur(...)` encima de un video.
  - Esto fuerza al navegador a recalcular shaders de desenfoque gaussiano 60 veces por segundo, disparando el uso de CPU a más del 50% incluso en reposo.

---

## 🚀 Cómo aplicar esta skill:
Cuando se solicite optimizar, modularizar o agregar funciones a una aplicación existente, la IA debe auditar previamente este checklist y confirmar que ninguna de las reglas anteriores sea vulnerada.

---
name: anti-regresion
description: Guía de ingeniería y protocolo de seguridad para evitar regresiones, bucles infinitos de eventos y roturas en código funcional durante refactorizaciones o agregado de funciones, con checklist especializado para video, frontend DOM y Python.
---

# Anti-Regresión & Refactor Seguro (Protocolo Universal)

Esta skill establece las directivas obligatorias de seguridad que el asistente debe respetar antes de modificar código funcional en cualquier proyecto (JavaScript, Python, Node, Remotion), evitando que optimizaciones o nuevas características rompan lo que ya anda bien.

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

## 🌐 PARTE 2: Blindaje de Frontend DOM & JavaScript Vanilla

Cuando se agreguen, muevan o eliminen botones o elementos visuales en HTML/JS:

### 1. Regla de Oro del Elemento Eliminado (Protección contra `TypeError: Cannot read properties of null`)
- **NUNCA** eliminar o mover un elemento del HTML sin auditar y blindar previamente **todas las referencias** a ese ID o clase en JavaScript.
- Si un elemento puede no existir en el DOM:
  - **PROHIBIDO:** `boton.disabled = false;` o `boton.addEventListener(...)` directo.
  - **OBLIGATORIO:** Usar guardas estrictas: `if (boton) { boton.disabled = false; }` o encadenamiento opcional `boton?.addEventListener(...)`.
  - Si un elemento arroja `TypeError`, **JavaScript detiene por completo la función** que lo contiene, rompiendo funciones críticas que estaban programadas más abajo (como la selección de pantallas o la reproducción).

### 2. Máquina de Estados de Clic vs Selección (Colisión de Eventos)
- Cuando un elemento hijo interactivo (ej. video, botón) esté dentro de un contenedor seleccionable (ej. tarjeta, teléfono):
  - **Distinguir siempre:** ¿El usuario hizo clic para **seleccionar/activar** el contenedor, o para **interactuar** con el hijo?
  - Si el contenedor estaba inactivo: el primer clic debe **activarlo** (sin disparar la acción toggle interna que lo cancelaría).
  - Si el contenedor ya estaba activo: el clic ejecuta la **acción interactiva** (ej. pausar/reproducir).

---

## 🐍 PARTE 3: Blindaje para Python, FastAPI y Pipelines de Backend

Cuando se modifique código backend en Python o pipelines de procesamiento:

### 1. Retrocompatibilidad Estricta de Payloads y APIs
- Al recibir diccionarios o JSON desde clientes web (`data = await request.json()`):
  - **NUNCA** asumir que una clave existe: usar siempre `data.get("clave", valor_por_defecto)`.
  - Si se añade un parámetro nuevo (ej. `pauseExport`), debe tener siempre fallback para clientes o pantallas antiguas que no lo envíen.

### 2. Ejecutables Externos y Dependencias de Sistema (FFmpeg, ImageMagick, etc.)
- **PROHIBIDO** asumir que un ejecutable como `ffmpeg` está en el `PATH` global de Windows.
- Usar siempre wrappers autocontenidos (ej. `imageio_ffmpeg.get_ffmpeg_exe()`) con fallback seguro.
- Si el proceso falla, capturar `stderr.decode()` para reportar el error exacto y no colgar el servidor.

### 3. Validación Preventiva de Sintaxis
- Antes de dar por terminado cualquier cambio en Python, ejecutar siempre:
  `python -m py_compile archivo.py`
  para garantizar que no haya errores de indentación, sintaxis o caracteres mal codificados.

---

## 🎬 PARTE 4: Checklist Crítico para Video, Audio y Multimedia Web

Cuando el proyecto involucre elementos HTML5 (`<video>`, `<audio>`), streaming o Web Audio API:

### 1. Manejo del elemento `<video>`
- **Jamás alterar `currentTime` en listeners de carga:**
  - NUNCA modificar `video.currentTime` dentro de `canplay`, `loadeddata` o `seeked` sin `{ once: true }`. Hacerlo reinicia el decodificador de video indefinidamente.
- **Cumplimiento estricto de la política de Autoplay:**
  - Asignar siempre `video.muted = true` **antes** de llamar a `video.play()`. Si se llama a `.play()` con audio sin interacción previa, el navegador rechaza la promesa y congela el video silenciosamente.
- **Prohibición de Autoplay al cambiar de pantalla o contenedor (Exclusión Mutua de Video):**
  - En interfaces con múltiples pantallas, diapositivas, tarjetas o teléfonos simultáneos (ej. editores de reels, carruseles):
    - **PROHIBIDO:** Disparar `.play()` automáticamente al hacer clic para seleccionar o cambiar de pantalla/lienzo. La selección de un contenedor debe dejar el video en **pausa limpia** en su fotograma correspondiente, esperando a que el usuario pulse explícitamente el botón Reproducir.
    - **Garantía de Pausa Global en el DOM:** NUNCA confiar únicamente en iterar arrays de estado en memoria para pausar videos. Se debe ejecutar siempre una pausa directa sobre todos los elementos del DOM: `document.querySelectorAll("video").forEach(v => { v.pause(); v.muted = true; })`.
    - **Exclusión Mutua Estricta:** Antes de iniciar la reproducción de cualquier video (`togglePlayPause`), pausar forzosamente todos los demás videos del documento para garantizar que jamás existan dos o más videos corriendo en simultáneo en segundo plano.
- **Sincronización Suave de Scrubber y Línea de Tiempo a 60 FPS:**
  - El evento nativo `timeupdate` de HTML5 solo dispara unas 3 a 4 veces por segundo (~250 ms), causando saltos y tirones visibles en el cursor de la barra de reproducción.
  - Usar un bucle de animación con `requestAnimationFrame` mientras el video esté en reproducción (`!video.paused`) para mover el cursor y el contador a 60/120 FPS fluidos.
  - Cancelar inmediatamente el bucle (`cancelAnimationFrame`) al pausar, finalizar o cambiar de pantalla para mantener el consumo de CPU en 0% en reposo.
  - En `<input type="range">`, utilizar `step="any"` para habilitar desplazamiento continuo sin cuantizaciones rígidas.
- **Respetar la fluidez nativa del decodificador:**
  - El decodificador de video corre por hardware a 25/30/60 FPS nativos.
  - NUNCA usar un `setInterval` de JavaScript para forzar `video.currentTime = ...` en cada cuadro durante la reproducción normal. Eso vacía el búfer de fotogramas y genera micro-congelamientos ("tirones").
  - Usar la propiedad nativa `video.loop = true` para bucles continuos sin cortes.
  - Solo corregir `currentTime` si el usuario arrastra manualmente la barra de tiempo o si el desfase supera un umbral holgado.

### 2. Streaming de Audio y Archivos Locales en Node.js
- **Protección contra `EMFILE` (Too many open files):**
  - Los archivos de audio que se reproduzcan en bucle continuo o reciban múltiples peticiones por rangos (`Range: bytes=...`) deben servirse desde un **búfer en memoria RAM** (`fs.readFileSync`), no abriendo `fs.createReadStream` en cada petición.
  - Esto reduce el consumo de CPU de Node a 0% y elimina los cuelgues en Windows.

### 3. Rendimiento CSS y Efectos de Fondo sobre Reproductores de Video
- **Evitar capas de composición pesadas:**
  - NUNCA superponer animaciones infinitas (`animate-ping`, `animate-pulse`) combinadas con filtros `backdrop-filter: blur(...)` encima de un video.
  - Esto fuerza al navegador a recalcular shaders de desenfoque gaussiano 60 veces por segundo, disparando el uso de CPU a más del 50% incluso en reposo.
- **Efectos de distorsión líquida o refracción (Navegador vs FFmpeg):**
  - **En el Navegador:** NUNCA usar filtros SVG dinámicos (`<feTurbulence>` con `<animate>`) junto a un reproductor de video: Chrome los procesa por CPU y congela la decodificación por hardware DirectComposition. Usar Shaders WebGL directos en la GPU, asegurando siempre `gl.viewport(0, 0, width, height)` explícito y jamás asignar `crossOrigin = "anonymous"` a imágenes en Base64 (`data:`).
  - **En FFmpeg:** Usar desplazamiento procedural Perlin (`displace=edge=smear`) y duplicar con `split` los mapas de ruido si se aplican pases de iluminación suave (`blend=softlight`) para crestas 3D.
- **Protección contra reseteo de `video.src` tras subidas asíncronas:**
  - Cuando un archivo de video se cargue localmente con `URL.createObjectURL(file)` y se suba al backend en segundo plano para persistencia, **NUNCA reasignar `video.src`** al recibir la URL del servidor si el video ya está reproduciéndose con éxito. Reasignar `video.src` reinicia forzosamente el buffer y la posición a 0s.

---

## 🚀 Cómo aplicar esta skill:
Cuando se solicite optimizar, modularizar o agregar funciones a una aplicación existente, la IA debe auditar previamente este checklist y confirmar que ninguna de las reglas anteriores sea vulnerada.

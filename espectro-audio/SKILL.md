---
name: espectro-audio
description: Arquitectura y suite de visualizadores de audio en tiempo real (FFT, Onda Podcast SoundCloud, Matriz LED 48 bandas, VFD Ice White, VU clasico y Oscilografo con scroll continuo) mediante Web Audio API para Electron y Web. Alias: /visualizador-audio, /matriz-led-audio
---

# /espectro-audio - Suite de Espectro y Visualizadores de Audio en Tiempo Real

Esta skill implementa, audita y optimiza analizadores de espectro acústico en tiempo real (FFT y Time-Domain PCM) mediante la **Web Audio API** de HTML5 y Canvas 2D a 60 FPS para aplicaciones de escritorio (Electron) y aplicaciones web (FastAPI, Flask, Node.js, Next.js, HTML puro).

---

## 💻 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** `Frontend Canvas / Web Audio API | Electron | Web (FastAPI, Flask, Express, Next.js, HTML5)`
- **Agnóstica al backend:** Funciona igual sobre Node/Electron o Python (FastAPI/Flask) porque corre directamente en el motor Chromium/Navegador.
- **Requisitos:** Soporte nativo para `AudioContext`, `createMediaElementSource` y `<canvas>`.

---

## 🛡️ Paso 0: Guarda de Seguridad y Diagnóstico Previo

Antes de inyectar código, auditar la estructura HTML/JS:
1. **Verificar elemento emisor:** Debe existir un `<video>` o `<audio>` con `crossorigin="anonymous"`.
2. **Verificar CORS:** Si los archivos multimedia provienen de un servidor local HTTP o remoto, el servidor DEBE enviar cabecera `Access-Control-Allow-Origin: *`.
3. **Comprobar canvas:** Debe existir un `<canvas id="waveformCanvas">` con dimensiones o redimensionado dinámico.

---

## 🎛️ Arquitectura de Audio y Enrutamiento sin Eco

### El Problema de Mute y Múltiples Reproductores
En reproductores duales (ej. video original 16:9 + simulador 9:16 vertical):
- Si ambos videos tienen audio, generan eco audible.
- Si se utiliza `video.muted = true` en el reproductor principal, Chromium desactiva la decodificación PCM, silenciando el analizador Web Audio API.

### La Solución de Grado Profesional
```javascript
let audioCtx = null;
let analyserNode = null;
let audioSourceNode = null;
let masterGain = null;
let frequencyData = null;
let timeDomainData = null;

function initWebAudioAnalyser(mediaElement) {
  if (audioCtx || !mediaElement) {
    if (audioCtx && audioCtx.state === "suspended") audioCtx.resume().catch(() => {});
    return;
  }

  const AudioContextClass = window.AudioContext || window.webkitAudioContext;
  audioCtx = new AudioContextClass();
  analyserNode = audioCtx.createAnalyser();
  analyserNode.fftSize = 512; // 256 bandas reales (resolución de 93.75 Hz/bin)
  analyserNode.smoothingTimeConstant = 0.78; // Ataque ágil y caída musical
  
  frequencyData = new Uint8Array(analyserNode.frequencyBinCount);
  timeDomainData = new Uint8Array(analyserNode.fftSize);

  audioSourceNode = audioCtx.createMediaElementSource(mediaElement);
  masterGain = audioCtx.createGain();
  masterGain.gain.value = 1.0;

  // Ruta: Video -> Analizador FFT -> Control Ganancia -> Altavoces
  audioSourceNode.connect(analyserNode);
  analyserNode.connect(masterGain);
  masterGain.connect(audioCtx.destination);

  // Mantener preview secundario permanentemente silenciado
  // Y sincronizar el mute del reproductor principal con masterGain (no con el tag de video)
  mediaElement.muted = false;
}
```

---

## 🎨 Los 6 Modos de Visualización

### 1. `podcast_wave` (🎙️ Onda Simétrica Podcast / SoundCloud)
- **Diseño estético de alta gama:** Ondas simétricas centradas en el eje horizontal medio (`centerY = h / 2`) con extremos completamente redondeados (cápsulas / pills con `ctx.roundRect`).
- **Gradiente vertical cálido:** Puntas magenta / violeta (`#b83280`, `#db2777`) que transicionan suavemente a rosa coral (`#fb7185`) y un núcleo central dorado melocotón / ámbar (`#fbbf24`), idéntico al estilo moderno de notas de voz y SoundCloud.
- **Densidad:** 64 columnas dinámicas con suavizado reactivo a frecuencias vocales y musicales.
- **Adaptabilidad:** Sincronizado dinámicamente con las 5 paletas de color.

### 2. `daw_led_matrix` (🎛️ DAW Matriz LED de 48 Bandas Segmentadas)
- **Densidad:** 48 columnas fijas de espectro completo (20Hz a 16kHz).
- **Celdas:** Cada columna dividida en 20 micro-bloques rectangulares LED (960 celdas totales).
- **Profundidad:** Las celdas inactivas permanecen visiblemente tenues (`#07180e`, `#1b1605`, `#220609`), creando el efecto de pantalla matricial física de estudio.
- **Picos flotantes:** Un micro-bloque LED superior suspendido en el aire con física de gravedad.

### 2. `daw_bars` (Barras DAW Neón de 48 Bandas Continuas)
- 48 columnas continuas con gradiente vertical de audio y picos flotantes sostenidos.

### 3. `vfd_ice` (VFD Mini-LED Ice White de 16 Bandas Panorámicas)
- 16 columnas con micro-LEDs dobles (textura dual-dot) en **Blanco Glaciar Luminoso** (`#ffffff`).
- Línea base de frecuencias con guiones y marcas grabadas en **Verde Menta / Esmeralda Neón** (`#00ff88`):
  `- 57 - 134 - 400 - 1K - 2K2 - 6K3 - 16K - -`.

### 4. `led_matrix` (Matriz LED Clásica de 10 Bandas RGB)
- 10 bandas de ecualizador vintage (`50`, `100`, `150`, `250`, `500`, `750`, `1K`, `2K`, `4K`, `HIGH`).
- 16 bloques por columna con escala clásica Verde → Amarillo/Ámbar → Rojo Carmesí.

### 5. `timeline_scroll` (Oscilógrafo Temporal con Scroll Continuo)
- **Desplazamiento síncrono al video (60 FPS):** A medida que el video avanza, la masa acústica se desplaza de derecha a izquierda como un sismógrafo de audio continuo. Al pausar, se congela para inspeccionar transitorios.
- **Envolvente simétrica verde neón:** Densa silueta acústica (`#00e676` / `#40ff00`).
- **Ejes métricos:** Eje vertical `Presión` (+1.0 a -1.0) y horizontal `Tiempo (s)` con marcas de segundos.
- **Aguja de tiempo (Playhead):** Aguja vertical ámbar/naranja (`#ff9800`) fija en la posición activa de lectura.

---

## 🌈 Sistema de Paletas de Color Dinámicas

Soporta 5 paletas estéticas que modifican dinámicamente tanto las matrices segmentadas como los gradientes de las barras:
- **🎙️ Classic Studio:** Verde Esmeralda (`#00e676`) → Ámbar (`#ffd600`) → Rojo Carmesí (`#ff1744`).
- **⚡ Cyberpunk Neón:** Cian Eléctrico (`#00f0ff`) → Fucsia Neón (`#ff007f`) → Púrpura Ultravioleta (`#b026ff`).
- **🌅 Gold Sunset:** Naranja Fuego (`#ff5722`) → Ámbar Cálido (`#ffb300`) → Blanco Neón (`#ffffff`).
- **🟢 Matrix Hacker:** Verde Fósforo (`#00ff41`) → Verde Lima (`#39ff14`) → Blanco Fósforo (`#e6ffed`).
- **❄️ Ice Glaciar:** Azul Glaciar (`#0284c7`) → Cian Ártico (`#38bdf8`) → Blanco Hielo (`#ffffff`).

---

## ⏱️ Control de Desvanecimiento de Picos (Peak Decay Rate)

Configuración dinámica del tiempo de suspensión de los picos antes de caer por gravedad:
- `slow`: 42 fotogramas de sostén (~1.2s), caída suave de 0.12 bloques/cuadro.
- `medium`: 20 fotogramas de sostén (~0.6s), caída estándar de 0.25 bloques/cuadro.
- `fast`: 8 fotogramas de sostén (~0.2s), caída rápida de 0.50 bloques/cuadro.
- `off`: Desactivación total de picos flotantes.

---

## ⚠️ Protocolo Anti-Regresión Crítico

1. **Orden de Declaración (Temporal Dead Zone):**
   - NUNCA usar variables en arreglos antes de su declaración:
     ```javascript
     // CORRECTO:
     const barCount = 48;
     const dawHeights = new Array(barCount).fill(0.04);
     ```
2. **Polyfill de `ctx.roundRect`:**
   - Algunas versiones de motores web embebidos no cuentan con `ctx.roundRect`. Siempre asegurar:
     ```javascript
     if (!ctx.roundRect) {
       ctx.roundRect = function(x, y, w, h) { ctx.rect(x, y, w, h); };
     }
     ```
3. **Escalado HiDPI / Pantallas Retina:**
   - Escalar `canvas.width` y `canvas.height` por `window.devicePixelRatio || 1` para evitar bordes borrosos.
4. **Persistencia limpia en `localStorage`:**
   - Almacenar selecciones (`spectrumStyle`, `peakDecayMode`, `spectrumColorTheme`) con valores por defecto seguros.

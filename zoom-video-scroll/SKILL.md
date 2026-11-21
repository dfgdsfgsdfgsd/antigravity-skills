---
name: zoom-video-scroll
description: Implementa zoom focal interactivo con la rueda del ratón (Scroll) y paneo por arrastre para reproductores de video HTML5 y Electron, 100% optimizado para GPUs integradas y CPUs livianas sin tarjeta gráfica dedicada. Alias: /zoom-video, /zoom-scroll
---

# /zoom-video-scroll - Zoom Focal con Scroll y Paneo Liviano para Reproductores de Video

Esta skill se activa con `/zoom-video-scroll` o sus alias `/zoom-video` y `/zoom-scroll`. Proporciona la arquitectura completa para implementar **ampliación interactiva mediante rueda del ratón (wheel/scroll)**, **zoom focal** (centrado en el cursor), **paneo por arrastre (drag-to-pan)** y **restablecimiento instantáneo al 100%** en cualquier reproductor de video HTML5 o aplicación Electron.

Está especialmente diseñada y optimizada para **PCs y laptops sin tarjeta gráfica dedicada**, funcionando con fluidez absoluta (60 FPS estables) sobre procesadores con gráfica integrada (Intel UHD, Iris Xe, AMD Vega/Radeon integrada) o CPUs de oficina sin provocar sobrecalentamiento ni uso excesivo del procesador.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** Frontend DOM / CSS3 / HTML5 Video / Electron / Vanilla JS / React / Vue / Vite.
- **Gráfica requerida:** Ninguna dedicada. Compatible al 100% con **Gráficas Integradas (iGPU)** y aceleración por compositor 2D estándar de Chromium/Blink/Gecko.
- **Impacto de CPU:** Cero repintado del DOM (0% de CPU adicional en transformaciones).

---

## 💡 ¿Por qué funciona perfectamente sin GPU dedicada?

Muchos desarrolladores creen erróneamente que "aceleración por GPU" en la web requiere una tarjeta gráfica costosa (NVIDIA RTX / AMD Radeon). **Esto es falso**:

1. **El Compositor de Texturas 2D:** Todos los navegadores modernos (Chromium, Edge, Chrome, Electron) utilizan las capacidades 2D básicas de la gráfica integrada del procesador (Intel/AMD) mediante capas de composición (*composited layers*).
2. **`transform: translate3d(...)` y `translateZ(0)`:** Al mover y escalar un video con estas propiedades, el navegador no recalcula el diseño (*reflow*) ni repinta los píxeles (*paint*) en la CPU. En su lugar, envía la textura del video a la gráfica integrada, que la escala instantáneamente por hardware.
3. **El error de alterar `width`/`height`:** Si se hiciera zoom modificando `video.style.width` o `video.style.top`, la CPU tendría que recalcular el layout 60 veces por segundo, saturándose al 100%. Con la técnica de esta skill, la CPU se mantiene descansada y fría.

---

## 🛠️ Procedimiento de Implementación en 4 Pasos

### Paso 1: Estructura HTML y Contenedor de Recorte

El elemento `<video>` debe alojarse dentro de un contenedor relativo con `overflow: hidden` para que la ampliación no desborde la interfaz:

```html
<!-- Contenedor del reproductor -->
<div class="video-container" id="videoWrapper">
  <video id="player" class="video-element" autoplay loop playsinline></video>

  <!-- HUD Flotante de Zoom -->
  <div id="videoZoomBadge" class="video-zoom-badge" title="Rueda del ratón para zoom, arrastra para mover, doble clic para 100%">
    <button id="btnZoomOut" class="zoom-btn" title="Alejar (-)">−</button>
    <span id="zoomLevelText" class="zoom-text">100%</span>
    <button id="btnZoomIn" class="zoom-btn" title="Acercar (+)">+</button>
    <button id="btnZoomReset" class="zoom-btn-reset" title="Restablecer (100%)">↺</button>
  </div>
</div>
```

---

### Paso 2: CSS de Aislamiento y Aceleración Ligera

Garantiza la creación de una capa de textura GPU 1:1 sin coste para el procesador:

```css
/* Contenedor que acota el visor */
.video-container {
  position: relative;
  overflow: hidden;
  background-color: #000;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Video con aceleración por compositor integrada */
.video-element {
  width: 100%;
  height: 100%;
  object-fit: contain;
  transform-origin: center center;
  transform: translateZ(0);
  will-change: transform;
  backface-visibility: hidden;
  user-select: none;
}

/* Badge HUD de Zoom */
.video-zoom-badge {
  position: absolute;
  top: 10px;
  right: 10px;
  background: rgba(13, 17, 23, 0.85);
  backdrop-filter: blur(8px);
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 6px;
  padding: 3px 8px;
  display: flex;
  align-items: center;
  gap: 5px;
  z-index: 20;
  user-select: none;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
  transition: border-color 0.2s, box-shadow 0.2s;
}

.video-zoom-badge.active-zoom {
  border-color: #00e676;
  box-shadow: 0 0 10px rgba(0, 230, 118, 0.35);
}

.video-zoom-badge .zoom-text {
  font-size: 0.72rem;
  font-weight: 700;
  color: #c9d1d9;
  min-width: 38px;
  text-align: center;
}

.video-zoom-badge.active-zoom .zoom-text {
  color: #00e676;
}

.video-zoom-badge .zoom-btn,
.video-zoom-badge .zoom-btn-reset {
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid rgba(255, 255, 255, 0.15);
  color: #f0f6fc;
  border-radius: 4px;
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.75rem;
  font-weight: 700;
  cursor: pointer;
  padding: 0;
  transition: background 0.15s;
}

.video-zoom-badge .zoom-btn:hover,
.video-zoom-badge .zoom-btn-reset:hover {
  background: rgba(255, 255, 255, 0.2);
}
```

---

### Paso 3: Matemática del Zoom Focal y Paneo Restringido

El zoom no debe agrandarse tontamente al centro: debe **hacer foco hacia la coordenada donde apunta el ratón**.

Fórmula matemática del punto focal:
Dado el contenedor de ancho $W$ y alto $H$, con centro en $(cX, cY)$:
El punto bajo el ratón $(mouseX, mouseY)$ antes del nuevo escalado es:
$$pX = mouseX - cX - panX_{anterior}$$
$$pY = mouseY - cY - panY_{anterior}$$

Al cambiar de escala a $Z_{nuevo}$, para que ese punto no se desplace de la vista del usuario:
$$panX_{nuevo} = (mouseX - cX) - pX \cdot \frac{Z_{nuevo}}{Z_{anterior}}$$
$$panY_{nuevo} = (mouseY - cY) - pY \cdot \frac{Z_{nuevo}}{Z_{anterior}}$$

Y el límite de arrastre permitido para que el video nunca se escape de la pantalla:
$$maxPanX = \frac{W \cdot (Z_{nuevo} - 1)}{2}$$
$$maxPanY = \frac{H \cdot (Z_{nuevo} - 1)}{2}$$

---

### Paso 4: Código JavaScript Modular y Blindado

```javascript
function initVideoZoom(wrapperEl, videoEl, badgeEl) {
  if (!wrapperEl || !videoEl) return;

  const state = {
    zoom: 1.0,
    panX: 0,
    panY: 0,
    isPanning: false,
    startMouseX: 0,
    startMouseY: 0,
    startPanX: 0,
    startPanY: 0,
    rafId: null
  };

  const textEl = badgeEl?.querySelector(".zoom-text");
  const btnIn = badgeEl?.querySelector("#btnZoomIn");
  const btnOut = badgeEl?.querySelector("#btnZoomOut");
  const btnReset = badgeEl?.querySelector("#btnZoomReset");

  function render(smooth = false) {
    if (state.rafId) cancelAnimationFrame(state.rafId);
    state.rafId = requestAnimationFrame(() => {
      const z = state.zoom;
      const px = Math.round(state.panX * 10) / 10;
      const py = Math.round(state.panY * 10) / 10;

      if (smooth) {
        videoEl.style.transition = "transform 0.18s cubic-bezier(0.2, 0, 0, 1)";
        setTimeout(() => { if (videoEl) videoEl.style.transition = ""; }, 200);
      } else {
        videoEl.style.transition = "";
      }

      videoEl.style.transform = `translate3d(${px}px, ${py}px, 0) scale(${z}) translateZ(0)`;

      // Estado de cursor y badge
      if (z > 1.0) {
        wrapperEl.style.cursor = state.isPanning ? "grabbing" : "grab";
        badgeEl?.classList.add("active-zoom");
      } else {
        wrapperEl.style.cursor = "";
        badgeEl?.classList.remove("active-zoom");
      }

      if (textEl) textEl.textContent = `${Math.round(z * 100)}%`;
    });
  }

  function setZoom(targetZoom, clientX, clientY, smooth = false) {
    const oldZoom = state.zoom;
    const clampedZoom = Math.min(5.0, Math.max(1.0, targetZoom));
    if (Math.abs(clampedZoom - oldZoom) < 0.001) return;

    const rect = wrapperEl.getBoundingClientRect();
    const mouseX = clientX !== undefined ? clientX - rect.left : rect.width / 2;
    const mouseY = clientY !== undefined ? clientY - rect.top : rect.height / 2;
    const cX = rect.width / 2;
    const cY = rect.height / 2;

    if (clampedZoom <= 1.0) {
      state.zoom = 1.0;
      state.panX = 0;
      state.panY = 0;
    } else {
      const pX = mouseX - cX - state.panX;
      const pY = mouseY - cY - state.panY;
      const ratio = clampedZoom / oldZoom;

      const newPanX = (mouseX - cX) - pX * ratio;
      const newPanY = (mouseY - cY) - pY * ratio;

      const maxPanX = (rect.width * (clampedZoom - 1)) / 2;
      const maxPanY = (rect.height * (clampedZoom - 1)) / 2;

      state.panX = Math.max(-maxPanX, Math.min(maxPanX, newPanX));
      state.panY = Math.max(-maxPanY, Math.min(maxPanY, newPanY));
      state.zoom = clampedZoom;
    }

    render(smooth);
  }

  function reset() {
    state.zoom = 1.0;
    state.panX = 0;
    state.panY = 0;
    render(true);
  }

  // 1. Zoom con Scroll
  wrapperEl.addEventListener("wheel", (e) => {
    e.preventDefault();
    e.stopPropagation();

    const factor = e.deltaY < 0 ? 1.15 : (1 / 1.15);
    let next = state.zoom * factor;
    if (next <= 1.04) next = 1.0;
    setZoom(next, e.clientX, e.clientY, false);
  }, { passive: false });

  // 2. Doble Clic para Reset
  wrapperEl.addEventListener("dblclick", (e) => {
    if (e.target.closest(".video-zoom-badge")) return;
    reset();
  });

  // 3. Paneo con Clic y Arrastre
  wrapperEl.addEventListener("mousedown", (e) => {
    if (e.button !== 0 || state.zoom <= 1.0) return;
    if (e.target.closest(".video-zoom-badge")) return;

    state.isPanning = true;
    state.startMouseX = e.clientX;
    state.startMouseY = e.clientY;
    state.startPanX = state.panX;
    state.startPanY = state.panY;
    wrapperEl.style.cursor = "grabbing";
    e.preventDefault();
  });

  window.addEventListener("mousemove", (e) => {
    if (!state.isPanning) return;
    const dx = e.clientX - state.startMouseX;
    const dy = e.clientY - state.startMouseY;

    const rect = wrapperEl.getBoundingClientRect();
    const maxPanX = (rect.width * (state.zoom - 1)) / 2;
    const maxPanY = (rect.height * (state.zoom - 1)) / 2;

    state.panX = Math.max(-maxPanX, Math.min(maxPanX, state.startPanX + dx));
    state.panY = Math.max(-maxPanY, Math.min(maxPanY, state.startPanY + dy));
    render(false);
  });

  const stopPan = () => {
    if (state.isPanning) {
      state.isPanning = false;
      if (wrapperEl) wrapperEl.style.cursor = state.zoom > 1.0 ? "grab" : "";
    }
  };

  window.addEventListener("mouseup", stopPan);
  window.addEventListener("blur", stopPan);

  // 4. Botones HUD
  btnIn?.addEventListener("click", (e) => { e.stopPropagation(); setZoom(state.zoom * 1.25, undefined, undefined, true); });
  btnOut?.addEventListener("click", (e) => { e.stopPropagation(); const n = state.zoom / 1.25; setZoom(n <= 1.04 ? 1.0 : n, undefined, undefined, true); });
  btnReset?.addEventListener("click", (e) => { e.stopPropagation(); reset(); });

  return { reset, setZoom };
}
```

---

## 🛡️ Protocolo Anti-Regresión & Casos Borde

1. **Colisión con Cuadros de Selección (Cropping/Stickers):**
   - Si la aplicación tiene cajas interactivas dentro del visor (como un recuadro 9:16), añadir `e.stopPropagation()` en el `mousedown` del recuadro para que arrastrar el marco no mueva el paneo del video.
2. **`passive: false` obligatorio en `wheel`:**
   - Para que `e.preventDefault()` cancele el scroll vertical de la ventana o panel en navegadores modernos, el listener `wheel` debe declararse con `{ passive: false }`.
3. **Cero Reflow en V-Sync:**
   - Todas las actualizaciones de posición deben canalizarse a través de `requestAnimationFrame`. Nunca actualizar estilos directamente en ráfagas de `mousemove` a 1000Hz.
4. **Prevención de Franjas Negras en Flexbox (`flex-shrink: 0` y `object-fit: cover`):**
   - Si el contenedor del visor es un elemento flex hijo (`flex-direction: column`), por defecto tiene `flex-shrink: 1`. Cuando la altura disponible de la ventana es menor a la requerida, el motor de flexbox aplasta la altura del visor, rompiendo la proporción `aspect-ratio: 16 / 9` (deformándolo a un rectángulo 2:1 o 18:9) y generando dos franjas negras (*pillarboxing*) a los lados.
   - Para erradicar las franjas negras al 100%:
     - Añadir obligatoriamente `flex-shrink: 0; width: 100%; aspect-ratio: 16 / 9;` en el contenedor `.video-container`.
     - Establecer `object-fit: cover;` en la etiqueta `<video>` para garantizar ajuste perfecto de borde a borde.

---
name: anti-estela
description: Diagnostica y elimina estelas fantasma y tearing en animaciones DOM Chromium mediante capas GPU (translateZ). Alias: /anti-ghosting
---

# /anti-estela - Eliminación de Estelas Fantasma y Artefactos de Renderizado en Chromium

Esta skill se activa con `/anti-estela` o su alias `/anti-ghosting`. Proporciona el protocolo técnico completo para diagnosticar, erradicar y prevenir el fenómeno de las **estelas fantasma (*ghost trailing*)**, desgarros de repintado (*screen tearing*) y marcas persistentes que ocurren al arrastrar (*drag & drop*) o animar elementos DOM (videos, imágenes, tarjetas de texto, stickers) en aplicaciones web interactivas.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** Frontend DOM / CSS3 / WebGL / HTML5 Canvas + Backend Web (FastAPI, Express, Flask, Node, etc.).
- **Navegadores:** Google Chrome, Microsoft Edge, Opera, Brave y cualquier navegador basado en Chromium.
- **Requisitos:** Acceso a los archivos de estilo (`.css`), lógica de arrastre (`.js`) y configuración del servidor backend.

---

## 🔍 Paso 0: Diagnóstico de la Causa Raíz

Las estelas fantasma no son errores de JavaScript, sino **fallos de invalidación de rectángulos de repintado (*damage rects*) en el motor gráfico de Chromium (Blink / Skia / Graphite)**. Ocurren cuando coinciden dos o más de estos factores:

1. **Escalado del contenedor padre (`transform: scale(...)`):**
   - Cuando un contenedor tiene `transform: scale(0.75)` o similar, las coordenadas en píxeles de los elementos hijos se multiplican por decimales (`120.75px`, `150.93px`).
   - Al mover el elemento con el ratón, Skia redondea hacia abajo las coordenadas del área dañada, **omitiendo la fila o columna exterior de píxeles**. El fotograma anterior no se limpia del búfer y se estampa repetidamente en cada movimiento.
2. **Uso de `outline` en lugar de `border`:**
   - La propiedad CSS `outline` se dibuja fuera del marco de la caja (*outside the bounding box*) y no genera reflujo (*reflow*). Bajo `scale(...)`, los bordes punteados se salen de la caja de recorte y manchan el lienzo permanentemente.
3. **Desincronización de capas GPU:**
   - Si una etiqueta `<video>` tiene aceleración 3D aislada (`translate3d(0,0,0)`, `perspective: 1000px`), pero su caja contenedora se dibuja en la capa 2D de software, las capas se desincronizan durante el arrastre rápido.
4. **Saturación del bucle de eventos (`mousemove` sin V-Sync):**
   - Disparar actualizaciones directas de `el.style.top` o `el.style.left` en cada evento crudo de ratón (que emite a 500-1000Hz en ratones gaming) satura el hilo principal sin sincronizarse con los 60Hz/120Hz del monitor.
5. **Caché agresiva del navegador:**
   - Si el backend no envía cabeceras `Cache-Control: no-cache, no-store, must-revalidate`, el navegador ejecuta archivos `.css` y `.js` antiguos desde la memoria caché, haciendo creer al desarrollador que las correcciones no surtieron efecto.

---

## 🛠️ Procedimiento de Solución en 4 Pasos

### Paso 1: Aislamiento de Capas GPU en 1:1 (`translateZ(0)`)

Para evitar que el motor de Chromium aplique transformaciones de subpíxeles durante el arrastre, se debe forzar una **superficie de textura propia en la GPU** para el contenedor del lienzo, la pantalla y el elemento arrastrable:

```css
/* 1. Contenedor escalado (simulador/mockup) */
.phone-mockup {
    transform: scale(0.75) translateZ(0);
    -webkit-backface-visibility: hidden;
    backface-visibility: hidden;
}

/* 2. Pantalla interna y lienzo de trabajo */
.phone-screen,
.reel-canvas {
    transform: translateZ(0);
    -webkit-backface-visibility: hidden;
    backface-visibility: hidden;
    isolation: isolate;
    contain: paint;
}

/* 3. Contenedor del elemento arrastrable (video / tarjeta) */
.media-container,
.draggable-card {
    transform: translateZ(0);
    -webkit-backface-visibility: hidden;
    backface-visibility: hidden;
}

/* 4. Etiqueta interna de video o imagen */
.media-container video,
.media-container img {
    display: block;
    pointer-events: none;
    transform: translateZ(0);
}
```

> [!TIP]
> `transform: translateZ(0)` y `backface-visibility: hidden` obligan a Chromium a crear un búfer de texturas nativo 1:1. El escalado a `0.75` se aplica globalmente al resultado final, eliminando por completo el truncamiento de subpíxeles internos.

---

### Paso 2: Reemplazar `outline` por `border` interno

Sustituir cualquier `outline` exterior por `border` interno con `box-sizing: border-box` para garantizar que las líneas punteadas o sólidas queden contenidas dentro del recorte del elemento:

```css
.media-container {
    box-sizing: border-box;
    border: 2px solid transparent;
    outline: none !important;
}

/* Resaltado al hacer hover o al estar seleccionada */
.media-container:hover,
.media-container.card-selected-highlight {
    border: 2px dashed var(--color-primary) !important;
    outline: none !important;
}
```

---

### Paso 3: Sincronización del Arrastre con `requestAnimationFrame`

En la función de arrastre de JavaScript (`setupDraggable`), sincronizar las mutaciones de estilo con el refresco de pantalla del navegador y añadir la clase `.is-dragging`:

```javascript
function setupDraggable(el, key, index) {
    if (!el) return;
    el.addEventListener("mousedown", (e) => {
        e.preventDefault();
        
        const startY = e.clientY;
        const startTop = el.offsetTop;
        const startX = e.clientX;
        const startLeft = el.offsetLeft;
        const scale = 0.75; // Factor de escala del mockup
        
        let rafId = null;
        let currentTop = startTop;
        let currentLeft = startLeft;
        let hasMoved = false;
        
        // Activar capa acelerada para arrastre fluido
        el.classList.add("is-dragging");
        
        function onMouseMove(moveEvent) {
            hasMoved = true;
            const dy = (moveEvent.clientY - startY) / scale;
            const dx = (moveEvent.clientX - startX) / scale;
            
            const top = startTop + dy;
            const left = startLeft + dx;
            
            currentTop = top;
            currentLeft = left;
            
            // Sincronizar con el refresco vertical de la pantalla (V-Sync)
            if (rafId) cancelAnimationFrame(rafId);
            rafId = requestAnimationFrame(() => {
                el.style.top = top + "px";
                el.style.left = left + "px";
                el.style.bottom = "auto";
            });
        }
        
        function onMouseUp() {
            if (rafId) cancelAnimationFrame(rafId);
            el.classList.remove("is-dragging");
            
            if (hasMoved) {
                el.style.top = currentTop + "px";
                el.style.left = currentLeft + "px";
                el.style.bottom = "auto";
            }
            
            document.removeEventListener("mousemove", onMouseMove);
            document.removeEventListener("mouseup", onMouseUp);
        }
        
        document.addEventListener("mousemove", onMouseMove);
        document.addEventListener("mouseup", onMouseUp);
    });
}
```

Y en CSS para `.is-dragging`:
```css
.is-dragging {
    will-change: top, left, transform;
    transition: none !important;
}
```

---

### Paso 4: Invalidación Forzada de Caché (*Cache-Busting*)

Para garantizar que el navegador descargue inmediatamente las reglas CSS y scripts actualizados:

1. **En el backend (ejemplo FastAPI / Python):**
   ```python
   @app.middleware("http")
   async def disable_browser_cache(request: Request, call_next):
       response = await call_next(request)
       response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
       response.headers["Pragma"] = "no-cache"
       response.headers["Expires"] = "0"
       return response
   ```
2. **En el archivo HTML (`index.html`):**
   Añadir sufijos de versión en los enlaces:
   ```html
   <link rel="stylesheet" href="style.css?v=20261106_v5">
   <script src="app.js?v=20261106_v5"></script>
   ```

---

## 🛡️ Checklist Anti-Regresión

- [ ] ¿Se eliminaron propiedades 3D en conflicto como `perspective: 1000px` en etiquetas hijas de video?
- [ ] ¿Todos los contenedores anidados con bordes redondeados y escalado tienen `transform: translateZ(0)`?
- [ ] ¿Se verificó que `.is-dragging` desactive transiciones CSS activas (`transition: none !important;`)?
- [ ] ¿Se cancela `cancelAnimationFrame(rafId)` tanto en `mousemove` como en `mouseup` para evitar fugas de ciclos?
- [ ] ¿Se reinició el servidor tras actualizar middlewares HTTP de cabeceras de caché?

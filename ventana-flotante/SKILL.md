---
name: ventana-flotante
description: Implementa paneles y ventanas flotantes duales (arrastrables y acoplables a márgenes) con localStorage. Alias: /flotante
---

# /ventana-flotante - Sistema Dual de Ventanas Flotantes Arrastrables y Paneles Acoplables

Esta skill implementa un patrón de arquitectura UI para herramientas, inspectores y paletas flotantes (como selectores de emojis, ruedas de color, inspectores de capas, propiedades, etc.) que resuelve de raíz los problemas clásicos de superposición sobre el lienzo y recorte por desborde en contenedores (`overflow: hidden` o `overflow-y: auto`).

---

## 💻 Ficha de Compatibilidad y Requisitos

- **Stack compatible:** Frontend DOM (Vanilla JavaScript, HTML5, CSS3, React, Vue, Svelte, Electron).
- **Entorno de ejecución:** Cualquier aplicación web con acceso al DOM del navegador.
- **Sin dependencias pesadas:** Usa APIs nativas del navegador (`position: fixed`, `getBoundingClientRect`, `localStorage`, eventos `mousedown`/`mousemove`/`mouseup`).

---

## 🛡️ Paso 0: Verificación de Entorno (Guarda de Seguridad)

Antes de aplicar el patrón, comprueba:
1. ¿Existe un archivo HTML o componente DOM en el proyecto (`index.html`, `.jsx`, `.vue`, etc.)?
   - Si el proyecto es exclusivamente backend/CLI (Python puro, Node sin frontend), informar al usuario que esta skill está diseñada para interfaces web y DOM.
2. ¿El contenedor padre tiene `overflow: hidden` u `overflow-y: auto`?
   - Si es así, la ventana flotante **DEBE** moverse a `document.body` (`document.body.appendChild(popup)`) para que no quede recortada.

---

## 📐 Arquitectura Técnica del Patrón

El sistema resuelve 4 desafíos críticos de experiencia de usuario (UX):
1. **Escape de desborde (Overflow Escape):** Si la herramienta nace dentro de una barra lateral estrecha, se traslada a `document.body` con `position: fixed` y `z-index: 10000`, permitiendo flotar sobre cualquier elemento sin deformar el sidebar.
2. **Posición inteligente por defecto (Canvas Awareness):** Detecta la caja de vista previa o lienzo (`phone.getBoundingClientRect()`) y se ubica automáticamente a su derecha, evitando tapar la pantalla activa donde el usuario está trabajando.
3. **Arrastre fluido con el mouse (Draggable):** Al hacer clic y arrastrar la barra de título (`.drag-handle`), calcula el desplazamiento relativo y limita la ventana a los bordes de la pantalla (`window.innerWidth`, `window.innerHeight`), guardando la posición elegida.
4. **Modo Dual de Anclaje (Docked Right):** Con un solo clic (`📌 Anclar a la derecha`), se acopla como un panel de herramientas fijo en el extremo derecho de la ventana (`right: 20px; top: 74px;`), dejando todo el centro despejado.
5. **Persistencia de preferencia:** Recuerda el modo elegido (`floating` o `docked_right`) y las coordenadas en `localStorage`.

---

## 🛠️ Implementación de Referencia

### 1. Estilos CSS (`style.css`)

```css
/* Ventana flotante dual con alta elevación */
.floating-tool-panel {
    background: #181b22;
    border: 1px solid rgba(255, 255, 255, 0.18);
    border-radius: 10px;
    padding: 10px 12px;
    display: none;
    flex-direction: column;
    gap: 8px;
    box-shadow: 0 16px 40px rgba(0, 0, 0, 0.85), 0 0 0 1px rgba(255, 255, 255, 0.08);
    width: 370px;
    max-width: calc(100vw - 30px);
    box-sizing: border-box;
    z-index: 10000;
    overflow-x: hidden !important;
    position: fixed;
    animation: fadeInToolPanel 0.15s ease-out;
}

/* Barra superior con tirador de arrastre */
.floating-tool-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding-bottom: 7px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    margin-bottom: 2px;
}

.floating-drag-handle {
    cursor: move;
    user-select: none;
    display: flex;
    align-items: center;
    gap: 7px;
    font-size: 0.78rem;
    font-weight: 600;
    color: #cbd5e1;
}

/* Modo anclado a la derecha */
.floating-tool-panel.is-docked-right {
    box-shadow: -8px 12px 36px rgba(0, 0, 0, 0.85);
    border-color: rgba(59, 130, 246, 0.35);
}

@keyframes fadeInToolPanel {
    from { opacity: 0; transform: scale(0.97); }
    to { opacity: 1; transform: scale(1); }
}
```

### 2. Controlador JavaScript (`panel-controller.js`)

```javascript
let userSavedPosition = null;

function setupFloatingPanel(triggerBtnId, panelId) {
    const btn = document.getElementById(triggerBtnId);
    const panel = document.getElementById(panelId);
    if (!btn || !panel) return;

    // 1. Escapar del contenedor con overflow y montar en body
    if (panel.parentElement !== document.body) {
        document.body.appendChild(panel);
    }

    let currentMode = localStorage.getItem('tool_panel_mode') || 'floating';

    function applyPosition() {
        if (currentMode === 'docked_right') {
            panel.classList.add('is-docked-right');
            panel.style.left = 'auto';
            panel.style.right = '20px';
            panel.style.top = '74px';
            return;
        }

        panel.classList.remove('is-docked-right');
        panel.style.right = 'auto';

        // Si el usuario ya la arrastró manualmente, respetar sus coordenadas
        if (userSavedPosition) {
            let left = Math.max(10, Math.min(window.innerWidth - panel.offsetWidth - 10, userSavedPosition.left));
            let top = Math.max(10, Math.min(window.innerHeight - panel.offsetHeight - 10, userSavedPosition.top));
            panel.style.left = `${left}px`;
            panel.style.top = `${top}px`;
            return;
        }

        // Posición inteligente: A la derecha del lienzo o pantalla principal
        const canvasEl = document.querySelector('.main-canvas') || document.querySelector('.preview-screen');
        let left = 740;
        let top = 100;

        if (canvasEl) {
            const rect = canvasEl.getBoundingClientRect();
            left = rect.right + 20;
            top = Math.max(70, rect.top + 10);
        }

        if (left + panel.offsetWidth > window.innerWidth - 10) {
            left = Math.max(10, window.innerWidth - panel.offsetWidth - 15);
        }

        panel.style.left = `${left}px`;
        panel.style.top = `${top}px`;
    }

    // 2. Sistema de arrastre con mouse
    const dragHandle = panel.querySelector('.floating-drag-handle');
    let isDragging = false;
    let dragOffsetX = 0, dragOffsetY = 0;

    if (dragHandle) {
        dragHandle.addEventListener('mousedown', (e) => {
            if (currentMode === 'docked_right') return;
            isDragging = true;
            const r = panel.getBoundingClientRect();
            dragOffsetX = e.clientX - r.left;
            dragOffsetY = e.clientY - r.top;
            document.body.style.userSelect = 'none';
            e.preventDefault();
        });
    }

    document.addEventListener('mousemove', (e) => {
        if (!isDragging) return;
        let left = Math.max(10, Math.min(window.innerWidth - panel.offsetWidth - 10, e.clientX - dragOffsetX));
        let top = Math.max(10, Math.min(window.innerHeight - panel.offsetHeight - 10, e.clientY - dragOffsetY));
        panel.style.left = `${left}px`;
        panel.style.top = `${top}px`;
        userSavedPosition = { left, top };
    });

    document.addEventListener('mouseup', () => {
        if (isDragging) {
            isDragging = false;
            document.body.style.userSelect = '';
        }
    });

    // 3. Apertura y cierre
    btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const isOpen = (panel.style.display === 'flex');
        panel.style.display = isOpen ? 'none' : 'flex';
        btn.classList.toggle('active', !isOpen);
        if (!isOpen) applyPosition();
    });
}
```

---

## 🚫 Protocolo Anti-Regresión

1. **Nunca cerrar la ventana al hacer clic en los campos de texto (`inputs` / `textareas`):** El detector de clics exteriores debe excluir explícitamente las cajas de texto asociadas (`!e.target.closest('textarea')`) para que el usuario pueda colocar el cursor o seleccionar texto sin que la paleta se cierre.
2. **Nunca dejar la ventana dentro de ancestros con `overflow-x: hidden` o `overflow-y: auto`:** Recortará cualquier desborde horizontal. Siempre extraer a `document.body`.
3. **Nunca olvidar `userSelect = 'none'` durante el arrastre:** Si no se previene, el texto del fondo se seleccionará y romperá la fluidez del movimiento del mouse.
4. **Respetar Shadow DOM en componentes web:** Si la ventana contiene web components (como `<emoji-picker>`), el manejador de clics exteriores debe comprobar `!e.target.closest('emoji-picker')` para evitar cierres accidentales al hacer clic dentro del shadow root.
5. **Dimensiones fijas sin scroll horizontal:** Asegurar siempre que los elementos internos tengan suficiente `min-width` para evitar barras de desplazamiento horizontal internas.

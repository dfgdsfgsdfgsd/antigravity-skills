---
name: alias-stream
description: Arquitectura y patrón de UI para gestión de streams en vivo con alias amigables, modal instantáneo (0ms) con desenfoque, auto-detección de portapapeles y blindaje de estados en vivo. Alias: /stream-alias, /url-amigable
---

# /alias-stream - Gestión de Streams con Nombres Amigables y Modal Instantáneo

Esta skill se activa con `/alias-stream` o sus alias `/stream-alias` y `/url-amigable`. Proporciona la arquitectura de interfaz de usuario, manejo de estados y patrones de diseño para reemplazar URLs crudas y largas de streaming (YouTube Live, Twitch, Kick, RTMP) por **alias amigables elegidos por el usuario**, integrando auto-detección del portapapeles y blindaje de estados visuales.

---

## 🎯 Problema que Resuelve

1. **URLs crudas antiestéticas:** Mostrar cadenas como `https://www.youtube.com/live/Dxi1CRQ9f_Y` satura visualmente la interfaz y dificulta identificar qué directo se está reproduciendo.
2. **Fricción al pegar enlaces:** Forzar al usuario a seleccionar, borrar y pegar manualmente enlaces cuando ya los tiene en el portapapeles.
3. **Animaciones lentas o intrusivas:** Modales con transiciones `fadeIn` o retardos innecesarios que ralentizan el flujo de trabajo diario.
4. **Falsos positivos de estado en vivo:** Mostrar controles contextuales como *"● Ver Directo 9:16"* o *"Pausar Directo"* cuando el usuario está viendo clips locales y aún no se ha conectado a ninguna transmisión real.

---

## 💻 Ficha Técnica y Compatibilidad

- **Stack compatible:** Frontend DOM (HTML5, CSS3, JavaScript Vanilla), Electron, Tauri, Web Apps multimedia.
- **APIs del Navegador:** `navigator.clipboard.readText()`, `localStorage`, `<datalist>`, `dataset`.
- **Rendimiento:** 0 ms de retraso en despliegue (sin animaciones CSS bloqueantes), apertura instantánea con `backdrop-filter: blur(8px)`.

---

## 🛠️ Procedimiento de Implementación en 5 Pasos

### Paso 1: Estructura HTML del Modal y la Barra de Entrada

```html
<!-- Barra Superior con Botón de Añadir -->
<div class="stream-controls">
  <input 
    type="text" 
    id="streamUrlInput" 
    class="stream-input" 
    list="streamHistoryList"
    placeholder="Pega enlace o asigna un nombre..." 
    autocomplete="off"
  />
  <datalist id="streamHistoryList"></datalist>
  <button id="btnAddUrl" class="btn btn-add-url" title="Añadir transmisión con nombre personalizado">➕</button>
  <button id="connectBtn" class="btn btn-primary">Conectar</button>
</div>

<!-- Modal Instantáneo con Desenfoque de Fondo -->
<div id="modalAddStream" class="stream-modal-backdrop" style="display: none;">
  <div class="stream-modal-card">
    <div class="stream-modal-header">
      <div style="display: flex; align-items: center; gap: 8px;">
        <span>📡</span>
        <strong>Añadir Transmisión en Vivo</strong>
      </div>
      <button id="btnCloseModalStream" class="stream-close-btn">&times;</button>
    </div>

    <div class="stream-modal-body">
      <div class="modal-form-group">
        <label class="modal-label">🏷️ Nombre o Título de la Transmisión</label>
        <input type="text" id="modalStreamNameInput" class="modal-input" placeholder="Ej: Podcast Ibai, Torneo Gaming..." />
        <small class="modal-help">Este nombre sustituirá la URL en la barra principal.</small>
      </div>

      <div class="modal-form-group">
        <label class="modal-label">🔗 Enlace / URL (YouTube, Twitch, Kick)</label>
        <div style="display: flex; gap: 8px;">
          <input type="text" id="modalStreamUrlInput" class="modal-input" placeholder="https://..." style="flex: 1;" />
          <button id="btnModalPasteUrl" class="btn" type="button">📋 Pegar</button>
        </div>
      </div>
    </div>

    <div class="stream-modal-footer">
      <button id="btnCancelModalStream" class="btn" type="button">Cancelar</button>
      <button id="btnSaveConnectStream" class="btn-connect-modal" type="button">⚡ Guardar y Conectar</button>
    </div>
  </div>
</div>
```

---

### Paso 2: Estilos CSS Ultra Rápidos (0ms Retardo + Desenfoque)

Evita por completo `animation: fadeIn` para garantizar una respuesta táctil inmediata:

```css
.stream-modal-backdrop {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0, 0, 0, 0.72);
  backdrop-filter: blur(8px); /* Desenfoque elegante */
  z-index: 2000;
  display: flex;
  align-items: center;
  justify-content: center;
  /* CERO ANIMACIONES para latencia 0ms */
}

.stream-modal-card {
  width: 520px;
  max-width: 92vw;
  background: #0d1117;
  border: 1px solid rgba(0, 230, 118, 0.4);
  border-radius: 12px;
  box-shadow: 0 16px 40px rgba(0, 0, 0, 0.8), 0 0 25px rgba(0, 230, 118, 0.15);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
```

---

### Paso 3: Separación de URL Técnica vs. Alias Visual

Nunca almacenes únicamente el alias visible; conserva la URL real mediante `dataset`:

```javascript
function setStreamInputDisplay(name, url) {
  const input = document.getElementById("streamUrlInput");
  if (!input) return;
  const cleanUrl = (url || "").trim();
  const displayName = (name && name.trim()) ? name.trim() : cleanUrl;

  input.value = displayName;
  input.dataset.url = cleanUrl;      // Fuente real para FFmpeg / yt-dlp / Hls.js
  input.dataset.name = displayName;  // Nombre amigable para el usuario
  input.title = `Transmisión: ${displayName}\nURL: ${cleanUrl}`;
}
```

---

### Paso 4: Auto-Detección Inteligente del Portapapeles

Al abrir el modal, inspecciona si el portapapeles contiene una URL válida sin bloquear la interfaz:

```javascript
function openAddStreamModal() {
  const modal = document.getElementById("modalAddStream");
  const nameInput = document.getElementById("modalStreamNameInput");
  const urlInput = document.getElementById("modalStreamUrlInput");
  if (!modal) return;

  modal.style.display = "flex";
  if (nameInput) nameInput.value = "";
  if (urlInput) urlInput.value = "";

  // Foco inmediato al primer campo (0 delay)
  if (nameInput) nameInput.focus();

  // Detección automática en segundo plano
  if (navigator.clipboard && navigator.clipboard.readText) {
    navigator.clipboard.readText().then(text => {
      const t = (text || "").trim();
      if (t.startsWith("http://") || t.startsWith("https://")) {
        if (urlInput) urlInput.value = t;
      }
    }).catch(() => {});
  }
}
```

---

### Paso 5: Persistencia Dual en LocalStorage con Autocompletado

```javascript
function saveStreamHistory(name, url) {
  if (!url) return;
  const cleanUrl = url.trim();
  const cleanName = (name && name.trim()) ? name.trim() : cleanUrl;

  localStorage.setItem("lastStreamUrl", cleanUrl);
  localStorage.setItem("lastStreamItem", JSON.stringify({ name: cleanName, url: cleanUrl }));

  let history = getStoredStreamHistory();
  history = [{ name: cleanName, url: cleanUrl }, ...history.filter(u => u.url !== cleanUrl)].slice(0, 10);
  localStorage.setItem("recentStreams", JSON.stringify(history));
  renderHistoryDatalist();
}
```

---

## 🛡️ Protocolo Anti-Regresión

1. **Guardas de Estado en Vivo (Evitar Falsos Positivos):**
   - El botón contextual para volver a la señal en vivo (ej: `● Ver Directo 9:16`) **debe ocultarse estrictamente (`display: none`)** si el usuario reproduce clips locales pero no hay ninguna transmisión activa conectada (`!state.liveMediaUrl`).
2. **Fallback si el usuario no escribe nombre:**
   - Si el campo del nombre se deja vacío, autogenerar un nombre legible derivado del dominio (ej: `Directo youtube.com`) en lugar de dejar el campo en blanco.
3. **Soporte de Entrada Directa:**
   - Si el usuario tipea o pega directamente una URL cruda en el campo principal sin usar el modal, la función `connectStream` debe detectarlo y procesarlo con normalidad.

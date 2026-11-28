---
name: conmutar-clip-live
description: Protocolo de ingeniería para conmutar sin congelamientos ni pantallas negras entre reproducción de clips locales MP4 y streaming HLS en vivo sobre el mismo elemento HTML5 video. Alias: /clip-a-live, /hls-mp4-switch, /toggle-live-clip
---

# /conmutar-clip-live - Conmutación Segura entre Clips MP4 y Streaming HLS en Vivo

Esta skill se activa con `/conmutar-clip-live` o sus alias `/clip-a-live`, `/hls-mp4-switch` y `/toggle-live-clip`. Proporciona el protocolo de ingeniería frontend y arquitectura de eventos para alternar fluidamente entre la reproducción de **clips grabados locales (`.mp4`)** y **transmisiones en vivo (`.m3u8` con Hls.js)** sobre un mismo reproductor `<video>` HTML5, evitando bloqueos de decodificación, saltos de minutero fuera de rango y congelamientos de pantalla.

---

## 🔍 Diagnóstico de la Causa Raíz

Cuando una aplicación multimedia (estilo SubiClip, Premiere Web, OBS Studio Web o Twitch Clips) permite previsualizar clips guardados y luego volver a la señal en directo sobre la misma vista, suele ocurrir una falla crítica: **la pantalla queda negra o congelada en el clip**.

Esto ocurre por la colisión de 3 factores del estándar HTMLMediaElement:

1. **Colisión de Fuente Directa (`src`) vs `MediaSource`:**
   - Para reproducir un clip, el código suele asignar `video.src = "http://.../clip.mp4"`.
   - Al querer volver al directo, Hls.js invoca `hls.attachMedia(video)`, que intenta asignar un `MediaSource` (`blob:http:...`). Si el atributo `src` previo no fue removido del DOM y el motor del navegador no se reseteó con `video.load()`, Chromium ignora la nueva fuente o arroja `DOMException: Overwriting src attribute during active playback`.
2. **Carrera del Minutero Maestro (*Seek Beyond Duration*):**
   - El reproductor en vivo suele tener un listener `timeupdate` que sincroniza los reproductores al tiempo actual del directo (ej: segundo `340.5`).
   - Al pasar a modo directo, si `video.currentTime` se asigna al tiempo del directo mientras el elemento `<video>` todavía tiene en memoria el clip de 30 segundos, el navegador intenta hacer seek a un punto inexistente (`currentTime > duration`), congelando el pipeline de reproducción.
3. **Inyección en Buffer no Listo (`readyState < HAVE_CURRENT_DATA`):**
   - Hls.js necesita varios cientos de milisegundos para descargar el manifiesto `.m3u8` y el primer fragmento `.ts`. Si el reloj maestro altera `video.currentTime` antes de que el buffer esté listo, Hls.js dispara un error fatal `bufferSeekOverHole` y destruye el stream.

---

## 🛠️ Procedimiento de Solución en 4 Pasos

### Paso 1: Purga Atómica del `<video>` antes de cambiar a Live

Nunca conectes HLS sobre un `<video>` que tuvo un archivo MP4 sin ejecutar antes esta secuencia de limpieza estricta:

```javascript
function purgeVideoElement(videoEl, hlsInstance) {
  if (!videoEl) return null;

  // 1. Destruir y desconectar instancia previa de HLS
  if (hlsInstance) {
    try {
      hlsInstance.stopLoad();
      hlsInstance.detachMedia();
      hlsInstance.destroy();
    } catch (e) {}
  }

  // 2. Limpieza completa de fuentes directas y buffers
  try {
    videoEl.pause();
    videoEl.removeAttribute('src');
    videoEl.srcObject = null;
    videoEl.src = '';
    videoEl.load(); // Fuerza al pipeline de Chromium a descargar decodificadores
  } catch (e) {}

  videoEl.loop = false;
  videoEl.playbackRate = 1.0;

  return null;
}
```

---

### Paso 2: Conexión HLS Limpia con Sincronización en `MANIFEST_PARSED`

Reinicia el flujo HLS y espera al evento de manifiesto antes de emparejar el minutero:

```javascript
function switchToLiveMode(videoEl, liveHlsUrl, masterVideoEl) {
  // 1. Purgar estado previo
  hlsInstance = purgeVideoElement(videoEl, hlsInstance);

  // 2. Adjuntar HLS fresco
  if (liveHlsUrl && videoEl) {
    hlsInstance = new Hls({ enableWorker: true, lowLatencyMode: false });
    hlsInstance.loadSource(liveHlsUrl);
    hlsInstance.attachMedia(videoEl);

    // 3. Sincronizar solo cuando el manifiesto y códecs estén listos
    hlsInstance.once(Hls.Events.MANIFEST_PARSED, () => {
      try {
        if (masterVideoEl && !isNaN(masterVideoEl.currentTime) && masterVideoEl.currentTime > 0) {
          videoEl.currentTime = masterVideoEl.currentTime;
        }
        if (masterVideoEl && !masterVideoEl.paused) {
          videoEl.play().catch(() => {});
        }
      } catch (e) {}
    });
  }
}
```

---

### Paso 3: Blindaje del Reloj de Sincronización en Vivo

En el listener `timeupdate` del video maestro, añade siempre una guarda que valide el estado del buffer antes de forzar seeks:

```javascript
masterVideoEl.addEventListener('timeupdate', () => {
  if (currentMode === 'live' && previewVideoEl && !previewVideoEl.paused) {
    // GUARDA CRÍTICA: Solo sincronizar si el buffer ya tiene datos (readyState >= 2) y no está buscando
    if (hlsInstance && previewVideoEl.readyState >= 2 && !previewVideoEl.seeking) {
      const diff = masterVideoEl.currentTime - previewVideoEl.currentTime;
      const absDiff = Math.abs(diff);

      if (absDiff > 0.75) {
        // Desvío grande: salto puntual
        previewVideoEl.currentTime = masterVideoEl.currentTime;
        previewVideoEl.playbackRate = 1.0;
      } else if (absDiff > 0.05) {
        // Corrección suave continua por velocidad sin saltos
        previewVideoEl.playbackRate = diff > 0 ? 1.05 : 0.95;
      } else {
        previewVideoEl.playbackRate = 1.0;
      }
    }
  }
});
```

---

### Paso 4: Puntos de Retorno Intuitivos en la Interfaz (UX)

Garantiza al usuario al menos 3 formas inmediatas de regresar al directo:
1. **Pestaña Superior de Modo:** Pestañas claras `● Directo` y `🎬 Clip Grabado`.
2. **Botón Flotante Dinámico:** Botón `● Volver al Vivo` que se hace visible únicamente al estar en modo Clip.
3. **Toggle en la Tarjeta de Clip:** Si el usuario hace clic nuevamente sobre el clip que ya se está reproduciendo, conmuta automáticamente de regreso a la pantalla en vivo.

---

## 🛡️ Protocolo Anti-Regresión

1. **Gestión de Audio Dual:**
   - En modo Live, el video secundario debe forzarse a `muted = true` para evitar que el audio suene dos veces (eco).
   - En modo Clip, el video debe respetar la preferencia de mute del usuario.
2. **Guarda en `timeupdate` de Clips:**
   - Las funciones que actualizan subtítulos o barras de progreso de clips deben abortar inmediatamente si `mode !== 'clip'`:
     `if (currentMode !== 'clip') return;`
3. **Sincronización Dual de Placeholders (Anti-Pantalla Tapada Inicial):**
   - Cuando la app inicia en frío sin transmisión conectada y el usuario reproduce directamente un clip del búfer, `switchToClip` **debe ocultar obligatoriamente los placeholders de ambos paneles** (`videoPlaceholder.style.display = 'none'`, `phonePlaceholder.style.display = 'none'`) y activar ambos reproductores (`videoPlayer.style.display = 'block'`, `previewVideo.style.display = 'block'`). De lo contrario, el placeholder 16:9 ("Ningún directo conectado") se superpone sobre el video del clip.
   - Al conmutar de regreso a Live (`switchToLive`), si no hay transmisión activa (`!liveMediaUrl`), restaurar ambos placeholders (`display = 'flex'`) y ocultar los reproductores (`display = 'none'`).

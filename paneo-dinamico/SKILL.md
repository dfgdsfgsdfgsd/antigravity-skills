---
name: paneo-dinamico
description: Arquitectura de grabación, replay a 60 FPS y renderizado FFmpeg de trayectoria de encuadre manual (Modo Camarógrafo) con protocolo anti-bloqueo de archivos de video en Windows. Alias: /camara-manual, /paneo-camara
---

# /paneo-dinamico - Paneo Manual Continuo, Replay 60 FPS y Renderizado FFmpeg

Esta skill implementa la arquitectura integral de **paneo dinámico y encuadre manual continuo (Modo Camarógrafo)** para aplicaciones de video, streaming y creación de clips verticales (16:9 a 9:16). Permite registrar en tiempo real cada movimiento de ratón o control deslizante, guardarlo como trayectoria de cámara (`traj_<clip_id>.json`), reproducirlo fluidamente a 60 FPS sincronizado al reloj maestro del video y renderizarlo en MP4 final mediante expresiones dinámicas de FFmpeg, eliminando además los bloqueos de archivo en Windows (`EBUSY / EPERM`).

---

## 💻 Ficha Técnica y Compatibilidad

- **Stack Compatible:** Node.js, Electron, JavaScript (DOM / HTML5 Video), Python (FFmpeg wrapper).
- **Entorno de Ejecución:** Windows 10/11, macOS, Linux.
- **Requisitos Previos:**
  - Node.js 18+ y Electron.
  - Binario `ffmpeg` disponible en PATH o ruta local configurada.
  - Doble reproductor HTML5 (`videoPlayer` panorámico 16:9 y `previewVideo` vertical 9:16).

---

## 🛡️ Paso 0: Verificación de Entorno (Guarda de Seguridad)

Antes de aplicar esta arquitectura, verifica que el proyecto posea los componentes multimedia base:

```javascript
// Comprobar disponibilidad de APIs y elementos DOM requeridos
const isCompatible = (
  typeof window !== 'undefined' &&
  document.getElementById('videoPlayer') !== null &&
  document.getElementById('cropOverlay') !== null
);
if (!isCompatible) {
  console.warn('[paneo-dinamico] Se requiere un contenedor de video 16:9 y un overlay de encuadre interactivo.');
}
```

---

## 🚀 Arquitectura en 4 Capas

### 1. Muestreo y Registro Continuo de Trayectoria (Live Sampling)

Durante la transmisión en directo o la grabación manual, se muestrean las coordenadas de encuadre en píxeles reales de video cada 80ms:

```javascript
let liveCropHistory = []; // Array circular { time: number, crop_x: number }
let manualRecordStartMs = null;

function getRealVideoCropX() {
  if (state.cropX === null || state.cropX === undefined) return 0;
  const container = elements.canvasWrapper || elements.videoPlayer;
  const containerW = container.clientWidth || 640;
  const containerH = container.clientHeight || 360;
  const cropW = containerH * (9 / 16);
  const maxDomLeft = Math.max(1, containerW - cropW);

  const vidW = (elements.videoPlayer && elements.videoPlayer.videoWidth) || state.videoWidth || 1920;
  const vidH = (elements.videoPlayer && elements.videoPlayer.videoHeight) || state.videoHeight || 1080;
  const vidCropW = Math.round(vidH * (9 / 16));
  const maxVidLeft = Math.max(1, vidW - vidCropW);

  const ratio = Math.max(0, Math.min(1, state.cropX / maxDomLeft));
  return Math.round(ratio * maxVidLeft);
}

function recordCropSample() {
  const now = Date.now();
  const cx = getRealVideoCropX();
  liveCropHistory.push({ time: now, crop_x: cx });
  const cutoff = now - 180000; // Conservar últimos 3 minutos en buffer circular
  while (liveCropHistory.length > 0 && liveCropHistory[0].time < cutoff) {
    liveCropHistory.shift();
  }
}

// Muestreo cada 80ms durante el streaming en vivo
setInterval(() => {
  if (state.viewMode916 === "live") {
    recordCropSample();
  }
}, 80);
```

### 2. Extracción y Persistencia de la Trayectoria (`traj_<clip_id>.json`)

Al clipear con tecla rápida (F9) o finalizar grabación manual, se extraen las muestras correspondientes al rango temporal del clip:

```javascript
// Extraer muestras exactas del lapso del clip
const samples = liveCropHistory.filter(s => s.time >= (startRecMs - 200) && s.time <= (endRecMs + 200));
let keyframes = [];

if (samples.length > 0) {
  keyframes = samples.map(s => ({
    timestamp: Math.max(0, Math.round(((s.time - startRecMs) / 1000) * 100) / 100),
    crop_x: s.crop_x
  }));
} else {
  const curX = getRealVideoCropX();
  keyframes = [
    { timestamp: 0, crop_x: curX },
    { timestamp: Math.max(1, recordSeconds), crop_x: curX }
  ];
}

// Persistir en disco mediante IPC en Electron
await window.electronAPI.saveClipTrajectory(clip.clip_id, keyframes);
```

### 3. Replay a 60 FPS con Reloj Maestro y Filtro Steadicam

En la reproducción del clip, un bucle `requestAnimationFrame` interpola linealmente la posición de cámara con amortiguación exponencial (0.18):

```javascript
function getInterpolatedCropDomX(t) {
  const kfs = state.trackingKeyframes;
  if (!kfs || kfs.length === 0) return null;

  let videoCropX;
  if (t <= kfs[0].timestamp) {
    videoCropX = kfs[0].crop_x;
  } else if (t >= kfs[kfs.length - 1].timestamp) {
    videoCropX = kfs[kfs.length - 1].crop_x;
  } else {
    for (let i = 0; i < kfs.length - 1; i++) {
      const kf1 = kfs[i];
      const kf2 = kfs[i + 1];
      if (t >= kf1.timestamp && t <= kf2.timestamp) {
        const span = kf2.timestamp - kf1.timestamp;
        const p = span > 0 ? (t - kf1.timestamp) / span : 0;
        videoCropX = kf1.crop_x + (kf2.crop_x - kf1.crop_x) * p;
        break;
      }
    }
  }

  if (videoCropX === undefined) videoCropX = kfs[0].crop_x;

  const container = elements.canvasWrapper || elements.videoPlayer;
  const containerW = container.clientWidth || 640;
  const containerH = container.clientHeight || 360;
  const cropW = containerH * (9 / 16);
  const maxLeft = Math.max(0, containerW - cropW);

  const vidW = (elements.videoPlayer && elements.videoPlayer.videoWidth) || state.videoWidth || 1920;
  const vidH = (elements.videoPlayer && elements.videoPlayer.videoHeight) || state.videoHeight || 1080;
  const vidCropW = Math.round(vidH * (9 / 16));
  const maxVideoLeft = Math.max(1, vidW - vidCropW);

  const ratio = Math.max(0, Math.min(1, videoCropX / maxVideoLeft));
  return ratio * maxLeft;
}

function startTrackingAnimationLoop() {
  if (trackingAnimationRafId) cancelAnimationFrame(trackingAnimationRafId);

  function step() {
    if (state.viewMode916 === "clip" && elements.previewVideo) {
      // Reloj maestro tolerante: usar el reproductor que esté activo
      const master = (elements.videoPlayer && !elements.videoPlayer.paused && elements.videoPlayer.currentTime > 0)
        ? elements.videoPlayer
        : elements.previewVideo;
      const t = (master && !isNaN(master.currentTime)) ? master.currentTime : 0;

      // Sincronización continua de reproductores
      if (elements.videoPlayer && elements.previewVideo) {
        if (!elements.videoPlayer.paused && elements.previewVideo.paused) {
          elements.previewVideo.play().catch(() => {});
        }
        if (Math.abs(elements.previewVideo.currentTime - elements.videoPlayer.currentTime) > 0.15) {
          elements.previewVideo.currentTime = elements.videoPlayer.currentTime;
        }
      }

      // Animación suave de cámara a 60 FPS
      if (state.isTrackingActive && state.trackingKeyframes && state.trackingKeyframes.length > 0) {
        const targetDomX = getInterpolatedCropDomX(t);
        if (targetDomX !== null) {
          if (state.smoothedCropDomX === undefined || state.smoothedCropDomX === null) {
            state.smoothedCropDomX = targetDomX;
          } else {
            state.smoothedCropDomX += (targetDomX - state.smoothedCropDomX) * 0.18;
          }
          updateCropDisplay(state.smoothedCropDomX);
        }
      }

      trackingAnimationRafId = requestAnimationFrame(step);
    }
  }

  trackingAnimationRafId = requestAnimationFrame(step);
}
```

### 4. Renderizado Dinámico en FFmpeg (Expresión Anidada)

En Python (`video_renderer.py`), la trayectoria se traduce en una expresión de crop evaluada por frame:

```python
def build_crop_x_expr(keyframes, max_x):
    """
    Construye una expresion anidada de FFmpeg:
    clip(if(lt(t, t1), x0 + (x1-x0)*(t-t0)/(t1-t0), ...), 0, max_x)
    """
    if not keyframes or len(keyframes) == 0:
        return f"{max_x // 2}"
    if len(keyframes) == 1:
        return f"{int(keyframes[0].get('crop_x', max_x // 2))}"

    expr = f"{int(keyframes[-1].get('crop_x', max_x // 2))}"
    for i in range(len(keyframes) - 2, -1, -1):
        kf1 = keyframes[i]
        kf2 = keyframes[i + 1]
        t1 = float(kf1.get('timestamp', 0))
        t2 = float(kf2.get('timestamp', t1 + 0.1))
        x1 = float(kf1.get('crop_x', max_x // 2))
        x2 = float(kf2.get('crop_x', max_x // 2))
        dt = max(0.01, t2 - t1)
        slope = (x2 - x1) / dt

        interp = f"{x1:.1f}+({slope:.2f})*(t-{t1:.2f})"
        expr = f"if(lt(t,{t2:.2f}),{interp},{expr})"

    return f"clip({expr},0,{max_x})"
```

---

## 🛑 Protocolo Anti-Bloqueo de Video en Windows (`EBUSY / EPERM`)

En Windows, un archivo `.mp4` abierto en una etiqueta `<video>` o en un stream HTTP queda bloqueado por el kernel, impidiendo su eliminación o sobreescritura. Aplica obligatoriamente esta triple salvaguarda:

1. **Liberación del elemento `<video>` en el frontend antes de borrar:**
   ```javascript
   if (state.activeClipId === cid) {
     [elements.videoPlayer, elements.previewVideo].forEach(v => {
       if (v) {
         try {
           v.pause();
           v.removeAttribute("src");
           v.load(); // Fuerza al navegador a cerrar el handle de lectura
         } catch (_) {}
       }
     });
   }
   ```
2. **Auto-cierre del stream en el servidor HTTP de Node.js:**
   ```javascript
   const file = fs.createReadStream(filePath, { start, end });
   res.on('close', () => { file.destroy(); }); // Evita descriptores zombis retenidos
   file.pipe(res);
   ```
3. **Borrado Seguro con cambio de permisos y fallback forzado:**
   ```javascript
   const safeUnlink = (p) => {
     if (!fs.existsSync(p)) return true;
     try {
       fs.chmodSync(p, 0o666);
       fs.unlinkSync(p);
       return true;
     } catch (e) {
       try {
         if (process.platform === 'win32') {
           execSync(`del /f /q "${p}"`, { stdio: 'ignore' });
         }
         return true;
       } catch (err) {
         console.error(`[delete-clip] Error al eliminar ${p}:`, err.message);
         return false;
       }
     }
   };
   ```

---

## ⚠️ Protocolo Anti-Regresión

1. **`loadedmetadata` Trap:** Nunca invoques `centerCrop()` incondicionalmente en el evento `loadedmetadata`. Comprueba primero si el clip cargado posee trayectoria activa con movimiento para evitar que la animación quede cancelada en el centro.
2. **`cropWidth` Dinámico:** No inicialices `state.cropWidth` con números fijos arbitrarios (como `200`). Debe calcularse siempre en proporción estricta: `Math.round(vidH * (9 / 16))`.
3. **Muestreo en Modo Directo Exclusivo:** La función `recordCropSample()` solo debe almacenar coordenadas cuando `state.viewMode916 === "live"`, asegurando que la reproducción de clips nunca altere el búfer de muestras pasadas.

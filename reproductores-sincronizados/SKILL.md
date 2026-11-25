---
name: reproductores-sincronizados
description: Sincronización continua de reproductores duales de video HTML5 sin saltos ni efecto terremoto mediante modulación de playbackRate (Zero Seeks), auto-seguimiento facial Steadicam 60 FPS y bus unificado de Web Audio API. Alias: /dual-player-sync, /camara-autonoma, /sync-dual-video
---

# /reproductores-sincronizados - Sincronización Dual de Video (Zero Seeks), Cámara Autónoma Steadicam y Bus Web Audio

Esta skill se activa con `/reproductores-sincronizados` o sus alias [`/dual-player-sync`](../dual-player-sync/SKILL.md), [`/camara-autonoma`](../camara-autonoma/SKILL.md) y `/sync-dual-video`. Proporciona los patrones de ingeniería multimedia para:

1. **Sincronización Dual Fluida (Zero Seeks):** Elimina el "efecto terremoto", vibración y congelamientos en reproductores dobles de video HTML5 (ej: vista 16:9 y vista recortada 9:16).
2. **Auto-seguimiento Facial 60 FPS con Filtro Steadicam:** Panea suavemente el cuadro de encuadre siguiendo keyframes de IA sin tirones ni ruido de detección.
3. **Bus Maestro Unificado de Web Audio API:** Garantiza que los visualizadores de espectro (FFT, forma de onda podcast, matriz LED) reaccionen en tiempo real tanto en directo como en reproducción de clips sin provocar eco ni cancelación de audio.

---

## 🔍 Diagnóstico de las 3 Fallas Críticas

### 1. El "Efecto Terremoto" por Tormenta de Micro-Seeks
Cuando dos elementos `<video>` reproducen el mismo archivo o stream, tienen decodificadores independientes. Intentar forzar la sincronía en un bucle `requestAnimationFrame` mediante:
```javascript
// ❌ ERROR GRAVE: Provoca vibración y tartamudeo ("terremoto")
if (Math.abs(video1.currentTime - video2.currentTime) > 0.08) {
  video1.currentTime = video2.currentTime;
}
```
provoca que Chromium vacíe el buffer del decodificador, busque el fotograma clave y reinicie la reproducción de 10 a 20 veces por segundo. Para el usuario, la imagen tiembla y salta violentamente.

### 2. Zapateo y Ruido en Detección Facial
Los modelos de detección facial (OpenCV Haar Cascades, MediaPipe, etc.) analizan fotogramas a intervalos (ej: cada 0.5s) y presentan ligeras variaciones de coordenadas. La interpolación lineal pura transmite ese ruido al cuadro de recorte, produciendo saltitos molestos en el video vertical.

### 3. Espectro y Onda de Audio Planos por Muting
Para evitar eco entre los dos reproductores, suele silenciarse uno (`video1.muted = true`). Si el nodo `createMediaElementSource` de Web Audio API está conectado a ese video silenciado, el decodificador de Chromium corta el envío de muestras de audio al pipeline de JavaScript, dejando el analizador FFT y la onda en silencio absoluto (amplitud 0).

---

## 🛠️ Arquitectura de Solución en 3 Capas

### Capa 1: Sincronización por Compensación de Velocidad (Zero Seeks)

En lugar de saltar con `currentTime`, se modula sutilmente la tasa de reproducción (`playbackRate` entre 0.96x y 1.04x). El oído y ojo humano no notan una variación de ±4%, y los dos videos se alinean milimétricamente sin perder un solo fotograma:

```javascript
function syncDualPlayersSmooth(followerVideo, masterVideo) {
  if (!followerVideo || !masterVideo || masterVideo.paused) return;

  const tMaster = masterVideo.currentTime || 0;
  const tFollower = followerVideo.currentTime || 0;

  // 1. Detección de reinicio de bucle (Loop restart)
  if (tMaster < 0.25 && tFollower > 1.0) {
    followerVideo.currentTime = 0;
    followerVideo.playbackRate = 1.0;
    return;
  }

  const drift = tFollower - tMaster;

  // 2. Desajuste severo (>600ms): Solo aquí se permite seek directo
  if (Math.abs(drift) > 0.6) {
    if (!followerVideo.seeking) {
      try { followerVideo.currentTime = tMaster; } catch (_) {}
    }
    followerVideo.playbackRate = 1.0;
  } else if (drift < -0.04) {
    // Seguidor atrasado por >40ms: acelerar 4% suavemente
    followerVideo.playbackRate = 1.04;
  } else if (drift > 0.04) {
    // Seguidor adelantado por >40ms: desacelerar 4% suavemente
    followerVideo.playbackRate = 0.96;
  } else {
    // En sincronía perfecta (±40ms): velocidad normal
    if (followerVideo.playbackRate !== 1.0) {
      followerVideo.playbackRate = 1.0;
    }
  }
}
```

---

### Capa 2: Movimiento Autónomo con Filtro Steadicam (EMA)

Para que el encuadre 9:16 se mueva de forma fluida a 60 FPS, se combina interpolación temporal lineal con amortiguación exponencial (EMA):

```javascript
let smoothedCropDomX = null;

function animateTrackingCrop(currentTime, keyframes, updateCropCallback) {
  if (!keyframes || keyframes.length === 0) return;

  const rawDomX = getInterpolatedKeyframeX(currentTime, keyframes);
  if (rawDomX === null) return;

  // Filtro de amortiguación exponencial (Efecto Steadicam / Gimbal)
  if (smoothedCropDomX === null) {
    smoothedCropDomX = rawDomX;
  } else {
    smoothedCropDomX += (rawDomX - smoothedCropDomX) * 0.18; // Factor alfa 0.18
  }

  updateCropCallback(smoothedCropDomX);
}
```

#### Optimización GPU en CSS:
El cuadro de recorte interactivo debe contar con su propia capa de composición GPU para evitar repintados del video:

```css
.crop-overlay-box {
  transform: translateZ(0);
  will-change: left;
  backface-visibility: hidden;
}
```

---

### Capa 3: Enrutamiento Maestro de Audio sin Duplicación

Para que los visualizadores sigan bailando y no exista eco:
1. **Reproductor Maestro (`videoPlayer`):** Emite el audio tanto para los altavoces como para el analizador Web Audio API (`muted = false`).
2. **Reproductor Seguidor (`previewVideo`):** Permanece permanentemente en `muted = true`.
3. **Control de Mute:** Al silenciar el audio, se muta el reproductor maestro o su nodo `masterGain`, pero nunca se conmuta la fuente del analizador:

```javascript
function setupMasterAudioPipeline(masterVideo, followerVideo, analyserNode, masterGain) {
  // Maestro emite audio
  masterVideo.muted = false;
  // Seguidor 100% silenciado (cero eco)
  followerVideo.muted = true;

  // El botón de mute actúa sobre el bus maestro
  btnMute.addEventListener("click", () => {
    masterVideo.muted = !masterVideo.muted;
    btnMute.textContent = masterVideo.muted ? "🔇 Silenciado" : "🔊 Con Sonido";
  });
}
```

---

## 🛡️ Checklist Anti-Regresión
- [x] Nunca ejecutar `video.currentTime = t` repetidamente en bucles `requestAnimationFrame` si la diferencia es menor a 0.5s.
- [x] Modula `playbackRate` con variaciones menores a ±5% (1.04x / 0.96x).
- [x] Al cambiar entre vivo y clips, resetea siempre `smoothedCropDomX = null` para evitar transiciones de arrastre fantasma.
- [x] Agrega `transform: translateZ(0)` al recuadro de encuadre en CSS.
- [x] Alimenta el `AudioContext` siempre desde el reproductor con audio activo (`muted = false`).

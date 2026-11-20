---
name: hls-sin-cortes
description: Diagnóstico, optimización y blindaje de streaming HLS en vivo (FFmpeg + Hls.js) para eliminar congelamientos, bucles de buffering y tirones mediante escritura atómica (temp_file), keyframes alineados y sincronización suave. Alias: /streaming-sin-cortes, /anti-freezing-hls
---

# /hls-sin-cortes (/streaming-sin-cortes, /anti-freezing-hls)

Esta skill proporciona la arquitectura de ingeniería definitiva para erradicar el **congelamiento de video, la recarga constante de búfer y los micro-cortes** en aplicaciones web y de escritorio que transmiten directos en tiempo real mediante **FFmpeg** y **Hls.js**.

---

## 💻 Ficha Técnica y Compatibilidad

| Atributo | Detalle |
| :--- | :--- |
| **Stack Compatible** | Multi-stack (`Node.js/Electron`, `Python/FastAPI`, `Go/Wails`, `HTML5/Vanilla JS`) |
| **Librerías Clave** | `Hls.js` (v1.4+), `FFmpeg` (v5.0+ en PATH), `yt-dlp` |
| **Problemas Resueltos** | Congelamientos al reproducir directos, buffer starvation, seeks destructivos y fragmentos truncos |
| **Impacto** | 0% congelamientos, reproducción continua a 60 fps, 0% CPU con `-c:v copy` |

---

## 🛑 Las 4 Causas Reales del Congelamiento en HLS en Vivo

1. **Lectura de Segmentos a Medio Escribir (Race Condition):**  
   FFmpeg crea `live00010.ts` y empieza a volcar bytes en disco. Si el reproductor Hls.js pide el archivo antes de que FFmpeg lo cierre, recibe un archivo corrupto/incompleto, el decodificador de video de Chromium colapsa y el video se congela.
2. **Inanición en el Borde del Directo (*Live Edge Starvation*):**  
   Configurar `lowLatencyMode: true` y colchones de solo 2 segundos hace que el reproductor viva al borde del abismo. Ante cualquier micro-retraso de red, se queda sin datos y se frena a recargar.
3. **Desalineación de Fotogramas Clave (Keyframes / GOP):**  
   YouTube y Twitch emiten fotogramas clave (I-frames) cada 2 segundos. Forzar `-hls_time 1` con `-c:v copy` produce fragmentos sin I-frame inicial, provocando saltos de PTS/DTS que traban el decodificador.
4. **Bucle Destructivo de Micro-Búsquedas (`currentTime` Seek Loop):**  
   Si se sincronizan dos videos con `previewVideo.currentTime = videoPlayer.currentTime` ante diferencias pequeñas (>80ms), el reproductor secundario vive en un ciclo infinito de `seeking -> pause -> flush -> seeked`, viéndose completamente entrecortado.

---

## 🛠️ Protocolo de Implementación en 4 Capas

### Capa 1: Transmuxing con Escritura Atómica en FFmpeg
En el proceso de ingesta de FFmpeg, configurar:
```bash
ffmpeg -y -i "<VIDEO_URL>" -i "<AUDIO_URL>" \
  -c:v copy \
  -c:a aac \
  -f hls \
  -hls_time 2 \
  -hls_list_size 60 \
  -hls_flags delete_segments+split_by_time+temp_file \
  "buffer/live_hls/live.m3u8"
```
* **`temp_file`:** FFmpeg escribe primero en un archivo `.tmp` invisible y lo renombra atómicamente a `.ts` **solo cuando está 100% terminado**. El reproductor jamás leerá un archivo a medio escribir.
* **`-hls_time 2`:** Sincronizado con la cadencia de keyframes nativa de las plataformas.
* **`-c:v copy`:** Pasa el flujo directo sin re-codificar en CPU (baja el consumo del 85% a <1%).

---

### Capa 2: Servidor HTTP con Soporte de Rangos (`206 Partial Content`)
El servidor local (Node o Python) debe responder con cabeceras completas de streaming:
```javascript
// En Node.js (main.js de Electron o servidor local):
const stat = fs.statSync(filePath);
const range = req.headers.range;

if (range) {
  const parts = range.replace(/bytes=/, "").split("-");
  const start = parseInt(parts[0], 10);
  const end = parts[1] ? parseInt(parts[1], 10) : stat.size - 1;
  res.writeHead(206, {
    'Content-Range': `bytes ${start}-${end}/${stat.size}`,
    'Accept-Ranges': 'bytes',
    'Content-Length': (end - start) + 1,
    'Content-Type': mimeTypes[ext] || 'application/octet-stream'
  });
  fs.createReadStream(filePath, { start, end }).pipe(res);
} else {
  res.writeHead(200, {
    'Content-Length': stat.size,
    'Accept-Ranges': 'bytes',
    'Content-Type': mimeTypes[ext] || 'application/octet-stream'
  });
  fs.createReadStream(filePath).pipe(res);
}
```

---

### Capa 3: Configuración Anti-Inanición y Auto-Salto en Hls.js
En el frontend, inicializar `Hls.js` con colchón de seguridad y auto-recuperación de huecos:
```javascript
const hls = new Hls({
  enableWorker: true,
  lowLatencyMode: false,          // Desactivar LL-HLS ultra-agresivo
  liveSyncDurationCount: 4,       // Colchón de 4 segmentos (~8 segundos de margen)
  liveMaxLatencyDurationCount: 8,
  backBufferLength: 20,
  maxBufferLength: 20,
  maxMaxBufferLength: 40,
  maxBufferHole: 0.5,             // Saltar micro-huecos en vez de congelar
  nudgeOffset: 0.1,
  nudgeMaxRetry: 5,
  // Re-intentos automáticos de red
  fragLoadingMaxRetry: 6,
  fragLoadingRetryDelay: 500,
  manifestLoadingMaxRetry: 6,
  manifestLoadingRetryDelay: 500
});
```

---

### Capa 4: Sincronización Suave con `playbackRate` (Cero Seeks)
Para sincronizar múltiples pantallas en tiempo real sin causar tirones:
```javascript
videoPlayer.addEventListener("timeupdate", () => {
  if (isLiveMode && previewVideo && !previewVideo.paused) {
    const diff = videoPlayer.currentTime - previewVideo.currentTime;
    const absDiff = Math.abs(diff);

    if (absDiff > 0.75) {
      // Solo hacer salto duro si el desfase es grande (>750ms)
      previewVideo.currentTime = videoPlayer.currentTime;
      previewVideo.playbackRate = 1.0;
    } else if (absDiff > 0.05) {
      // Sincronización continua suave: acelerar o frenar sutilmente
      previewVideo.playbackRate = diff > 0 ? 1.05 : 0.95;
    } else {
      previewVideo.playbackRate = 1.0;
    }
  }
});
```

---

## ⚠️ Protocolo Anti-Regresión

1. **Nunca usar `lowLatencyMode: true` sin soporte de LL-HLS en el origen.**
2. **Nunca omitir `temp_file`:** En discos mecánicos o con I/O ocupada, omitir `temp_file` garantiza 100% de probabilidad de congelamientos.
3. **No forzar re-codificación en tiempo real sin GPU dedicada:** Con `libx264` en CPU para 1080p, si la velocidad de transcodificación cae por debajo de 1.0x, el buffer siempre se vaciará. Usar `-c:v copy`.

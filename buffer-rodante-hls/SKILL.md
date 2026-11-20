---
name: buffer-rodante-hls
description: Arquitectura y motor de streaming local en buffer rodante HLS con FFmpeg para sincronización a 0ms entre múltiples reproductores y recorte de clips en 0.2s sin re-codificación. Alias: /hls-rodante, /stream-sincronizado
---

# /buffer-rodante-hls (/hls-rodante, /stream-sincronizado)

Esta skill se activa cuando:
- El usuario escribe: **`/buffer-rodante-hls`**, **`/hls-rodante`**, **`/stream-sincronizado`**.
- O cuando se requiere capturar transmisiones en vivo (YouTube Live, Twitch, Kick) sincronizando múltiples pantallas (16:9 y 9:16) con **0 ms de retraso** y cortando clips en caliente sin sobrecargar CPU o disco.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Stack compatible:** Multi-stack (`Python/FastAPI`, `Node.js/Electron`, `Rust/Tauri`, `Go/Wails`).
- **Frontend compatible:** HTML5 `<video>`, `Hls.js`, WebGL.
- **Binarios necesarios:**
  - `ffmpeg` (versión 5.0+ en PATH)
  - `yt-dlp` (para resolución de directos en streaming)

---

## 🛑 El Problema Técnico que Resuelve

1. **Desincronización de Reproductores (1 a 2 segundos):**
   Al incrustar dos iframes o reproductores consumiendo directamente de internet, cada uno crea su propio buffer de red independiente, generando un desfase visual molesto entre la vista panorámica y el recorte vertical móvil.
2. **Cuelgues al Capturar Clips con `-sseof`:**
   En directos remotos de varias horas, pasar `-sseof -30` a FFmpeg sobre una URL remota obliga a leer metadatos de horas de transmisión, demorando hasta 30 segundos o provocando time-outs.
3. **Saturación de Disco y CPU:**
   Grabar un directo completo sin rotación puede llenar gigabytes de disco y llevar la CPU al 100%.

---

## 🛠️ Arquitectura y Procedimiento en 5 Pasos

### Paso 1: Extracción del Stream con yt-dlp
Extraer URLs directas de video y audio en máxima calidad:
```python
ydl_opts = {'format': 'bestvideo+bestaudio/best', 'quiet': True, 'no_warnings': True}
with yt_dlp.YoutubeDL(ydl_opts) as ydl:
    info = ydl.extract_info(stream_url, download=False)
    # Extrae requested_formats[0] (video) y requested_formats[1] (audio)
```

### Paso 2: Ingesta en Buffer Rodante HLS Ultrarrápido (Escritura Atómica con temp_file)
Ejecutar un único subproceso FFmpeg de fondo con eliminación automática y copia directa de flujo (-c:v copy) a 0% CPU:
```bash
ffmpeg -y \
  -i "<VIDEO_URL>" \
  -i "<AUDIO_URL>" \
  -c:v copy -c:a aac \
  -f hls \
  -hls_time 2 \
  -hls_list_size 60 \
  -hls_flags delete_segments+split_by_time+temp_file \
  "buffer/live_hls/live.m3u8"
```
* **Escritura Atómica (`temp_file`):** FFmpeg escribe en un archivo `.tmp` y lo renombra solo al finalizar, evitando que el reproductor lea fragmentos truncos y se congele.
* **Alineación de Keyframes (`-hls_time 2`):** Sincronizado con la cadencia de I-frames nativa de YouTube/Twitch (2s).
* **0% de Consumo CPU:** `-c:v copy` evita transcodificar en CPU, produciendo fragmentos en 10ms.

### Paso 3: Servidor HTTP Local con Soporte de Rangos (206 Partial Content)
Exponer el directorio `buffer/live_hls/` con cabeceras `Accept-Ranges: bytes` y `Content-Length` exactas para evitar que el pipeline de video de Chromium se vacíe.

### Paso 4: Reproducción Sincronizada y Reloj Maestro en Frontend (Cero Seeks)
Ambos reproductores HTML5 (`#videoPlayer` y `#previewVideo`) se conectan a la misma fuente HLS local con colchón de seguridad:
```javascript
const hls = new Hls({
  enableWorker: true,
  lowLatencyMode: false,
  liveSyncDurationCount: 4,
  liveMaxLatencyDurationCount: 8,
  backBufferLength: 20,
  maxBufferHole: 0.5,
  nudgeOffset: 0.1
});

// Sincronizador Suave mediante velocidad (Cero Saltos / Seeks destructivos)
videoPlayer.addEventListener("timeupdate", () => {
  if (isLiveMode && previewVideo && !previewVideo.paused) {
    const diff = videoPlayer.currentTime - previewVideo.currentTime;
    const absDiff = Math.abs(diff);

    if (absDiff > 0.75) {
      previewVideo.currentTime = videoPlayer.currentTime;
      previewVideo.playbackRate = 1.0;
    } else if (absDiff > 0.05) {
      previewVideo.playbackRate = diff > 0 ? 1.05 : 0.95;
    } else {
      previewVideo.playbackRate = 1.0;
    }
  }
});
```

### Paso 5: Clipping Instantáneo en ~0.2 Segundos (Stream Copy Concat)
Al pulsar **F9** o detener grabación manual:
1. Listar los archivos locales `.ts` generados en `buffer/live_hls/` ordenados por fecha.
2. Seleccionar los últimos $N$ segmentos según los segundos requeridos (ej. 30 segmentos para 30 s).
3. Escribir lista temporal `concat.txt`:
   ```
   file 'D:/vivo/buffer/live_hls/live120.ts'
   file 'D:/vivo/buffer/live_hls/live121.ts'
   ...
   ```
4. Concatenar en milisegundos sin re-codificar:
   ```bash
   ffmpeg -y -f concat -safe 0 -i concat.txt -c copy clip_timestamp.mp4
   ```
5. Generar miniatura en 1 frame:
   ```bash
   ffmpeg -y -i clip_timestamp.mp4 -ss 00:00:01 -vframes 1 -q:v 2 thumb_timestamp.jpg
   ```

---

## 🛡️ Protocolo Anti-Regresión

1. **Limpieza Previa:** Antes de arrancar un nuevo directo, terminar el proceso FFmpeg anterior y vaciar la carpeta `live_hls/` para evitar que fragmentos viejos corrompan la nueva lista de reproducción.
2. **Espera de Generación:** Al iniciar la conexión, aguardar 2 a 3 segundos hasta que `live.m3u8` tenga al menos 1 fragmento antes de responder al frontend.
3. **Persistencia del Monitor:** Al reproducir un clip en el móvil vertical, el reproductor panorámico izquierdo **nunca debe detenerse** para que el usuario no pierda el hilo del directo en vivo.

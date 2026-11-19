---
name: clipping-en-vivo
description: Arquitectura y motor para clipping en caliente de streams en directo (YouTube, Twitch, Kick) con hotkey F9, reencuadre 9:16 con Face Tracking, subtítulos dinámicos y copys virales con IA. Alias: /subiclip-live, /clip-caliente
---

# /clipping-en-vivo - Suite de Clipping en Caliente con IA

Esta skill permite generar, auditar o desplegar una plataforma completa de **clipping en tiempo real para transmisiones en vivo**, inspirada en la arquitectura de herramientas como SubiClip. Permite capturar momentos virales con un atajo de teclado (`F9`) mientras el directo está ocurriendo, reencuadrarlos a formato vertical 9:16 siguiendo el rostro de los hablantes, transcribir el audio a subtítulos dinámicos y generar copys virales listos para publicar en TikTok, Reels y Shorts.

---

## 💻 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** `Python 3.10+ | FFmpeg | FastAPI / Uvicorn | Frontend Web`
- **Binarios Requeridos:**
  - `python` en PATH con soporte pip.
  - `ffmpeg` y `ffprobe` en PATH (indispensables para corte HLS y renderizado 9:16).
- **Librerías Python:** `fastapi`, `uvicorn`, `yt-dlp`, `opencv-python`, `numpy`, `faster-whisper`, `requests`.

---

## 🛡️ Paso 0: Verificación de Entorno (Guarda de Seguridad)

Antes de ejecutar o desplegar la suite, verifica los requisitos en PowerShell:

```powershell
# 1. Verificar Python
python --version
if ($LASTEXITCODE -ne 0) { throw "Python no detectado en el PATH." }

# 2. Verificar FFmpeg
ffmpeg -version
if ($LASTEXITCODE -ne 0) { throw "FFmpeg no detectado en el PATH." }

# 3. Comprobar o instalar dependencias de Python
python -m pip install -q fastapi uvicorn yt-dlp opencv-python numpy faster-whisper requests
```

---

## 🛠️ Arquitectura y Procedimiento Paso a Paso

### 1. Conexión a Streams en Vivo sin Error de Formato (YouTube / Twitch / Kick)
Para evitar el error común `Requested format is not available` en YouTube Live (donde las transmisiones emiten en HLS con audio y video separados):

```python
import yt_dlp

ydl_opts = {
    'format': 'bestvideo+bestaudio/best',  # Crucial para streams HLS separados
    'quiet': True,
    'no_warnings': True
}

with yt_dlp.YoutubeDL(ydl_opts) as ydl:
    info = ydl.extract_info(stream_url, download=False)
    # Si devuelve requested_formats, se separan video y audio
    req_fmts = info.get('requested_formats')
    if req_fmts and len(req_fmts) >= 2:
        video_url = req_fmts[0]['url']
        audio_url = req_fmts[1]['url']
    else:
        video_url = info.get('url')
        audio_url = None
```

### 2. Captura Instantánea en Caliente (Hotkey `F9` y Buffer Rodante)
Al presionar `F9`, el motor extrae los últimos $N$ segundos (ej. 30s) sin esperar a que termine el directo:

```python
# Con streams separados de audio y video
cmd = [
    "ffmpeg", "-y",
    "-sseof", f"-{duration_sec}", "-i", video_url,
    "-sseof", f"-{duration_sec}", "-i", audio_url,
    "-t", str(duration_sec),
    "-c:v", "libx264", "-preset", "ultrafast",
    "-c:a", "aac",
    clip_output_path
]
subprocess.run(cmd, check=True)
```

### 3. Auto-Reframe 9:16 con Seguimiento Facial Suavizado
Para reencuadrar el video horizontal (16:9) al formato vertical (9:16):
- Se analiza el video muestreando cada 0.5s.
- Se detecta el rostro o sujeto en movimiento principal.
- Se aplica un **filtro exponencial (smoothing)** para evitar saltos bruscos de cámara:
  $$\text{center}_{t} = \alpha \cdot \text{raw\_center} + (1 - \alpha) \cdot \text{center}_{t-1}$$
- Se limita el encuadre para que jamás se salga de los bordes del video original.

### 4. Subtítulos Dinámicos y Transcripción
- Se procesa el clip con `faster-whisper` (`WhisperModel("tiny", device="cpu", compute_type="int8")`) con `word_timestamps=True`.
- En el frontend, se sincroniza el `<video>` con el evento `timeupdate` para iluminar la palabra activa estilo TikTok/Hormozi.

### 5. Copys Virales y Metadatos con Diversidad Obligatoria
- Genera Título viral, Hook, Descripción y Hashtags.
- **Regla estricta:** Variar emojis iniciales (`🔥`, `⚡`, `🎯`, `💡`, `🤯`, `👑`, `🚨`) y emojis de footer (`💬`, `🚀`, `📌`, `👀`, `✨`), sin repetir nunca el mismo emoji de forma consecutiva.
- Incluir botón **"Copiar Todo"** para pegar en 1 clic en TikTok / Reels.

### 6. Renderizado Vertical Acelerado
Renderizado a 1080x1920 con FFmpeg:
```bash
ffmpeg -y -i input.mp4 -vf "crop=W_CROP:H_CROP:X_OFFSET:0,scale=1080:1920:flags=bicubic,drawtext=text='GANCHO':fontsize=52:fontcolor=yellow:box=1:boxcolor=black@0.75:x=(w-text_w)/2:y=180" -c:v libx264 -preset veryfast -crf 22 -c:a aac -threads 4 output_reel.mp4
```

### 7. Lanzador Blindado (`iniciar.bat`)
- Codificación UTF-8 (`chcp 65001 >nul`).
- Saltos de línea CRLF obligatorios.
- Apertura no-bloqueante del navegador (`start "" "http://localhost:8505"`).
- Uso de puertos no conflictivos (ej. `8505` para evitar zombies en `8000`).

---

## 🚫 Protocolo Anti-Regresión y Trampas Resueltas

1. **Error `Requested format is not available` en YouTube:** Usar siempre `format='bestvideo+bestaudio/best'` y gestionar la lista `requested_formats` de yt-dlp.
2. **Pantalla negra en frontend:** Evitar reproductores `<video>` vacíos sin feedback visual; usar placeholders interactivos y reproducir con `muted=true` inicial para cumplir políticas de autoplay de navegadores.
3. **Bloqueo CORS de Google Video:** Para streams en vivo de YouTube en el visor web, incrustar el reproductor oficial (`<iframe src="https://www.youtube.com/embed/ID?autoplay=1&mute=1">`) mientras el backend procesa el m3u8 con FFmpeg.
4. **Saturación de CPU:** Limitar siempre los hilos de FFmpeg (`-threads 4`) y usar el modelo `tiny` o `base` cuantizado (`int8`) en Whisper.

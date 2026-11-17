---
name: suite-reels
description: Arquitectura, integración y persistencia para suites de creación de Reels y podcasts: combina transcripción semántica (Whisper/Vosk/Gemini), corte de silencios (Jump Cuts), subtítulos dinámicos palabra por palabra estilo TikTok/Hormozi y editor visual de plantillas 9:16 sobre FastAPI. Alias: /suite-reels-ia, /unificar-reels
---

# /suite-reels - Suite Integral de Reels: Detección Semántica, Jump Cuts, Subtítulos Dinámicos y Editor Visual 9:16

Esta skill proporciona la arquitectura de referencia, protocolos de persistencia, integración de endpoints y pautas anti-regresión para unificar herramientas de creación de Reels (detección de mejores momentos en podcasts + recorte inteligente de silencios + subtítulos animados palabra por palabra + diseño en plantillas visuales con canvas 9:16).

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** Python (FastAPI, Uvicorn, Faster-Whisper, Vosk, Gemini API, Pillow) + FFmpeg + Frontend Web (Canvas 9:16, HTML5 Video, XHR).
- **Requisitos previos:**
  - `python` 3.9 o superior.
  - `ffmpeg` y `ffprobe` disponibles en el `PATH` del sistema.
  - Navegador web moderno (Chromium, Firefox, Edge).
- **Entorno objetivo:** Windows PowerShell, Linux y macOS.

---

## 🛡️ Paso 0: Verificación de Entorno (Guarda de Seguridad)

Antes de iniciar o generar el código, verificar que el entorno cumpla los requisitos multimedia y de Python:

```powershell
python --version
ffmpeg -version
ffprobe -version
```

> **Aviso de fallback:** Si no está instalado `ffmpeg`, instalarlo en Windows con `winget install Gyan.FFmpeg`. Si falta alguna librería de Python, instalar mediante `pip install fastapi uvicorn pillow vosk faster-whisper requests python-multipart`.

---

## 🏗️ Arquitectura de la Suite Unificada

Una suite modular integra ambos mundos (análisis semántico y edición visual de video) bajo una única instancia de servidor FastAPI en el puerto 8000:

```
suite-reels-ia/
├── app.py                 # API REST FastAPI unificada, orquestación y rutas UI
├── requirements.txt       # Dependencias mínimas del servidor
├── iniciar.bat            # Lanzador de 1-clic interactivo no-bloqueante
├── core/                  # Motor de extracción de clips, audio y subtítulos
│   ├── audio.py           # Extracción WAV mono 16kHz optimizado para voz
│   ├── silence.py         # Recorte inteligente de silencios (Jump Cuts con FFmpeg)
│   ├── transcriber.py     # Transcripción dual: Faster-Whisper (puntuación y timestamps) o Vosk offline
│   ├── curator.py         # Algoritmo de detección de ganchos virales por semántica
│   ├── reframe.py         # Recorte inteligente y render 9:16 (blur background / center crop)
│   └── subtitles.py       # Generador de subtítulos dinámicos .ass (estilo TikTok / Hormozi)
├── engine/                # Motor de plantillas visuales
│   └── canvas_renderer.py # Renderizador headless de plantillas Pillow + FFmpeg
├── uploads/               # Almacén de videos de entrada y projects_db.json
├── exports/               # Reels terminados listos para descarga
└── static/                # Módulos frontend independientes
    ├── podcast/           # Módulo 1: Extractor de clips con simulador móvil 9:16 y subtítulos en vivo
    │   ├── index.html
    │   └── app.js
    └── editor/            # Módulo 2: Editor interactivo de plantillas visuales
        ├── index.html
        ├── style.css
        └── app.js
```

---

## ⚙️ Protocolos y Patrones Técnicos Clave

### 1. Subtítulos Dinámicos Karaoke Palabra por Palabra (Estilo TikTok / Hormozi) vs. Estáticos
Permite previsualizar en vivo en el simulador móvil y quemar con calidad tipográfica profesional en el video 9:16:
- **Estructura ASS de alto impacto (`core/subtitles.py`):**
  - Resolución nativa `PlayResX: 1080`, `PlayResY: 1920`.
  - Estilo `ReelStyle` (`Arial Black`, 58px, centrado abajo `Alignment: 2`, `MarginV: 420` para safe area de Reels, borde negro 6px y sombra 3D).
  - **Modo Dinámico Palabra por Palabra:** Agrupa en bloques de 3 a 4 palabras. Cada palabra activa emite un evento `Dialogue` con tags `{\c<COLOR>&\fscx115\fscy115}<PALABRA>{\r}` (color y escala 115%), mientras las demás permanecen en blanco. Para evitar parpadeos, extiende el fin de la palabra activa hasta el inicio de la siguiente si la pausa es menor a 0.35s.
  - **Modo Dinámico Rápido:** Ráfagas cortas de 2 a 3 palabras.
  - **Modo Estático Clásico:** Frases u oraciones completas estándar.
  - **Paleta de Colores en formato BGR:** Amarillo Neón (`&H0000FFFF&`), Verde Neón (`&H0033FF55&`), Cian Eléctrico (`&H00FFFF00&`), Rosa Neón (`&H00FF33FF&`), Blanco Puro (`&H00FFFFFF&`).
- **Sincronización en Vivo en el Simulador (`app.js`):**
  - Guarda `currentTranscript` con timestamps individuales (`words`).
  - Al avanzar el reproductor en `timeupdate` o mover la barra `clipSeeker`, ejecuta `renderLiveSubtitles(currentTime)` actualizando dinámicamente el HTML del contenedor `#phone-sub-overlay` con clases `.sub-word` y `.sub-word-active` (`transform: scale(1.22)` y glow de color).
- **Escape Seguro de Rutas FFmpeg en Windows:**
  - Los filtros de FFmpeg interpretan los dos puntos (`:`) como separadores de opciones, rompiendo rutas como `D:\...`.
  - Solución obligatoria: Pasar rutas relativas para el filtro (`ass='exports/sub.ass'`) y definir `cwd=BASE_DIR` en `subprocess.run()`.

### 2. Recorte Inteligente de Silencios (Jump Cuts con FFmpeg)
Condensa podcasts y entrevistas eliminando tiempos muertos y respiraciones largas sin acelerar la voz:
- Detección precisa de pausas usando el filtro `silencedetect=noise=-25dB:d=0.35`.
- Cálculo de intervalos audibles con margen de protección (`padding = 0.08s`) en cada corte para asegurar que no se coman consonantes iniciales ni finales.
- Generación de lista de concatenación (`concat demuxer`) o extracción directa con FFmpeg.
- Opción de previsualización en el simulador: botón *"Escuchar este clip SIN silencios"* que genera un preview instantáneo para validar la naturalidad del diálogo antes de renderizar.

### 3. Motor Dual de Transcripción (Faster-Whisper + Vosk)
- **OpenAI Whisper (vía Faster-Whisper `tiny` o `base`):**
  - Entrega puntuación perfecta (signos `¿?`, `¡!`, comas y mayúsculas) y marcas de tiempo palabra por palabra.
  - Requiere inicialización con `compute_type="int8"` y `device="cpu"` para máxima portabilidad sin GPU dedicada.
- **Vosk Offline:**
  - Alternativa 100% local, ligera y de latencia ultra baja para equipos con hardware limitado.
- **Telemetría en tiempo real:**
  - Ambas opciones reportan progreso porcentual a través de `progress_callback` sincronizado con la barra visual de la interfaz.

### 4. Persistencia de Proyectos (`projects_db.json` + `localStorage`)
Evita la pérdida de datos cuando el usuario recarga la página o navega entre pestañas:
- **En Backend (`app.py`):** Guardar cada video subido, transcripción y clips analizados en `uploads/projects_db.json`. Al iniciar el servidor, auto-indexar cualquier archivo presente en `uploads/`.
- **En Frontend (`app.js`):**
  - Recordar el ID activo en `localStorage.setItem('suite_last_active_project_id', id)`.
  - Conectar el botón de regreso hacia el podcast pasando el query param: `/?video_id=${id}`.
  - Ofrecer un dropdown de **"Historial de Videos"** para alternar entre proyectos y un botón **"+ Subir Otro Video"** para resetear el estado sin perder el historial guardado.

### 5. Flujo de Revisión de Clips con Checklist (`[✓] Revisado`)
- Cada tarjeta de clip detectado cuenta con un botón de selección (`[✓] Revisado`) y un botón de previsualización en el simulador vertical.
- Una barra flotante muestra la cantidad de clips marcados (`"X seleccionados"`), con opción de marcar/desmarcar todos y transferirlos masivamente al editor mediante `localStorage['suite_incoming_clips']`.

### 6. Audio Desmuteado en el Editor
- En el reproductor de video HTML5 del editor de plantillas, asegurar que `video.muted = false` y `video.volume = 1.0` en cada cambio de escena o reproducción.

### 7. Prevención de Desarmado de CSS en Rutas Estáticas
- En `static/editor/index.html`, declarar siempre `<base href="/editor/">` en el `<head>` y utilizar rutas con versión (`/editor/style.css?v=...`).
- En FastAPI, declarar explícitamente `@app.get("/editor")` y `@app.get("/editor/")` devolviendo `FileResponse(EDITOR_STATIC / "index.html")` además del `app.mount("/editor", StaticFiles(...))`.

---

## 🛑 Protocolo Anti-Regresión

1. **No bloquear el Event Loop de FastAPI:** Las funciones pesadas que ejecutan FFmpeg, Whisper o Vosk deben declararse como `def` síncronas en FastAPI (para que corran en un threadpool worker) o mediante tareas de fondo (`BackgroundTasks`), nunca en `async def` bloqueando el loop de peticiones.
2. **Audio Mono a 16kHz para Speech Recognition:** Los motores acústicos de voz requieren PCM 16kHz mono sin compresión para máxima precisión de transcripción y timestamps.
3. **Manejo de Rutas en Windows FFmpeg:** Nunca inyectar rutas absolutas con letras de disco (`C:\`, `D:\`) dentro de la cadena `-filter_complex` o `-vf ass=...`. Usar siempre rutas relativas a la carpeta raíz del proceso.
4. **Manejo de CORS y Rutas Cruzadas:** Permitir `CORSMiddleware` en FastAPI para evitar bloqueos al servir videos desde `/uploads` y `/exports`.

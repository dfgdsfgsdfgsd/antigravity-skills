---
name: suite-reels
description: Arquitectura, integración y persistencia para suites de creación de Reels y podcasts: combina transcripción semántica con Vosk/Gemini y editor visual de plantillas 9:16 sobre FastAPI. Alias: /suite-reels-ia, /unificar-reels
---

# /suite-reels - Suite Integral de Reels: Detección Semántica + Editor Visual 9:16

Esta skill proporciona la arquitectura de referencia, protocolos de persistencia, integración de endpoints y pautas anti-regresión para unificar herramientas de creación de Reels (detección de mejores momentos en podcasts + diseño en plantillas visuales con canvas 9:16).

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** Python (FastAPI, Uvicorn, Pillow, Vosk/Gemini) + FFmpeg + Frontend Web (Canvas 9:16, HTML5 Video, XHR).
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

> **Aviso de fallback:** Si no está instalado `ffmpeg`, instalarlo en Windows con `winget install Gyan.FFmpeg`. Si falta alguna librería de Python, instalar mediante `pip install fastapi uvicorn pillow vosk requests python-multipart`.

---

## 🏗️ Arquitectura de la Suite Unificada

Una suite modular integra ambos mundos (análisis semántico y edición visual de video) bajo una única instancia de servidor FastAPI en el puerto 8000:

```
suite-reels-ia/
├── app.py                 # API REST FastAPI unificada, orquestación y rutas UI
├── requirements.txt       # Dependencias mínimas del servidor
├── iniciar.bat            # Lanzador de 1-clic interactivo no-bloqueante
├── core/                  # Motor de extracción de clips y audio
│   ├── audio.py           # Extracción WAV mono 16kHz optimizado para voz
│   ├── transcriber.py     # Transcripción con Vosk (o Gemini API) con telemetría de progreso
│   ├── curator.py         # Algoritmo de detección de ganchos virales por semántica
│   ├── reframe.py         # Recorte inteligente y render 9:16 con desenfoque de fondo
│   └── subtitles.py       # Generador y quemador de subtítulos dinámicos .ass
├── engine/                # Motor de plantillas visuales
│   └── canvas_renderer.py # Renderizador headless de plantillas Pillow + FFmpeg
├── uploads/               # Almacén de videos de entrada y projects_db.json
├── exports/               # Reels terminados listos para descarga
└── static/                # Módulos frontend independientes
    ├── podcast/           # Módulo 1: Extractor de clips con simulador móvil 9:16
    │   ├── index.html
    │   └── app.js
    └── editor/            # Módulo 2: Editor interactivo de plantillas visuales
        ├── index.html
        ├── style.css
        └── app.js
```

---

## ⚙️ Protocolos y Patrones Técnicos Clave

### 1. Persistencia de Proyectos (`projects_db.json` + `localStorage`)
Evita la pérdida de datos cuando el usuario recarga la página o navega entre pestañas:
- **En Backend (`app.py`):** Guardar cada video subido y sus clips analizados en `uploads/projects_db.json`. Al iniciar el servidor, auto-indexar cualquier archivo `*_input.*` presente en la carpeta `uploads/`.
- **En Frontend (`app.js`):**
  - Recordar el ID activo en `localStorage.setItem('suite_last_active_project_id', id)`.
  - Conectar el botón de regreso hacia el podcast pasando el query param: `/?video_id=${id}`.
  - Ofrecer un dropdown de **"Historial de Videos"** para alternar entre proyectos y un botón **"+ Subir Otro Video"** para resetear el estado sin perder el historial guardado.

### 2. Telemetría de Subida y Procesamiento en Vivo
No dejar al usuario a ciegas durante operaciones pesadas:
- Subida de video con `XMLHttpRequest` capturando `onprogress` para calcular porcentaje, megabytes transferidos y velocidad de subida en tiempo real.
- Indicador explícito de extracción de audio con FFmpeg (`-vn -acodec pcm_s16le -ar 16000 -ac 1`).
- Polling cada 700ms a `/api/status/{video_id}` informando del avance de Vosk o Gemini.

### 3. Flujo de Revisión de Clips con Checklist (`[✓] Revisado`)
Permite previsualizar antes de enviar al editor:
- Cada tarjeta de clip detectado cuenta con un botón de selección (`[✓] Revisado`) y un botón de previsualización en el simulador vertical.
- Una barra flotante muestra la cantidad de clips marcados (`"X seleccionados"`), con opción de marcar/desmarcar todos y transferirlos masivamente al editor mediante `localStorage['suite_incoming_clips']`.

### 4. Audio Desmuteado en el Editor
- En el reproductor de video HTML5 del editor de plantillas, asegurar que `video.muted = false` y `video.volume = 1.0` en cada cambio de escena o reproducción.
- Mantener un botón de control de volumen/mute accesible en la barra superior.

### 5. Prevención de Desarmado de CSS en Rutas Estáticas
- En `static/editor/index.html`, declarar siempre `<base href="/editor/">` en el `<head>` y utilizar rutas con versión (`/editor/style.css?v=...`).
- En FastAPI, declarar explícitamente `@app.get("/editor")` y `@app.get("/editor/")` devolviendo `FileResponse(EDITOR_STATIC / "index.html")` además del `app.mount("/editor", StaticFiles(...))`.

---

## 🛑 Protocolo Anti-Regresión

1. **No bloquear el Event Loop de FastAPI:** Las funciones pesadas que ejecutan FFmpeg o Vosk deben declararse como `def` síncronas en FastAPI (para que corran en un threadpool worker) o mediante tareas de fondo (`BackgroundTasks`), nunca en `async def` bloqueando el loop de peticiones.
2. **Audio Mono a 16kHz para Vosk:** Los modelos acústicos locales de Vosk requieren PCM 16kHz mono sin compresión para máxima precisión de transcripción y timestamps.
3. **Manejo de CORS y Rutas Cruzadas:** Permitir `CORSMiddleware` en FastAPI para evitar bloqueos al servir videos desde `/uploads` y `/exports`.

---
name: editor-video-go
description: Genera y orquesta un motor de edición de video en Go (Golang) con FFmpeg, worker pool concurrente, API REST, CLI y UI web embebida. Alias: /video-go, /motor-video-go
---

# /editor-video-go - Motor de Edición y Automatización Multimedia en Go

Esta skill permite generar, estructurar y extender un **motor de edición y procesamiento de video en Go (Golang)** respaldado por **FFmpeg/ffprobe**, con arquitectura concurrente por **Goroutines**, endpoints REST y panel web embebido sin dependencias externas.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** Go (Golang) + FFmpeg.
- **Requisitos previos:**
  - `go` (1.20 o superior).
  - `ffmpeg` y `ffprobe` disponibles en el `PATH` del sistema.
- **Entorno objetivo:** Windows PowerShell, Linux y macOS.

---

## 🛡️ Paso 0: Verificación de Entorno (Guarda de Seguridad)

Antes de ejecutar o generar el código, verificar que las herramientas requeridas estén instaladas:

```powershell
go version
ffmpeg -version
ffprobe -version
```

> **Aviso de fallback:** Si Go no está instalado en el sistema, sugerir el uso del wrapper alternativo en Python (`moviepy` / `ffmpeg-python`) o Node.js. Si falta `ffmpeg`, guiar la instalación mediante `winget install Gyan.FFmpeg` o gestor del sistema.

---

## 🏗️ Arquitectura del Motor en Go

El motor se organiza en paquetes independientes para desacoplar CLI, API y lógica de render:

```
editor-auto-go/
├── pkg/
│   ├── probe/          # Inspección de metadatos (resolución, fps, codecs, bitrate)
│   ├── ffmpeg/         # Runner de FFmpeg con Context, timeout y captura de stderr
│   ├── editor/         # Operaciones: Trim, Concat, Reel 9:16 (blur), Watermark, Audio
│   └── queue/          # Worker Pool concurrente (Goroutines + Canales)
├── web/                # UI estática (HTML/CSS/JS) compilada dentro del binario con embed.FS
├── main.go             # Entrypoint dual (CLI + Servidor REST)
├── iniciar.bat         # Lanzador no bloqueante de 1 clic (Windows)
└── go.mod
```

---

## ⚙️ Capacidades y Patrones Técnicos Clave

### 1. Generador de Reels/Shorts (9:16 Vertical)
Convierte material 16:9 o cualquier proporción a 1080x1920 con fondo dinámico desenfocado:
```go
filter := fmt.Sprintf(
    "[0:v]scale=%d:%d:force_original_aspect_ratio=increase,crop=%d:%d,boxblur=%d:5[bg];"+
    "[0:v]scale=%d:-2[fg];"+
    "[bg][fg]overlay=(W-w)/2:(H-h)/2[base]",
    w, h, w, h, blur, w,
)
```

### 2. Recorte Preciso vs. Copia Rápida
- **Copia sin recodificar (`-c copy`):** Extracción instantánea por keyframe cuando la velocidad es prioridad.
- **Recodificación controlada (`-c:v libx264 -crf 22`):** Corte en el frame milimétrico exacto sin desincronización de audio/video.

### 3. Worker Pool Concurrente (Evitar saturación de CPU)
Las peticiones de video se encolan en canales de Go y son procesadas por un número acotado de workers (`workers = 2` o configurable):
```go
type Job struct {
    ID        string
    Status    JobStatus
    Task      func(ctx context.Context) (string, error)
}
```

### 4. Distribución en Binario Único Portable
Toda la interfaz web se incrusta en el binario final mediante `//go:embed web/*`, generando un ejecutable autocontenido de ~10 MB sin necesidad de runtime externo.

---

## 🚫 Protocolo Anti-Regresión

1. **Rutas en Windows:** En archivos de lista para `concat demuxer`, siempre reemplazar barras invertidas `\` por barras normales `/` (`file 'D:/ruta/video.mp4'`) para evitar errores de escape en FFmpeg.
2. **Flag `-y` Mandatorio:** Todo comando FFmpeg ejecutado desde Go debe incluir `-y` y `-hide_banner` al inicio para evitar que el proceso se congele esperando confirmación interactiva en `stdin`.
3. **Control de Timeouts:** Todo `exec.CommandContext` debe incluir timeout (ej. 15-30 minutos) para evitar procesos zombis ante archivos corruptos.

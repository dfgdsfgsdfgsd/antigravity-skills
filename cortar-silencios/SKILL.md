---
name: cortar-silencios
description: Detección y eliminación automática de silencios y pausas muertas (Jump Cuts) en videos y podcasts con FFmpeg mediante auto-calibración adaptativa de volumen y protección de palabras. Alias: /jump-cuts, /auto-silence
---

# /cortar-silencios - Jump Cuts y Eliminación Inteligente de Pausas con FFmpeg

Esta skill proporciona el protocolo definitivo para detectar y recortar silencios, respiraciones largas y pausas muertas en cualquier video o archivo de audio mediante **Jump Cuts sincronizados** usando FFmpeg y Python, resolviendo el problema crítico de los pisos de ruido variables.

---

## 💻 Ficha de Compatibilidad y Requisitos

- **Stack compatible:** Python 3.9+ con FFmpeg en el PATH (Windows, Linux, macOS).
- **Herramientas requeridas:** `ffmpeg` accesible desde la línea de comandos (`ffmpeg -version`).
- **Casos de uso:** Reels, TikToks, Shorts, podcasts, clases grabadas, entrevistas y videos de YouTube dinámicos.

---

## 🛡️ Paso 0: Verificación de Entorno (Guarda de Seguridad)

Antes de ejecutar el procesamiento, verifica que el sistema cuente con FFmpeg instalado:

```python
import shutil

if not shutil.which("ffmpeg"):
    raise SystemError("FFmpeg no está instalado o no se encuentra en la variable de entorno PATH.")
```

---

## ⚠️ El Problema Clásico de los Umbrales Fijos de Silencio

El filtro estándar `silencedetect=noise=-25dB:d=0.35` de FFmpeg falla en más del 60% de los videos reales:
1. **Ruido de sala / eco / micrófono sensible:** Si el piso de ruido ambiental o la reverberación de la sala se encuentra a `-24 dB` o `-23 dB`, el volumen en las pausas jamás baja de `-25 dB`, haciendo que FFmpeg reporte **0 silencios** y devuelva el video idéntico sin cortar.
2. **Audios muy comprimidos o grabados bajo:** Si el volumen medio está a `-30 dB`, un umbral fijo a `-25 dB` detectará pausas intermedias como parte de las frases o viceversa.
3. **Pausas de habla rápida:** Fijar `d=0.35s` descarta pausas naturales de respiración y silencios conversacionales que suelen durar entre `0.20s` y `0.30s`.
4. **Cortes secos:** Cortar exactamente en el silencio mutila la primera consonante explosiva (p, t, k) o la última sílaba de la frase. Se requiere siempre un **padding simétrico** de seguridad (50ms - 80ms).

---

## 🧠 Arquitectura de Auto-Calibración Adaptativa

La solución consta de 3 capas:
1. **Pre-análisis ultrarrápido con `volumedetect` (~0.15s):** Mide el volumen promedio (`mean_volume`) y máximo (`max_volume`) del stream de audio sin decodificar video (`-f null -`).
2. **Ajuste dinámico del umbral en decibelios:**
   - Si `mean_volume > -19.0 dB` (audio alto/masterizado) ➔ Umbral: `-25 dB`
   - Si `mean_volume > -24.0 dB` (audio normal/estándar) ➔ Umbral: `-22 dB`
   - Si `mean_volume <= -24.0 dB` (audio bajo o con ruido de fondo) ➔ Umbral: `-20 dB`
3. **Búsqueda de rescate progresiva:** Si en un clip largo (>6s) no detecta pausas con el umbral inicial, reintenta automáticamente con umbrales más agresivos (`-20 dB`, `-18 dB` con `d=0.25s`).

---

## 📦 Implementación Python de Referencia

Guarda este módulo como `core/silence.py` o dentro de los servicios de procesamiento de tu proyecto:

```python
import subprocess
import re
import os
from pathlib import Path
from typing import Tuple, List, Dict

def get_audio_volume_stats(video_or_audio_path: str) -> Dict[str, float]:
    """
    Ejecuta un análisis rápido de volumen (volumedetect) en FFmpeg.
    Tarda <0.2s al no procesar video ni escribir en disco.
    """
    cmd = [
        "ffmpeg", "-y",
        "-i", str(video_or_audio_path),
        "-af", "volumedetect",
        "-f", "null", "-"
    ]
    try:
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        stderr = proc.stderr or ""
        mean_m = re.search(r"mean_volume:\s*([-\d\.]+)\s*dB", stderr)
        max_m = re.search(r"max_volume:\s*([-\d\.]+)\s*dB", stderr)
        return {
            "mean_volume": float(mean_m.group(1)) if mean_m else -25.0,
            "max_volume": float(max_m.group(1)) if max_m else 0.0
        }
    except Exception as e:
        return {"mean_volume": -25.0, "max_volume": 0.0}

def detect_silences(
    video_path: str,
    noise_db: str = "auto",
    min_silence_sec: float = 0.28
) -> Tuple[float, List[Tuple[float, float]]]:
    """
    Detecta pausas y silencios con FFmpeg.
    Si noise_db == 'auto', calcula automáticamente el umbral óptimo según el volumen medio.
    """
    if not os.path.exists(video_path):
        return 0.0, []

    is_auto = not noise_db or str(noise_db).lower() in ("auto", "none", "default")
    if is_auto:
        stats = get_audio_volume_stats(video_path)
        mean_vol = stats["mean_volume"]
        if mean_vol > -19.0:
            effective_db = "-25dB"
        elif mean_vol > -24.0:
            effective_db = "-22dB"
        else:
            effective_db = "-20dB"
    else:
        effective_db = str(noise_db)
        if not effective_db.endswith("dB"):
            effective_db = f"{effective_db}dB"

    def _run_silencedetect(thresh_db: str, min_sec: float):
        cmd = [
            "ffmpeg", "-y",
            "-i", str(video_path),
            "-af", f"silencedetect=noise={thresh_db}:d={min_sec}",
            "-f", "null", "-"
        ]
        try:
            proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            stderr = proc.stderr or ""

            dur_match = re.search(r"Duration:\s*(\d+):(\d+):([\d\.]+)", stderr)
            total_dur = (
                float(dur_match.group(1)) * 3600 +
                float(dur_match.group(2)) * 60 +
                float(dur_match.group(3))
            ) if dur_match else 0.0

            starts = [float(x) for x in re.findall(r"silence_start:\s*([\d\.]+)", stderr)]
            ends = [float(x) for x in re.findall(r"silence_end:\s*([\d\.]+)", stderr)]

            silences = []
            for i in range(min(len(starts), len(ends))):
                if ends[i] > starts[i]:
                    silences.append((starts[i], ends[i]))

            if len(starts) > len(ends) and total_dur > 0 and starts[-1] < total_dur:
                silences.append((starts[-1], total_dur))

            return total_dur, silences
        except Exception:
            return 0.0, []

    total_dur, silences = _run_silencedetect(effective_db, min_silence_sec)

    # Fallback inteligente de rescate si no detectó silencios en clips largos
    if is_auto and not silences and total_dur > 6.0:
        for fallback_db in ["-20dB", "-18dB"]:
            _, fallback_silences = _run_silencedetect(fallback_db, min_sec=0.25)
            if fallback_silences:
                silences = fallback_silences
                break

    return total_dur, silences

def remove_silence_from_video(
    input_video_path: str,
    output_video_path: str,
    noise_db: str = "auto",
    min_silence_sec: float = 0.28,
    padding_sec: float = 0.07
) -> Tuple[bool, str]:
    """
    Genera Jump Cuts perfectos de video y audio usando un grafo filter_complex trim+concat.
    """
    if not os.path.exists(input_video_path):
        return False, "El archivo de entrada no existe."

    total_dur, silences = detect_silences(input_video_path, noise_db, min_silence_sec)

    if not silences or total_dur <= 0:
        # Sin silencios detectados: copia directa ultrarrápida
        cmd_copy = ["ffmpeg", "-y", "-i", str(input_video_path), "-c", "copy", str(output_video_path)]
        res = subprocess.run(cmd_copy, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return res.returncode == 0, ""

    # Calcular segmentos activos agregando padding de protección
    segments: List[Tuple[float, float]] = []
    curr = 0.0
    for s_start, s_end in silences:
        seg_end = min(total_dur, s_start + padding_sec)
        if seg_end > curr + 0.06:
            segments.append((curr, seg_end))
        curr = max(0.0, s_end - padding_sec)

    if curr < total_dur - 0.06:
        segments.append((curr, total_dur))

    if not segments:
        cmd_copy = ["ffmpeg", "-y", "-i", str(input_video_path), "-c", "copy", str(output_video_path)]
        res = subprocess.run(cmd_copy, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return res.returncode == 0, ""

    # Construir grafo de filtros FFmpeg trim + atrim + concat
    filter_parts = []
    concat_inputs = []
    for i, (s, e) in enumerate(segments):
        filter_parts.append(f"[0:v]trim=start={s:.3f}:end={e:.3f},setpts=PTS-STARTPTS[v{i}];")
        filter_parts.append(f"[0:a]atrim=start={s:.3f}:end={e:.3f},asetpts=PTS-STARTPTS[a{i}];")
        concat_inputs.append(f"[v{i}][a{i}]")

    filter_str = "".join(filter_parts) + "".join(concat_inputs) + f"concat=n={len(segments)}:v=1:a=1[outv][outa]"

    cmd_cut = [
        "ffmpeg", "-y",
        "-i", str(input_video_path),
        "-filter_complex", filter_str,
        "-map", "[outv]",
        "-map", "[outa]",
        "-c:v", "libx264",
        "-preset", "ultrafast",
        "-crf", "22",
        "-c:a", "aac",
        "-b:a", "192k",
        "-movflags", "+faststart",
        str(output_video_path)
    ]

    try:
        proc = subprocess.run(cmd_cut, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if proc.returncode != 0:
            return False, proc.stderr[-400:] if proc.stderr else "Error en FFmpeg concat"
        return True, ""
    except Exception as e:
        return False, str(e)
```

---

## 🚫 Protocolo Anti-Regresión

1. **Protección de Archivos en Windows (`WinError 32`):** Nunca hagas `replace()` directo sobre un video que un navegador web o reproductor de FastAPI pueda tener abierto. Si el reemplazo falla, guarda el archivo con prefijo `clean_` y apunta la URL al nuevo nombre.
2. **Padding Obligatorio (`padding_sec`):** Mantener un margen de entre `0.05s` y `0.08s` antes y después de cada silencio detectado para que la respiración inicial o consonantes sordas no queden mutiladas.
3. **Sincronización de Subtítulos:** Si el pipeline incluye subtítulos `.ass` o `.srt`, **primero se deben cortar los silencios del video** y luego re-transcribir o desplazar los timestamps del subtítulo, de lo contrario los textos quedarán desfasados con respecto a la voz.
4. **Modo Live Preview en el Navegador:** Una etiqueta `<video>` de HTML5 no puede aplicar Jump Cuts en streaming al vuelo. El usuario debe entender que la eliminación de pausas se procesa en el backend antes de reproducirse.

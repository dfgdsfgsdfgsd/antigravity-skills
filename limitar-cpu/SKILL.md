---
name: limitar-cpu
description: Diagnostica, audita y limita el consumo de CPU en proyectos de Inteligencia Artificial (Whisper, PyTorch), renderizado con FFmpeg y scripts matemáticos para evitar la saturación al 100%, congelamientos de Windows y sobrecalentamiento. Alias: /eco-cpu, /control-nucleos, /cpu-threads
---

# /limitar-cpu - Control de Núcleos y Modo Eco Anti-Saturación

Esta skill proporciona el protocolo y los snippets definitivos para diagnosticar, auditar y limitar el uso de CPU en cualquier script, servidor o pipeline intensivo (Whisper, PyTorch, CTranslate2, FFmpeg, NumPy, ONNX).

Evita que los procesos se apropien del **100% de la CPU**, manteniendo la computadora fresca, silenciosa y permitiendo que Windows y el navegador web respondan de forma fluida y sin tirones.

---

## 💻 Ficha de Compatibilidad y Requisitos

- **Stack compatible:** Python 3.8+ (Windows, Linux, macOS), scripts Batch `.bat` y FFmpeg.
- **Librerías objetivo:** `faster-whisper`, `whisper`, `torch`, `numpy`, `opencv`, `ffmpeg`, `scipy`.
- **Ámbito:** Cualquier PC o laptop (especialmente equipos sin GPU NVIDIA dedicada o con 4 a 8 núcleos de CPU).

---

## 🛡️ Paso 0: Verificación de Entorno y Diagnóstico de CPU

Antes de aplicar cualquier límite, inspecciona la cantidad de núcleos disponibles en la máquina:

```python
import os

total_cores = os.cpu_count() or 4
print(f"Núcleos lógicos detectados: {total_cores}")

# Perfiles recomendados:
eco_threads = max(1, min(2, total_cores // 3))          # ~30% - 35% CPU
balanced_threads = max(1, min(3, total_cores // 2))     # ~45% - 50% CPU
fast_threads = max(1, total_cores - 2)                  # ~65% - 75% CPU
```

---

## ⚠️ El Problema de las Librerías Devoradoras de CPU

Por defecto:
1. **Whisper / CTranslate2:** Utiliza `cpu_threads = 0`, lo que instruye al runtime a consumir todos los núcleos lógicos al 100%.
2. **OpenMP / MKL / BLAS:** Las operaciones de álgebra lineal de PyTorch o NumPy generan hilos en cascada saturando todos los hilos libres.
3. **FFmpeg:** Los encoders `libx264` o `libx265` usan por defecto hilos automáticos (`-threads 0`).
4. **Prioridad de Windows:** Si corren con prioridad normal, compiten con la GPU, el explorador de Windows y el navegador Chrome, causando que la pantalla se congele y el puntero del mouse dé saltos.

---

## 🧠 Solución Técnica en 3 Niveles

### Nivel 1: Prioridad Baja Nativa en Windows (Sin dependencias)
Ajusta el proceso en ejecución a `BELOW_NORMAL_PRIORITY_CLASS` (0x00004000). El sistema operativo le dará prioridad a tus ventanas y aplicaciones cotidianas:

```python
def set_low_process_priority():
    """Configura la prioridad del proceso a BELOW_NORMAL en Windows vía Win32 API."""
    try:
        import ctypes
        from ctypes import wintypes
        kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
        kernel32.GetCurrentProcess.restype = wintypes.HANDLE
        kernel32.SetPriorityClass.argtypes = [wintypes.HANDLE, wintypes.DWORD]
        kernel32.SetPriorityClass.restype = wintypes.BOOL
        # 0x00004000 = BELOW_NORMAL_PRIORITY_CLASS
        kernel32.SetPriorityClass(kernel32.GetCurrentProcess(), 0x00004000)
    except Exception:
        pass
```

---

### Nivel 2: Candado a Nivel de Variables de Entorno (OpenMP, MKL, Torch)
**Debe ejecutarse antes de importar PyTorch, NumPy o CTranslate2:**

```python
import os

def apply_cpu_environment_limits(max_threads: int = 2):
    """Restringe librerías matemáticas concurrentes para evitar inundación de hilos."""
    threads_str = str(max_threads)
    os.environ["OMP_NUM_THREADS"] = threads_str
    os.environ["MKL_NUM_THREADS"] = threads_str
    os.environ["OPENBLAS_NUM_THREADS"] = threads_str
    os.environ["VECLIB_MAXIMUM_THREADS"] = threads_str
    os.environ["NUMEXPR_NUM_THREADS"] = threads_str

    try:
        import torch
        torch.set_num_threads(max_threads)
    except ImportError:
        pass
```

---

### Nivel 3: Parámetros Explícitos por Motor

#### A) Para OpenAI Whisper / faster-whisper:
```python
from faster_whisper import WhisperModel

# En una máquina de 6 núcleos, cpu_threads=2 consume ~35% de CPU
model = WhisperModel(
    "tiny",
    device="cpu",
    compute_type="int8",
    cpu_threads=2,
    num_workers=1
)
```

#### B) Para FFmpeg (Video y Audio):
Añade el flag `-threads <n>` para evitar que el encoding de video sature todos los núcleos:
```bash
ffmpeg -y -i entrada.mp4 -threads 2 -c:v libx264 -preset veryfast salida.mp4
```

#### C) Para scripts Batch de Windows (`iniciar.bat`):
Lanza la aplicación con prioridad baja y/o afinidad de núcleos mediante el comando `start /low`:
```bat
@echo off
start /low python app.py
```

---

## 📋 Selector de Modos para Frontend Web (Tailwind + HTML)

Si el proyecto cuenta con una interfaz web (FastAPI, Flask, Streamlit), añade este bloque para que el usuario controle su CPU:

```html
<div class="space-y-1">
  <label class="block text-xs font-medium text-slate-300 flex items-center justify-between">
    <span>Uso de CPU</span>
    <span class="text-[10px] text-emerald-400 font-mono"><i class="fa-solid fa-leaf"></i> Anti-saturación</span>
  </label>
  <select id="cpu-threads" class="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-2 text-xs text-slate-200">
    <option value="2" selected>🌿 Modo Eco (2 núcleos, ~35% CPU - Ideal para usar la PC)</option>
    <option value="3">⚖️ Modo Equilibrado (3 núcleos, ~50% CPU - Recomendado)</option>
    <option value="4">⚡ Modo Rápido (4 núcleos, ~65% CPU)</option>
    <option value="0">🔥 Máxima Potencia (Todos los núcleos al 100%)</option>
  </select>
</div>
```

---

## 🚫 Protocolo Anti-Regresión

1. **Nunca fijar `cpu_threads = 1` en tareas con UI en el mismo proceso:** Si usas un solo núcleo y la interfaz gráfica o servidor corre en el mismo hilo, la página web puede responder con lentitud. El mínimo recomendado para modo Eco en procesadores modernos es **2 núcleos**.
2. **Definir variables de entorno ANTES de importar dependencias:** `os.environ["OMP_NUM_THREADS"]` debe asignarse al inicio del script antes de `import torch` o `import numpy`, de lo contrario las librerías C++ ya habrán inicializado su thread pool.
3. **No usar `psutil` si no es estrictamente necesario:** El acceso mediante `ctypes.windll.kernel32.SetPriorityClass` no requiere instalar dependencias adicionales por pip y funciona en el 100% de las instalaciones de Windows.

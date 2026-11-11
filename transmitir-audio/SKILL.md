---
name: transmitir-audio
description: Transmite el audio de la PC al celular en tiempo real por WiFi sin apps externas usando captura WASAPI y WebSockets de ultra baja latencia. Alias: /audio-pc, /soundcast
---

# /transmitir-audio - Transmisor de Audio PC a Celular en Tiempo Real

Esta skill genera o repara una suite de transmisión de audio local para escuchar todo lo que suena en la PC en el teléfono celular o tablet en tiempo real, sin instalar apps en el móvil, escaneando un código QR desde el navegador.

---

## 💻 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** Python (FastAPI + Uvicorn + PyAudioWPatch) + Frontend (HTML5 / Web Audio API)
- **Plataforma:** Windows 10 u 11 (requiere WASAPI loopback para capturar sonido del sistema sin cables virtuales adicionales).
- **Dependencias Python:** `fastapi`, `uvicorn`, `pyaudiowpatch`, `qrcode`, `pillow`, `numpy`, `websockets`.
- **Navegador del Celular:** Cualquier navegador moderno con soporte Web Audio API (Chrome, Safari iOS, Edge, Firefox).

---

## 🛡️ Paso 0: Verificación de Entorno (Guarda de Seguridad)

Antes de iniciar la transmisión o generar el servidor:
1. Verificar si el sistema operativo es Windows:
   - WASAPI loopback nativo solo opera en Windows.
2. Verificar la presencia de Python:
   ```powershell
   python --version
   ```
3. Comprobar que `pyaudiowpatch` detecta el dispositivo loopback predeterminado:
   ```python
   import pyaudiowpatch as p
   pa = p.PyAudio()
   dev = pa.get_default_wasapi_loopback()
   print("Loopback activo:", dev["name"])
   pa.terminate()
   ```

---

## 🏗️ Arquitectura del Sistema

```
[ PC: Altavoces / Windows WASAPI ]
              │ (pyaudiowpatch paInt16 Stereo 48kHz)
              ▼
   [ Hilo de Captura Loopback ]
              │ (Colas async dedicadas no-bloqueantes)
              ▼
    [ Servidor FastAPI / WS ] ───► QR Code en Consola / GUI (IP Local LAN)
              │
       (Red WiFi Local)
              │
              ▼
   [ Celular: Navegador Web ]
              │
   [ Web Audio API C++ Engine ] ──► Resampling nativo + AudioBuffer Scheduling
              ▼
       [ Auriculares / Celular ]
```

---

## ⚙️ Reglas Críticas para Evitar Microcortes y Eco (Anti-Regresión)

### 1. Evitar `ScriptProcessorNode` en Móviles
- **Problema:** `ScriptProcessorNode` ejecuta `onaudioprocess` en el hilo principal de JavaScript de la UI. En teléfonos móviles, cualquier animación de canvas, evento táctil o recolector de basura bloquea el hilo 15-30ms, generando chasquidos y tartamudeo metálico.
- **Solución:** Utilizar **`AudioBufferSourceNode` programado en el motor C++ nativo de Web Audio API**. La reproducción ocurre en el hilo de audio de alta prioridad del hardware del celular.

### 2. Algoritmo de Programación Continua Anti-Lag
- **Problema:** Si el reproductor del celular detecta que `nextPlayTime < currentTime` y suma artificialmente un silencio de `currentTime + jitterBuffer`, genera un bache de 100ms que suena a ametralladora/eco de repetición.
- **Solución:** Si un paquete llega levemente demorado por el WiFi, programarlo inmediatamente en `now` (`nextPlayTime = now`) **sin agregar silencios forzados**. Si la demora acumulada supera 500ms, resincronizar suavemente.

### 3. Pacing de Paquetes en Servidor (`CHUNK_SIZE = 1536`)
- A 48.000 Hz, fragmentos de 1.536 muestras corresponden a ~32 ms (31 paquetes por segundo).
- Esto reduce el estrés del router WiFi a la mitad en comparación con fragmentos de 1.024 (47 paquetes/seg), eliminando la congestión de paquetes pequeños.

### 4. Colas Asíncronas por Cliente (`asyncio.Queue`)
- En el servidor, cada cliente WebSocket debe tener una cola `asyncio.Queue(maxsize=15)`.
- Si un celular tiene WiFi débil temporalmente, se descartan los paquetes viejos (`q.get_nowait()`) para no frenar el hilo de captura ni congelar a otros clientes.

### 5. Resampling Automático
- Las PC suelen emitir a 48.000 Hz, mientras que muchos celulares (como iPhone o auriculares Bluetooth) operan a 44.100 Hz.
- `audioCtx.createBuffer(channels, frames, streamSampleRate)` realiza el remuestreo sinc/polifase automáticamente en hardware C++, evitando cambios de tono o desbordes de buffer.

### 6. Control del Eco Acústico
- Si los altavoces físicos de la PC están sonando en la misma habitación que el celular, el usuario escuchará la PC (0ms) y el celular (~100ms después).
- Para evitarlo: recomendar bajar el volumen de los parlantes de la PC o conectar auriculares al celular.

---

## 🚀 Implementación Rápida

### 1. Backend (`server.py`)
- Inicia captura WASAPI en hilo de fondo usando `pyaudiowpatch`.
- Detecta IP local (`socket.connect(('8.8.8.8', 80))`).
- Genera código QR tanto en terminal ASCII como en imagen base64 para la web.
- Expone WebSocket `/ws/audio` para streaming PCM 16-bit.
- Expone endpoint `/stream.wav` para compatibilidad con reproductores como VLC.

### 2. Frontend (`static/index.html` + `static/app.js`)
- Botón táctil grande con animación de pulso.
- Canvas visualizador ligero sin `shadowBlur` a 30 FPS.
- Deslizador de volumen con software boost hasta 200%.
- Wake Lock (`navigator.wakeLock.request('screen')`) y loop de audio silencioso para mantener la reproducción al bloquear la pantalla.
- Selector de perfiles de latencia:
  - ⚡ Ultra Rápida (~50ms)
  - ⚖ Balanceada (~120ms - recomendada)
  - 🛡 Estable (~250ms)

### 3. Lanzador de 1 Clic (`iniciar.bat`)
- Instala o verifica dependencias de `requirements.txt`.
- Lanza el servidor y abre automáticamente `http://localhost:5000` en el navegador de la PC.

---

## 📌 Checklist de Verificación Final
- [ ] ¿El audio suena limpio sin tartamudeos ni silencios periódicos?
- [ ] ¿El remuestreo entre 48kHz y 44.1kHz se realiza sin desafinación?
- [ ] ¿El código QR se escanea correctamente en la misma red WiFi?
- [ ] ¿Se mantiene el sonido al bloquear la pantalla del celular?

---
name: soundcast-go
description: Transmisor nativo de audio PC a celular en Go (WASAPI Loopback puro sin CGO, binario único portable de ~10MB, <15MB RAM y frontend embebido). Alias: /audio-pc-go
---

# /soundcast-go - Transmisor de Audio PC a Celular en Go (WASAPI Pure Go)

Esta skill crea, repara o compila una suite de transmisión de audio en tiempo real desde Windows hacia cualquier dispositivo móvil conectado a la misma red WiFi, utilizando **Go (Golang)** nativo sin CGO, generando un único ejecutable portable `.exe` de ~10 MB con frontend embebido y consumo menor a 15 MB de RAM.

---

## 💻 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** Go (Golang 1.18+) + Windows COM Audio + Frontend Web Audio API
- **Plataforma:** Windows 10 u 11 (WASAPI Loopback nativo)
- **Modo de compilación:** Pure Go (`CGO_ENABLED=0`), sin necesidad de GCC, MinGW ni MSVC C++
- **Librerías Go:**
  - `github.com/go-ole/go-ole`: Manejo de llamadas COM de Windows
  - `github.com/moutend/go-wca`: Interfaces Core Audio (`IMMDeviceEnumerator`, `IAudioClient`, `IAudioCaptureClient`)
  - `github.com/gorilla/websocket`: Servidor WebSocket de alta concurrencia
  - `github.com/skip2/go-qrcode`: Generador de códigos QR en consola y data-URI base64

---

## 🛡️ Paso 0: Verificación de Entorno (Guarda de Seguridad)

Antes de compilar o ejecutar el proyecto:
1. Verificar que el sistema operativo es Windows:
   - WASAPI Loopback solo está disponible en Windows Vista / 7 / 10 / 11.
2. Comprobar la presencia de Go:
   ```powershell
   & "C:\Program Files\Go\bin\go.exe" version
   # o
   go version
   ```
3. Verificar que el entorno compila en Pure Go:
   ```powershell
   $env:CGO_ENABLED = "0"
   go env CGO_ENABLED
   ```

---

## 🏗️ Arquitectura del Sistema

```
[ PC: Altavoces / Windows WASAPI ]
              │ (Audio loopback directo por COM)
              ▼
[ Hilo de Captura Loopback (go-wca) ]
              │ (LockOSThread + Conversión IEEE Float 32b -> PCM 16b + VU Meter)
              ▼
    [ Broadcast Hub en Go ] ───► QR Code en Consola / GUI (IP Local LAN)
              │ (Canales no-bloqueantes con drop-frame anti-lag)
              ▼
[ Servidor HTTP / WebSockets Embebido ]
              │
       (Red WiFi Local)
              │
              ▼
   [ Celular: Navegador Web ]
              │
   [ Web Audio API C++ Engine ] ──► Resampling nativo + AudioBuffer Scheduling
              ▼
       [ Auriculares / Celular 🎧 ]
```

---

## 🚀 Instrucciones de Creación y Compilación

### 1. Inicializar Módulo y Dependencias
```powershell
go mod init soundcast
go get github.com/go-ole/go-ole
go get github.com/moutend/go-wca
go get github.com/gorilla/websocket
go get github.com/skip2/go-qrcode
```

### 2. Estructura de Paquetes
- `main.go`: Punto de entrada, CLI flags (`-port`, `-no-browser`) y `//go:embed static/*`
- `pkg/audio/capture.go`: Captura loopback, conversión PCM 16-bit y cálculo de pico/RMS
- `pkg/network/ip.go`: Detección de IP LAN local y generador de QR Unicode/Base64
- `pkg/server/server.go`: Endpoints REST (`/api/info`, `/api/select_device`) y WebSockets (`/ws/audio`, `/ws/status`)
- `static/`: Frontend web (HTML5, CSS3, JS Vanilla con Web Audio API)

### 3. Compilación Optimizada a Binario Único
```powershell
go build -ldflags="-s -w" -o SoundCast.exe main.go
```
*(Opcional: añadir `-H=windowsgui` si se desea ocultar completamente la consola de terminal).*

---

## ⚠️ Protocolo Anti-Regresión

1. **LockOSThread para llamadas COM:** Windows COM requiere que las llamadas a interfaces de audio se ejecuten en el mismo hilo del sistema operativo donde se llamó a `CoInitializeEx`. Siempre usar `runtime.LockOSThread()` en el worker de captura.
2. **Formato IEEE Float 32-bit:** En Windows 10/11, la mezcla por defecto casi siempre es IEEE Float 32-bit (`FormatTag=65534`). Realizar el clamp entre `[-1.0, 1.0]` y multiplicar por `32767.0` para convertir a PCM 16-bit sin distorsión.
3. **Drop-Frame Anti-Lag:** Nunca usar canales sin amortiguamiento ni bloquear el bucle de audio cuando un cliente sufra lag en Wi-Fi. Descartar el buffer más antiguo para mantener latencia en tiempo real.
4. **Liberación de memoria COM:** Toda interfaz (`IMMDevice`, `IAudioClient`, `ReleaseBuffer`) debe llamar a su `.Release()` respectivo para evitar fugas de memoria en handles del kernel.

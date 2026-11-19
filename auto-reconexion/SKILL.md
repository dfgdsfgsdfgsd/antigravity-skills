---
name: auto-reconexion
description: Implementa y audita patrones de auto-reconexión automática y tolerancia Wi-Fi para streaming y WebSockets en tiempo real (Go, Node, JS Web Audio, Android Kotlin). Alias: /reconectar-stream, /reconnect-ws
---

# /auto-reconexion - Patrón Resiliente de Streaming y WebSockets

Esta skill implementa un protocolo robusto de **auto-reconexión continua y tolerancia de latencia Wi-Fi** para sistemas de transmisión de datos y audio en tiempo real. Resuelve el problema común donde micro-cortes, cambios de antena del router o suspensión de pantallas en dispositivos móviles provocan desconexiones constantes o bloquean el cliente sin reintentar.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Stack compatible:** Multi-stack (`Go` / `Node.js` en backend, `JavaScript / Web Audio API` en frontend móvil, `Kotlin / OkHttp` en Android).
- **Ámbito:** Streaming de audio PCM, sockets de telemetría, dashboards en vivo, WebSockets binarios o de texto.
- **Requisitos previos:** Soporte para WebSockets (librerías `gorilla/websocket`, `ws`, `OkHttp` o nativo del navegador).

---

## 🛡️ Paso 0: Verificación de Entorno (Guarda de Seguridad)

Antes de aplicar cambios en el proyecto:
1. Identificar qué parte del stack está fallando:
   - **Servidor:** ¿El timeout de escritura (`WriteDeadline`) es demasiado estricto (< 1 segundo)?
   - **Cliente Web:** ¿El WebSocket llama a `stop()` en `onclose` / `onerror` sin programar reintentos?
   - **Cliente Android:** ¿El `Service` se apaga o descarta los `WakeLock` ante el primer fallo de conexión?
2. Preservar la intención explícita del usuario (`userWantsStreaming`):
   - **Regla de oro:** Solo dejar de intentar reconectar si el usuario presionó explícitamente **Detener** o cerró la app.

---

## 🔧 Implementación por Capas

### 1. Servidor Backend (Go / Gorilla WebSocket)
Un error crítico frecuente es fijar deadlines de submilisegundos (ej. 500ms). En redes Wi-Fi residenciales, cualquier cola temporal de paquetes excede ese tiempo y el servidor corta la conexión.

```go
// 1. Configurar PingHandler nativo para RFC 6455
conn.SetPingHandler(func(appData string) error {
    return conn.WriteControl(websocket.PongMessage, []byte(appData), time.Now().Add(5*time.Second))
})

// 2. Deadline elástico de 5 segundos para chunks binarios
for {
    select {
    case <-done:
        return
    case data, ok := <-streamChan:
        if !ok {
            return
        }
        conn.SetWriteDeadline(time.Now().Add(5 * time.Second))
        if err := conn.WriteMessage(websocket.BinaryMessage, data); err != nil {
            return
        }
    }
}
```

### 2. Cliente Web Móvil (JavaScript & Web Audio)
En navegadores móviles (Chrome/Safari), la pestaña se suspende o la red parpadea cuando el usuario apaga la pantalla.

```javascript
let userWantsStreaming = false;
let reconnectTimer = null;
let reconnectAttempts = 0;

function startStreaming(isManual = false) {
  if (isManual) {
    userWantsStreaming = true;
    reconnectAttempts = 0;
  }
  if (reconnectTimer) clearTimeout(reconnectTimer);

  initAudioContext();
  const ws = new WebSocket(wsUrl);

  ws.onopen = () => {
    reconnectAttempts = 0;
    updateStatus('connected', '🟢 En Vivo');
  };

  ws.onmessage = (event) => {
    if (audioCtx && audioCtx.state === 'suspended') {
      audioCtx.resume().catch(() => {});
    }
    playAudioBuffer(event.data);
  };

  ws.onclose = () => handleDisconnect();
  ws.onerror = () => handleDisconnect();
}

function handleDisconnect() {
  if (userWantsStreaming) {
    reconnectAttempts++;
    const delayMs = Math.min(1500 + (reconnectAttempts * 500), 4000);
    updateStatus('reconnecting', `🔄 Reconectando en ${(delayMs/1000).toFixed(0)}s (intento ${reconnectAttempts})...`);
    
    reconnectTimer = setTimeout(() => {
      if (userWantsStreaming) startStreaming(false);
    }, delayMs);
  }
}

// Auto-recuperación ante eventos de sistema
window.addEventListener('online', () => {
  if (userWantsStreaming) startStreaming(false);
});

document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'visible') {
    if (audioCtx && audioCtx.state === 'suspended') audioCtx.resume();
    if (userWantsStreaming && (!ws || ws.readyState !== WebSocket.OPEN)) {
      startStreaming(false);
    }
  }
});
```

### 3. Cliente Nativo Android (Kotlin + OkHttp)
El servicio debe permanecer en `startForeground` con `WakeLock` y reintentar de forma continua en una corrutina.

```kotlin
enum class State { IDLE, CONNECTING, CONNECTED, RECONNECTING, ERROR }

private var userRequestedStreaming = false
private var reconnectAttempts = 0
private var reconnectJob: Job? = null

fun connectWebSocket() {
    if (!userRequestedStreaming) return

    val request = Request.Builder().url(wsUrl).build()
    webSocket = okHttpClient.newWebSocket(request, object : WebSocketListener() {
        override fun onOpen(webSocket: WebSocket, response: Response) {
            reconnectAttempts = 0
            _serviceState.value = State.CONNECTED
        }

        override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
            if (userRequestedStreaming) scheduleReconnect()
        }

        override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
            if (userRequestedStreaming) scheduleReconnect()
        }
    })
}

private fun scheduleReconnect() {
    reconnectJob?.cancel()
    reconnectAttempts++
    val delayMs = (1500L + (reconnectAttempts * 500L)).coerceAtMost(4000L)
    _serviceState.value = State.RECONNECTING
    
    reconnectJob = serviceScope.launch {
        delay(delayMs)
        if (userRequestedStreaming) connectWebSocket()
    }
}
```

---

## ⚠️ Protocolo Anti-Regresión

1. **Evitar bucles infinitos agresivos (CPU Spin):** Siempre utilizar retroceso exponencial o escalonado (1.5s, 2s, 2.5s hasta tope de 4-5s) para no saturar la CPU ni el router en caso de caída prolongada del servidor.
2. **AudioContext Invalido:** En navegadores móviles, llamar siempre a `audioCtx.resume()` dentro del listener de interacción inicial o en `onmessage`/`visibilitychange`.
3. **Limpieza de sockets zombis:** Antes de crear una nueva instancia de `WebSocket`, desenganchar los listeners antiguos (`onopen=null`, `onclose=null`, etc.) y llamar a `close()` para evitar fugas de memoria o múltiples conexiones concurrentes.

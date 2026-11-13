---
name: soundcast-android
description: Generador de cliente Android nativo (APK) para transmisión de audio PC a celular en tiempo real con AudioTrack PCM, auto-descubrimiento UDP y CI/CD en GitHub Actions. Alias: /audio-pc-android, /apk-audio
---

# /soundcast-android - Cliente Nativo Android de Streaming de Audio PC

Esta skill crea, repara o actualiza una aplicación nativa para Android en **Kotlin** diseñada para recibir el audio de la computadora en tiempo real mediante **WebSockets** y reproducirlo a través de **AudioTrack** con latencia ultra baja (~15 a 25ms), auto-detección de la PC por WiFi y compilación automatizada en la nube con GitHub Actions.

---

## 💻 Ficha de Compatibilidad y Requisitos

- **Lenguaje:** Kotlin 1.9+
- **Motor de Audio:** `android.media.AudioTrack` en modo `MODE_STREAM` (PCM 16-bit estéreo a 48.000 Hz)
- **Red y Transporte:** OkHttp 4.12+ (WebSockets binarios) + DatagramSocket (UDP broadcast en puerto 5002)
- **Compatibilidad del Sistema:** Android 5.0 (API 21) hasta Android 15 (API 35) con soporte para dispositivos legacy como Moto G4 (MultiDex)
- **Compilación:** Automatizada en la nube mediante GitHub Actions (no requiere instalar Android Studio ni Java en la PC local)

---

## 🏗️ Arquitectura del Sistema Móvil

```
[ PC: SoundCast Go / WASAPI ]
              │
       (Red WiFi Local)
              │
              ├──► [ UDP Port 5002 ] ───► Auto-descubrimiento Zero-Config
              │
              ▼
   [ WebSocket: /ws/audio ] ───► Chunks Binarios PCM 16-bit
              │
              ▼
[ Android: AudioStreamService ] ──► Foreground Service + WakeLock + WifiLock
              │
              ├──► [ AudioPlayerEngine ] ──► AudioTrack PCM Direct Buffer
              │                                      │
              │                                      ▼
              │                             [ Auriculares / Parlante 🎧 ]
              │
              └──► [ Notification Manager ] ──► Botón directo "Detener"
```

---

## 🛡️ Protocolo Anti-Regresión y Reglas Críticas

1. **Ciclo de Vida y Detención Limpia:**
   - Para evitar que el audio siga sonando cuando el usuario cierra la app, `AudioStreamService` debe implementar obligatoriamente `onTaskRemoved` y `onStartCommand` con `ACTION_STOP`.
   - En `MainActivity.onDestroy`, si `isFinishing == true`, debe llamarse a `stopStreaming()`.
   - La barra de notificaciones debe incluir una acción `Detener` para pausar sin abrir la app.
2. **Compatibilidad con Dispositivos Antiguos (Android 5/6 - Moto G4):**
   - Siempre activar `multiDexEnabled true` en `defaultConfig`.
   - Declarar `android:name="androidx.multidex.MultiDexApplication"` en el tag `<application>` de `AndroidManifest.xml`.
   - Evitar `targetSdk 34` si no se requieren permisos de Google Play Store para eludir las restricciones de instalación de paquetes de Android 14 (`targetSdk 33` es el más estable para sideloading).
3. **Firma Permanente (`debug.keystore`):**
   - Para evitar el error `INSTALL_FAILED_UPDATE_INCOMPATIBLE` ("la firma no coincide con la versión instalada"), el repositorio debe incluir su propio archivo `debug.keystore` fijo y asignarlo a `signingConfigs.debug`.
4. **Instalador Alternativo (SAI):**
   - Si el instalador del fabricante falla silenciosamente, utilizar **SAI (Split APKs Installer)** para diagnosticar el código de error exacto.

---

## 🚀 Flujo de Compilación y Distribución Automática

El proyecto se compila y distribuye directamente a través de `.github/workflows/build-apk.yml`:
- Compila con JDK 17 y Gradle 8.5.
- Firma con el `debug.keystore` fijo del repositorio.
- Genera el archivo `SoundCast.apk`.
- Lo publica automáticamente en la pestaña **Releases** de GitHub para que el usuario lo descargue con un solo clic directamente a su teléfono.

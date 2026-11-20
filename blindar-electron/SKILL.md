---
name: blindar-electron
description: Blindaje integral para aplicaciones Electron y Node.js en Windows contra colisiones de puerto (EADDRINUSE), procesos zombis de FFmpeg/Python y doble apertura mediante SingleInstanceLock y auto-liberacion de sockets. Alias: /electron-blindado, /anti-eaddrinuse
---

# /blindar-electron - Blindaje de Procesos, Puertos y Doble Apertura en Electron

Esta skill audita, implementa y blinda aplicaciones de escritorio **Electron** y servidores embebidos de **Node.js** en Windows, eliminando de raíz:
1. Errores `listen EADDRINUSE: address already in use` cuando el puerto quedó tomado por una ejecución anterior o caída repentina.
2. Ventanas duplicadas y bloqueos al hacer doble clic repetido en el lanzador (`.bat`).
3. Procesos huérfanos o zombis (FFmpeg, Python, yt-dlp) que quedan consumiendo red o CPU en segundo plano tras cerrar la app.

---

## 💻 Ficha Técnica y Compatibilidad

| Atributo | Detalle |
| :--- | :--- |
| **Stack Compatible** | Electron (v18 a v34+), Node.js (v16 a v24+), Windows (PowerShell / CMD) |
| **Herramientas Clave** | `app.requestSingleInstanceLock()`, `taskkill /F /T`, `Get-NetTCPConnection`, `server.on('error')` |
| **Archivos Afectados** | `main.js` (proceso principal), `iniciar.bat` (lanzador Windows) |
| **Impacto** | 0% fallos al iniciar, auto-recuperación de puertos en <600ms, 0 subprocesos huérfanos |

---

## 🛡️ Paso 0: Verificación de Entorno (Guarda de Seguridad)

Antes de aplicar el blindaje, verificar:
1. Existencia de `package.json` con dependencia de `electron` en `devDependencies` o `dependencies`.
2. Archivo del proceso principal (usualmente `main.js`, `index.js` o `src/main/index.ts`).
3. Existencia o necesidad de lanzador Windows (`iniciar.bat`).

---

## 🚀 Arquitectura del Blindaje en 4 Capas

### Capa 1: Bloqueo de Instancia Única (`SingleInstanceLock`) en `main.js`
Impide que dos instancias de Electron compitan por los mismos puertos y recursos locales. Si el usuario abre el ejecutable dos veces, la segunda instancia enfoca la primera y se cierra limpiamente:

```javascript
const { app, BrowserWindow } = require('electron');

let mainWindow = null;

// Solicitar el cerrojo de instancia única
const gotTheLock = app.requestSingleInstanceLock();

if (!gotTheLock) {
  console.log('[Electron] Ya existe otra instancia ejecutándose. Cerrando instancia secundaria...');
  app.quit();
} else {
  // Al intentar abrir una segunda instancia, enfocar la existente
  app.on('second-instance', (event, commandLine, workingDirectory) => {
    if (mainWindow) {
      if (mainWindow.isMinimized()) mainWindow.restore();
      mainWindow.focus();
    }
  });

  app.whenReady().then(createWindow);
}
```

---

### Capa 2: Auto-Recuperación de Puerto en Servidor HTTP Local (`server.on('error')`)
Si tu aplicación levanta un servidor HTTP local embebido (ej. para HLS, APIs internas o WebSockets) y el puerto está ocupado por una caída previa, el servidor detecta `EADDRINUSE`, identifica el PID responsable en Windows, lo liquida y reintenta escuchar sin crashear la UI:

```javascript
const http = require('http');
const { execSync } = require('child_process');

const PORT = 8525; // O el puerto configurado

const server = http.createServer((req, res) => {
  // Manejo de peticiones...
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.warn(`[HTTP Server] Puerto ${PORT} ocupado. Liberando socket...`);
    try {
      if (process.platform === 'win32') {
        const pids = execSync(`netstat -ano | findstr :${PORT} | findstr LISTENING`).toString();
        const lines = pids.trim().split('\n');
        for (const line of lines) {
          const parts = line.trim().split(/\s+/);
          const pid = parts[parts.length - 1];
          if (pid && pid !== String(process.pid)) {
            execSync(`taskkill /F /PID ${pid}`, { stdio: 'ignore' });
          }
        }
        // Reintentar escuchar tras liberar el puerto
        setTimeout(() => server.listen(PORT, '127.0.0.1'), 600);
        return;
      }
    } catch (e) {
      console.error('[HTTP Server] No se pudo liberar el puerto automáticamente:', e.message);
    }
  } else {
    console.error('[HTTP Server Error]', err);
  }
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`[HTTP Server] Listo en http://127.0.0.1:${PORT}`);
});
```

---

### Capa 3: Terminación Forzada de Árbol de Subprocesos (`Anti-Zombies`)
En Windows, llamar simplemente a `.kill('SIGTERM')` sobre un proceso hijo (como FFmpeg o Python) **no** mata los procesos nietos creados por la consola. Para evitar que queden procesos zombis consumiendo el 100% de CPU/Red:

```javascript
function terminateProcessTree(childProc) {
  if (childProc && childProc.pid) {
    try {
      if (process.platform === 'win32') {
        // /T mata el árbol completo de procesos; /F fuerza el cierre
        execSync(`taskkill /F /T /PID ${childProc.pid}`, { stdio: 'ignore' });
      } else {
        childProc.kill('SIGKILL');
      }
    } catch (e) {}
  }
}

// Escuchar todos los eventos de salida para garantizar limpieza
app.on('before-quit', () => cleanupAllChildren());
app.on('will-quit', () => cleanupAllChildren());
process.on('exit', () => cleanupAllChildren());
process.on('SIGINT', () => { cleanupAllChildren(); process.exit(0); });
process.on('SIGTERM', () => { cleanupAllChildren(); process.exit(0); });
```

---

### Capa 4: Pre-vuelo en Lanzador Windows (`iniciar.bat`)
Antes de invocar `npm start`, el lanzador limpia preventivamente cualquier proceso colgado en el puerto objetivo usando PowerShell en 1 sola línea segura (evitando los bugs de sintaxis de CMD):

```bat
@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo [1/2] Verificando y liberando puertos locales...
powershell -NoProfile -Command "Get-NetTCPConnection -LocalPort 8525 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }" >nul 2>nul

echo [2/2] Iniciando aplicacion Electron...
call npm start
```

---

## ⚠️ Protocolo Anti-Regresión

1. **Nunca usar `taskkill /F /IM electron.exe` dentro de `main.js`**: Mataría a la propia instancia actual. Solo matar PIDs externos identificados por `netstat` cuyo PID difiera de `process.pid`.
2. **Proteger el orden de arranque:** `app.requestSingleInstanceLock()` debe ejecutarse **antes** de inicializar cualquier ventana o servidor HTTP.
3. **Manejar excepciones en `execSync`**: Rodear siempre los comandos de `taskkill` con bloques `try / catch`, ya que si el proceso ya cerró por su cuenta, Windows devuelve errorlevel 1 y tiraría una excepción no capturada.

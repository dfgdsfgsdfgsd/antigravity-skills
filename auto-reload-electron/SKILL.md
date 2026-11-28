---
name: auto-reload-electron
description: Implementa recarga en caliente instantánea (Hot Reload) y auto-reinicio (Auto-Relaunch) para aplicaciones Electron sin dependencias externas pesadas, con vigilancia debounced de archivos y liberación limpia de SingleInstanceLock. Alias: /electron-reload, /hot-reload-electron, /reiniciar-electron
---

# /auto-reload-electron - Hot Reload y Auto-Relaunch Nativo para Electron

Esta skill se activa con `/auto-reload-electron` o sus alias `/electron-reload`, `/hot-reload-electron` y `/reiniciar-electron`. Proporciona la arquitectura completa para que cualquier aplicación de escritorio en **Electron** se actualice automáticamente ante cualquier modificación en su código fuente, diferenciando inteligentemente entre cambios visuales (interfaz) y cambios estructurales (proceso principal).

---

## 💻 Ficha Técnica y Compatibilidad

- **Stack Compatible:** Electron (v18 a v34+), Node.js (v16 a v24+), Windows (CMD / PowerShell).
- **Dependencias externas requeridas:** **Cero (0)**. Funciona 100% con APIs nativas de Node (`fs.watch`) y Electron (`webContents.reloadIgnoringCache`, `app.relaunch`).
- **Tiempo de respuesta:** ~150-200ms para cambios de UI (sin parpadeos ni cerrar ventana) y ~600ms para reinicio completo del proceso principal.

---

## 💡 ¿Por qué es superior a paquetes externos como `nodemon` o `electron-reload`?

1. **Cero Dependencias y Cero Bloqueos:** No requiere instalar paquetes npm pesados ni herramientas de compilación C++.
2. **Doble Comportamiento Inteligente:**
   - **Cambios en `renderer/` (HTML, CSS, JS):** NO mata el proceso de Electron. Simplemente refresca la ventana web en 150ms preservando la posición de la ventana.
   - **Cambios en `main.js` o `preload.js`:** Realiza un reinicio completo del ejecutable (`app.relaunch(); app.exit(0);`).
3. **Liberación Limpia de `SingleInstanceLock`:** En Windows, relanzar Electron mientras el cerrojo de instancia está activo suele causar que la nueva instancia detecte la anterior y se cierre sola. Esta skill incluye la secuencia de liberación antes del relanzamiento.
4. **Filtro Anti-Ráfaga (Debounce):** Los editores de código (VS Code, Antigravity) disparan múltiples eventos de sistema al guardar. El debounce de 200ms previene bucles de recarga repetitivos.

---

## 🛠️ Procedimiento de Implementación Paso a Paso

### Paso 0: Verificación de Entorno

Comprobar que el proyecto tiene `package.json` y un archivo principal de Electron (`main.js` o `index.js`).

---

### Paso 1: Integrar el Watcher en `main.js`

Dentro del archivo `main.js`, añade la función `setupAutoReload()` y vincúlala en el ciclo de vida de `createWindow()`:

```javascript
// --- Auto-Reload y Auto-Relaunch Nativo ---
function setupAutoReload() {
  let debounceTimer = null;

  try {
    fs.watch(__dirname, { recursive: true }, (eventType, filename) => {
      if (!filename) return;

      const norm = filename.replace(/\\/g, '/');

      // Ignorar directorios de datos, temporales, logs y git
      if (
        norm.startsWith('.git') ||
        norm.startsWith('node_modules') ||
        norm.startsWith('buffer') ||
        norm.startsWith('exports') ||
        norm.includes('.tmp') ||
        norm.endsWith('.log') ||
        norm === 'package-lock.json'
      ) {
        return;
      }

      // Solo vigilar extensiones de código relevantes
      const isCodeFile = norm.endsWith('.js') || norm.endsWith('.html') || norm.endsWith('.css') || norm.endsWith('.json');
      if (!isCodeFile) return;

      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(() => {
        console.log(`[Auto-Reload] 📝 Modificación detectada en ${norm} (${eventType}).`);

        const isMainProcess = norm === 'main.js' || norm === 'preload.js' || norm === 'package.json';

        if (isMainProcess) {
          console.log('[Auto-Reload] 🔄 Reiniciando aplicación Electron por cambios en el proceso principal...');
          
          // 1. Limpieza de subprocesos si aplica (FFmpeg, Python, etc.)
          if (typeof stopLiveHls === 'function') stopLiveHls();

          // 2. Liberar cerrojo de instancia única para permitir la apertura del nuevo proceso
          if (typeof gotTheLock !== 'undefined' && gotTheLock) {
            try { app.releaseSingleInstanceLock(); } catch (e) {}
          }

          // 3. Relanzar y salir limpiamente
          app.relaunch();
          app.exit(0);
        } else {
          console.log('[Auto-Reload] ⚡ Recargando interfaz de usuario (Renderer)...');
          if (mainWindow && !mainWindow.isDestroyed()) {
            mainWindow.webContents.reloadIgnoringCache();
          }
        }
      }, 200);
    });

    console.log('[Auto-Reload] Vigilando cambios en tiempo real en todo el proyecto...');
  } catch (err) {
    console.warn('[Auto-Reload] Advertencia al activar watcher global:', err.message);
  }
}
```

---

### Paso 2: Activar Atajos Manuales (`F5` y `Ctrl + R`)

En la función `createWindow()`, registra la escucha de eventos de entrada para permitir también la recarga manual:

```javascript
function createWindow() {
  mainWindow = new BrowserWindow({
    // opciones de ventana...
  });

  // Atajos de teclado para recarga manual sin menú visible
  mainWindow.webContents.on('before-input-event', (event, input) => {
    if ((input.control && input.key.toLowerCase() === 'r') || input.key === 'F5') {
      console.log('[Dev] Recarga manual solicitada (F5 / Ctrl+R)');
      mainWindow.webContents.reloadIgnoringCache();
      event.preventDefault();
    }
  });

  // Iniciar el watcher
  setupAutoReload();
}
```

---

### Paso 3: Configurar Scripts en `package.json`

Asegura que el script de inicio apunte a Electron:

```json
{
  "scripts": {
    "start": "electron .",
    "dev": "electron ."
  }
}
```

---

## 🛡️ Protocolo de Ciclo de Vida Limpio en Desarrollo (Clean Lifecycle)

Cuando un desarrollador o agente de IA trabaja sobre el código fuente de Electron, relanzar automáticamente el ejecutable en cada micro-guardado genera **parpadeos, cierres sucesivos molestos y colisiones de sockets**. Aplica este protocolo:

1. **Al iniciar el desarrollo / refactorización:** Detener completamente los procesos de Electron (`Stop-Process -Name electron`).
2. **Durante la edición:** Realizar todas las modificaciones, pruebas unitarias y sincronizaciones en silencio sin abrir ventanas a medias.
3. **Al finalizar el trabajo:** Iniciar la aplicación **una sola vez** (`npm start`), garantizando una experiencia fluida y sin ventanas parpadeantes.

---

## 🛡️ Protocolo Anti-Regresión

1. **Exclusión Estricta de Carpetas de Datos/Búfer:**
   - El watcher debe vigilar **únicamente** las carpetas de código fuente (`renderer/`, `src/`). Nunca vigilar la raíz con archivos dinámicos (como `buffer/`, `logs/`, `exports/`, `.git/`), de lo contrario la aplicación se reiniciará en bucle infinito cada vez que guarde un archivo temporal o genere un clip.
2. **Liberación del Bloqueo (`app.releaseSingleInstanceLock()`):**
   - Siempre invocar `app.releaseSingleInstanceLock()` antes de `app.relaunch()`. Si no se libera, Windows detectará que la aplicación sigue abierta y abortará el nuevo proceso.
3. **Mata de Procesos Hijos:**
   - Si la app corre procesos secundarios (FFmpeg, Python, servidores HTTP), deben terminarse (`stopLiveHls()`) antes de `app.exit(0)` para no dejar sockets colgados en el puerto.
4. **Prevención de Tormenta de Reinicios (Relaunch Storm):**
   - Si se editan múltiples archivos del proceso principal en ráfaga (`main.js`, `preload.js`), es preferible no forzar `app.relaunch()` automático en cada guardado, sino recargar suavemente el renderer y dejar que el ciclo de vida del entorno reinicie la app una sola vez al terminar.

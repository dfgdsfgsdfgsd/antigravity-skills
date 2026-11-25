---
name: ota-telemetria-electron
description: Arquitectura completa de telemetría de distribución (conteo de máquinas únicas y sesiones con Machine ID anónimo) y motor de auto-actualizaciones remotas (OTA silencioso en segundo plano) con electron-builder y electron-updater. Alias: /actualizaciones-ota, /fleet-telemetry, /telemetria-electron
---

# /ota-telemetria-electron - Telemetría de Flota y Auto-Actualizaciones Remotas (OTA) en Electron

Esta skill implementa la arquitectura integral para **distribuir aplicaciones de escritorio en Electron para Windows**, saber con precisión **cuántas computadoras únicas usan la app** (Fleet Analytics) y desplegar **actualizaciones automáticas remotas (OTA - Over The Air)** sin que los usuarios finales tengan que descargar ejecutables manualmente.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** Node.js 18+ / Electron 28+ / Windows (NSIS).
- **Librerías Clave:** `electron-builder`, `electron-updater`, `crypto`, `os`, `https`.
- **Canal de Despliegue:** GitHub Releases (público o privado), Amazon S3, Cloudflare R2 o servidor HTTP/HTTPS propio.
- **Canal de Telemetría:** Webhooks HTTP no bloqueantes (Google Sheets / Google Apps Script, Supabase, Cloudflare Worker o Discord).

---

## 🔍 ¿Qué problemas resuelve esta arquitectura?

1. **Incertidumbre de Distribución:** Cuando pasas un archivo `.exe` o instalador, no sabes cuántas personas lo abrieron, en cuántas computadoras se instaló ni cuándo estuvieron activas.
2. **Falso Conteo por IP o Reinstalaciones:** Las IPs cambian o son compartidas (NAT/WiFi). Esta skill genera un `machine_id` persistente y anónimo ligado al hardware de la máquina en `%APPDATA%`, asegurando que cada PC se cuente como **1 máquina única**, incluso si reinstala la app.
3. **Fricción de Actualización:** Obligar a los usuarios a ir a un enlace de descarga, bajar un `.exe` de 150MB y reemplazar el programa provoca que el 80% de los usuarios queden en versiones viejas con errores. Con esta skill, la app detecta la actualización en segundo plano, la descarga en silencio y se actualiza sola al reiniciar en 3 segundos.

---

## 🛠️ Arquitectura Paso a Paso

### 1. Módulo de Telemetría de Flota (`telemetry.js`)

Genera un hash SHA-256 anónimo con datos estables del sistema (nombre de host, plataforma, procesador y memoria física) y almacena un registro permanente en la carpeta de datos de usuario de Windows:

```javascript
// telemetry.js
const fs = require('fs');
const path = require('path');
const os = require('os');
const https = require('https');
const crypto = require('crypto');

let machineData = null;
let currentSessionId = null;
let sessionStartTime = Date.now();
let userDataDir = '';
let appVersion = '1.0.0';
let TELEMETRY_ENDPOINT = process.env.APP_TELEMETRY_URL || '';

function generateMachineId() {
  const parts = [
    os.hostname() || 'host',
    os.platform() || 'platform',
    os.arch() || 'arch',
    (os.cpus() && os.cpus()[0] && os.cpus()[0].model) || 'cpu',
    os.totalmem() || 'mem'
  ];
  const rawHash = crypto.createHash('sha256').update(parts.join('::')).digest('hex').substring(0, 16);
  const randomSuffix = crypto.randomBytes(4).toString('hex');
  return `usr_${rawHash}_${randomSuffix}`;
}

function initMachineData(appInstance) {
  try {
    userDataDir = appInstance.getPath('userData');
    appVersion = appInstance.getVersion ? appInstance.getVersion() : '1.0.0';
  } catch (_) {
    userDataDir = process.cwd();
  }

  const machineFilePath = path.join(userDataDir, 'telemetry_machine.json');
  currentSessionId = `sess_${crypto.randomBytes(8).toString('hex')}`;
  sessionStartTime = Date.now();

  try {
    if (fs.existsSync(machineFilePath)) {
      machineData = JSON.parse(fs.readFileSync(machineFilePath, 'utf8'));
    }
  } catch (_) {
    machineData = null;
  }

  if (!machineData || !machineData.machine_id) {
    machineData = {
      machine_id: generateMachineId(),
      first_installed_at: new Date().toISOString(),
      total_launches: 1,
      last_seen_at: new Date().toISOString(),
      created_version: appVersion,
      current_version: appVersion
    };
  } else {
    machineData.total_launches = (machineData.total_launches || 0) + 1;
    machineData.last_seen_at = new Date().toISOString();
    machineData.current_version = appVersion;
  }

  try {
    fs.writeFileSync(machineFilePath, JSON.stringify(machineData, null, 2), 'utf8');
  } catch (_) {}

  return machineData;
}
```

### 2. Emisión de Latidos Silenciosos (Heartbeats)

Un temporizador en segundo plano emite un latido al arrancar y luego cada 15 minutos con timeout estricto de 6 segundos y captura silenciosa de errores:

```javascript
function sendHeartbeat(extraMetrics = {}) {
  const payload = {
    event: 'heartbeat',
    timestamp: new Date().toISOString(),
    machine_id: machineData.machine_id,
    session_id: currentSessionId,
    app_version: appVersion,
    total_launches: machineData.total_launches,
    session_uptime_sec: Math.round((Date.now() - sessionStartTime) / 1000),
    os: {
      platform: os.platform(),
      release: os.release(),
      cpus: os.cpus().length,
      ram_gb: Math.round(os.totalmem() / (1024 * 1024 * 1024))
    },
    metrics: extraMetrics
  };

  if (!TELEMETRY_ENDPOINT) return Promise.resolve();
  // Envío POST asíncrono con https.request no bloqueante...
}
```

---

### 3. Motor de Actualizaciones Remotas (`updater.js`)

Utiliza `electron-updater` con control de estados y retransmisión por IPC hacia la interfaz gráfica:

```javascript
// updater.js
const { app, ipcMain } = require('electron');
const { autoUpdater } = require('electron-updater');

let updaterState = {
  status: 'idle', // 'checking' | 'available' | 'downloading' | 'downloaded' | 'not-available'
  currentVersion: '1.0.0',
  availableVersion: null,
  progress: { percent: 0 }
};

function initAutoUpdater(win) {
  autoUpdater.autoDownload = true;
  autoUpdater.autoInstallOnAppQuit = true;

  autoUpdater.on('update-available', (info) => {
    updaterState.status = 'available';
    updaterState.availableVersion = info.version;
    win.webContents.send('updater:status', updaterState);
  });

  autoUpdater.on('download-progress', (progressObj) => {
    updaterState.status = 'downloading';
    updaterState.progress.percent = Math.round(progressObj.percent || 0);
    win.webContents.send('updater:status', updaterState);
  });

  autoUpdater.on('update-downloaded', (info) => {
    updaterState.status = 'downloaded';
    updaterState.availableVersion = info.version;
    win.webContents.send('updater:status', updaterState);
  });

  if (app.isPackaged) {
    autoUpdater.checkForUpdatesAndNotify().catch(() => {});
  }
}
```

---

### 4. Configuración en `package.json`

Para que `electron-builder` genere el ejecutable NSIS y el archivo de control `latest.yml`:

```json
{
  "dependencies": {
    "electron-updater": "^6.3.9"
  },
  "devDependencies": {
    "electron-builder": "^25.1.8"
  },
  "scripts": {
    "build:win": "electron-builder --win",
    "release": "electron-builder --win --publish always"
  },
  "build": {
    "appId": "com.tuapp.desktop",
    "productName": "TuApp Desktop",
    "directories": { "output": "dist" },
    "win": {
      "target": [{ "target": "nsis", "arch": ["x64"] }]
    },
    "nsis": {
      "oneClick": false,
      "allowToChangeInstallationDirectory": true,
      "createDesktopShortcut": true,
      "runAfterFinish": true
    },
    "publish": {
      "provider": "github",
      "owner": "TU_USUARIO",
      "repo": "tu-repositorio"
    }
  }
}
```

---

## 🛡️ Protocolo Anti-Regresión y Seguridad

1. **Aislamiento en Desarrollo (`!app.isPackaged`):**
   - El updater debe verificar `app.isPackaged`. En modo dev no debe intentar descargar ni lanzar excepciones por falta de `app-update.yml`.
2. **Cero Caídas por Falta de Conexión:**
   - Tanto la telemetría como el updater deben envolver sus llamadas HTTP en timeouts y capturar excepciones silenciosamente. Si el usuario está offline o sin internet, la aplicación debe arrancar y operar al 100%.
3. **Watcher de Archivos en Desarrollo (`setupAutoReload`):**
   - Asegurarse de que el watcher ignore `dist/`, `telemetry_machine.json` y `telemetry_events.log` para evitar bucles infinitos de reinicio.
4. **Instalación No Disruptiva:**
   - `autoUpdater.autoInstallOnAppQuit = true` permite que la actualización se instale sola cuando el usuario decida cerrar el programa, sin interrumpir su trabajo.

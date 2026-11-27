/**
 * =========================================================================
 * SNIPPET DE INTEGRACIÓN PARA CUALQUIER APP ELECTRON
 * =========================================================================
 */

// 1. EN main.js:
// -------------------------------------------------------------------------
const { app, BrowserWindow, ipcMain } = require('electron');
const telemetry = require('./telemetry');
const licenseControl = require('./license_control');

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false
    }
  });

  // Iniciar telemetría (Google Sheets $0)
  telemetry.startTelemetry(app);

  // Iniciar monitor de licencias (Gist $0)
  const machineId = telemetry.getMachineId();
  licenseControl.startLicenseMonitor(app, machineId, mainWindow, (blockedState) => {
    // Si está bloqueado, notificar a la interfaz
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.send('license:status', blockedState);
    }
  });

  mainWindow.loadFile('renderer/index.html');
}

// IPC Handlers de Licencia y Cuota Diaria
ipcMain.handle('license:get-status', async () => {
  return licenseControl.getLicenseState();
});

ipcMain.handle('license:get-daily-usage', async () => {
  const lic = licenseControl.getLicenseState();
  const usage = licenseControl.getDailyUsage();
  const can = licenseControl.checkCanExport(lic.isPro);
  return {
    ...usage,
    isPro: lic.isPro,
    canExport: can.canExport,
    remaining: can.remaining,
    limit: can.limit
  };
});

ipcMain.handle('license:record-usage', async () => {
  return licenseControl.recordUsage();
});


// 2. EN preload.js:
// -------------------------------------------------------------------------
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('api', {
  getLicenseStatus: () => ipcRenderer.invoke('license:get-status'),
  getDailyUsage: () => ipcRenderer.invoke('license:get-daily-usage'),
  recordUsage: () => ipcRenderer.invoke('license:record-usage'),
  onLicenseBlocked: (callback) => ipcRenderer.on('license:status', (event, data) => callback(data))
});


// 3. EN renderer.js (UI):
// -------------------------------------------------------------------------
async function updateDailyCounterBadge() {
  const info = await window.api.getDailyUsage();
  const container = document.getElementById('dailyUsageBadge');
  if (!container) return;

  if (info.isPro) {
    container.innerHTML = `⭐ <strong>PRO:</strong> Usos Ilimitados`;
    container.className = 'badge-pro';
  } else {
    container.innerHTML = `🎬 Usos hoy: <strong>${info.count} / ${info.limit}</strong>`;
    container.className = info.count >= info.limit ? 'badge-limit' : 'badge-normal';
  }
}

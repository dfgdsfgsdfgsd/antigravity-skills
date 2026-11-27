const fs = require('fs');
const path = require('path');
const os = require('os');
const https = require('https');
const http = require('http');
const crypto = require('crypto');

/**
 * Módulo Universal de Telemetría y Flota (Google Sheets $0)
 * ---------------------------------------------------------
 * Genera un ID anónimo por hardware en %APPDATA%, cuenta aperturas,
 * mide minutos de uso acumulados y envía latidos no-bloqueantes.
 */

let machineData = null;
let currentSessionId = null;
let sessionStartTime = Date.now();
let heartbeatTimer = null;
let userDataDir = '';
let appVersion = '1.0.0';
let TELEMETRY_ENDPOINT = process.env.APP_TELEMETRY_URL || '';

function loadTelemetryEndpoint() {
  if (process.env.APP_TELEMETRY_URL) {
    TELEMETRY_ENDPOINT = process.env.APP_TELEMETRY_URL.trim();
    return;
  }
  const localFile = path.join(__dirname, 'telemetry_url.txt');
  if (fs.existsSync(localFile)) {
    try {
      const u = fs.readFileSync(localFile, 'utf8').trim();
      if (u) { TELEMETRY_ENDPOINT = u; return; }
    } catch (_) {}
  }
  try {
    const userFile = path.join(userDataDir, 'telemetry_url.txt');
    if (fs.existsSync(userFile)) {
      const u = fs.readFileSync(userFile, 'utf8').trim();
      if (u) { TELEMETRY_ENDPOINT = u; return; }
    }
  } catch (_) {}
}

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
  return `app_${rawHash}_${randomSuffix}`;
}

function initMachineData(appInstance) {
  try {
    userDataDir = appInstance.getPath('userData');
    appVersion = appInstance.getVersion ? appInstance.getVersion() : '1.0.0';
  } catch (_) {
    userDataDir = process.cwd();
  }

  loadTelemetryEndpoint();

  const machineFilePath = path.join(userDataDir, 'telemetry_machine.json');
  currentSessionId = `sess_${crypto.randomBytes(8).toString('hex')}`;
  sessionStartTime = Date.now();

  try {
    if (fs.existsSync(machineFilePath)) {
      const raw = fs.readFileSync(machineFilePath, 'utf8');
      machineData = JSON.parse(raw);
    }
  } catch (err) {
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
  } catch (err) {
    console.warn('[Telemetry] No se pudo guardar telemetry_machine.json:', err.message);
  }

  return machineData;
}

function getSystemMetrics() {
  const cpus = os.cpus() || [];
  return {
    os_platform: os.platform(),
    os_release: os.release(),
    cpu_model: (cpus[0] && cpus[0].model) || 'Desconocido',
    cpu_cores: cpus.length,
    ram_total_gb: Math.round((os.totalmem() / (1024 ** 3)) * 10) / 10,
    ram_free_gb: Math.round((os.freemem() / (1024 ** 3)) * 10) / 10
  };
}

function sendHeartbeat(eventType = 'heartbeat', extraMeta = {}) {
  if (!TELEMETRY_ENDPOINT) return;
  if (!machineData) return;

  const uptimeMinutes = Math.round((Date.now() - sessionStartTime) / 60000);
  const payload = {
    machine_id: machineData.machine_id,
    session_id: currentSessionId,
    event_type: eventType,
    app_version: appVersion,
    total_launches: machineData.total_launches,
    session_minutes: uptimeMinutes,
    system: getSystemMetrics(),
    timestamp: new Date().toISOString(),
    ...extraMeta
  };

  const jsonStr = JSON.stringify(payload);
  try {
    const parsed = new URL(TELEMETRY_ENDPOINT);
    const client = parsed.protocol === 'https:' ? https : http;
    const req = client.request(parsed, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(jsonStr)
      },
      timeout: 6000
    });
    req.on('error', () => {});
    req.write(jsonStr);
    req.end();
  } catch (_) {}
}

function startTelemetry(appInstance) {
  initMachineData(appInstance);
  sendHeartbeat('app_start');
  if (heartbeatTimer) clearInterval(heartbeatTimer);
  heartbeatTimer = setInterval(() => {
    sendHeartbeat('heartbeat');
  }, 15 * 60 * 1000); // Latido cada 15 min
}

function stopTelemetry() {
  if (heartbeatTimer) clearInterval(heartbeatTimer);
  sendHeartbeat('app_close');
}

function getMachineId() {
  return machineData ? machineData.machine_id : 'sin_id';
}

module.exports = {
  startTelemetry,
  stopTelemetry,
  sendHeartbeat,
  getMachineId,
  initMachineData
};

const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

/**
 * Módulo Universal de Monetización Freemium y Kill Switch (Gist $0)
 * ------------------------------------------------------------------
 * • Control diario de exportaciones/usos con reseteo a medianoche.
 * • Consulta remota no-bloqueante a control.json en GitHub Gist.
 * • Soporte para licencias PRO específicas o comodín "*".
 * • Persistencia anti-bypass en disco (license_lock.json).
 */

let controlUrl = process.env.APP_CONTROL_URL || '';
let checkIntervalTimer = null;
let mainWindowRef = null;
let userDataDir = '';
let defaultFreeLimit = 3;

let currentBlockState = {
  isBlocked: false,
  isPro: false,
  reason: '',
  blockedAt: null,
  contactInfo: '',
  machineId: ''
};

function getFreeLimit() {
  return defaultFreeLimit;
}

function getDailyUsageFile() {
  return path.join(userDataDir, 'daily_usage.json');
}

function getTodayString() {
  return new Date().toISOString().split('T')[0]; // "YYYY-MM-DD"
}

function getDailyUsage() {
  const file = getDailyUsageFile();
  const today = getTodayString();
  let usage = { date: today, count: 0, lastExportTime: null };
  try {
    if (fs.existsSync(file)) {
      const parsed = JSON.parse(fs.readFileSync(file, 'utf8'));
      if (parsed && parsed.date === today) {
        usage = parsed;
      }
    }
  } catch (_) {}
  return usage;
}

function recordUsage() {
  const file = getDailyUsageFile();
  const today = getTodayString();
  const usage = getDailyUsage();
  if (usage.date !== today) {
    usage.date = today;
    usage.count = 0;
  }
  usage.count += 1;
  usage.lastExportTime = Date.now();
  try {
    fs.writeFileSync(file, JSON.stringify(usage, null, 2), 'utf8');
  } catch (_) {}
  return usage;
}

function checkCanExport(isPro) {
  if (isPro) {
    return { canExport: true, isPro: true, count: 0, limit: Infinity, remaining: Infinity };
  }
  const usage = getDailyUsage();
  const limit = defaultFreeLimit || 3;
  const remaining = Math.max(0, limit - usage.count);
  return {
    canExport: usage.count < limit,
    isPro: false,
    count: usage.count,
    limit: limit,
    remaining: remaining
  };
}

function sanitizeControlUrl(u) {
  if (!u) return '';
  let cleaned = String(u).trim();
  // Remueve commit hash si el usuario copió el enlace específico de Gist
  cleaned = cleaned.replace(/\/raw\/[a-f0-9]{40}\//i, '/raw/');
  return cleaned;
}

function loadControlUrl(appInstance) {
  if (process.env.APP_CONTROL_URL) {
    controlUrl = sanitizeControlUrl(process.env.APP_CONTROL_URL);
    return controlUrl;
  }
  const localFile = path.join(__dirname, 'control_url.txt');
  if (fs.existsSync(localFile)) {
    try {
      const u = fs.readFileSync(localFile, 'utf8').trim();
      if (u) { controlUrl = sanitizeControlUrl(u); return controlUrl; }
    } catch (_) {}
  }
  try {
    const userFile = path.join(userDataDir, 'control_url.txt');
    if (fs.existsSync(userFile)) {
      const u = fs.readFileSync(userFile, 'utf8').trim();
      if (u) { controlUrl = sanitizeControlUrl(u); return controlUrl; }
    }
  } catch (_) {}
  return controlUrl;
}

function getLockFilePath() {
  return path.join(userDataDir, 'license_lock.json');
}

function checkLocalLockFile(machineId) {
  const lockPath = getLockFilePath();
  if (fs.existsSync(lockPath)) {
    try {
      const raw = fs.readFileSync(lockPath, 'utf8');
      const data = JSON.parse(raw);
      if (data && data.isBlocked) {
        currentBlockState = {
          isBlocked: true,
          isPro: false,
          reason: data.reason || 'Licencia suspendida.',
          blockedAt: data.blockedAt || new Date().toISOString(),
          contactInfo: data.contactInfo || '',
          machineId: machineId
        };
        return true;
      }
    } catch (_) {}
  }
  return false;
}

function saveLocalLockFile(state) {
  try {
    const lockPath = getLockFilePath();
    if (state.isBlocked) {
      fs.writeFileSync(lockPath, JSON.stringify(state, null, 2), 'utf8');
    } else if (fs.existsSync(lockPath)) {
      fs.unlinkSync(lockPath);
    }
  } catch (_) {}
}

function fetchRemoteControl(url) {
  return new Promise((resolve, reject) => {
    try {
      const parsed = new URL(url);
      parsed.searchParams.set('_t', Date.now().toString());
      const client = parsed.protocol === 'https:' ? https : http;
      const req = client.get(parsed, { timeout: 7000 }, (res) => {
        if (res.statusCode < 200 || res.statusCode >= 300) {
          return reject(new Error(`HTTP ${res.statusCode}`));
        }
        let data = '';
        res.on('data', chunk => { data += chunk; });
        res.on('end', () => {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(new Error('JSON malformado'));
          }
        });
      });
      req.on('error', reject);
      req.on('timeout', () => { req.destroy(); reject(new Error('Timeout')); });
    } catch (err) {
      reject(err);
    }
  });
}

async function verifyLicense(machineId, appInstance) {
  if (checkLocalLockFile(machineId)) {
    return currentBlockState;
  }
  if (!controlUrl) return currentBlockState;

  try {
    const remote = await fetchRemoteControl(controlUrl);

    // 1. Kill switch global
    if (remote.global_active === false) {
      currentBlockState = {
        isBlocked: true,
        isPro: false,
        reason: remote.kill_message || 'El servicio está suspendido temporalmente.',
        blockedAt: new Date().toISOString(),
        contactInfo: remote.contact_info || '',
        machineId
      };
      saveLocalLockFile(currentBlockState);
      return currentBlockState;
    }

    // 2. Máquina bloqueada selectivamente
    const blockedList = Array.isArray(remote.blocked_machines) ? remote.blocked_machines : [];
    if (blockedList.includes(machineId)) {
      currentBlockState = {
        isBlocked: true,
        isPro: false,
        reason: 'Esta instalación ha sido revocada.',
        blockedAt: new Date().toISOString(),
        contactInfo: remote.contact_info || '',
        machineId
      };
      saveLocalLockFile(currentBlockState);
      return currentBlockState;
    }

    // 3. Licencia PRO (Comodín "*" o ID específico)
    const proList = Array.isArray(remote.pro_machines) ? remote.pro_machines : [];
    const hasPro = proList.includes('*') || proList.includes(machineId);

    // Si estaba todo bien, desbloqueo limpio
    currentBlockState = {
      isBlocked: false,
      isPro: hasPro,
      reason: '',
      blockedAt: null,
      contactInfo: '',
      machineId
    };
    saveLocalLockFile(currentBlockState);
  } catch (err) {
    // Si falla la red pero no estaba bloqueado previamente, permitir continuar
    console.warn('[LicenseControl] No se pudo verificar en remoto, operando en modo offline.');
  }

  return currentBlockState;
}

function startLicenseMonitor(appInstance, machineId, win, onBlockCallback) {
  try {
    userDataDir = appInstance.getPath('userData');
  } catch (_) {
    userDataDir = process.cwd();
  }
  mainWindowRef = win;
  loadControlUrl(appInstance);

  const initialCheck = () => {
    verifyLicense(machineId, appInstance).then(state => {
      if (state.isBlocked && onBlockCallback) {
        onBlockCallback(state);
      }
    });
  };

  initialCheck();
  if (checkIntervalTimer) clearInterval(checkIntervalTimer);
  checkIntervalTimer = setInterval(initialCheck, 10 * 60 * 1000); // Chequeo cada 10 min
}

function getLicenseState() {
  return currentBlockState;
}

module.exports = {
  startLicenseMonitor,
  verifyLicense,
  getLicenseState,
  getDailyUsage,
  recordUsage,
  checkCanExport,
  getFreeLimit
};

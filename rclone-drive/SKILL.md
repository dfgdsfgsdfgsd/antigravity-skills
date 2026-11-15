---
name: rclone-drive
description: Orquestación, sincronización diferencial y gestión multi-cuenta de Google Drive sin cliente oficial mediante binarios portables de rclone. Alias: /rclone-gdrive, /google-drive-sync
---

# /rclone-drive - Sincronización y Gestión Multi-Cuenta de Google Drive con rclone

Esta skill enseña a orquestar, automatizar y sincronizar carpetas locales hacia múltiples cuentas de **Google Drive** de manera autónoma, ultra-rápida y diferencial, utilizando el binario portable de **rclone** sin necesidad de instalar la aplicación oficial de Google Drive en Windows ni consumir cientos de megabytes de RAM en segundo plano.

---

## 💻 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** CLI / C# / Python / PowerShell / Node.js
- **Plataforma:** Windows 10, 11 (x64 / x86), Linux, macOS
- **Binario Requerido:** `rclone.exe` (portable, alojado en `tools/` o en `PATH`)
- **Dependencias del Sistema:** Conexión a internet HTTPS (puerto 443) y navegador web para la autorización OAuth2 inicial.

---

## 🛡️ Paso 0: Verificación de Entorno (Guarda de Seguridad)

Antes de invocar comandos de rclone:
1. Verificar la presencia del binario:
   ```powershell
   Test-Path "tools\rclone.exe"
   # o en sistema:
   Get-Command rclone -ErrorAction SilentlyContinue
   ```
2. Comprobar conectividad rápida contra el endpoint de Google (sin descargar datos pesados):
   ```powershell
   try {
       $req = [System.Net.WebRequest]::Create("https://clients3.google.com/generate_204")
       $req.Timeout = 4000
       $res = $req.GetResponse()
       $res.Close()
       # Conexión confirmada
   } catch {
       Write-Warning "Sin conexión a internet hacia los servidores de Google."
   }
   ```

---

## 🏗️ Capacidades y Flujos Clave

### 1. Sincronización Diferencial Estricta (Anti-Duplicación)
La API de Google Drive maneja marcas de tiempo en UTC con variaciones de hasta 1 segundo respecto a sistemas de archivos NTFS de Windows. Para evitar re-subir gigabytes de archivos que no han cambiado:
```powershell
tools\rclone.exe sync "D:\Proyectos\MiCarpeta" "gdrive:/Backups_Proyectos/MiCarpeta" `
    --update `
    --modify-window 2s `
    --fast-list `
    --transfers 4 `
    --checkers 8 `
    --contimeout 5s `
    --timeout 15s `
    --retries 2
```
* `--update`: Solo sube archivos si la versión local es más nueva que la remota.
* `--modify-window 2s`: Ignora discrepancias de tiempo menores a 2 segundos (tolerancia NTFS / Cloud).
* `--fast-list`: Lista el directorio remoto en un solo lote en memoria, reduciendo el 90% de las llamadas a la API de Google y acelerando el escaneo.

### 2. Vinculación Multi-Cuenta OAuth2 sin Servidor Externo
Para vincular cuentas de Google Drive (`gdrive`, `gdrive2`, `gdrive_trabajo`):
```powershell
tools\rclone.exe config create gdrive drive `
    config_is_local=true `
    scope=drive
```
* Abre automáticamente el navegador predeterminado para autorizar la cuenta con Google.
* Guarda el token de acceso y refresco en `tools/rclone.conf`.
* Los tokens se renuevan solos de por vida sin pedir re-autenticación al usuario.

### 3. Consulta en Vivo de Cuota y Espacio (`rclone about`)
Permite saber exactamente cuántos gigabytes quedan disponibles en la cuenta de Google Drive en formato JSON:
```powershell
tools\rclone.exe about gdrive: --json
```
**Respuesta JSON esperada:**
```json
{
  "total": 16106127360,
  "used": 8589934592,
  "free": 7516192768,
  "trashed": 104857600
}
```

### 4. Selector de Perfiles Google en Navegador (`AccountChooser`)
Al abrir una carpeta de Google Drive en el navegador, Google por defecto carga la cuenta de sesión 0 del navegador. Para forzar a que abra la cuenta exacta vinculada:
```
https://accounts.google.com/AccountChooser?Email=usuario@gmail.com&continue=https%3A%2F%2Fdrive.google.com%2Fdrive%2Fmy-drive
```
* Si la cuenta ya está iniciada en Chrome/Edge, Google cambia automáticamente a esa cuenta y muestra su Drive.
* Si no está iniciada, abre el formulario con el correo pre-rellenado para evitar que el usuario abra archivos en la cuenta equivocada.

---

## ⚠️ Protocolo Anti-Regresión

1. **Excluir `rclone.conf` de Git:**
   - Contiene tokens OAuth y credenciales privadas. Agregar obligatoriamente `tools/*.conf` al `.gitignore`.
2. **Evitar bloqueos por falta de internet:**
   - Usar `--contimeout 5s --timeout 15s` para que el proceso no quede colgado indefinidamente si se corta la conexión WiFi durante una sincronización en segundo plano.
3. **No usar `copy` cuando se desea paridad espejo:**
   - `rclone copy` no elimina archivos borrados en local. Si se busca réplica exacta, usar `rclone sync`.

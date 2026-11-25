---
name: kill-switch-electron
description: Implementa sistema de desactivación remota (Kill Switch), control de licencias y bloqueo selectivo por Machine ID mediante archivo JSON en GitHub/Gist con pantalla de bloqueo infranqueable y persistencia anti-bypass para aplicaciones Electron en Windows. Alias: /desactivar-remoto, /licencia-remota
---

# /kill-switch-electron - Desactivación Remota y Control de Licencias para Electron

Esta skill implementa un motor de **Kill Switch remoto y control de licencias** para aplicaciones de escritorio desarrolladas con **Electron en Windows**. Permite al creador suspender la app globalmente, bloquear máquinas específicas por su **Machine ID único**, o forzar la actualización a una versión mínima requerida, todo controlado mediante un simple archivo `control.json` alojado de forma gratuita en **GitHub** o **GitHub Gist**.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Stack compatible:** `Node.js + Electron` (Windows, macOS, Linux).
- **Entorno de control:** GitHub (Repositorio público/privado) o GitHub Gist (Secret Gist).
- **Requisitos previos:**
  - Node.js 18+ y Electron 20+.
  - Módulo `https` o `http` nativo de Node.js (cero dependencias externas npm).
  - Almacenamiento seguro en `%APPDATA%` (`app.getPath('userData')`).

---

## 🛡️ Paso 0: Verificación de Entorno (Guarda de Seguridad)

Antes de inyectar los archivos, verificar que el proyecto actual sea una aplicación Electron válida:
1. Comprobar existencia de `package.json` con dependencia de `"electron"`.
2. Verificar la presencia de `main.js` (o entrypoint principal de Electron) y `preload.js`.
3. Si el proyecto no es de Electron, advertir al usuario y sugerir la adaptación correspondiente a su stack.

---

## 🏗️ Arquitectura del Sistema

```mermaid
flowchart TD
    A["SubiClip / App Electron"] -->|"1. Al iniciar + cada 10 min (con timestamp anti-cache)"| B["GitHub Raw / Gist: control.json"]
    B -->|"2. Responde JSON con reglas"| A
    A -->|"3. Evalúa reglas"| C{"¿Bloqueado?"|
    C -->|"global_active == false"| D["⛔ Bloqueo Global Inmediato"]
    C -->|"machine_id en blocked_machines"| E["🚫 Bloqueo Selectivo de Máquina"]
    C -->|"app_version < min_allowed_version"| F["🔄 Bloqueo por Versión Caducada"]
    C -->|"Todo en orden"| G["✅ Ejecución Normal"]
    D & E & F --> H["Persistir license_lock.json en disco (Anti-Bypass Offline)"]
    H --> I["Detener FFmpeg / Procesos + Mostrar Pantalla Infranqueable"]
```

---

## 📂 Archivos y Componentes Clave

### 1. `license_control.js` (Motor Central de Validación)
Maneja la lectura de la URL de control (desde archivo local `subiclip_control_url.txt` o variable de entorno `SUBICLIP_CONTROL_URL`), la consulta HTTP/HTTPS GET con cabeceras anti-caché y seguimiento de redirecciones 301/302, la comparación SemVer de versiones y la persistencia local de seguridad.

### 2. Estructura del Archivo Remoto `control.json` (GitHub / Gist)
```json
{
  "global_active": true,
  "global_message": "El software ha sido desactivado temporalmente por el administrador.",
  "blocked_machines": [
    "subi_a73d8f1e2c90_8421"
  ],
  "min_allowed_version": "1.0.0",
  "outdated_message": "Esta versión ha caducado. Por favor descarga la actualización más reciente.",
  "contact_info": "Soporte: contacto@tudominio.com | WhatsApp: +00 0000 0000"
}
```

### 3. Pantalla de Bloqueo Infranqueable (`renderer/index.html` y `renderer/style.css`)
- Modal fijado a pantalla completa (`z-index: 99999999`, `backdrop-filter: blur(12px)`).
- Bloquea cualquier interacción con el resto de la interfaz.
- Muestra el motivo exacto, datos de contacto y el **Machine ID** en una caja con botón de un clic para copiar al portapapeles.
- Botones de acción: `🔄 Reintentar Verificación` y `✕ Cerrar Programa`.

### 4. Blindaje en `main.js` y `preload.js`
- Detención de procesos pesados (FFmpeg, streaming, WebSockets) al detectar la desactivación.
- Los handlers IPC de inicio de stream o clipeo verifican `licenseControl.getBlockState().isBlocked` antes de proceder.
- El atajo global (ej. `F9`) se inhabilita para evitar llamadas indebidas.

---

## 🔒 Protocolo de Seguridad Anti-Bypass

1. **Anti-Desconexión de Cable (Offline Bypass):**
   - Si un usuario apaga el WiFi o retira el cable de red después de ser bloqueado, el archivo local `license_lock.json` en `%APPDATA%` mantendrá la app bloqueada permanentemente hasta que el administrador lo desbloquee en GitHub y vuelva a conectarse.
2. **Anti-Caché CDN de GitHub:**
   - Cada consulta añade `_t=Date.now()` a la query string y envía cabeceras `Cache-Control: no-cache, no-store` para garantizar lectura en tiempo real y evitar que GitHub sirva un JSON desactualizado.
3. **Auto-Desbloqueo Limpio:**
   - En cuanto el administrador retira el ID de `blocked_machines` o reactiva `global_active: true`, el siguiente ciclo de sondeo o el botón de reintento elimina `license_lock.json` y restaura el acceso al instante.

---

## ⚡ Comandos y Acciones Rápidas

| Acción Deseada | Cambio en GitHub `control.json` | Resultado en los Equipos |
| :--- | :--- | :--- |
| **Apagar la app para todos** | `"global_active": false` | Todos los programas se bloquean en ≤ 10 min. |
| **Suspender a un cliente específico** | Añadir su `machine_id` en `"blocked_machines"` | Solo esa PC queda bloqueada; los demás siguen. |
| **Desbloquear a un cliente** | Quitar su `machine_id` de `"blocked_machines"` | Se reactiva automáticamente en la próxima consulta. |
| **Forzar actualización** | `"min_allowed_version": "1.1.0"` | Quien tenga `< 1.1.0` verá aviso de actualización obligatoria. |

---
name: radar
description: Radiografía instantánea de todos los proyectos en disco (estado de Git, ramas, cambios pendientes y sincronización con GitHub) junto con un sistema de recordatorios técnicos persistentes y sincronización masiva en lote.
---

# /radar - Centro de Control, Estado de Proyectos y Recordatorios Persistentes

Esta skill se activa con `/radar` o sus alias `/actualizar-proyectos` y `/pendientes`. Funciona como la torre de control de todo tu espacio de trabajo (por defecto `D:\Proyectos`), permitiendo en un solo comando:

1. **Radiografía Completa en Segundos:** Escanea todos los proyectos, detecta sus ramas activas, remotos en GitHub y si tienen archivos modificados sin guardar.
2. **Radar de Pendientes y Recordatorios:** Muestra tareas técnicas activas registradas en memoria persistente (ej. repositorios que faltan crear en GitHub, features por terminar).
3. **Sincronización Masiva en Lote:** Con un solo comando (`/actualizar-proyectos` o `/radar sync`), guarda y sube todos los proyectos pendientes a GitHub de un solo tiro.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** Universal (PowerShell 5.1+ / Git en Windows).
- **Ruta Base Monitoreada:** `D:\Proyectos` (configurable a cualquier directorio).
- **Almacenamiento Persistente:** `C:\Users\Daniel\.gemini\config\recordatorios.json`.

---

## 🛠️ Modos de Uso Paso a Paso

### 1. Ver el Radar y Estado General (Solo Lectura)
Muestra la tabla de todos los repositorios y las alertas activas sin tocar ningún archivo:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\Daniel\.gemini\config\skills\radar\scripts\radar_proyectos.ps1" -Accion "estado"
```

* **Disparadores en chat:** `/radar`, `/estado-proyectos`, *"¿cómo están mis proyectos?"*.

---

### 2. Sincronizar Todos los Proyectos en Lote a GitHub
Detecta cada repositorio con cambios pendientes, genera el commit, hace rebase y lo sube automáticamente a su respectivo remoto en GitHub:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\Daniel\.gemini\config\skills\radar\scripts\radar_proyectos.ps1" -Accion "sync"
```

* **Disparadores en chat:** `/actualizar-proyectos`, `/radar sync`, *"sube todos los proyectos a github"*.

---

### 3. Ver o Agregar Recordatorios Persistentes
* **Ver recordatorios:**
  ```powershell
  powershell -ExecutionPolicy Bypass -File "C:\Users\Daniel\.gemini\config\skills\radar\scripts\radar_proyectos.ps1" -Accion "recordatorios"
  ```
  *Disparador:* `/pendientes`

* **Agregar nuevo recordatorio:**
  ```powershell
  powershell -ExecutionPolicy Bypass -File "C:\Users\Daniel\.gemini\config\skills\radar\scripts\radar_proyectos.ps1" -Accion "agregar" -NuevoRecordatorio "Revisar token de Supabase en agencyos"
  ```
  *Disparador:* *"recuérdame que X"* o `/radar agregar "..."`.

---

## 🛡️ Protocolo Anti-Regresión y Seguridad

1. **Protección de Binarios:** No intenta subir ejecutables pesados (`.exe`, `.dll` > 50MB); respeta `.gitignore` en cada repositorio.
2. **Detección de Remotos Externos:** Distingue entre tus repositorios personales (`dfgdsfgsdfgsd/...`) y forks upstream externos (como `Vette1123/...`), alertando al usuario antes de fallar.
3. **Persistencia Garantizada:** Los recordatorios se guardan en un archivo JSON centralizado en la configuración global de Antigravity para que sobrevivan a cualquier reinicio de conversación.

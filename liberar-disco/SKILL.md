---
name: liberar-disco
description: Diagnostica saturación de disco al 100%, termina procesos zombis y optimiza cuellos de botella HDD/USB. Alias: /disco-100
---

# /liberar-disco - Protocolo de Diagnóstico y Liberación de Disco al 100% y Procesos Zombis

Esta skill se activa con `/liberar-disco` o su alias `/disco-100`. Proporciona el protocolo técnico completo para diagnosticar, erradicar y solucionar el problema de **disco saturado al 100%**, latencias de respuesta extremas (>1.000 ms) y cuellos de botella causados por procesos invisibles/huérfanos en segundo plano en sistemas Windows.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Sistema Operativo:** Windows 10 / Windows 11.
- **Entorno:** PowerShell 5.1+ / PowerShell Core.
- **Stack Compatible:** Universal (Node.js, Next.js, Python, Vite, C++, Docker, Git, etc.).
- **Unidades:** Discos locales SSD/HDD (C:, D:) y discos externos USB (Seagate, WD, Kingston, etc.).

---

## 🔍 Paso 0: Diagnóstico de la Causa Raíz

Cuando un disco marca **100% de uso** pero transfiere velocidades irrisorias (pocos KB/s) y la latencia sube a más de 1.000 ms, casi nunca se trata de falta de RAM o de un fallo físico inmediato; suele deberse a uno de estos 4 factores:

1. **Procesos Huérfanos / Zombis Headless:**
   - Servidores de desarrollo (`next dev`, `python server.py`, `vite`) lanzados desde terminales integradas de editores o sesiones de agentes de IA que se cierran sin matar a sus procesos hijos.
   - Estos procesos quedan vivos en memoria sin ventana visible en la barra de tareas, pero ejecutando *file watchers* activos que monitorean decenas de miles de archivos.
2. **Entornos de Desarrollo en Discos Mecánicos USB:**
   - Carpetas masivas como `node_modules` o `.next` (30.000 a 60.000 micro-archivos) corriendo sobre un HDD externo USB (5400 RPM / discos SMR). Los cabezales mecánicos colapsan con el acceso concurrente a miles de archivos pequeños.
3. **Comandos en Bucle Infinito o Sintaxis Rota:**
   - Procesos `cmd.exe` o `powershell.exe` ejecutando comandos como `rmdir /s /q " ruta\` con comillas mal cerradas o recursiones circulares que quedan atrapados leyendo `$BitMap` o la MFT (Master File Table) de NTFS al 100% de CPU y disco.
4. **Inspección de Archivos Masivos (Antivirus / Indexador):**
   - Windows Defender (`MsMpEng.exe`) o Windows Search (`SearchIndexer.exe`) recorriendo carpetas con miles de fragmentos de código (ej. APKs descompilados con carpetas `smali_classes`), lo que genera una avalancha de escrituras en `$I30` y metadatos por parte del proceso `System` (PID 4).

---

## 🛠️ Procedimiento de Solución en 4 Pasos

### Paso 1: Medir el Estado y la Cola del Disco en Tiempo Real

Ejecuta en PowerShell para obtener las métricas reales del disco sin depender de la UI:

```powershell
Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk | 
    Select-Object Name, PercentDiskTime, CurrentDiskQueueLength, AvgDiskSecPerTransfer | 
    Format-Table
```

* **Interpretación:**
  - `PercentDiskTime > 80%`: Saturación activa.
  - `CurrentDiskQueueLength > 2.0`: Hay un embudo masivo de lecturas/escrituras encoladas.
  - `AvgDiskSecPerTransfer > 0.05` (50 ms): El disco está sufriendo para responder; valores > 1.0 (1 segundo) indican congelamiento.

---

### Paso 2: Rastrear Procesos que Apuntan a la Unidad Afectada

Inspecciona la línea de comandos completa de todos los procesos activos para encontrar qué ejecutables están leyendo o escribiendo en la unidad (ej. `H:`):

```powershell
$Letra = "H:"  # Cambiar por la letra de la unidad en conflicto
Get-CimInstance Win32_Process | 
    Where-Object { $_.CommandLine -like "*$Letra\*" -and $_.Name -ne "language_server.exe" } | 
    Select-Object ProcessId, ParentProcessId, Name, CommandLine | 
    Format-List
```

---

### Paso 3: Identificar Comandos Colgados o Servidores Zombis

Filtra procesos con alto consumo de CPU acumulado o comandos de terminal invisibles:

```powershell
Get-Process node, python, powershell, cmd -ErrorAction SilentlyContinue | 
    Select-Object Id, ProcessName, CPU, WorkingSet | 
    Sort-Object CPU -Descending
```

* Prestar especial atención a instancias de `cmd.exe` con CPU > 100 segundos o árboles de `node.exe` anidados bajo `language_server.exe` o terminales ya cerradas.

---

### Paso 4: Terminación Limpia y Forzada de Árboles Huérfanos

Detén de raíz todos los procesos vinculados a la ruta del disco o servidores huérfanos:

```powershell
# 1. Matar procesos apuntando a la ruta del proyecto o disco
$targets = Get-CimInstance Win32_Process | Where-Object { 
    ($_.CommandLine -like "*H:\*" -and $_.Name -ne "language_server.exe") -or
    ($_.Name -eq "cmd.exe" -and $_.CommandLine -like "*rmdir*") -or
    ($_.Name -eq "node.exe" -and ($_.CommandLine -like "*next*" -or $_.CommandLine -like "*postcss*"))
}

foreach ($p in $targets) {
    Write-Output "Deteniendo PID $($p.ProcessId): $($p.Name)"
    Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
}
```

---

### Paso 5: Verificación Inmediata de Caída al 0%

Comprueba que la cola se vació por completo:

```powershell
Start-Sleep -Seconds 2
Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk | 
    Where-Object { $_.Name -like "*1*" -or $_.Name -like "*H:*" } | 
    Select-Object Name, PercentDiskTime, CurrentDiskQueueLength, AvgDiskSecPerTransfer | 
    Format-Table
```

* **Resultado esperado:**
  - `PercentDiskTime: 0%`
  - `CurrentDiskQueueLength: 0`
  - `AvgDiskSecPerTransfer: 0`

---

## 🛡️ Reglas de Oro para Prevenir Recaídas

1. **Nunca correr `node_modules` en discos HDD USB externos:**
   - Mantén los proyectos de Node/Next/Vite en discos locales SSD internos (`C:` o `D:`).
   - Usa los discos mecánicos externos únicamente para almacenamiento masivo (backups, videos terminados, instaladores).
2. **Cierre explícito de procesos con `Ctrl + C`:**
   - Antes de cerrar un editor o cambiar de tarea, asegúrate de enviar la señal de interrupción al servidor de desarrollo.
3. **Excluir carpetas masivas de microarchivos en Windows Defender e Indexador:**
   - Si guardas APKs descompilados (`smali`), datasets masivos o repositorios pesados en un disco externo, agrega la carpeta a las **Exclusiones de Seguridad de Windows** para evitar que `MsMpEng.exe` y `System` lo saturen.

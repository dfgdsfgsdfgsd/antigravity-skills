---
name: sync-gui
description: Sincronizador gráfico de carpetas y discos para Windows en C# WinForms con panel dual, multi-carpeta, auto-sync en tiempo real y explorador con drill-down (sin dependencias externas). Alias: /sincronizador-gui, /sincronizador
---

# /sync-gui - Sincronizador Gráfico de Carpetas y Discos en C# (Sin Dependencias)

Esta skill crea, repara o compila un **sincronizador gráfico moderno para Windows** desarrollado en **C# con Windows Forms**, capaz de sincronizar carpetas locales hacia discos externos o particiones secundarias sin necesidad de instalar Go, Node.js, Python ni herramientas de compilación pesadas, ya que se compila nativamente en ~1 segundo usando el compilador `csc.exe` preinstalado en cualquier versión moderna de Windows.

---

## 💻 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** C# (.NET Framework 4.0 / 4.8) + Windows Forms
- **Plataforma:** Windows 7, 8, 10, 11 (x64 / x86)
- **Dependencias externas:** **0** (no requiere instalar runtime adicional ni paquetes NuGet)
- **Compilador nativo preinstalado:**
  `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe`

---

## 🛡️ Paso 0: Verificación de Entorno (Guarda de Seguridad)

Antes de compilar o generar el proyecto:
1. Comprobar que el sistema operativo es Windows:
   ```powershell
   [System.Environment]::OSVersion.Platform
   ```
2. Verificar la existencia de `csc.exe`:
   ```powershell
   Test-Path "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
   ```
3. Si `csc.exe` está disponible, compilar directamente con `/target:winexe` para que no abra consola negra.

---

## 🏗️ Arquitectura y Componentes Clave

```
┌────────────────────────────────────────────────────────────────────────┐
│                   Sincronizador de Archivos Multi-Carpeta             │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Carpeta Origen: [ D:\Proyectos                               ] [Exam]│
│ 2. Carpeta Destino: [ E:\Respaldo                               ] [Exam]│
├───────────────────────────────────┬────────────────────────────────────┤
│ 📁 Subcarpetas Origen (Izquierda) │ 💾 Dispositivos Destino (Derecha)  │
│ [✔] agencyos                      │ [✔] E:\Respaldo (Disco Externo)    │
│ [✔] dowloader_video               │ [✔] F:\Backup_USB (Memoria USB)    │
│ [✔] generador-reels               │ [✔] [☁ Drive] gdrive:/Backups      │
│ [✔ Todas] [☐ Ninguna]             │ ➕ Añadir | 🔍 USBs | ☁ Drive      │
│                                   │ 📂 Abrir  | ➖ Quitar              │
├───────────────────────────────────┴────────────────────────────────────┤
│ Pestañas: [ 📊 Sincronización y Progreso ] [ 📂 Explorador de Archivos ]│
│                                                                        │
│ • Modo: Actualizar (copia nuevos) / Espejo (elimina sobrantes) / DryRun│
│ • Excluir carpetas pesadas (.venv, node_modules, __pycache__)          │
│ • 🔄 Auto-Sync en tiempo real (FileSystemWatcher)                      │
│ • Explorador Jerárquico Drill-Down (doble clic para entrar/salir)      │
│ • Barra de progreso exacta (%) con velocidad MB/s y conteo en vivo     │
└────────────────────────────────────────────────────────────────────────┘
```

### 1. Panel Dual 50/50 Responsivo
Utiliza un `TableLayoutPanel` de 2 columnas al 50% para que en una sola pantalla el usuario vea sus carpetas de origen a la izquierda con checkboxes, y a la derecha las carpetas que ya existen en el disco externo de respaldo.

### 2. Escáner Ultra-Rápido con Estructura Ligera de Memoria
Para soportar proyectos masivos con entornos virtuales como `.venv` o `node_modules` (más de 750.000 archivos) sin consumir gigabytes de RAM:
```csharp
public struct FileItemData
{
    public long Length;
    public DateTime LastWriteTimeUtc;
}
```
Usa colas iterativas `Queue<string>` en lugar de recursión para evitar `StackOverflowException` y mantiene el consumo de memoria en menos de 15 MB.

### 3. Persistencia Automática de Configuración (`sync_config.txt`)
Guarda y recarga automáticamente al iniciar:
- Carpeta origen y carpeta destino.
- Selección exacta de casillas marcadas con `[✔]`.
- Modos seleccionados (Actualizar, Espejo, Excluir dev, Auto-Sync).

### 4. Vigilancia en Vivo y Auto-Sync (`FileSystemWatcher`)
- **Vigilante en destino:** Detecta cuando se crean, renombran o borran carpetas en el disco externo y refresca la lista derecha en tiempo real.
- **Auto-Sync en origen:** Si se activa la casilla, cualquier archivo nuevo o modificado en las carpetas vigiladas se copia de inmediato al destino sin pulsar ningún botón.

### 5. Explorador Jerárquico Comparativo (*Drill-Down* de 3 Niveles) y Selector de Destino
- **Selector de Destino Activo (`cmbExplorerDest`):** Menú desplegable en la barra del explorador que lista todos los destinos (discos externos locales y Google Drive). Al cambiar de destino o al cargar la pestaña, compara automáticamente contra la unidad elegida (priorizando discos físicos con datos sincronizados reales).
- **Columna `Ruta Destino`:** Muestra la ruta física o remota exacta en el destino (`H:\sync2`, `H:\sync2\agencyos\archivo.txt` o `gdrive:/...`) para saber en todo momento dónde reside cada archivo y carpeta.
- **Nivel 0 (Directorio Raíz de Origen):** Muestra la carpeta raíz principal sincronizada (ej. `📁 Proyectos (D:\Proyectos)`) con su tamaño total en origen y destino, conteo de subcarpetas, total de archivos y estado global consolidado (`🟢 Al día 100% Sincronizada`).
- **Nivel 1 (Subcarpetas):** Doble clic en la raíz entra a sus subcarpetas individuales (`agencyos`, `VoiceStudio`, etc.) mostrando su ruta destino respectiva, tamaño y archivos al día, con opción `⬅️ Volver a Raíz`.
- **Nivel 2 (Archivos):** Doble clic en cualquier subcarpeta muestra sus archivos individuales con fechas de modificación y rutas de destino exactas, con opción `⬅️ Volver a Subcarpetas`.
- **Botón de Modo:** Permite alternar entre la navegación jerárquica y "Todos los Archivos" (vista plana con rutas completas).

### 6. Sincronización en la Nube con Google Drive (Sin Cliente de Escritorio)
- **Botón `[☁ Google Drive]`:** Inicia el asistente de vinculación OAuth2 abriendo el navegador predeterminado para iniciar sesión en Google y otorgar acceso.
- **Sincronización Diferencial Estricta (`--update --modify-window 2s --fast-list`):** Compara tamaño y fecha con tolerancia de 2s para evitar re-subir archivos idénticos debido a diferencias de precisión entre Windows NTFS y la API de Google Drive. Solo sube archivos genuinamente nuevos o modificados, omitiendo los que ya están al día con 0 bytes de transferencia.
- **Gestión transparente:** Añade `[☁ Drive] gdrive:/Backups_Proyectos` a la lista de destinos, permitiendo marcar casillas para respaldar localmente y en la nube en una sola corrida.
- **Auto-Sync a la nube:** Replica archivos modificados al instante vía conexiones cifradas HTTPS sin consumir RAM constante.
- **Seguridad de tokens:** Las credenciales y tokens se almacenan en `tools/rclone.conf` protegido y excluido de Git.

### 7. Inicio Automático con Windows y Segundo Plano (*System Tray*)
- **Casilla `🚀 Iniciar con Windows (segundo plano)`:** Registra la aplicación en el Registro de Windows (`HKCU\Software\Microsoft\Windows\CurrentVersion\Run`) con el parámetro `--minimized` para que arranque invisible al encender la PC.
- **Casilla `🗕 Quedar en segundo plano al cerrar la ventana [X]`:** Al hacer clic en la `X` de la ventana, la aplicación no se cierra; se oculta en la bandeja de notificación junto al reloj de Windows (con globo de aviso).
- **Ícono en la Bandeja del Sistema (`NotifyIcon`):**
  - **Doble clic:** Restaura y trae la ventana principal al frente.
  - **Clic derecho (Menú contextual):** Ofrece las opciones `📂 Abrir Sincronizador`, `▶ Sincronizar ahora` y `❌ Salir definitivamente`.
  - **Combinación con Auto-Sync:** Permite que tus carpetas se sincronicen en tiempo real de forma 100% silenciosa en segundo plano sin ocupar espacio en la barra de tareas.

### 7. Menú Desplegable con Historial de Acceso Rápido e Inicio Limpio
- **Inicio limpio y despejado:** Al abrir la aplicación, las listas y cajas comienzan completamente vacías sin forzar proyectos residuales.
- **ComboBox con Historial (`▼`):** Los campos de Origen y Destino cuentan con menú desplegable y autocompletado inteligente con el historial de rutas recientes.
- **Carga instantánea al seleccionar:** Al elegir cualquier carpeta del desplegable, se cargan sus subcarpetas de inmediato.
- **Botón `[🗑 Vaciar]`:** Permite resetear y vaciar la lista de origen en cualquier momento con un solo clic.

### 8. Botón de Estado de Conexión Nube y Prevención Anti-Bloqueo
- **Botón Dinámico de Estado:** Ubicado en la cabecera superior de la columna de destinos, muestra en tiempo real `[🟢 Nube: En línea]`, `[🟡 Nube: Sin cuenta]` o `[🔴 Nube: Sin conexión]`.
- **Diagnóstico con 1 Clic:** Al pulsar el botón, comprueba la conectividad instantánea contra el endpoint HTTP 204 de Google en segundo plano sin congelar la interfaz.
- **Prevención Anti-Bloqueo:** Al iniciar una sincronización hacia la nube, si no hay internet se detiene inmediatamente con una advertencia explicativa, evitando que la aplicación quede "pensando" o congelada indefinidamente.
- **Timeouts estrictos:** Llamadas a rclone con `--contimeout 5s --timeout 15s --retries 2` para abortar limpiamente en caso de cortes repentinos de red.

### 9. Spinning Animado en Tiempo Real Estilo Google Drive
- **Spinner circular vectorial GDI+:** Dibuja un arco giratorio azul suave a ~28 FPS (`#1A73E8`) con puntas redondeadas y pista gris tenue sobre fondo de doble búfer anti-parpadeo.
- **Píldoras de estado dinámicas por fila (`SyncCheckedListBox`):** Cada carpeta seleccionada en la lista muestra su estado visual en tiempo real en la columna derecha de su fila sin alterar las rutas de archivo:
  - `[ 🔄 Sincronizando... ]`: Anima el spinner circular de Google Drive sobre la carpeta activa.
  - `[ ✔ Al día (Drive) ]`: Píldora verde con verificación al finalizar la transferencia con éxito.
  - `[ ⏳ En cola... ]`: Indicador en espera para las carpetas pendientes.
- **Widget de cabecera:** En la barra superior de la columna de origen se activa un spinner maestro que indica en vivo: `☁ Drive: nombre_carpeta` o `💾 Respaldando: nombre_carpeta`.

---

## 🚀 Compilación y Ejecución

### Comando Único de Compilación Nativa (PowerShell)
```powershell
& "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /target:winexe /optimize+ /out:"D:\SyncGUI\Sincronizador.exe" "D:\SyncGUI\Program.cs"
```

### Parámetros Explicados:
- `/target:winexe`: Genera una aplicación nativa de ventanas de Windows (GUI puro sin ventana negra de consola).
- `/optimize+`: Activa las optimizaciones del compilador para máxima velocidad de transferencia.
- `/out:...`: Especifica la ruta del archivo ejecutable generado.

---

## ⚠️ Protocolo Anti-Regresión

1. **Evitar bucle de animación verde (`ProgressBarStyle.Marquee`):**
   - Siempre cambiar explícitamente a `ProgressBarStyle.Blocks` al finalizar el escaneo antes de pasar a la fase de copia o al terminar el proceso.
2. **Fin de línea CRLF en scripts `.bat`:**
   - En Windows, los archivos `.bat` deben tener saltos de línea `\r\n` (CRLF); los saltos UNIX `\n` truncan los comandos (`echo` -> `ho`).
3. **Orden de apilamiento en WinForms (`Dock` y `Z-Order`):**
   - Para que los elementos como `clbSources` o botones no queden tapados por otros paneles, usar `BringToFront()` o envolver en un `TableLayoutPanel`.
4. **Filtro de desarrollo obligatorio:**
   - Omitir `.venv`, `node_modules`, `.git`, `__pycache__` por defecto para evitar saturar el disco copiando millones de archivos innecesarios.
5. **Cero Parpadeo en Listas WinForms (`WM_ERASEBKGND` e Invalidación Selectiva):**
   - Para eliminar el parpadeo blanco nativo en controles `ListBox`/`CheckedListBox`, interceptar el mensaje Win32 `0x0014 (WM_ERASEBKGND)` en `WndProc` asignando `m.Result = (IntPtr)1`.
   - Nunca ejecutar temporizadores de repintado continuo (`this.Invalidate()`) sobre la lista completa: invalidar únicamente el rectángulo exacto de la fila modificada (`this.Invalidate(GetItemRectangle(index))`) cuando cambie su estado.
6. **Transición Garantizada de Estados Visuales (`operations == 0` y Sweep Final):**
   - Cuando una carpeta no requiere transferencias (`operations == 0` por estar ya al día), llamar a `SetFolderState(src, FolderSyncState.Completed)` antes del `continue` del bucle para no dejarla atascada en "Sincronizando...".
   - Al terminar el worker (`Worker_RunWorkerCompleted`), realizar un barrido final confirmando todas las carpetas marcadas como `✔ Al día`.

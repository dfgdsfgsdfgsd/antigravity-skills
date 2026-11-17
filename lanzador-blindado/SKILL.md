---
name: lanzador-blindado
description: Audita, genera y repara archivos .bat en Windows garantizando saltos de línea CRLF (\r\n) obligatorios, codificación UTF-8, apertura no-bloqueante del navegador, prevención de trampas de entrada y protección anti-cierre repentino de consola. Alias: /bat-blindado, /anti-cierre-bat
---

# /lanzador-blindado (/bat-blindado, /anti-cierre-bat) - Estándar y Reparador de Lanzadores .BAT Indestructibles

Esta skill se activa cuando:
- El usuario escribe: **`/lanzador-blindado`**, **`/bat-blindado`**, **`/anti-cierre-bat`**, **`/reparar-bat`**.
- O reporta: *"al iniciar el bat se cierra la ventana"*, *"hago doble clic y se cierra la consola"*, *"el bat tira error 65001 no se reconoce o comandos cortados"*, *"arregla el lanzador para que no se cierre solo"*.
- O al crear cualquier nuevo lanzador `.bat` en proyectos Windows.

Su propósito es **erradicar para siempre el cierre prematuro y la corrupción de scripts `.bat` en Windows**, asegurando saltos de línea CRLF nativos, estructura blindada, control de errores y apertura limpia del navegador.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Sistema Operativo:** Windows 10 / 11 (cmd.exe y PowerShell).
- **Stack Aplicable:** Proyectos Node.js, Python (Flask, FastAPI, Streamlit), Go, Rust o HTML estático.

---

## 🛑 Las 5 Causas Fatales de Cierre de un `.bat` (Matriz de Diagnóstico)

| Defecto | Síntoma en Consola | Causa Técnica | Solución Obligatoria |
| :--- | :--- | :--- | :--- |
| **1. Saltos Unix LF (`\n`)** | `"65001" no se reconoce`, `"e" no se reconoce`, ventana se cierra en 10ms. | `cmd.exe` busca offsets de bytes basados en `\r\n`. Con `\n`, trunca las primeras letras de cada comando. | **Forzar CRLF (`\r\n`) binario** al guardar el archivo. |
| **2. UTF-8 con BOM (`EF BB BF`)** | `'ï»¿@echo' no se reconoce`, se imprimen comandos en crudo. | La marca BOM rompe la primera línea de `cmd.exe` provocando que `@echo off` falle. | Guardar siempre en **UTF-8 SIN BOM** (`UTF8Encoding($false)`). |
| **3. Dependencias no comprobadas** | `ModuleNotFoundError: No module named '...'` al elegir una opción. | El script o subcarpeta (`backend/`) requiere librerías (`requirements.txt`) que no se validaron antes de ejecutar. | **Guarda pre-flight obligatoria:** validar con `python -c "import ..."` o `pip install -r ...`. |
| **4. Comando `cls` en menús** | No se ven las opciones, solo aparece la última línea del prompt. | `cls` envía carácter Form Feed (`\x0c`) que en varias terminales de Windows hace scroll hacia abajo u oculta las opciones. | **No usar `cls` en bucles de menú**, separar con líneas vacías. |
| **5. Falta de `pause` o bucle** | La ventana parpadea y desaparece al terminar la ejecución o al fallar. | El proceso por lotes finaliza su última línea y el OS cierra el proceso `cmd.exe`. | Añadir `pause` final y envolver menús en bucles `:menu ... goto menu`. |
| **6. Variables vacías sin comillas** | `La sintaxis del comando no es correcta.` | Si el usuario presiona Enter vacío en `set /p opt=`, `if %opt%==1` se evalúa como `if ==1`. | Siempre encomillar variables: `if "%opt%"=="1"`. |
| **7. Apertura bloqueante** | El navegador nunca abre o abre antes de tiempo con `ERR_CONNECTION_REFUSED`. | `start http://...` se pone DESPUÉS del servidor (que nunca termina), o antes sin timeout. | Apertura asíncrona no-bloqueante con `timeout 2`. |

---

## 🛠️ Procedimiento de Reparación y Auditoría en 4 Pasos

### Paso 1: Inspeccionar y Corregir Saltos de Línea (CRLF Forzado)
Verificar si el archivo tiene bytes `\r\n` (13, 10). Si solo tiene `\n` (10), convertirlo inmediatamente con PowerShell:
```powershell
$text = [System.IO.File]::ReadAllText("iniciar.bat")
$textCrlf = $text -replace "`r`n", "`n" -replace "`n", "`r`n"
[System.IO.File]::WriteAllText("iniciar.bat", $textCrlf, [System.Text.Encoding]::UTF8)
```

### Paso 2: Aplicar la Estructura Blindada Universal
Todo `.bat` debe comenzar con:
```bat
@echo off
chcp 65001 >nul
title <Nombre del Proyecto>
cd /d "%~dp0"
```
- `cd /d "%~dp0"`: Garantiza que la terminal se ubique en la carpeta del script sin importar si se ejecutó desde un acceso directo, disco secundario (`D:`) o System32.
- `chcp 65001 >nul`: Codificación UTF-8 para emojis y acentos.

### Paso 3: Guarda Pre-flight de Dependencias Faltantes
Todo lanzador debe auditar si existen dependencias requeridas (incluso en subcarpetas como `backend/` o `client/`):
```bat
REM Verificación previa de dependencias críticas
python -c "import flask_cors, pysubs2" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [*] Detectadas dependencias faltantes. Instalando automaticamente...
    if exist "requirements.txt" pip install -r requirements.txt
    if exist "backend\requirements.txt" pip install -r backend\requirements.txt
)
```
Si es un proyecto Node.js:
```bat
if not exist "node_modules" (
    echo [*] Instalando modulos npm por primera vez...
    call npm install
)
```

### Paso 4: Patrón Anti-Bloqueo de Navegador
Para aplicaciones web (Flask, FastAPI, Streamlit, Vite, Next.js), programar la apertura asíncrona ANTES de iniciar el proceso bloqueante:
```bat
echo [*] Abriendo navegador en http://localhost:<PUERTO> ...
start "" cmd /c "timeout /t 2 /nobreak >nul && start http://localhost:<PUERTO>"
```

### Paso 4: Captura de Errores y Protección Anti-Cierre
Si un comando crítico falla (ej. `npm install`, `pip install`, `python app.py`), capturar `%ERRORLEVEL%`:
```bat
call python app.py
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================================
    echo  [ERROR] La aplicación se detuvo con código %ERRORLEVEL%.
    echo ========================================================
    echo.
    pause
)
```

---

## 📄 Plantillas Maestras Indestructibles

### Plantilla A: Servidor Único (Python / Node / HTML)
```bat
@echo off
chcp 65001 >nul
title Servidor: %~n0
cd /d "%~dp0"

echo ========================================================
echo               INICIANDO APLICACIÓN
echo ========================================================
echo.

REM 1. Apertura asíncrona del navegador (no bloqueante)
start "" cmd /c "timeout /t 2 /nobreak >nul && start http://localhost:8000"

REM 2. Ejecutar servidor principal
echo [*] Servidor activo. Presiona Ctrl+C para detener.
echo.
python app.py

REM 3. Protección final en caso de cierre o fallo
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Se produjo un error al ejecutar el servidor.
)
echo.
pause
```

### Plantilla B: Menú Interactivo Multi-Opción
```bat
@echo off
chcp 65001 >nul
title Mi Proyecto - Panel de Control
cd /d "%~dp0"

:menu
cls
echo ========================================================
echo               PANEL DE CONTROL
echo ========================================================
echo.
echo   [1] Opción 1
echo   [2] Opción 2
echo   [3] Salir
echo.
echo ========================================================
set /p opt="Elige una opción (1-3): "

if "%opt%"=="1" (
    echo Ejecutando opción 1...
    REM Comando aquí
    echo.
    pause
    goto menu
)
if "%opt%"=="2" (
    echo Ejecutando opción 2...
    REM Comando aquí
    echo.
    pause
    goto menu
)
if "%opt%"=="3" (
    exit /b 0
)

echo.
echo Opción inválida. Intenta nuevamente.
timeout /t 2 >nul
goto menu
```

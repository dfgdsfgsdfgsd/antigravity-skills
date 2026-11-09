---
name: lanzador
description: Detecta el stack de cualquier proyecto (Node.js, Vite, Next.js, Flask, FastAPI, Streamlit, HTML) y genera un lanzador iniciar.bat inteligente que instala dependencias si faltan, arranca el servidor y abre el navegador automáticamente, ejecutándolo de inmediato si se invoca desde el chat (/run, /lanzador, /arrancar).
---

# /lanzador (/run, /arrancar) - Lanzador Inteligente de Proyectos sin Consola

Esta skill permite poner en marcha cualquier proyecto de desarrollo **sin tener que recordar ni teclear comandos en la consola**.

Se activa cuando el usuario:
- Escribe: **`/lanzador`**, **`/run`**, **`/arrancar`**, **`/iniciar-servidor`**, **`/play`**.
- O pide en lenguaje natural: *"inicia el servidor"*, *"echa a correr el proyecto"*, *"crea un archivo para abrir esto con doble clic"*.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** Universal (Node.js / React / Next / Vite / Astro, Python Flask / FastAPI / Streamlit / Django, HTML Estático).
- **Sistema Operativo:** Optimizado para Windows (con archivos `.bat` y apertura nativa del navegador), compatible con POSIX (`iniciar.sh`).

---

## 🛠️ Procedimiento de Ejecución en 3 Pasos

### Paso 1: Detección Automática de Stack y Puerto

Al ejecutarse en el proyecto actual (o sobre una ruta especificada):

1. **Si detecta `package.json` (Ecosistema Node.js / Web):**
   - **Gestor de paquetes:**
     - Si hay `pnpm-lock.yaml` ➔ `pnpm`
     - Si hay `yarn.lock` ➔ `yarn`
     - Si hay `bun.lockb` ➔ `bun`
     - Por defecto ➔ `npm`
   - **Comando de inicio:**
     - Si `scripts.dev` existe ➔ `run dev`
     - Si `scripts.start` existe ➔ `start`
     - Si `scripts.serve` existe ➔ `run serve`
   - **Puerto habitual:**
     - Next.js ➔ `3000`
     - Vite / React / Vue / Svelte ➔ `5173`
     - Astro ➔ `4321`
     - Angular ➔ `4200`
     - Defecto ➔ `3000`

2. **Si detecta Python (`requirements.txt`, `app.py`, `main.py`):**
   - **Framework y Comando:**
     - Si usa Streamlit ➔ `streamlit run app.py` (puerto `8501`)
     - Si usa FastAPI / Uvicorn ➔ `uvicorn main:app --reload` (puerto `8000`)
     - Si usa Flask ➔ `python app.py` o `python app_web.py` (puerto `5000`)
     - Si es app de escritorio (Tkinter / PyWebView) ➔ `python main.py` o `python app_desktop.py` (sin abrir URL de navegador)
   - **Dependencias:** Si existe `requirements.txt`, incluir comprobación `pip install -r requirements.txt`.

3. **Si es HTML / CSS Estático (sin backend):**
   - Si existe `index.html` sin servidor:
     - Utilizar el servidor HTTP integrado de Python: `python -m http.server 8080` (puerto `8080`).

---

### Paso 2: Generación del Archivo `iniciar.bat`

Crea o actualiza el archivo `iniciar.bat` en la raíz del proyecto con la plantilla optimizada para Windows:

#### Plantilla para Proyectos Node.js:
```bat
@echo off
cd /d "%~dp0"
title Servidor: %~n0
echo ========================================================
echo               INICIANDO PROYECTO
echo ========================================================
echo.
if not exist "node_modules" (
    echo [1/2] Dependencias no encontradas. Instalando por primera vez...
    call npm install
    echo.
)
echo [2/2] Abriendo navegador en http://localhost:<PUERTO> ...
timeout /t 2 /nobreak >nul
start http://localhost:<PUERTO>
echo.
echo Servidor activo. Presiona Ctrl+C para detener.
call npm run dev
pause
```

#### Plantilla para Proyectos Python Web:
```bat
@echo off
cd /d "%~dp0"
title Servidor Python: %~n0
echo ========================================================
echo               INICIANDO SERVIDOR PYTHON
echo ========================================================
echo.
if exist "requirements.txt" (
    echo [1/2] Verificando dependencias necesarias...
    pip install -r requirements.txt
    echo.
)
echo [2/2] Abriendo navegador en http://localhost:<PUERTO> ...
timeout /t 2 /nobreak >nul
start http://localhost:<PUERTO>
echo.
echo Servidor activo. Presiona Ctrl+C para detener.
python <SCRIPT>.py
pause
```

---

### Paso 3: Puesta en Marcha Inmediata (Modo Desacoplado)

Si el usuario invocó el comando en el chat (`/run`, `/lanzador`, etc.):
- Antigravity no debe congelar su sesión esperando en un subproceso bloqueante.
- Ejecuta el `.bat` en una ventana visible e independiente en el escritorio del usuario mediante PowerShell:
  ```powershell
  Start-Process "cmd.exe" -ArgumentList "/c iniciar.bat" -WorkingDirectory (Get-Location).Path
  ```
- Informa al usuario:
  - 🚀 El servidor se ha iniciado en una ventana de consola independiente.
  - 🌐 Su navegador se abrirá en `http://localhost:<PUERTO>`.
  - 💾 El archivo `iniciar.bat` ha quedado guardado para que en el futuro solo haga doble clic desde Windows.

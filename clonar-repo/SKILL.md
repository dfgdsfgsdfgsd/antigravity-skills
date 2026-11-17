---
name: clonar-repo
description: Clona cualquier repositorio de GitHub, detecta automáticamente su stack tecnológico, identifica el entrypoint y genera un lanzador iniciar.bat de 1 clic listo para usar. Alias: /clonar, /clone-run, /repo-lanzador
---

# /clonar-repo - Clonador Inteligente de Repositorios con Lanzador Automático (.bat)

Esta skill permite clonar cualquier repositorio de GitHub y ponerlo en marcha **de forma 100% automatizada**, analizando su código, detectando su framework, resolviendo sus dependencias y creando un archivo `iniciar.bat` listo para abrir el proyecto en el navegador o terminal con un solo doble clic.

Se activa cuando el usuario:
- Escribe: **`/clonar-repo <url>`**, **`/clonar <url>`**, **`/clone-run <url>`**.
- O pide en lenguaje natural: *"clona este repo y hazle un lanzador"*, *"descarga este proyecto de github y déjalo listo para arrancar"*.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** Universal (Python FastAPI / Flask / Streamlit / Gradio / PyWebView, Node.js / Vite / Next.js / React / Express / Astro, HTML Estático, Go, Rust).
- **Herramientas requeridas:** `git` en el `PATH` del sistema.
- **Sistema Operativo:** Windows (`iniciar.bat`) y POSIX (`iniciar.sh`).

---

## 🛠️ Procedimiento de Ejecución en 5 Pasos

### Paso 1: Clonar el Repositorio
1. Si el usuario especifica carpeta destino, clonar en ella:
   ```powershell
   git clone <URL_GITHUB> <CARPETA_DESTINO>
   ```
2. Si no especifica carpeta, inferir el nombre del repositorio a partir de la URL (ej. `https://github.com/user/my-app.git` ➔ carpeta `my-app`).

---

### Paso 2: Escaneo Profundo y Detección de Stack y Entrypoint

Al ingresar en la carpeta clonada:

#### 1. Detección en Python:
- **Streamlit:**
  - Si en el código o `requirements.txt` aparece `streamlit`:
  - Buscar archivo de inicio (`webui.py`, `app.py`, `main.py`, `dashboard.py`).
  - Comando: `streamlit run <archivo> --theme.base dark`
  - Puerto predeterminado: `http://localhost:8501`
- **Gradio:**
  - Si usa `gradio` o `import gradio`:
  - Buscar `app.py`, `webui.py`, `run.py`.
  - Comando: `python <archivo>`
  - Puerto predeterminado: `http://localhost:7860`
- **FastAPI / Uvicorn:**
  - Si usa `fastapi` o `uvicorn`:
  - Buscar `main:app` o `app:app` en `app.py` o `main.py`.
  - Comando: `python app.py` o `uvicorn main:app --reload --port <PUERTO>`
  - Puerto predeterminado: `http://localhost:8000`
- **Flask:**
  - Si usa `flask`:
  - Comando: `python app.py` (puerto `http://localhost:5000`)
- **App de Escritorio / GUI (PyWebView, Tkinter, PyQt):**
  - Si abre ventana nativa: comando `python main.py` (sin abrir navegador externo).
- **Scripts CLI / Batch:**
  - Si es una utilidad de consola: preparar lanzador interactivo con menú o argumentos.

#### 2. Detección en Node.js / TypeScript:
- Leer `package.json`:
  - **Gestor:** `pnpm` si hay `pnpm-lock.yaml`, `yarn` si hay `yarn.lock`, `bun` si hay `bun.lockb`, o `npm` por defecto.
  - **Script de inicio:** `dev` ➔ `npm run dev`, `start` ➔ `npm start`, `serve` ➔ `npm run serve`.
  - **Puerto:** Next.js (`3000`), Vite (`5173`), Astro (`4321`), Angular (`4200`).

#### 3. Detección en HTML / Web Estático:
- Si existe `index.html` sin servidor:
  - Usar servidor local integrado: `python -m http.server 8080` (puerto `8080`).

---

### Paso 3: Generación del Lanzador `iniciar.bat`

Crea en la raíz del proyecto clonado el archivo `iniciar.bat` adaptado a su stack exacto:

#### Plantilla Universal para Python (Web / Streamlit / Gradio / FastAPI):
```bat
@echo off
cd /d "%~dp0"
title %~n0 (Lanzador Automatico)
color 0B
echo ========================================================
echo             INICIANDO %~n0
echo ========================================================
echo.

if exist "requirements.txt" (
    echo [1/2] Verificando dependencias en requirements.txt...
    pip install -q -r requirements.txt
    echo Dependencias listas.
    echo.
)

echo [2/2] Abriendo navegador en http://localhost:<PUERTO> ...
timeout /t 2 /nobreak >nul
start http://localhost:<PUERTO>
echo.
echo ========================================================
echo  Servidor activo en http://localhost:<PUERTO>
echo  Presiona Ctrl+C para detener.
echo ========================================================
echo.
<COMANDO_EXACTO>
pause
```

#### Plantilla Universal para Node.js / Vite / Next:
```bat
@echo off
cd /d "%~dp0"
title %~n0 (Lanzador Automatico)
color 0A
echo ========================================================
echo             INICIANDO %~n0
echo ========================================================
echo.

if not exist "node_modules" (
    echo [1/2] Instalando paquetes de dependencias...
    call npm install
    echo.
)

echo [2/2] Abriendo navegador en http://localhost:<PUERTO> ...
timeout /t 2 /nobreak >nul
start http://localhost:<PUERTO>
echo.
call npm run dev
pause
```

---

### Paso 4: Registro y Documentación

Si el clon se realizó dentro de una carpeta de investigación (ej. `D:\Proyectos\subtitulos\`), actualizar automáticamente su `README.md` o catálogo con:
- Nombre del repo y URL.
- Stack detectado.
- Cómo ejecutarlo con `iniciar.bat`.
- Ideas clave o arquitectura encontrada.

---

## 🛑 Protocolo Anti-Regresión

1. **Apertura No-Bloqueante:** El comando `start http://localhost:...` debe ejecutarse **antes** del servidor (con un `timeout /t 2`) o en segundo plano para que el navegador no quede esperando a que el servidor termine.
2. **`pause` Obligatorio al Final:** Nunca omitir `pause` al final del script `.bat`. Si ocurre un error de importación o excepción de Python/Node, la ventana se cerraría al instante y el usuario no podría leer el mensaje de error.
3. **Mapeo de Rutas Relativas:** Usar `cd /d "%~dp0"` al inicio del `.bat` para garantizar que las rutas sean relativas a la carpeta del proyecto, sin importar desde dónde se invoque el script.

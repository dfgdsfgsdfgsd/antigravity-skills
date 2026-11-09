---
name: que-hace
description: Analiza cualquier proyecto, script o carpeta técnica tras preguntas como '¿qué hace esto?', '¿qué hace esta app?' o el comando /que-hace, explicando su funcionamiento y generando automáticamente una ficha QUE_HACE.txt y QUE_HACE.md en la raíz del proyecto.
---

# /que-hace - Radiografía y Documentación Automática de Proyectos

Esta skill se activa automáticamente cuando el usuario:
- Pregunta: *"¿Qué hace esto?"*, *"¿Qué hace esta aplicación?"*, *"¿De qué trata este proyecto?"*, *"¿Cómo funciona esta carpeta?"*
- O escribe los comandos: **`/que-hace`** o **`/explicar`** (opcionalmente seguido de una ruta, ej. `/que-hace H:\receta 1\transfer`).

Su objetivo es analizar exhaustivamente la base de código, explicarla de forma clara en el chat y **generar de inmediato un archivo `QUE_HACE.txt` (y `QUE_HACE.md`) en la raíz del proyecto analizado** para que quede documentado para siempre.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** Universal (Python, Node.js, Android/Kotlin, Go, Rust, PHP, C#, C++, Web/HTML, scripts batch/shell).
- **Entorno:** Windows, Linux, macOS.

---

## 🔍 Protocolo de Análisis Autónomo en 4 Pasos

Cuando se invoque la skill sobre un proyecto (el espacio de trabajo actual o una carpeta indicada por el usuario):

### 1. Detección Rápida de Manifiestos y Stack
Inspeccionar los archivos de configuración para identificar el lenguaje y las dependencias:
- **Node.js:** `package.json` (scripts, dependencias principales).
- **Python:** `requirements.txt`, `pyproject.toml`, `Pipfile`, `setup.py`.
- **Android / Java / Kotlin:** `build.gradle`, `settings.gradle`, `AndroidManifest.xml`.
- **Rust / Go / PHP:** `Cargo.toml`, `go.mod`, `composer.json`.
- **Lanzadores directos:** Archivos `.bat`, `.cmd`, `.sh`, `Makefile`.

### 2. Inspección de Puntos de Entrada
Leer los archivos que orquestan la ejecución (`main.py`, `app.py`, `server.js`, `index.ts`, `MainActivity.kt`, etc.) para comprender:
- ¿Qué problema resuelve o qué tarea automatiza?
- ¿Tiene interfaz gráfica (HTML, Tkinter, PyWebView, Electron), CLI o corre en segundo plano?
- ¿Expone puertos o servidores locales (Flask, Express, Ktor, FastAPI)?
- ¿Consume o produce archivos (audio, video, base de datos, imágenes)?

### 3. Generación Obligatoria de `QUE_HACE.txt` y `QUE_HACE.md`
Crear automáticamente en la raíz de la carpeta del proyecto el archivo `QUE_HACE.txt` con el siguiente formato estructurado:

```text
================================================================================
                    RADIOGRAFÍA DEL PROYECTO: <NOMBRE_PROYECTO>
================================================================================

📌 ¿QUÉ HACE ESTE PROYECTO?
<Resumen conciso y claro en 2 o 3 oraciones de su propósito principal>.

🛠️ STACK TECNOLÓGICO DETECTADO:
- Lenguaje / Entorno: <Python / Node.js / Android Kotlin / etc.>
- Librerías clave: <librería 1, librería 2, librería 3...>
- Tipo de aplicación: <Web local / CLI / App móvil / Automatización de fondo>

🚀 ¿CÓMO SE PONE EN MARCHA? (MODO DE USO):
<Instrucciones exactas para ejecutarlo, paso a paso>:
1. Si tiene lanzador: Hacer doble clic en <nombre.bat>
2. O por comando: <comando de terminal exacto, ej. python app.py o npm run dev>
3. Dirección de acceso (si es web/servidor): http://localhost:<puerto>

📂 MAPA DE ARCHIVOS Y CARPETAS CLAVE:
- <archivo_o_carpeta_1>: <para qué sirve>
- <archivo_o_carpeta_2>: <para qué sirve>
- <archivo_o_carpeta_3>: <para qué sirve>

🎯 CARACTERÍSTICAS Y FUNCIONALIDADES PRINCIPALES:
- [x] <Funcionalidad 1>
- [x] <Funcionalidad 2>
- [x] <Funcionalidad 3>

Fecha de análisis: YYYY-MM-DD
================================================================================
```

> **Regla de oro:** Si existe la posibilidad, generar también la versión en Markdown (`QUE_HACE.md`) con tablas, diagramas mermaid y alertas para que se vea impecable en GitHub o editores Markdown.

### 4. Presentación al Usuario en el Chat
Responder en el chat de forma organizada:
1. Resumen directo de qué hace y para qué sirve.
2. Cómo se echa a correr (comandos o `.bat`).
3. Notificación de que el archivo `QUE_HACE.txt` ha sido creado en la raíz del proyecto para referencia futura.

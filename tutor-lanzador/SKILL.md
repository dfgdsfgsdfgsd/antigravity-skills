---
name: tutor-lanzador
description: Genera un lanzador didáctico e interactivo (iniciar_tutor.bat) que enseña comandos de terminal (pip, npm, start, puertos) con tips paso a paso y opciones [S/N]. Alias: /aprender-lanzador, /tutor-run
---

# /tutor-lanzador (/aprender-lanzador, /tutor-run) - Lanzador Educativo de Proyectos con Aprendizaje de Comandos

Esta skill se activa cuando el usuario:
- Escribe: **/tutor-lanzador**, **/aprender-lanzador**, **/tutor-run**, **/lanzador-educativo**.
- O pide: *"crea un lanzador para aprender comandos"*, *"quiero un .bat que me explique qué hace cada comando"*, *"dame un lanzador interactivo con opciones [S/N]"*.
- O pasa una ruta: `/tutor-lanzador H:\receta 1\tts`.

Su propósito es **enseñar informática y comandos de consola de forma práctica**. En lugar de ejecutar procesos en segundo plano como una "caja negra", genera en el proyecto el archivo **`iniciar_tutor.bat`** (y `iniciar.bat` automático si falta) que explica con claridad meridiana qué hace cada línea, qué comandos reales se usan en la terminal, cómo evitar que se congele la consola y permite al usuario decidir paso a paso.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** Universal (Python Flask / FastAPI / Streamlit / Django, Node.js / Vite / Next / Express / Astro, HTML estático).
- **Entorno:** Optimizado para Windows (`.bat`), compatible conceptualmente con scripts didácticos POSIX (`iniciar_tutor.sh`).

---

## 🛠️ Procedimiento de Ejecución en 4 Pasos

### Paso 1: Detección del Stack y Comandos Relevantes
Inspeccionar la raíz del proyecto para determinar:
1. **Gestor de Paquetes y Dependencias:**
   - 🐍 Python: `requirements.txt` ➔ Comando: `pip install -r requirements.txt`.
   - 🟢 Node.js: `package.json` (npm / pnpm / yarn / bun) ➔ Comando: `npm install`.
2. **Framework y Puerto Local:**
   - FastAPI: puerto `8000` (Uvicorn).
   - Flask: puerto `5000` o `5005`.
   - Streamlit: puerto `8501`.
   - Vite / React: puerto `5173`.
   - Next.js: puerto `3000`.
   - HTML Estático: puerto `8080` con `python -m http.server 8080`.

### Paso 2: Generación del Archivo `iniciar_tutor.bat`
Crear el archivo `iniciar_tutor.bat` estructurado en 3 pasos pedagógicos:

#### Estructura Pedagógica de `iniciar_tutor.bat`:
1. **Encabezado y Bienvenida:** Explica el objetivo del script y que servirá de guía interactiva.
2. **Paso 1: Dependencias (PIP / NPM):**
   - Muestra el comando exacto.
   - Explica los argumentos (ej. qué significa `-r` en `pip` o por qué `node_modules` no se sube a Git).
   - Pregunta: `Deseas ejecutar la instalacion ahora? [S/N]:`.
3. **Paso 2: Apertura de Navegador y Truco Anti-Bloqueo:**
   - Muestra el comando nativo `start http://localhost:<PUERTO>`.
   - Enseña la regla de oro: *"Si pones start después del servidor, la consola se bloquea y nunca abre el navegador"*.
   - Explica el truco asíncrono con temporizador:
     ```bat
     start "" cmd /c "timeout /t 2 /nobreak >nul && start http://localhost:<PUERTO>"
     ```
   - Pregunta si desea programar la apertura automática o abrirlo a mano.
4. **Paso 3: Servidor y Detención:**
   - Muestra el comando de arranque (`python app.py` o `npm run dev`).
   - Recuerda cómo detener el proceso en cualquier momento: `Ctrl + C`.
   - Pregunta antes de lanzar: `Listo para iniciar el servidor? [S/N]:`.

### Paso 3: Asegurar la Pareja Automática (`iniciar.bat`)
Si el proyecto no tiene aún `iniciar.bat` (el modo rápido sin preguntas), la skill genera también `iniciar.bat` para que el usuario tenga:
- `iniciar.bat` ➔ Para abrir rápido en 1 clic.
- `iniciar_tutor.bat` ➔ Para aprender, recordar comandos y practicar en la terminal.

### Paso 4: Presentación al Usuario
Mostrar en el chat un resumen de los comandos enseñados para que el usuario pueda guardarlos en sus notas o probarlos directamente en su terminal.

---

## 🛡️ Reglas de Robustez Batch (Anti-Cierre Inesperado)

Para evitar que la ventana se cierre de golpe en Windows CMD:
1. **Evitar paréntesis anidados:** No colocar textos largos con paréntesis dentro de bloques `if (...)`. Utilizar saltos con etiquetas `goto :label` (ej. `if not exist "requirements.txt" goto sin_reqs`).
2. **Valor por defecto en preguntas:** Inicializar siempre la variable antes de `set /p` (ej. `set "INST=S"`) para que si el usuario solo presiona ENTER, no cause error de sintaxis `=="S"`.
3. **Escape de caracteres:** En los textos explicativos dentro de `echo`, escapar caracteres reservados como `^&^&` y `^>`.

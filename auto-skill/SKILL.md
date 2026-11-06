---
name: auto-skill
description: Analiza la conversación actual, detecta el stack tecnológico (Python, Node, WebGL, FFmpeg, etc.), extrae el flujo resuelto, crea automáticamente una nueva skill global adaptativa y la respalda en GitHub.
---

# /auto-skill - Creador Autónomo de Skills con Detección de Stack

Esta meta-skill se activa cuando el usuario escribe `/auto-skill`, `/autoskill`, `/aprender`, o pide *"convierte lo que hicimos en una skill"*, *"crea una skill de esto"*, etc.

Su propósito es **automatizar la creación de skills inteligentes**, asegurando que cada skill conozca exactamente su **entorno de compatibilidad** (Python, Node.js, Frontend WebGL/DOM, FFmpeg, Git o Universal) y verifique los requisitos antes de ejecutarse.

---

## 🛠️ Procedimiento de Ejecución en 6 Pasos

### Paso 1: Analizar la Conversación y Detectar el Stack
1. **Identificar la Solución:** ¿Qué problema se resolvió o qué funcionalidad se construyó?
2. **Detectar el Stack Tecnológico:**
   - 🐍 **Python:** Si usa scripts `.py`, dependencias `pip`, librerías como OpenCV, MoviePy, FastAPI, etc.
   - 🟢 **Node.js / JS / TS:** Si usa `package.json`, librerías npm, Remotion, Express, Electron, etc.
   - 🌐 **Frontend / WebGL / DOM:** Si opera sobre `index.html`, `canvas`, fragment shaders, WebGL o CSS.
   - 🎬 **Herramientas Multimedia:** Si depende de binarios externos (`ffmpeg`, `ffprobe`, aceleración por hardware).
   - 🐙 **Git / Terminal / DevOps:** Agnóstica a lenguajes (aplica a cualquier proyecto).
   - 🔄 **Híbrida / Multi-stack:** Si tiene una versión en Python y otra en Node.js (ej. script de procesamiento de datos).

### Paso 2: Definir el Nombre y los Comandos de Activación
- Escoge un nombre **corto, claro y nemotécnico en español** (ej. `ondas-agua`, `cortar-audio`, `optimizar-video`).
- Define los comandos de disparo (`/<nombre>`, alias si corresponde).

### Paso 3: Redactar el `SKILL.md` con Detección de Entorno
Toda skill generada debe incluir en su estructura:

1. **Frontmatter YAML:**
   ```yaml
   ---
   name: <nombre-skill>
   description: <qué hace y para qué stack aplica>
   ---
   ```
2. **Ficha de Compatibilidad y Requisitos:**
   - **Stack compatible:** `Python | Node.js | Frontend WebGL | Universal`
   - **Requisitos previos:** Binarios requeridos (ej. Python 3.9+, Node 18+, FFmpeg en PATH).
3. **Paso 0 de Verificación (Guarda de Seguridad):**
   - Antes de ejecutar comandos, la skill debe verificar si el proyecto actual cumple el entorno:
     - *Si el proyecto no tiene Python/Node:* la skill debe avisar al usuario antes de fallar o ofrecer la alternativa correspondiente a su stack.
4. **Instrucciones de Ejecución Paso a Paso:**
   - Comandos exactos probados con explicaciones claras.
   - Manejo de rutas relativas y compatibilidad con Windows PowerShell / POSIX.
5. **Protocolo Anti-Regresión:**
   - Qué trampas comunes evitar (CORS, memory leaks, bloqueo de CPU vs. GPU, TDZ, etc.).

### Paso 4: Guardar en la Carpeta Global de Skills
- Carpeta principal: `C:\Users\Daniel\.gemini\config\skills\<nombre-skill>\`
- Generar obligatoriamente dos archivos:
  1. `SKILL.md`: La especificación técnica completa para Antigravity.
  2. `QUE_HACE.txt`: Ficha resumen en texto plano con el banner, ¿QUÉ HACE?, comandos en segundo plano y ejemplos de uso.
- Si corresponde alias, crear también la carpeta del alias con su `SKILL.md` y `QUE_HACE.txt`.

### Paso 5: Respaldar y Sincronizar en GitHub
Ejecuta la sincronización en el repositorio universal:
```powershell
cd "C:\Users\Daniel\.gemini\config\skills"
git add .
git commit -m "feat(skills): agregar skill /<nombre-skill> [stack: <stack>]"
git pull --rebase origin main
git push origin main
```

### Paso 6: Presentar Ficha al Usuario
Muestra al usuario:
- 🏷️ **Comando:** `/<nombre-skill>`
- 💻 **Stack Detectado:** (ej. *Python + FFmpeg* o *Frontend WebGL*)
- 🛡️ **Verificación de Entorno:** Cómo se comprueba si el proyecto es compatible.
- 📁 **Ubicación:** Enlace cliqueable al archivo `SKILL.md`.

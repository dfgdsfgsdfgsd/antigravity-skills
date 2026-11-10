# 📚 Catálogo Maestro de Skills de Antigravity

> **Total de herramientas maestras:** 26 skills consolidadas  
> **Repositorio de respaldo:** [github.com/dfgdsfgsdfgsd/antigravity-skills](https://github.com/dfgdsfgsdfgsd/antigravity-skills)  
> **Comando de consulta rápida:** `/catalogo`

---

## 🗂️ Índice por Familias Funcionales

1. [🐙 Control de Versiones & Git](#1--control-de-versiones--git) (10 herramientas)
2. [🚀 Automatización, Servidores & GUI](#2--automatización-servidores--gui) (3 herramientas)
3. [🔍 Diagnóstico, Análisis & Estructura](#3--diagnóstico-análisis--estructura) (3 herramientas)
4. [🎨 Frontend, DOM & Multimedia](#4--frontend-dom--multimedia) (3 herramientas)
5. [🧹 Mantenimiento, Copias & Disco](#5--mantenimiento-copias--disco) (3 herramientas)
6. [🧠 Meta-Skills, Aprendizaje & Documentación](#6--meta-skills-aprendizaje--documentación) (4 herramientas)

---

## 1. 🐙 Control de Versiones & Git

| Comando Principal | Alias Reconocidos | ¿Qué hace? |
| :--- | :--- | :--- |
| **`/iniciar`** | `/init` | Inicializa Git en el proyecto (`main`, `.gitignore` inteligente, commit inicial). |
| **`/guardar`** | `/save` | Guarda todos los cambios locales pendientes (`git add .` + `git commit`). |
| **`/subir`** | `/push` | Sube los commits locales de la rama actual a GitHub (`git push`). |
| **`/bajar`** | `/pull` | Descarga las novedades de GitHub a tu máquina (`git pull`). |
| **`/sincronizar`** | `/sync` | Sincronización completa en 1 paso: baja con rebase, guarda y sube con push. |
| **`/rama`** | `/branch` | Crea una nueva rama y cambia a ella (`git checkout -b <nombre>`). |
| **`/deshacer`** | `/rollback`, `/volver`, `/restaurar` | Descarta cambios o restaura el proyecto a cualquier commit o versión limpia previa. |
| **`/estado`** | `/status` | Radiografía rápida de Git: rama activa, archivos modificados y estado remoto. |
| **`/git-arbol`** | `/git-tree` | Genera el grafo de commits en `ARBOL_GIT.txt` y activa hooks de auto-actualización. |
| **`/radar`** | `/actualizar-proyectos`, `/pendientes` | Escanea todos los proyectos en disco `D:`, avisa cambios sin subir y gestiona recordatorios. |

---

## 2. 🚀 Automatización, Servidores & GUI

| Comando Principal | Alias Reconocidos | ¿Qué hace? |
| :--- | :--- | :--- |
| **`/lanzador`** | `/run`, `/arrancar`, `/play` | Detecta el stack (Node, Vite, Next, Flask, etc.), crea `iniciar.bat`, instala dependencias y abre el navegador automáticamente. |
| **`/verificar-lanzador`** | `/chequear-lanzador`, `/audit-lanzador` | Audita si el proyecto tiene lanzador (.bat/.sh), si abre el navegador automáticamente de forma no-bloqueante, y repara o genera scripts de inicio. |
| **`/gui-dual`** | `/interfaz-dual` | Transforma scripts de Python en suites visuales modernas (Web Flask + Ventana nativa PyWebView con HTML/Tailwind y carpeta `out/`). |

---

## 3. 🔍 Diagnóstico, Análisis & Estructura

| Comando Principal | Alias Reconocidos | ¿Qué hace? |
| :--- | :--- | :--- |
| **`/que-hace`** | `/explicar` | Analiza cualquier proyecto desconocido, explica qué hace y genera automáticamente `QUE_HACE.txt`. |
| **`/arbol`** | `/tree` | Genera un diagrama de árbol limpio del proyecto (sin node_modules/.git) en `ESTRUCTURA_PROYECTO.txt`. |
| **`/anti-regresion`** | — | Protocolo de ingeniería de 4 leyes para evitar roturas o bucles de eventos al refactorizar. |

---

## 4. 🎨 Frontend, DOM & Multimedia

| Comando Principal | Alias Reconocidos | ¿Qué hace? |
| :--- | :--- | :--- |
| **`/anti-estela`** | `/anti-ghosting` | Elimina estelas fantasma y screen tearing en animaciones DOM Chromium aislando capas GPU (`translateZ`). |
| **`/ventana-flotante`** | `/flotante` | Paneles flotantes arrastrables y acoplables a márgenes con persistencia en localStorage. |
| **`/reparar-downloader`**| `/fix-ytdlp` | Repara aplicaciones Next.js/Turbopack con yt-dlp/youtube-dl-exec (descargas infinitas o binarios vacíos). |

---

## 5. 🧹 Mantenimiento, Copias & Disco

| Comando Principal | Alias Reconocidos | ¿Qué hace? |
| :--- | :--- | :--- |
| **`/copiar-proyecto`** | `/copiar` | Copia proyectos completos entre discos mostrando barra de progreso visual, velocidad y ETA en tiempo real. |
| **`/liberar-disco`** | `/disco-100` | Diagnostica disco al 100%, mata procesos zombis en segundo plano y optimiza cuellos de botella HDD/USB. |
| **`/limpiar`** | `/clean` | Elimina archivos temporales, cachés ocultas y carpetas `__pycache__` para aligerar el proyecto. |

---

## 6. 🧠 Meta-Skills, Aprendizaje & Documentación

| Comando Principal | Alias Reconocidos | ¿Qué hace? |
| :--- | :--- | :--- |
| **`/auto-skill`** | `/autoskill` | Analiza el flujo técnico recién resuelto, crea automáticamente una nueva skill global y la respalda en GitHub. |
| **`/sync-skills`** | `/backup-skills` | Sincroniza bidireccionalmente todas las skills con el repositorio remoto de GitHub. |
| **`/armar-libro`** | `/libro` | Convierte soluciones técnicas y debates en capítulos de libro estructurados (Clase Charlada + Manual O'Reilly). |
| **`/catalogo`** | `/skills`, `/menu-skills` | Muestra este índice estructurado clasificado por categorías y permite búsquedas temáticas. |

---

## 🎯 Guía Rápida: "¿Qué comando uso si quiero...?"

- **...iniciar un servidor sin tocar la consola?** ➔ `/run` o `/lanzador`
- **...entender qué hace una carpeta o proyecto nuevo?** ➔ `/que-hace` o `/explicar`
- **...guardar y respaldar todo mi trabajo?** ➔ `/sync` o `/guardar`
- **...copiar un proyecto pesado a mi disco externo?** ➔ `/copiar`
- **...hacerle una interfaz gráfica a un script de Python?** ➔ `/gui-dual`
- **...crear una nueva skill a partir de lo que hicimos?** ➔ `/auto-skill`
- **...ver todo lo que tengo disponible?** ➔ `/catalogo`

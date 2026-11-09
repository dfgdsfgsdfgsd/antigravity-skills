# 📚 Catálogo Maestro de Skills de Antigravity

> **Total de herramientas registradas:** 50 skills / comandos  
> **Repositorio de respaldo:** [github.com/dfgdsfgsdfgsd/antigravity-skills](https://github.com/dfgdsfgsdfgsd/antigravity-skills)  
> **Comando de consulta rápida:** `/catalogo` o `/skills`

---

## 🗂️ Índice por Categorías

1. [🐙 Control de Versiones & Git](#1--control-de-versiones--git) (18 comandos)
2. [🚀 Automatización, Servidores & GUI](#2--automatización-servidores--gui) (4 comandos)
3. [🔍 Diagnóstico, Análisis & Estructura](#3--diagnóstico-análisis--estructura) (5 comandos)
4. [🎨 Frontend, DOM & Multimedia](#4--frontend-dom--multimedia) (5 comandos)
5. [🧹 Mantenimiento, Copias & Disco](#5--mantenimiento-copias--disco) (6 comandos)
6. [🧠 Meta-Skills, Aprendizaje & Documentación](#6--meta-skills-aprendizaje--documentación) (8 comandos)

---

## 1. 🐙 Control de Versiones & Git

Comandos para operar Git sin recordar sintaxis compleja, con protección automática de ramas y árboles visuales.

| Comando Principal | Alias Rápidos | ¿Qué hace? |
| :--- | :--- | :--- |
| **`/iniciar`** | `/init` | Inicializa Git en el proyecto (`main`, `.gitignore` inteligente, commit inicial). |
| **`/guardar`** | `/save` | Guarda todos los cambios locales pendientes (`git add .` + `git commit`). |
| **`/subir`** | `/push` | Sube los commits locales de la rama actual a GitHub (`git push`). |
| **`/bajar`** | `/pull` | Descarga las novedades de GitHub a tu máquina (`git pull`). |
| **`/sync`** | `/sincronizar` | Sincronización completa en 1 paso: baja con rebase, guarda y sube con push. |
| **`/rama`** | `/branch` | Crea una nueva rama y cambia a ella (`git checkout -b <nombre>`). |
| **`/deshacer`** | `/rollback`, `/volver`, `/restaurar` | Descarta cambios o restaura el proyecto a cualquier commit o versión limpia previa. |
| **`/estado`** | `/status` | Radiografía rápida de Git: rama activa, archivos modificados y estado remoto. |
| **`/git-arbol`** | `/git-tree` | Genera el grafo de commits en `ARBOL_GIT.txt` y activa hooks de auto-actualización. |
| **`/radar`** | `/actualizar-proyectos`, `/pendientes` | Escanea todos los proyectos en disco, avisa cambios sin subir y gestiona recordatorios. |

---

## 2. 🚀 Automatización, Servidores & GUI

Comandos para poner en marcha servidores y transformar scripts en aplicaciones visuales.

| Comando Principal | Alias Rápidos | ¿Qué hace? |
| :--- | :--- | :--- |
| **`/lanzador`** | `/run`, `/arrancar` | Detecta el stack (Node, Vite, Next, Flask, etc.), crea `iniciar.bat`, instala dependencias y abre el navegador. |
| **`/gui-dual`** | `/interfaz-dual` | Transforma cualquier script de Python en una suite visual moderna (Web Flask + Ventana PyWebView con HTML/Tailwind). |

---

## 3. 🔍 Diagnóstico, Análisis & Estructura

Herramientas para inspeccionar proyectos desconocidos y blindar el código contra roturas.

| Comando Principal | Alias Rápidos | ¿Qué hace? |
| :--- | :--- | :--- |
| **`/que-hace`** | `/explicar` | Analiza cualquier proyecto desconocido, explica qué hace y genera automáticamente `QUE_HACE.txt`. |
| **`/arbol`** | `/tree` | Genera un diagrama de árbol limpio del proyecto (sin node_modules/.git) en `ESTRUCTURA_PROYECTO.txt`. |
| **`/anti-regresion`** | — | Protocolo de ingeniería de 4 leyes para evitar roturas o bucles de eventos al refactorizar. |

---

## 4. 🎨 Frontend, DOM & Multimedia

Optimización de interfaces web, renderizado GPU y utilidades de video.

| Comando Principal | Alias Rápidos | ¿Qué hace? |
| :--- | :--- | :--- |
| **`/anti-estela`** | `/anti-ghosting` | Elimina estelas fantasma y screen tearing en animaciones DOM Chromium aislando capas GPU (`translateZ`). |
| **`/ventana-flotante`** | `/flotante` | Paneles flotantes arrastrables y acoplables a márgenes con persistencia en localStorage. |
| **`/reparar-downloader`**| `/fix-ytdlp` | Repara aplicaciones Next.js/Turbopack con yt-dlp/youtube-dl-exec (descargas infinitas, binarios 0 bytes). |

---

## 5. 🧹 Mantenimiento, Copias & Disco

Rendimiento del sistema, migración de archivos pesados y liberación de almacenamiento.

| Comando Principal | Alias Rápidos | ¿Qué hace? |
| :--- | :--- | :--- |
| **`/copiar-proyecto`** | `/copiar` | Copia proyectos completos entre discos mostrando barra de progreso visual, velocidad y ETA en tiempo real. |
| **`/liberar-disco`** | `/disco-100` | Diagnostica disco al 100%, mata procesos zombis en segundo plano y optimiza cuellos de botella HDD/USB. |
| **`/clean`** | `/limpiar` | Elimina archivos temporales, cachés ocultas y carpetas `__pycache__` para aligerar el proyecto. |

---

## 6. 🧠 Meta-Skills, Aprendizaje & Documentación

Skills que crean otras skills, sincronizan el entorno y generan material educativo.

| Comando Principal | Alias Rápidos | ¿Qué hace? |
| :--- | :--- | :--- |
| **`/auto-skill`** | `/autoskill` | Analiza el flujo técnico recién resuelto, crea automáticamente una nueva skill global y la respalda en GitHub. |
| **`/sync-skills`** | `/backup-skills` | Sincroniza bidireccionalmente todas las skills con el repositorio remoto de GitHub. |
| **`/armar-libro`** | `/libro` | Convierte soluciones técnicas y debates en capítulos de libro estructurados (Clase Charlada + Manual O'Reilly). |
| **`/catalogo`** | `/skills` | Muestra este índice estructurado clasificado por categorías y permite búsquedas temáticas. |

---

## 🔍 Guía Rápida: "¿Qué comando uso si quiero...?"

- **...empezar un proyecto desde cero?** ➔ `/iniciar`
- **...guardar lo que hice y no perderlo?** ➔ `/sync` o `/guardar`
- **...poner a correr una web sin tocar la consola?** ➔ `/run` o `/lanzador`
- **...entender de qué trata una carpeta que me pasaron?** ➔ `/que-hace`
- **...copiar un proyecto pesado a mi disco externo?** ➔ `/copiar`
- **...hacerle una interfaz gráfica a un script de Python?** ➔ `/gui-dual`
- **...guardar un truco o solución nueva para siempre?** ➔ `/auto-skill`

---
name: catalogo
description: Muestra el catálogo maestro clasificado de las skills organizadas en 6 familias funcionales (Git, Automatización/Servidores, Diagnóstico, Frontend, Mantenimiento y Meta-Skills), permitiendo búsquedas por categorías.
---

# /catalogo (/skills) - Catálogo Maestro de Herramientas de Antigravity

Esta skill se activa cuando el usuario:
- Escribe: **`/catalogo`**, **`/skills`**, **`/menu-skills`**, **`/mis-skills`**, **`/ayuda-skills`**.
- O pregunta: *"¿qué skills tengo?"*, *"muéstrame la lista de comandos"*, *"qué herramientas hay disponibles"*.
- O consulta una categoría específica: `/catalogo git`, `/catalogo servidores`, `/catalogo frontend`, etc.

---

## 🛠️ Procedimiento de Ejecución

1. **Si el usuario no especifica filtro:**
   - Lee y presenta el índice estructurado desde [`C:\Users\Daniel\.gemini\config\skills\CATALOGO.md`](file:///C:/Users/Daniel/.gemini/config/skills/CATALOGO.md).
   - Muestra las 6 categorías con sus comandos principales y la guía rápida *"¿Qué comando uso si quiero...?"*.

2. **Si el usuario especifica una categoría (ej. `/catalogo git` o `/catalogo audio`):**
   - Filtra y muestra únicamente los comandos pertenecientes a esa categoría con sus alias y casos de uso detallados.

3. **Recordatorio de creación:**
   - Si el usuario necesita una herramienta que aún no existe, recordarle que puede crearla automáticamente con `/auto-skill`.

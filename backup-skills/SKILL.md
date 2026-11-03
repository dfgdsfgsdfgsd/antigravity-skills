---
name: backup-skills
description: Sincroniza bidireccionalmente todas las skills globales de Antigravity con GitHub (antigravity-skills), descargando novedades y subiendo cambios locales.
---

# /backup-skills - Sincronización Bidireccional de Skills con GitHub

Esta skill se activa cuando el usuario escribe `/backup-skills`, `/sync-skills`, `sincronizar skills`, `backup skills`, `respaldar skills` o pide sincronizar sus skills con GitHub.

## Instrucciones de ejecución:

1. **Ir a la carpeta global de skills**:
   `cd "C:\Users\Daniel\.gemini\config\skills"`

2. **Paso 1: Descargar novedades remotas primero (GitHub -> PC local)**:
   - Ejecuta `git pull --rebase origin main` para traer cualquier skill creada o modificada en otra computadora o desde la web de GitHub.
   - Si hubo archivos descargados o actualizados, indícaselo brevemente al usuario.

3. **Paso 2: Comprobar cambios locales pendientes (PC local -> GitHub)**:
   - Ejecuta `git status --porcelain` para verificar si hay skills nuevas, modificadas o eliminadas localmente.

4. **Paso 3: Subir cambios locales si existen**:
   - Si hay cambios:
     - Añadir todos los archivos: `git add .`
     - Crear un commit con fecha y hora actual:
       `git commit -m "chore(skills): sincronizar skills ($((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))"`
     - Subir a GitHub:
       `git push origin main`
   - Si no había cambios locales ni remotos:
     - Informar al usuario que sus skills ya están 100% sincronizadas y al día en ambas direcciones.

5. **Mostrar resumen con el enlace al repositorio**:
   - Repositorio: https://github.com/dfgdsfgsdfgsd/antigravity-skills

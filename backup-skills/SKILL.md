---
name: backup-skills
description: Sincroniza bidireccionalmente todas las skills globales de Antigravity con GitHub (antigravity-skills), descargando novedades y subiendo cambios locales.
---

# /backup-skills - Sincronización Bidireccional de Skills con GitHub

Esta skill se activa cuando el usuario escribe `/backup-skills`, `/sync-skills`, `sincronizar skills`, `backup skills`, `respaldar skills` o pide sincronizar sus skills con GitHub.

## Instrucciones de ejecución segura en 4 pasos:

1. **Ir a la carpeta global de skills**:
   `cd "C:\Users\Daniel\.gemini\config\skills"`

2. **Paso 1: Guardar cambios locales primero (evita bloqueos de git pull)**:
   - Ejecuta `git add .`
   - Comprueba si hay cambios con `git status --porcelain`.
   - Si hay cambios, crea el commit local:
     `git commit -m "chore(skills): sincronizar skills ($((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))"`

3. **Paso 2: Descargar novedades remotas de GitHub**:
   - Ejecuta `git pull --rebase origin main`
   - Esto descarga e integra cualquier cambio o skill creada en otra máquina o en GitHub sin perder lo que tengas local.

4. **Paso 3: Subir cambios locales a GitHub**:
   - Ejecuta `git push origin main`
   - Si no hubo cambios ni locales ni remotos, indícale al usuario que todo está 100% al día en ambas direcciones.

5. **Mostrar confirmación con el enlace**:
   - Repositorio: https://github.com/dfgdsfgsdfgsd/antigravity-skills

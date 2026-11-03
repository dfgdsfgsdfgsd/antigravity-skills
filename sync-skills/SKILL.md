---
name: sync-skills
description: Sincroniza bidireccionalmente todas las skills globales de Antigravity con GitHub (antigravity-skills), descargando novedades y subiendo cambios locales.
---

# /sync-skills - Sincronización Bidireccional de Skills con GitHub

Alias de `/backup-skills`.

Sigue exactamente las instrucciones de `backup-skills`:
1. `cd "C:\Users\Daniel\.gemini\config\skills"`
2. Descarga cambios remotos: `git pull --rebase origin main`
3. Comprueba cambios locales: `git status --porcelain`
4. Si hay cambios locales, confirma y sube:
   `git add .`
   `git commit -m "chore(skills): sincronizar skills ($((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))"`
   `git push origin main`
5. Informa del estado y enlace: https://github.com/dfgdsfgsdfgsd/antigravity-skills

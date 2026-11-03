---
name: sync-skills
description: Sincroniza bidireccionalmente todas las skills globales de Antigravity con GitHub (antigravity-skills), descargando novedades y subiendo cambios locales.
---

# /sync-skills - Sincronización Bidireccional de Skills con GitHub

Alias de `/backup-skills`.

Sigue exactamente las instrucciones de `backup-skills`:
1. `cd "C:\Users\Daniel\.gemini\config\skills"`
2. Prepara y confirma cambios locales (`git add .`, `git commit`).
3. Descarga novedades remotas (`git pull --rebase origin main`).
4. Sube cambios a GitHub (`git push origin main`).
5. Repositorio: https://github.com/dfgdsfgsdfgsd/antigravity-skills

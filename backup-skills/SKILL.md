---
name: backup-skills
description: Respalda y sincroniza automáticamente todas las skills globales de Antigravity en el repositorio de GitHub (antigravity-skills).
---

# /backup-skills - Respaldo automático de skills en GitHub

Esta skill se activa cuando el usuario escribe `/backup-skills`, `backup skills`, `respaldar skills` o pide guardar sus skills en GitHub.

## Instrucciones de ejecución:

1. Ir a la carpeta global de skills:
   `cd "C:\Users\Daniel\.gemini\config\skills"`

2. Comprobar si hay cambios pendientes o archivos nuevos:
   `git status --porcelain`

3. Si hay cambios:
   - Añadir todos los archivos: `git add .`
   - Crear un commit con fecha y hora actual:
     `git commit -m "chore(skills): actualizar respaldo de skills ($((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))"`
   - Subir a GitHub:
     `git push origin main`

4. Si no hay cambios:
   - Informar al usuario que todas sus skills ya están al día en GitHub.

5. Mostrar resumen con el enlace al repositorio:
   - Repositorio: https://github.com/dfgdsfgsdfgsd/antigravity-skills

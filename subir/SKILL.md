---
name: subir
description: Sube los commits locales de la rama actual al repositorio remoto en GitHub mediante git push. Alias: /push
---

# /subir - Subir cambios a GitHub (git push)

Esta skill se activa cuando el usuario escribe `/subir` para enviar sus commits locales al repositorio remoto en GitHub.

## Instrucciones de ejecución

1. **Obtener la rama actual**:
   - Ejecuta `git branch --show-current` para identificar el nombre exacto de la rama activa.

2. **Verificar el remoto**:
   - Ejecuta `git remote -v` para confirmar que existe un repositorio remoto configurado (típicamente `origin`).
   - Si no hay ningún remoto configurado, avisa al usuario explicando cómo vincular su repositorio con `git remote add origin <url>`.

3. **Ejecutar el push**:
   - Ejecuta `git push -u origin <rama_actual>` para asegurar que la rama quede vinculada a upstream y se envíen todos los commits pendientes.

4. **Manejar posibles incidencias**:
   - Si el push es rechazado porque el remoto tiene commits nuevos (non-fast-forward), informa al usuario y ofrece hacer un `git pull --rebase` antes de volver a intentar.
   - Si ocurre un error de permisos o credenciales, indica claramente qué sucede.

5. **Confirmar al usuario**:
   - Muestra un mensaje claro indicando que los cambios están subidos con éxito a GitHub en la rama correspondiente.

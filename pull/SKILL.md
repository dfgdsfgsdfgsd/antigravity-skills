---
name: pull
description: Descarga y sincroniza en tu máquina los últimos cambios existentes en GitHub mediante git pull.
---

# /pull - Descargar cambios desde GitHub (Alias en inglés de /bajar)

Esta skill se activa cuando el usuario escribe `/pull`. Realiza exactamente las mismas operaciones que `/bajar`.

## Instrucciones de ejecución

1. **Identificar la rama actual**:
   - Ejecuta `git branch --show-current`.

2. **Comprobar si hay cambios locales sin guardar**:
   - Ejecuta `git status -s`.
   - Si existen cambios locales sin guardar, advierte al usuario antes de proceder.

3. **Ejecutar la sincronización**:
   - Ejecuta `git pull origin <rama_actual>`.

4. **Confirmar al usuario**:
   - Reporta claramente si se descargaron cambios o si el repositorio ya estaba al día.

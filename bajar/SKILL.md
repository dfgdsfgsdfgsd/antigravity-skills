---
name: bajar
description: Descarga y sincroniza en tu máquina los últimos cambios existentes en GitHub mediante git pull.
---

# /bajar - Descargar cambios desde GitHub

Esta skill se activa cuando el usuario escribe `/bajar` para actualizar su repositorio local con las novedades remotas.

## Instrucciones de ejecución

1. **Identificar la rama actual**:
   - Ejecuta `git branch --show-current`.

2. **Comprobar si hay cambios locales sin guardar**:
   - Ejecuta `git status -s`.
   - Si existen cambios locales sin guardar, advierte al usuario y sugiere guardarlos antes con `/guardar` para evitar colisiones.

3. **Ejecutar la sincronización**:
   - Ejecuta `git pull origin <rama_actual>`.

4. **Confirmar al usuario**:
   - Si no había novedades: `✅ Tu proyecto ya estaba completamente actualizado con GitHub.`
   - Si se descargaron commits: Muestra un resumen de los archivos actualizados y los nuevos commits incorporados.

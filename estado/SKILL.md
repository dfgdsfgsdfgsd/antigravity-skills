---
name: estado
description: Muestra una radiografía rápida del estado del proyecto (rama activa, archivos modificados y sincronización con GitHub). Alias: /status
---

# /estado - Radiografía rápida del repositorio

Esta skill se activa cuando el usuario escribe `/estado` para consultar la situación actual de su proyecto en Git.

## Instrucciones de ejecución

1. **Identificar la rama actual**:
   - Ejecuta `git branch --show-current`.

2. **Revisar cambios pendientes locales**:
   - Ejecuta `git status -s`.
   - Clasifica los archivos en modificados (`M`), nuevos (`??`) o eliminados (`D`).
   - Si no hay cambios, reporta: `✅ Espacio de trabajo limpio (sin cambios pendientes)`.

3. **Verificar sincronización con el remoto (GitHub)**:
   - Ejecuta `git status` para comprobar si la rama local está al día con `origin`, o si está adelantada (`ahead by N commits`) o atrasada (`behind by N commits`).

4. **Resumen visual conciso**:
   - Entrega al usuario un reporte limpio y amigable de 3 o 4 líneas:
     - 🌿 **Rama activa:** `<nombre>`
     - 📝 **Archivos pendientes:** `<lista breve o 'Ninguno'>`
     - ☁️ **Sincronización con GitHub:** `<Al día / N commits pendientes de subir con /subir / N commits pendientes de bajar con /bajar>`

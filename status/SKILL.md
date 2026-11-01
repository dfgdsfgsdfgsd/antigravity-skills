---
name: status
description: Muestra una radiografía rápida del estado del proyecto (rama activa, archivos modificados y sincronización con GitHub).
---

# /status - Radiografía rápida del repositorio (Alias en inglés de /estado)

Esta skill se activa cuando el usuario escribe `/status`. Realiza exactamente las mismas operaciones que `/estado`.

## Instrucciones de ejecución

1. **Identificar la rama actual**:
   - Ejecuta `git branch --show-current`.

2. **Revisar cambios pendientes locales**:
   - Ejecuta `git status -s`.
   - Si no hay cambios, reporta: `✅ Espacio de trabajo limpio (sin cambios pendientes)`.

3. **Verificar sincronización con el remoto (GitHub)**:
   - Ejecuta `git status` para comprobar si la rama local está al día, adelantada (`ahead`) o atrasada (`behind`).

4. **Resumen visual conciso**:
   - Entrega al usuario un reporte limpio y amigable de 3 o 4 líneas:
     - 🌿 **Rama activa:** `<nombre>`
     - 📝 **Archivos pendientes:** `<lista breve o 'Ninguno'>`
     - ☁️ **Sincronización con GitHub:** `<Al día / Pendientes de subir / Pendientes de bajar>`

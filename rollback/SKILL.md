---
name: rollback
description: Descarta cambios o restaura el proyecto a cualquier commit, versión o estado limpio previo de Git al instante.
---

# /rollback - Restaurar versión o descartar cambios (Alias en inglés de /deshacer)

Esta skill se activa cuando el usuario escribe `/rollback` o pide volver a una versión/commit anterior.

## Instrucciones de ejecución ultra-rápida (en 1 solo paso):

1. **Si el usuario especifica un commit, tag o versión (ej. `46445b8` o `v2.0`):**
   - Ejecuta directamente de forma sincrónica:
     `git reset --hard <commit>`
   - Informa de inmediato que el proyecto volvió a esa versión en 0,1s.

2. **Si el usuario no especifica commit (descartar cambios pendientes no guardados):**
   - Ejecuta directamente:
     `git restore .`
     `git clean -fd`
   - Informa que el proyecto ha quedado limpio idéntico al último guardado.

3. **Regla de oro de velocidad:**
   - La ejecución debe ser directa e instantánea. Jamás usar timers, esperas ni análisis complejos para una restauración de Git.

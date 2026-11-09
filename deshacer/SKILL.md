---
name: deshacer
description: Descarta cambios o restaura el proyecto a cualquier commit, versión o estado limpio previo de Git al instante. Alias: /rollback, /volver, /restaurar
---

# /deshacer - Restaurar versión o descartar cambios

Esta skill se activa cuando el usuario escribe `/deshacer`, `volver a la versión <hash>`, `restaurar versión` o descartar cambios.

## Instrucciones de ejecución ultra-rápida (en 1 solo paso):

1. **Si el usuario especifica un commit, tag o versión (ej. `46445b8` o `v2.0`):**
   - Ejecuta directamente de forma sincrónica:
     `git reset --hard <commit>`
   - No ejecutar escaneos de puertos ni subprocesos lentos en segundo plano.
   - Informa de inmediato que el proyecto volvió a esa versión en 0,1s.

2. **Si el usuario no especifica commit (descartar cambios pendientes no guardados):**
   - Ejecuta directamente:
     `git restore .`
     `git clean -fd`
   - Informa que el proyecto ha quedado limpio idéntico al último guardado.

3. **Regla de oro de velocidad:**
   - La ejecución debe ser directa e instantánea. Jamás usar timers, esperas ni análisis complejos para una restauración de Git.

---
name: volver
description: Vuelve al instante a cualquier commit, hash, tag o versión previa de Git en 1 solo paso rápido.
---

# /volver - Volver a una versión o commit anterior al instante (Alias de /restaurar)

Esta skill se activa cuando el usuario escribe `/volver <hash|tag|rama>` o pide volver a una versión específica.

## Instrucciones de ejecución ultra-rápida (1 solo paso):

1. **Obtener el objetivo**:
   - Si el usuario proporciona un commit hash, tag o rama (ej. `/volver 46445b8`):
     Ejecuta directamente:
     `git reset --hard <objetivo>`
   - Si no se especifica objetivo, restaura al último commit guardado (`git restore . ; git clean -fd`).

2. **Cero fricción y cero demoras**:
   - NO leer guías ni manuales antes de ejecutar.
   - NO escanear puertos ni lanzar tareas en background lentas.
   - Ejecuta el comando de Git directamente de forma sincrónica (`WaitMsBeforeAsync: 5000`).

3. **Confirmar al instante**:
   - Informa en 1 línea que el proyecto ya está en la versión indicada junto con el título del commit.

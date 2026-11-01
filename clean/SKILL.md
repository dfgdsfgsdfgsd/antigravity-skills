---
name: clean
description: Elimina archivos temporales y cachés invisibles (__pycache__, .tmp) para mantener el repositorio ligero.
---

# /clean - Eliminar cachés y archivos temporales (Alias en inglés de /limpiar)

Esta skill se activa cuando el usuario escribe `/clean`. Realiza exactamente las mismas operaciones que `/limpiar`.

## Instrucciones de ejecución

1. **Remover cachés**:
   - Limpia carpetas `__pycache__` y archivos `*.pyc`.

2. **Remover temporales**:
   - Limpia archivos `.tmp`, `.temp` o logs efímeros.

3. **Confirmar al usuario**:
   - Informa el resultado del saneamiento de espacio.

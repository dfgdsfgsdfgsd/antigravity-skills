---
name: limpiar
description: Elimina archivos temporales y cachés invisibles (__pycache__, .tmp) para mantener el repositorio ligero. Alias: /clean
---

# /limpiar - Eliminar cachés y archivos temporales

Esta skill se activa cuando el usuario escribe `/limpiar` para sanear el espacio de trabajo de residuos generados por compiladores o ejecutores.

## Instrucciones de ejecución

1. **Buscar y remover cachés de Python**:
   - Elimina recursivamente directorios `__pycache__` y archivos `*.pyc`, `*.pyo`.

2. **Buscar archivos temporales**:
   - Elimina archivos temporales `.tmp`, `.temp`, o volcados efímeros generados durante pruebas.

3. **Preservar el código**:
   - Nunca borra archivos de código fuente, imágenes de assets, archivos Markdown ni configuraciones de Git o Antigravity.

4. **Confirmar al usuario**:
   - Muestra cuántos elementos temporales se eliminaron y confirma que el proyecto quedó limpio y liviano.

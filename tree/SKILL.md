---
name: tree
description: Genera un diagrama de árbol limpio del proyecto (ignorando node_modules y .git), mostrándolo en el chat y guardándolo en ESTRUCTURA_PROYECTO.txt.
---

# /tree - Generar Diagrama de Árbol de Carpetas y Archivos

Esta skill se activa cuando el usuario escribe `/tree` o `/arbol` para visualizar la estructura del proyecto o exportarla a un archivo de texto.

## Instrucciones de ejecución

1. **Escanear la estructura del proyecto**:
   - Inspecciona la raíz del proyecto actual.
   - **Excluye obligatoriamente** carpetas y archivos pesados o de configuración interna:
     - `.git`
     - `node_modules`
     - `__pycache__`, `*.pyc`
     - `.gemini`, `.system_generated`
     - `out`, `dist`, `build`, `.remotion`, `.cache`
   - Limita la profundidad por defecto a 3 o 4 niveles para evitar listas kilométricas, a menos que el usuario pida más detalle.

2. **Guardar en archivo de texto**:
   - Genera o actualiza en la raíz del proyecto un archivo llamado:
     `ESTRUCTURA_PROYECTO.txt`
   - Incluye la fecha de generación y el árbol completo formateado con conectores (`├──`, `└──`, `│`).

3. **Presentar en el chat**:
   - Muestra el diagrama dentro de un bloque de código tipo `text` para que se lea con claridad monoespaciada en la interfaz de Antigravity.
   - Proporciona un enlace directo a `ESTRUCTURA_PROYECTO.txt`.

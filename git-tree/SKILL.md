---
name: git-tree
description: Genera el grafo de Git, lo guarda en ARBOL_GIT.txt y activa la auto-actualización automática mediante Git hooks tras cada commit o cambio de rama.
---

# /git-tree - Diagrama de Árbol de Git con Auto-Actualización (Alias de /git-arbol)

Esta skill genera el grafo de Git y activa la **auto-actualización automática** para que nunca más tengas que pedirlo manualmente tras cada modificación.

## Instrucciones de ejecución

1. **Auto-actualización automática permanente (Git Hooks)**:
   - Asegura la existencia de `scripts/update_arbol.js` y de los hooks `.git/hooks/post-commit`, `post-checkout` y `post-merge` para que Git regenere `ARBOL_GIT.txt` **automáticamente tras cada commit, merge o cambio de rama**.
   - En `scripts/update_arbol.js`, usa el formato con fecha y hora exacta:
     `git log --graph --pretty=format:"%h %ad | %s%d [%an]" --date=format:"%Y-%m-%d %H:%M:%S" --all`
   - Cada vez que el asistente realice cualquier modificación o commit, `ARBOL_GIT.txt` se actualiza de inmediato sin requerir que el usuario lo pida.

2. **Obtener el grafo actual**:
   - Ejecuta:
     `git log --graph --pretty=format:"%h %ad | %s%d [%an]" --date=format:"%Y-%m-%d %H:%M:%S" --all`

3. **Guardar en `ARBOL_GIT.txt` con UTF-8**:
   - Guarda el archivo en la raíz del proyecto con saltos de línea limpios (`\r\n`).

4. **Presentar en el chat**:
   - Muestra el grafo en un bloque de código `text`.
   - Confirma que la **auto-actualización permanente** está activa.
   - Enlace directo a `ARBOL_GIT.txt`.

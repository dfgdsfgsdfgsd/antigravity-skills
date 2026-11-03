---
name: init
description: Inicializa un repositorio Git local automáticamente (git init, .gitignore inteligente, branch main y primer commit).
---

# /init - Inicializar Git en un proyecto nuevo

Alias en inglés para `/iniciar`.

## Instrucciones de ejecución

Sigue exactamente las instrucciones de la skill `/iniciar`:
1. Verifica si ya existe `.git`.
2. Ejecuta `git init -b main`.
3. Crea un `.gitignore` completo si no existe.
4. Ejecuta `git add .` y `git commit -m "feat: commit inicial del proyecto"`.
5. Confirma al usuario el estado inicial.

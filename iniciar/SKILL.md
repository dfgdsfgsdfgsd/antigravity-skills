---
name: iniciar
description: Inicializa un repositorio Git local automáticamente (git init, .gitignore inteligente, branch main y primer commit).
---

# /iniciar - Inicializar Git en un proyecto nuevo

Esta skill se activa cuando el usuario escribe `/iniciar`, `/init`, `iniciar git`, `crear git` o pide inicializar el control de versiones en el proyecto actual.

## Instrucciones de ejecución

1. **Verificar si ya existe Git**:
   - Comprueba si existe la carpeta `.git` en el directorio de trabajo actual (`Test-Path .git` o `git status`).
   - Si ya es un repositorio Git, informa al usuario indicándole la rama activa (`git branch --show-current`) y el estado actual, sin reinicializar.

2. **Inicializar Git**:
   - Ejecuta: `git init -b main`
   - Si la versión de Git no toma `-b main`, ejecuta: `git init` y luego `git branch -M main`.

3. **Crear `.gitignore` automático (si no existe)**:
   - Si no existe un `.gitignore` en la raíz, genera uno adecuado que incluya exclusiones estándar:
     ```gitignore
     # Dependencias
     node_modules/
     __pycache__/
     *.py[cod]
     *$py.class
     .venv/
     venv/
     env/

     # Variables de entorno y secretos
     .env
     .env.local
     .env.*.local

     # Sistema operativo y editores
     .DS_Store
     Thumbs.db
     ehthumbs.db
     Desktop.ini

     # Builds y temporales
     dist/
     build/
     out/
     *.tmp
     *.log
     ```

4. **Crear el primer commit**:
   - Ejecuta: `git add .`
   - Ejecuta: `git commit -m "feat: commit inicial del proyecto"`

5. **Confirmación clara**:
   - Muestra un resumen confirmando:
     - Repositorio inicializado en la rama `main`.
     - Archivo `.gitignore` creado.
     - Primer commit realizado con éxito.
     - Recordatorio de que en adelante puede usar `/guardar` para registrar sus avances.

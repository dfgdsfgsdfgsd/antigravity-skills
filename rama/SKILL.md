---
name: rama
description: Crea una nueva rama en el repositorio Git local y cambia a ella usando git checkout -b.
---

# /rama - Crear y cambiar a una nueva rama en Git

Esta skill se activa cuando el usuario escribe `/rama` o `/branch` para crear una nueva rama en Git.

## Instrucciones de ejecución

1. **Obtener el nombre de la rama**:
   - Si el usuario especificó un nombre en su mensaje (ej. `/rama nuevo-diseño` o `/rama fix/audio`):
     - Normalízalo en minúsculas, reemplazando espacios o tildes por guiones (`-`).
     - Si no incluye prefijo (`feature/`, `fix/`, etc.), antepón `feature/` por defecto (ej. `feature/nuevo-diseno`).
   - Si el usuario ejecutó `/rama` sin especificar nombre:
     - Pregúntale brevemente qué nombre desea darle o dedúcelo del trabajo en curso.

2. **Verificar el estado del repositorio**:
   - Ejecuta `git status -s`.
   - Si hay cambios pendientes, se mantendrán al crear la rama con `checkout -b`.

3. **Crear y cambiar de rama**:
   - Ejecuta:
     `git checkout -b <nombre-rama>`

4. **Confirmar al usuario**:
   - Muestra el nombre de la nueva rama activa.
   - Recuerda que puede guardar con `/save` y subir a GitHub con `/push`.

---
name: branch
description: Crea una nueva rama en el repositorio Git local y cambia a ella usando git checkout -b.
---

# /branch - Crear y cambiar a una nueva rama en Git

Esta skill se activa cuando el usuario escribe `/branch` (o solicita crear una rama).

## Instrucciones de ejecución

1. **Obtener el nombre de la rama**:
   - Si el usuario especificó un nombre en su mensaje (ej. `/branch nuevo-diseño` o `/branch fix/audio`):
     - Normalízalo en minúsculas, reemplazando espacios o caracteres especiales por guiones (`-`).
     - Si no incluye prefijo (`feature/`, `fix/`, `test/`), añade `feature/` por defecto (ej. `feature/nuevo-diseno`).
   - Si el usuario ejecutó `/branch` sin especificar un nombre:
     - Pregúntale brevemente qué nombre desea darle a la rama, o dedúcelo a partir del contexto del trabajo actual.

2. **Verificar el estado del repositorio**:
   - Ejecuta `git status -s`.
   - Si hay cambios pendientes sin guardar, se trasladarán automáticamente a la nueva rama al hacer `checkout -b`.

3. **Crear y cambiar de rama**:
   - Ejecuta:
     `git checkout -b <nombre-rama>`

4. **Confirmar al usuario**:
   - Informa que la rama se ha creado con éxito y que ahora se encuentra activa.
   - Muestra la rama activa (`git branch --show-current`).
   - Recuerda que para guardar cambios puede usar `/save` y para subirlos a GitHub `/push`.

---
name: guardar
description: Guarda todos los cambios pendientes en el repositorio Git local mediante git add y git commit.
---

# /guardar - Guardar cambios en Git local

Esta skill se activa cuando el usuario escribe `/guardar` para registrar el estado local de su proyecto en Git.

## Instrucciones de ejecución

1. **Verificar el estado del repositorio**:
   - Ejecuta `git status -s` para comprobar si hay archivos modificados, nuevos o eliminados.
   - Si no hay ningún cambio pendiente (`nothing to commit, working tree clean`), infórmale al usuario que el proyecto ya está completamente guardado y al día, sin hacer nada más.

2. **Preparar los archivos**:
   - Ejecuta `git add .` para incluir todos los cambios pendientes.

3. **Determinar el mensaje del commit**:
   - Si el usuario escribió un mensaje junto al comando (ejemplo: `/guardar ajustes en diseño`), usa ese texto para el commit:
     `git commit -m "<mensaje del usuario>"`
   - Si el usuario ejecutó simplemente `/guardar` sin texto adicional, analiza brevemente los archivos modificados y genera un mensaje convencional claro y descriptivo en español (por ejemplo: `git commit -m "feat: actualizar estilos y componentes"` o `git commit -m "chore: guardar cambios locales"`).

4. **Confirmar al usuario**:
   - Muestra un resumen breve con:
     - El hash y mensaje del commit creado.
     - La cantidad de archivos guardados.
     - Un recordatorio indicando que si desea subirlo a GitHub puede usar `/subir` o `/push`.

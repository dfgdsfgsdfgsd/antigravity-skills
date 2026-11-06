---
name: sync
description: Sincroniza bidireccionalmente el proyecto con GitHub en 1 solo paso (baja novedades con rebase, guarda cambios locales y sube con push).
---

# /sync - Sincronización Total con GitHub

Esta skill se activa cuando el usuario escribe `/sync` (o `/sincronizar`) para sincronizar de forma bidireccional y limpia el repositorio local con GitHub en un único paso seguro.

## Ventajas sobre un push directo
- **Evita conflictos:** Hace primero un `git pull --rebase` para incorporar cualquier cambio existente en GitHub antes de empujar.
- **Todo en uno:** Si tienes archivos modificados sin guardar, los detecta, crea el commit automáticamente y los sube junto al resto.
- **Tranquilidad total:** Al finalizar, el repositorio local y el remoto en GitHub quedan en un espejo 100% idéntico.

---

## Instrucciones de ejecución

1. **Identificar la rama actual y el remoto**:
   - Ejecuta `git branch --show-current` para obtener el nombre exacto de la rama activa.
   - Ejecuta `git remote -v` para confirmar que existe el remoto `origin`.
   - Si no existe remoto, avisa amablemente al usuario indicándole cómo vincular su repositorio (`git remote add origin <url>`).

2. **Traer novedades de GitHub (Pull preventivo)**:
   - Si la rama ya existe en el remoto, ejecuta:
     `git pull --rebase origin <rama_actual>`
   - Esto evita errores de tipo `non-fast-forward` o rechazos de subida.
   - Si la rama es nueva y solo existe localmente, continúa directamente al siguiente paso.

3. **Verificar y empaquetar cambios locales pendientes**:
   - Ejecuta `git status -s`.
   - Si hay archivos modificados, nuevos o eliminados:
     - Ejecuta `git add .`
     - Si el usuario escribió un mensaje junto al comando (ej. `/sync ajustes de diseno`), úsalo:
       `git commit -m "<mensaje>"`
     - Si no especificó mensaje, analiza los cambios y genera un commit descriptivo en español (ej. `git commit -m "chore: sincronizacion de cambios locales con github"`).

4. **Subir commits a GitHub (Push seguro)**:
   - Ejecuta:
     `git push -u origin <rama_actual>`
   - La opción `-u` asegura que la rama quede enlazada con upstream para futuras sincronizaciones.

5. **Actualizar el árbol visual si existe**:
   - Si el proyecto contiene `scripts/update_arbol.js` o `ARBOL_GIT.txt`, verifica que el hook o script haya actualizado el historial.

6. **Confirmación al usuario**:
   - Muestra un reporte conciso y visual:
     - 🌿 **Rama:** `<rama_actual>`
     - 📥 **Novedades recibidas:** Si hubo cambios descargados desde GitHub.
     - 💾 **Commits subidos:** Mensaje o cantidad de commits enviados.
     - 🚀 **Estado final:** Confirmar que el repositorio local y GitHub están 100% al día y sincronizados.

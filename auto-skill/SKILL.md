---
name: auto-skill
description: Analiza la conversación actual, extrae el flujo o truco técnico recién resuelto, crea automáticamente una nueva skill global funcional y la respalda en GitHub.
---

# /auto-skill - Creador Autónomo de Skills

Esta meta-skill se activa cuando el usuario escribe `/auto-skill`, `/autoskill`, `/aprender`, o pide *"convierte lo que hicimos en una skill"*, *"crea una skill de esto"*, etc.

Su propósito es **automatizar la creación de skills** sin que el usuario tenga que redactar instrucciones técnicas ni estructurar carpetas manualmente.

---

## 🛠️ Procedimiento de Ejecución en 6 Pasos

### Paso 1: Analizar la Conversación
- Revisa los mensajes y pasos recientes de la conversación.
- Identifica el núcleo de valor:
  - ¿Qué problema se resolvió o qué funcionalidad se construyó?
  - ¿Qué comandos exactos se ejecutaron (PowerShell, Git, Node, Python, FFmpeg)?
  - ¿Qué errores o trampas surgieron y cómo se solucionaron?
  - ¿Cuáles son los parámetros o variables que cambian según el proyecto?

### Paso 2: Definir el Nombre y los Comandos de Activación
- Escoge un nombre **corto, claro y nemotécnico en español** (ej. `recortar-audio`, `optimizar-imagen`, `extraer-subtitulos`, `water-shader`).
- Define los disparadores obvios (ej: `/recortar-audio`, `recorta audio`, etc.).
- Si tiene un equivalente común en inglés o un alias corto, planifica crear también la carpeta alias.

### Paso 3: Redactar el `SKILL.md`
Crea una especificación completa y robusta siguiendo el estándar de Antigravity:
1. **Frontmatter YAML:**
   ```yaml
   ---
   name: <nombre-skill>
   description: <descripción concisa de 1 oración indicando qué hace y cuándo usarla>
   ---
   ```
2. **Título y Cuándo se Activa:**
   Explicar claramente qué comandos o frases disparan la skill.
3. **Paso a Paso Infalible:**
   - Instrucciones numeradas y directas.
   - Comandos de terminal exactos con variables explicadas.
   - Checklist de prevención de errores y anti-regresión (qué NO hacer para evitar romper el entorno).
4. **Respuesta al Usuario:**
   Formato esperado del informe o confirmación que debe dar la IA al completar la tarea.

### Paso 4: Guardar en la Carpeta Global de Skills
- Ruta de destino: `C:\Users\Daniel\.gemini\config\skills\<nombre-skill>\SKILL.md`
- Si corresponde crear un alias, crea también `C:\Users\Daniel\.gemini\config\skills\<alias>\SKILL.md`.

### Paso 5: Respaldar y Sincronizar en GitHub
Ejecuta la sincronización automática en el repositorio de skills:
```powershell
cd "C:\Users\Daniel\.gemini\config\skills"
git add .
git commit -m "feat(skills): agregar skill /<nombre-skill>"
git pull --rebase origin main
git push origin main
```

### Paso 6: Confirmación al Usuario
Muestra una ficha clara con:
- 🏷️ **Comando:** `/<nombre-skill>`
- 📝 **Propósito:** Qué tarea automatiza.
- 📁 **Ubicación:** Enlace cliqueable al archivo `SKILL.md` generado.
- 🚀 **Disponibilidad:** Confirmación de que ya está instalada globalmente y sincronizada en GitHub.

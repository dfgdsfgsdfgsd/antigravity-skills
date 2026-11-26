---
name: armar-libro
description: Transforma explicaciones, soluciones complejas o debates técnicos en capítulos de libro duales en formato Markdown (.md) y Microsoft Word (.docx). Detecta proactivamente momentos clave para crear, expandir o actualizar tutoriales. Alias: /libro
---

# /armar-libro (/libro) - Constructor y Actualizador Proactivo de Libros y Tutoriales Técnicos Duales

Esta skill se activa cuando el usuario escribe:
- **/armar-libro**, **/libro**
- O frases como: *"arma un capítulo con esto"*, *"pasa esto a formato libro"*, *"inmortaliza esta explicación en libro"*, *"añádelo al tutorial"*, *"actualiza el libro"*.
- **O PROACTIVAMENTE:** Cuando el agente detecta que se resolvió un hito técnico o duda conceptual de alto valor y propone inmortalizarlo.

Su propósito es extraer la solución, debate técnico o flujo resuelto en la conversación actual y redactarlo simultáneamente en **formato dual**:
1. **Versión Clase Magistral Charlada (`GUIA_CLASE_CHARLADA_*.md` y `.docx`):** Diálogo dinámico entre Profesor y alumnos (con analogías cotidianas, metáforas y tono pedagógico accesible).
2. **Versión Manual de Ingeniería O'Reilly (`LIBRO_TECNICO_*.md` y `.docx`):** Rigor formal, diagramas arquitectónicos Mermaid, tablas de referencia, código fuente y análisis profundo.
3. **Compilación Automática a DOCX:** Generación de archivos Microsoft Word (`.docx`) formateados profesionalmente.
4. **Historial Editorial:** Registro y versionado cronológico incremental (`v1.0 -> v2.0 -> v2.1`) en `HISTORIAL_VERSIONES_LIBRO.txt`.

---

## 🧭 Modo Proactivo: ¿Cuándo proponer crear o modificar un tutorial?

El agente evaluará al final de su respuesta si se cumplió un **Hito Técnico o Conceptual**:
1. **Gatillos de Hito:**
   - Debates de arquitectura, costos o infraestructura (ej: Google Sheets como BD, Git vs GitHub, Kill Switch).
   - Superación de bugs críticos o escollos no triviales de Windows / Electron / FFmpeg / Python.
   - Implementación de nuevas funcionalidades o paneles clave (ej: Panel de Admin, Hotkeys, Telemetría).
   - Preguntas existenciales del usuario (*"¿y si se me rompe la PC?", "¿cómo se hace profesionalmente?", "¿los clientes pueden ver esto?"*).

2. **Detección de Estado:**
   - **Si ya existe un libro en el proyecto:** Proponer anexar un nuevo Acto teatral a la Guía Charlada y una nueva Sección al Libro Técnico, subiendo la versión menor (ej: `v2.0 -> v2.1`).
   - **Si aún no existe libro:** Proponer inaugurar el Volumen 1 (`v1.0`) del proyecto.

3. **Llamado a la Acción Breve al Final:**
   > 📖 **Sugerencia Editorial / Tutorial:**  
   > *Hemos resuelto [tema]. ¿Deseas inmortalizarlo en el tutorial?*  
   > *(Solo responde: **"agrégalo al libro"**, **"crea el tutorial"** o **"actualiza la guía"**)*.

---

## 📋 Protocolo de Ejecución en 4 Pasos

### Paso 1: Extracción del Núcleo de Aprendizaje
Identificar el problema resuelto en la sesión, las metáforas explicadas, los bugs diagnosticados (ej. saltos de línea CRLF/LF, dependencias de entorno) y las soluciones de ingeniería aplicadas.

### Paso 2: Redacción / Actualización de los Archivos Markdown
- **Creación Inicial:** Genera en la raíz `GUIA_CLASE_CHARLADA_<TEMA>.md` y `LIBRO_TECNICO_<TEMA>.md`.
- **Actualización Incremental:** Si ya existen, inserta el nuevo Acto teatral con diálogos vivaces y el nuevo capítulo técnico con diagramas Mermaid y tablas comparativas, actualizando los índices.

### Paso 3: Compilación Automática a Microsoft Word (.docx)
Ejecutar el script compilador integrado para convertir ambos Markdown a formato Word:
```bash
python "C:\Users\Daniel\.gemini\config\skills\armar-libro\scripts\md_to_docx.py" "<archivo.md>"
```
El script mapea encabezados, tablas, listas, bloques de código en fuente monoespaciada (Consolas), citas y estilos de página con márgenes simétricos. Si el archivo `.docx` está bloqueado por estar abierto en Word, genera una copia `_actualizado.docx` sin arrojar error.

### Paso 4: Registro en HISTORIAL_VERSIONES_LIBRO.txt
Actualizar en la raíz el archivo `HISTORIAL_VERSIONES_LIBRO.txt` documentando:
- Número de edición / versión (ej. `v1.0`, `v2.0`, `v2.1`).
- Título del hito incorporado.
- Puntos clave abordados en la Versión Charlada y en el Manual Técnico.
- Confirmación de las exportaciones `.docx` generadas.

---

## 🛠️ Herramientas Auxiliares
- **Compilador DOCX:** `C:\Users\Daniel\.gemini\config\skills\armar-libro\scripts\md_to_docx.py` (usa la librería `python-docx`).

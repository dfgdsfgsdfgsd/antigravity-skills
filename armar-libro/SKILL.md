---
name: armar-libro
description: Transforma explicaciones, soluciones complejas o debates técnicos en capítulos de libro duales en formato Markdown (.md) y Microsoft Word (.docx). Alias: /libro
---

# /armar-libro (/libro) - Constructor de Capítulos y Libros Técnicos Duales

Esta skill se activa cuando el usuario escribe:
- **/armar-libro**, **/libro**
- O frases como: *"arma un capítulo con esto"*, *"pasa esto a formato libro"*, *"inmortaliza esta explicación en libro"*.

Su propósito es extraer la solución, debate técnico o flujo resuelto en la conversación actual y redactarlo simultáneamente en **formato dual**:
1. **Versión Clase Magistral Charlada (`GUIA_CLASE_CHARLADA_*.md` y `.docx`):** Diálogo dinámico entre Profesor y alumnos (con analogías cotidianas, metáforas y tono pedagógico accesible).
2. **Versión Manual de Ingeniería O'Reilly (`LIBRO_TECNICO_*.md` y `.docx`):** Rigor formal, diagramas arquitectónicos Mermaid, tablas de referencia, código fuente y análisis profundo.
3. **Compilación Automática a DOCX:** Generación de archivos Microsoft Word (`.docx`) formateados profesionalmente.
4. **Historial Editorial:** Registro y versionado cronológico en `HISTORIAL_VERSIONES_LIBRO.txt`.

---

## 📋 Protocolo de Ejecución en 4 Pasos

### Paso 1: Extracción del Núcleo de Aprendizaje
Identificar el problema resuelto en la sesión, las metáforas explicadas, los bugs diagnosticados (ej. saltos de línea CRLF/LF, dependencias de entorno) y las soluciones de ingeniería aplicadas.

### Paso 2: Redacción de los Archivos Markdown
Generar en la raíz del proyecto los dos documentos:
- `GUIA_CLASE_CHARLADA_<TEMA>.md`: Con actos teatrales, diálogo pedagógico fluido y metáforas vivas.
- `LIBRO_TECNICO_<TEMA>.md`: Con estándar formal O'Reilly, prólogo, análisis de arquitectura, tablas y especificaciones.

### Paso 3: Compilación Automática a Microsoft Word (.docx)
Ejecutar el script compilador integrado para convertir ambos Markdown a formato Word:
```bash
python "C:\Users\Daniel\.gemini\config\skills\armar-libro\scripts\md_to_docx.py" "<archivo.md>"
```
El script mapea encabezados, tablas, listas, bloques de código en fuente monoespaciada (Consolas), citas y estilos de página con márgenes simétricos.

### Paso 4: Registro en HISTORIAL_VERSIONES_LIBRO.txt
Actualizar o crear en la raíz el archivo `HISTORIAL_VERSIONES_LIBRO.txt` documentando:
- Número de edición / versión (ej. `v1.0`).
- Título de la obra o capítulo.
- Puntos clave incorporados tanto en la Versión Charlada como en el Manual Técnico.
- Confirmación de las exportaciones `.docx` generadas.

---

## 🛠️ Herramientas Auxiliares
- **Compilador DOCX:** `C:\Users\Daniel\.gemini\config\skills\armar-libro\scripts\md_to_docx.py` (usa la librería `python-docx`).

---
name: libro
description: Transforma explicaciones, soluciones complejas, tutoriales o debates técnicos en capítulos de libro organizados en doble formato (Clase Charlada y Manual Técnico O'Reilly).
---

# /libro - Creador y Actualizador Editorial de Libros y Tutoriales

Esta skill se activa cuando el usuario escribe `/libro`, `/armar-libro`, `/anotar`, o dice *"arma un libro con esto"*, *"agrega esta explicación al libro"*, *"crea un tutorial para el libro"*, etc.

Su propósito es **capturar el conocimiento valioso generado en las conversaciones** (soluciones de bugs difíciles, arquitecturas de software, conceptos de Git, WebGL, shaders, Python, etc.) y estructurarlo formalmente en un sistema de libros pedagógico y duradero.

---

## 🎯 El Sistema de Edición Dual

Cada tema se redacta por defecto en **dos formatos complementarios**:

### 1. 🎭 Versión Charlada *(Clase en Vivo)*
* **Público:** Principiantes, creadores de contenido, estudiantes o cualquiera que busque entender el concepto sin miedo.
* **Formato:** Guión pedagógico teatral en vivo protagonizado por un **Profesor** y sus alumnos:
  - **Mateo:** Alumno curioso que hace preguntas prácticas y pragmáticas (*"¿Y esto para qué me sirve en la vida real?"*).
  - **Sofía:** Alumna investigadora que pregunta por la historia, los estándares de la industria y la razón de ser de las cosas.
  - **Camila:** Alumna que representa los miedos comunes, errores de principiante o confusión ante términos raros.
* **Técnica:** Uso de analogías de la vida diaria (mudanzas, videojuegos, cuentas bancarias, recetas de cocina), humor, cero tecnicismos sin explicar, y paso a paso visual.

### 2. ⚙️ Versión Libro Técnico *(Manual de Ingeniería)*
* **Público:** Desarrolladores, arquitectos de software, documentación corporativa y archivo técnico de producción.
* **Formato:** Estilo editorial riguroso (*O'Reilly*, *Manning*, *Pragmatic Bookshelf*).
* **Estructura fija de cada capítulo:**
  1. **Marco Conceptual:** Principio teórico y problema que resuelve.
  2. **Arquitectura y Flujo:** Diagrama formal en Mermaid (`flowchart`, `sequenceDiagram` o `stateDiagram`).
  3. **Especificación de Parámetros:** Tablas con contratos de datos, configuraciones, flags y variables.
  4. **Implementación de Referencia:** Fragmentos de código mínimos y limpios con comentarios esenciales.
  5. **Análisis de Fallas y Causa Raíz (RCA):** Qué errores pueden ocurrir, por qué ocurren y cómo prevenirlos (protocolo anti-regresión).

---

## 📂 Dónde se Guardan los Libros

1. **Ubicación Maestra Universal:**
   Si el proyecto actual no tiene una carpeta de libros definida, la ubicación por defecto es el repositorio maestro de libros:
   - **Ruta:** `D:\Proyectos\simulacion-mensajes\`
   - **Archivos:**
     - `GUIA_CLASE_CHARLADA.md`
     - `LIBRO_TECNICO_VERSIONADO_IA.md`
     - `HISTORIAL_VERSIONES_LIBRO.txt`

2. **Ubicación Local en el Proyecto Actual:**
   Si el usuario pide guardar el libro dentro del proyecto donde está trabajando (o en otra carpeta), crea la carpeta `docs/libro/` con:
   - `GUIA_CLASE_CHARLADA.md`
   - `LIBRO_TECNICO.md`
   - `HISTORIAL_VERSIONES_LIBRO.txt`

---

## 🛠️ Procedimiento de Ejecución en 5 Pasos

### Paso 1: Identificar el Tema
- Si el usuario especificó un tema (ej: `/libro shaders WebGL y filtros FFmpeg`), toma ese tema.
- Si solo ejecutó `/libro`, analiza los últimos mensajes del chat para extraer el conocimiento técnico más valioso y reciente (ej: la resolución del bug de animación de agua, la optimización GPU vs CPU, o el guardado automático de Git).

### Paso 2: Redactar los Capítulos
1. **Redactar el Acto para la Versión Charlada:**
   - Crear un nuevo acto (ej. `Acto IV: Las Olas Invisibles — Cómo la Placa Gráfica mueve el agua sin cansar al procesador`).
   - Escribir el diálogo didáctico con el Profesor, Mateo, Sofía y Camila.
2. **Redactar el Capítulo para el Libro Técnico:**
   - Crear el capítulo numerado (ej. `Capítulo 6: Renderizado de Ondas en Tiempo Real vía Fragment Shaders WebGL y Filtrado FFmpeg`).
   - Incluir diagrama Mermaid, matriz de parámetros y código clave.

### Paso 3: Actualizar los Archivos Markdown
- Lee el archivo existente con `read_file`.
- Agrega el nuevo contenido al final del archivo respetando la numeración y el índice.
- Guarda los cambios con `edit_file` o `write_file`.

### Paso 4: Actualizar el Historial Editorial
- Abre `HISTORIAL_VERSIONES_LIBRO.txt`.
- Incrementa la versión editorial (ej. de `[Edición v2.5]` a `[Edición v2.6]`).
- Agrega fecha, hora y lista de nuevos actos/capítulos incorporados.

### Paso 5: (Opcional) Compilar a Word (`.docx`)
- Si el usuario lo solicita o si los archivos `.docx` existen en la carpeta, ejecuta un script con `python-docx` para compilar o actualizar el documento de lectura formal.

### Paso 6: Confirmación al Usuario
Muestra un resumen elegante y claro:
- Título del tema agregado.
- Resumen del **Acto** en la Versión Charlada y del **Capítulo** en el Libro Técnico.
- Enlaces cliqueables a los archivos Markdown y Word actualizados.

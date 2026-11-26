---
name: cortar-pdf
description: Diseña, genera y audita aplicaciones visuales de corte, división y extracción de páginas PDF con CustomTkinter, PyMuPDF y Pillow con fidelidad vectorial y lanzador blindado. Alias: /dividir-pdf, /pdf-splitter
---

# /cortar-pdf (/dividir-pdf, /pdf-splitter) - Suite Visual de División y Recorte de PDFs

Esta skill se activa cuando:
- El usuario escribe: **`/cortar-pdf`**, **`/dividir-pdf`**, **`/pdf-splitter`**.
- O solicita: *"necesito hacer una app para cortar un pdf"*, *"dividir pdf por páginas"*, *"extraer hojas de un pdf"*, *"hacer un splitter de pdf visual"*, *"separar un pdf en varios archivos"*.

Su propósito es **diseñar, estructurar, generar y blindar suites de corte, división y extracción de páginas PDF**, con interfaz gráfica moderna de escritorio, previsualización interactiva de miniaturas, entrada de rangos inteligentes y manipulación vectorial 100% nativa sin pérdida de calidad.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Sistema Operativo:** Windows 10 / Windows 11 (64-bit) (compatible también con macOS y Linux).
- **Stack Tecnológico:** 🐍 Python 3.10+ (`customtkinter>=6.0.0`, `pymupdf>=1.24.0`, `pillow>=10.0.0`).
- **Motor de PDF:** `PyMuPDF` (`pymupdf` / `fitz`) para lectura, renderizado de miniaturas y operaciones vectoriales atómicas.
- **Ventaja Crítica:**
  - **Fidelidad Vectorial 100%:** No rasteriza ni destruye textos o hipervínculos; utiliza `insert_pdf` para conservar el PDF original intacto.
  - **Cero Congelamientos:** Renderizado de miniaturas y exportaciones pesadas ejecutadas en hilos secundarios (`threading.Thread`) sincronizados con `root.after()`.
  - **Empaque Directo a ZIP:** Capacidad de dividir cientos de páginas y empaquetarlas al vuelo en un único archivo comprimido.
  - **Lanzador Blindado:** Archivo `iniciar.bat` con CRLF forzado, UTF-8 sin BOM y pre-flight de dependencias.

---

## 🛡️ Paso 0: Guarda de Seguridad y Verificación de Entorno

Antes de procesar o construir la aplicación, validar las herramientas requeridas:

```bash
# 1. Comprobar instalación de Python
python --version

# 2. Validar / Instalar dependencias esenciales
pip install customtkinter pymupdf pillow

# 3. Comprobar importación limpia
python -c "import customtkinter, pymupdf, PIL; print('OK: Dependencias disponibles')"
```

---

## 🏗️ Arquitectura del Sistema (3 Capas)

### 1. Motor de Procesamiento Vectorial (`pdf_engine.py`)

- **Análisis de Rangos (`parse_page_ranges` y `parse_range_blocks`):**
  - Convierte entradas tipo `"1-3, 5, 8-12"` o bloques `"1-3; 4-7; 8-10"` en listas validadas contra el total de páginas del documento.
- **Renderizado Rápido de Miniaturas (`render_page_thumbnail`):**
  - Renderiza pixmaps a 96 DPI con `page.get_pixmap(dpi=96)` y genera miniaturas Pillow con filtro `LANCZOS` manteniendo la relación de aspecto.
- **Operaciones de Corte:**
  1. `extract_pages(src, pages, out)`: Guarda en un nuevo PDF únicamente las páginas seleccionadas.
  2. `remove_pages(src, pages_to_remove, out)`: Excluye las páginas seleccionadas y guarda el resto.
  3. `split_all_pages(src, out_dir, as_zip)`: Crea un PDF por cada página (`doc_pag_001.pdf`).
  4. `split_every_n_pages(src, n, out_dir, as_zip)`: Divide el documento en bloques fijos de $N$ páginas.
  5. `split_by_custom_ranges(src, blocks, out_dir, as_zip)`: Separa por grupos específicos.
- **Optimización al Guardar:** Siempre aplicar `doc.save(out_path, garbage=3, deflate=True)` para eliminar objetos huérfanos y comprimir streams.

### 2. Interfaz Gráfica de Escritorio (`app.py`)

- **Tema y Paleta:** CustomTkinter en modo oscuro (`"dark"`, tema `"blue"`), tarjetas de miniaturas en `#23242A` y bordes activos en `#3B82F6`.
- **Componentes Esenciales:**
  - **Cabecera:** Nombre de archivo, total de páginas, tamaño en MB, botón "📁 Abrir PDF" y "🔄 Recargar".
  - **Toolbar de Selección:** Caja de rangos de texto con botón "Aplicar", botones de selección rápida (`✓ Todo`, `✕ Ninguno`, `⇄ Invertir`, `Pares`, `Impares`) y contador dinámico.
  - **Scrollable Grid:** Muestra tarjetas interactivas de cada página con checkbox, badge numérico y miniatura cliqueable.
  - **Panel de Acciones Lateral (Tabs):**
    - Pestaña 1: *Extraer seleccionadas* o *Eliminar seleccionadas*.
    - Pestaña 2: *Dividir cada página* (con switch opcional de ZIP).
    - Pestaña 3: *Dividir por bloques* (cada N páginas o rangos manuales con ZIP).
  - **Barra de Estado y Progreso:** Barra `CTkProgressBar` y botón dinámico "📂 Abrir Carpeta de Salida" activado al finalizar con éxito.

### 3. Lanzador Blindado (`iniciar.bat`)

- Cumple estrictamente con el estándar de `/lanzador-blindado`:
  - Saltos de línea CRLF (`\r\n`) obligatorios.
  - Codificación UTF-8 sin BOM (`chcp 65001 >nul`).
  - Validación pre-flight de Python y `requirements.txt`.
  - Protección anti-cierre con `pause` en caso de excepción.

---

## 🛑 Protocolo Anti-Regresión

| Riesgo | Causa | Solución Obligatoria |
| :--- | :--- | :--- |
| **Pérdida de texto / Pixelado** | Convertir páginas a imágenes y re-ensamblarlas. | **Prohibido.** Usar siempre `out_doc.insert_pdf(src_doc, from_page=i, to_page=i)`. |
| **Congelamiento de la GUI** | Cargar miniaturas o exportar PDFs en el hilo principal de Tkinter. | Delegar siempre el trabajo pesado a `threading.Thread(target=..., daemon=True)` y actualizar la UI mediante `self.after(0, callback)`. |
| **Fuga de descriptores de archivo** | Dejar documentos de PyMuPDF abiertos tras procesar. | Envolver siempre en bloques `try...finally: doc.close()`. |
| **Archivos inflados en disco** | Guardar sin optimización de basura. | Utilizar siempre los flags `garbage=3, deflate=True` al invocar `doc.save()`. |
| **Error por entradas de rango vacías** | Rangos fuera de límites (ej: pág. 99 en documento de 10 págs). | Filtrar en `parse_page_ranges` con condición `1 <= p <= total_pages`. |

---

## 💡 Flujo de Trabajo Típico de la Aplicación

1. El usuario abre el archivo PDF deseado.
2. La aplicación analiza los metadatos y lanza el renderizado de miniaturas en segundo plano.
3. El usuario marca las páginas deseadas directamente haciendo clic sobre las miniaturas o escribiendo un rango (`ej: 1-5, 8`).
4. Selecciona el modo de corte desde el panel lateral (Extraer, Excluir, Dividir Todo o Dividir por Bloques).
5. Selecciona la ruta o carpeta de destino.
6. La barra de progreso reporta el avance y, al finalizar, ofrece un botón para abrir directamente la carpeta de salida con el explorador de Windows.

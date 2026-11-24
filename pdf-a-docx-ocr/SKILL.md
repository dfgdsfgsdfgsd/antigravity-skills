---
name: pdf-a-docx-ocr
description: Conversor y suite inteligente de PDF a Word (DOCX) con OCR nativo de Windows (Windows.Media.Ocr sin Tesseract externo), modo híbrido digital/escaneado, reconstrucción de párrafos e interfaz gráfica CustomTkinter. Alias: /pdf-ocr, /ocr-pdf
---

# /pdf-a-docx-ocr (/pdf-ocr, /ocr-pdf) - Suite Conversora de PDF a DOCX con OCR Nativo

Esta skill se activa cuando:
- El usuario escribe: **`/pdf-a-docx-ocr`**, **`/pdf-ocr`**, **`/ocr-pdf`**.
- O pide: *"puedes hacer una app que pase pdf a docx mediante ocr"*, *"convertir pdf escaneado a word"*, *"extraer texto de pdf con ocr a docx"*, *"hacer un extractor ocr de pdf a docx editable"*.

Su propósito es **diseñar, auditar, generar o reparar aplicaciones de conversión de PDF a Microsoft Word (.docx)** con capacidades de reconocimiento óptico de caracteres (OCR) de alta fidelidad, detección automática de páginas escaneadas vs digitales y reconstrucción natural de párrafos sin dependencias binarias externas complejas.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Sistema Operativo:** Windows 10 / Windows 11 (64-bit).
- **Stack Tecnológico:** 🐍 Python 3.10+ (PyMuPDF, python-docx, winocr, Pillow, CustomTkinter).
- **Motor OCR:** `Windows.Media.Ocr` nativo del sistema operativo (vía paquete oficial `winocr` / `winrt-runtime`).
- **Ventaja Crítica:** **Cero binarios externos de Tesseract**, cero instaladores de 500MB y cero problemas de variables de entorno PATH. Funciona 100% offline y con aceleración nativa de Windows.

---

## 🛡️ Paso 0: Guarda de Seguridad y Verificación de Entorno

Antes de procesar o crear la aplicación, verificar que el entorno cumpla los requisitos:

```bash
# 1. Comprobar Python
python --version

# 2. Comprobar soporte de OCR nativo en Windows PowerShell
powershell -Command "[Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime] | Out-Null; [Windows.Media.Ocr.OcrEngine]::AvailableRecognizerLanguages"

# 3. Validar / Instalar dependencias esenciales
pip install pymupdf python-docx customtkinter pillow winocr
```

---

## 🏗️ Arquitectura del Sistema (3 Capas)

### 1. Motor OCR y Reconstructor de Párrafos (`ocr_engine.py`)
- Utiliza `winocr.recognize_pil(image, lang)` para ejecutar OCR asíncrono sobre imágenes en memoria.
- **Algoritmo de Reconstrucción de Párrafos:**
  - El OCR crudo devuelve líneas sueltas o palabras con bounding boxes.
  - Para evitar que Word tenga saltos de línea forzados en cada renglón, se calcula la altura media de línea y el delta vertical ($gap = y_{0,\text{actual}} - y_{1,\text{previo}}$).
  - Si el gap vertical es mayor al 90% de la altura de línea o la línea previa termina en puntuación (`.`, `:`, `!`, `?`), se crea un nuevo párrafo; de lo contrario, se fusionan con un espacio.

### 2. Orquestador de Conversión Híbrida (`converter.py`)
- Carga el documento con `pymupdf.open(pdf_path)`.
- **Modos de procesamiento:**
  1. **Híbrido Inteligente (Default):** Evalúa cada página con `page.get_text()`. Si tiene más de 25 caracteres significativos, extrae directamente los bloques vectoriales digitales (en <5ms). Si la página es una imagen o escaneo, la renderiza a alta resolución (200, 300 o 400 DPI con `page.get_pixmap(dpi=...)`) y aplica OCR.
  2. **Forzar OCR en todas las hojas:** Para documentos históricos, fotocopias o PDFs con fuentes corruptas.
  3. **Solo Texto Digital:** Modo ultra veloz sin rasterizado ni OCR.
- **Generación Word DOCX:** Configura tipografía Segoe UI/Calibri a 11pt, espaciado de párrafo de 6pt e inserta saltos de página entre hojas.

### 3. Interfaz Gráfica Moderna (`app.py`)
- Desarrollada con `customtkinter` en modo oscuro/claro elegante.
- Ejecuta la conversión en un hilo secundario (`threading.Thread`) para garantizar que la interfaz nunca se cuelgue ni muestre *"No responde"*.
- Cola de archivos por lotes con tarjeta de estado (Pendiente, Procesando, Completado, Error).
- Barra de progreso real (0% a 100%), log con timestamps en vivo y botones de 1 clic para abrir el archivo generado o la carpeta contenedora con `os.startfile()`.

---

## 🚀 Implementación Rápida de Referencia

### 1. Conversor Núcleo Mínimo
```python
import io, asyncio, pymupdf, winocr
from PIL import Image
from docx import Document

async def ocr_page(pil_img, lang="es"):
    res = await winocr.recognize_pil(pil_img.convert("RGBA"), lang)
    return res.text

def pdf_to_docx(pdf_path, docx_path, dpi=300):
    pdf = pymupdf.open(pdf_path)
    doc = Document()
    
    for page in pdf:
        text = page.get_text().strip()
        if len(text) > 30:  # Digital
            doc.add_paragraph(text)
        else:  # Escaneado -> OCR
            pix = page.get_pixmap(dpi=dpi)
            img = Image.open(io.BytesIO(pix.tobytes("png")))
            ocr_text = asyncio.run(ocr_page(img))
            doc.add_paragraph(ocr_text)
        doc.add_page_break()
        
    doc.save(docx_path)
    pdf.close()
```

### 2. Lanzador Blindado Windows (`iniciar.bat`)
Garantizar codificación UTF-8 sin BOM y saltos de línea CRLF obligatorios:
```bat
@echo off
chcp 65001 >nul
title PDF a DOCX con OCR Inteligente
cd /d "%~dp0"

where python >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Python no esta en el PATH.
    pause
    exit /b 1
)

python -c "import pymupdf, docx, customtkinter, PIL, winocr" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [*] Instalando dependencias necesarias...
    pip install pymupdf python-docx customtkinter pillow winocr
)

python app.py
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] La aplicacion finalizo con codigo %ERRORLEVEL%.
    pause
)
```

---

## ⚠️ Protocolo Anti-Regresión

1. **Evitar dependencias de C++ no compiladas:** En versiones recientes de Python (ej. 3.14/3.15), evitar librerías como `pyclipper` o `scikit-image` que intenten compilar desde código fuente sin MSVC instalado. Usar `winocr` y `pymupdf` precompilados vía wheels ABI3.
2. **RGBA Obligatorio para winocr:** `winocr.recognize_pil` requiere imágenes con modo `'RGBA'`. Siempre ejecutar `img.convert('RGBA')` antes de llamar a la función.
3. **No bloquear el hilo de Tkinter:** Las llamadas de OCR síncronas (`asyncio.run()`) o de renderizado pesado deben correr siempre en un worker `threading.Thread`, usando `root.after(0, callback)` para actualizar labels y barras de progreso.
4. **Control de Saltos de Página:** No agregar un salto de página (`doc.add_page_break()`) en la última hoja procesada para evitar hojas en blanco al final del documento Word.

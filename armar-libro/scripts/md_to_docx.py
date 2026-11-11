import sys
import re
from pathlib import Path
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls

def set_cell_background(cell, fill_hex):
    shading_elm = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    cell._tc.get_or_add_tcPr().append(shading_elm)

def set_table_borders(table, color="D3D3D3"):
    tblPr = table._tbl.tblPr
    borders = parse_xml(
        f'<w:tblBorders {nsdecls("w")}>'
        f'  <w:top w:val="single" w:sz="4" w:space="0" w:color="{color}"/>'
        f'  <w:left w:val="none"/>'
        f'  <w:bottom w:val="single" w:sz="6" w:space="0" w:color="{color}"/>'
        f'  <w:right w:val="none"/>'
        f'  <w:insideH w:val="single" w:sz="4" w:space="0" w:color="{color}"/>'
        f'  <w:insideV w:val="none"/>'
        f'</w:tblBorders>'
    )
    tblPr.append(borders)

def format_inline(paragraph, text):
    pattern = re.compile(r'(\*\*.*?\*\*|\*.*?\*|`.*?`)')
    tokens = pattern.split(text)
    for token in tokens:
        if not token:
            continue
        if token.startswith('**') and token.endswith('**') and len(token) >= 4:
            run = paragraph.add_run(token[2:-2])
            run.bold = True
        elif token.startswith('*') and token.endswith('*') and len(token) >= 2:
            run = paragraph.add_run(token[1:-1])
            run.italic = True
        elif token.startswith('`') and token.endswith('`') and len(token) >= 2:
            run = paragraph.add_run(token[1:-1])
            run.font.name = 'Consolas'
            run.font.size = Pt(9.5)
            run.font.color.rgb = RGBColor(180, 40, 60)
        else:
            paragraph.add_run(token)

def convert_md_to_docx(md_path, docx_path=None):
    md_file = Path(md_path)
    if not md_file.exists():
        print(f"Error: {md_path} no existe.", file=sys.stderr)
        return False
    
    if docx_path is None:
        docx_file = md_file.with_suffix('.docx')
    else:
        docx_file = Path(docx_path)

    doc = Document()

    # Configuración de márgenes estándar de libro
    for section in doc.sections:
        section.top_margin = Inches(1)
        section.bottom_margin = Inches(1)
        section.left_margin = Inches(1.1)
        section.right_margin = Inches(1.1)

    lines = md_file.read_text(encoding='utf-8').splitlines()

    in_code_block = False
    code_lines = []
    in_table = False
    table_lines = []

    def flush_table():
        nonlocal in_table, table_lines
        if not table_lines:
            in_table = False
            return
        
        # Filtrar separadores |---|---|
        rows = []
        for tl in table_lines:
            raw_cells = [c.strip() for c in tl.strip().strip('|').split('|')]
            if all(re.match(r'^:?-+:?$', c) for c in raw_cells):
                continue
            rows.append(raw_cells)

        if rows:
            col_count = max(len(r) for r in rows)
            table = doc.add_table(rows=len(rows), cols=col_count)
            table.alignment = WD_TABLE_ALIGNMENT.CENTER
            set_table_borders(table)

            for i, row in enumerate(rows):
                for j, cell_text in enumerate(row):
                    if j < col_count:
                        cell = table.cell(i, j)
                        p = cell.paragraphs[0]
                        p.paragraph_format.space_before = Pt(3)
                        p.paragraph_format.space_after = Pt(3)
                        format_inline(p, cell_text)
                        if i == 0:
                            set_cell_background(cell, "F1F5F9")
                            for r in p.runs:
                                r.bold = True
            doc.add_paragraph() # Espacio después de tabla
        table_lines = []
        in_table = False

    def flush_code():
        nonlocal in_code_block, code_lines
        if not code_lines:
            in_code_block = False
            return
        code_p = doc.add_paragraph()
        code_p.paragraph_format.space_before = Pt(4)
        code_p.paragraph_format.space_after = Pt(4)
        code_p.paragraph_format.left_indent = Inches(0.4)
        for cl in code_lines:
            run = code_p.add_run(cl + "\n")
            run.font.name = "Consolas"
            run.font.size = Pt(8.5)
            run.font.color.rgb = RGBColor(40, 50, 60)
        code_lines = []
        in_code_block = False

    for line in lines:
        stripped = line.strip()

        # 1. Bloques de código ```
        if stripped.startswith('```'):
            if in_code_block:
                flush_code()
            else:
                if in_table:
                    flush_table()
                in_code_block = True
                code_lines = []
            continue

        if in_code_block:
            code_lines.append(line)
            continue

        # 2. Tablas Markdown |
        if stripped.startswith('|') and stripped.endswith('|'):
            in_table = True
            table_lines.append(stripped)
            continue
        elif in_table:
            flush_table()

        # 3. Líneas en blanco
        if not stripped:
            continue

        # 4. Separadores horizontales ---
        if re.match(r'^-{3,}$', stripped) or re.match(r'^\*{3,}$', stripped):
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(6)
            p.paragraph_format.space_after = Pt(6)
            run = p.add_run("―" * 40)
            run.font.color.rgb = RGBColor(180, 180, 180)
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            continue

        # 5. Encabezados (#, ##, ###, ####)
        if stripped.startswith('# '):
            p = doc.add_heading(level=0)
            format_inline(p, stripped[2:])
            p.paragraph_format.space_after = Pt(8)
            continue
        elif stripped.startswith('## '):
            p = doc.add_heading(level=1)
            format_inline(p, stripped[3:])
            p.paragraph_format.space_before = Pt(14)
            p.paragraph_format.space_after = Pt(6)
            continue
        elif stripped.startswith('### '):
            p = doc.add_heading(level=2)
            format_inline(p, stripped[4:])
            p.paragraph_format.space_before = Pt(10)
            p.paragraph_format.space_after = Pt(4)
            continue
        elif stripped.startswith('#### '):
            p = doc.add_heading(level=3)
            format_inline(p, stripped[5:])
            p.paragraph_format.space_before = Pt(8)
            p.paragraph_format.space_after = Pt(3)
            continue

        # 6. Citas / Diálogos (> ...)
        if stripped.startswith('> '):
            quote_text = stripped[2:].strip()
            # Alertas GitHub (> [!NOTE], etc.)
            if quote_text.startswith('[!'):
                quote_text = re.sub(r'^\[!\w+\]\s*', '📌 NOTA: ', quote_text)
            p = doc.add_paragraph()
            p.paragraph_format.left_indent = Inches(0.4)
            p.paragraph_format.space_before = Pt(3)
            p.paragraph_format.space_after = Pt(3)
            format_inline(p, quote_text)
            continue

        # 7. Listas con viñetas (- o * )
        if re.match(r'^[-*]\s+', stripped):
            item_text = re.sub(r'^[-*]\s+', '', stripped)
            p = doc.add_paragraph(style='List Bullet')
            p.paragraph_format.space_before = Pt(1)
            p.paragraph_format.space_after = Pt(2)
            format_inline(p, item_text)
            continue

        # 8. Listas numeradas (1. , 2. )
        if re.match(r'^\d+\.\s+', stripped):
            item_text = re.sub(r'^\d+\.\s+', '', stripped)
            p = doc.add_paragraph(style='List Number')
            p.paragraph_format.space_before = Pt(1)
            p.paragraph_format.space_after = Pt(2)
            format_inline(p, item_text)
            continue

        # 9. Párrafo normal
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(2)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.line_spacing = 1.15
        format_inline(p, stripped)

    if in_code_block:
        flush_code()
    if in_table:
        flush_table()

    doc.save(str(docx_file))
    print(f"Exportación exitosa: {docx_file}")
    return True

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Uso: python md_to_docx.py <archivo.md> [archivo.docx]")
        sys.exit(1)
    md_in = sys.argv[1]
    docx_out = sys.argv[2] if len(sys.argv) > 2 else None
    success = convert_md_to_docx(md_in, docx_out)
    sys.exit(0 if success else 1)

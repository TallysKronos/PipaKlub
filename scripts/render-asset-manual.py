"""Build the asset handbook PDF from its editable Markdown source.

Requires ReportLab. Run from any directory; output is relative to the repository.
The renderer deliberately supports the small Markdown vocabulary in this manual.
"""
from pathlib import Path
import re
import html
import textwrap
from reportlab.pdfgen import canvas
from reportlab.platypus import (
    BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, PageBreak,
    Table, TableStyle, Flowable, KeepTogether,
)
from reportlab.platypus.tableofcontents import TableOfContents
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.pagesizes import A4

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'MANUAL-DE-ASSETS.md'
OUTPUT = ROOT / 'output/pdf/PipaKlub-Manual-Mestre-de-Assets-v1.pdf'
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
FONT_DIR = Path('C:/Windows/Fonts')
for family, filename in [('Arial', 'arial.ttf'), ('Arial-Bold', 'arialbd.ttf'),
                         ('Arial-Italic', 'ariali.ttf'), ('Mono', 'consola.ttf')]:
    pdfmetrics.registerFont(TTFont(family, str(FONT_DIR / filename)))
pdfmetrics.registerFontFamily('Arial', normal='Arial', bold='Arial-Bold', italic='Arial-Italic', boldItalic='Arial-Bold')
NAVY = colors.HexColor('#17384a')
INK = colors.HexColor('#263940')
TEAL = colors.HexColor('#227a80')
RUST = colors.HexColor('#b75335')
CREAM = colors.HexColor('#f5efe1')
MUTED = colors.HexColor('#627178')
PAGE_W, PAGE_H = A4
WIDTH = PAGE_W - 104

styles = {
    'body': ParagraphStyle('body', fontName='Arial', fontSize=10, leading=14.6, textColor=INK, spaceAfter=8, splitLongWords=True),
    'chapter': ParagraphStyle('chapter', fontName='Arial-Bold', fontSize=22, leading=27, textColor=NAVY, spaceAfter=17, keepWithNext=True),
    'section': ParagraphStyle('section', fontName='Arial-Bold', fontSize=12.3, leading=17, textColor=TEAL, spaceBefore=11, spaceAfter=7, keepWithNext=True),
    'list': ParagraphStyle('list', fontName='Arial', fontSize=10, leading=14.6, textColor=INK, leftIndent=14, firstLineIndent=-11, spaceAfter=5),
    'quote': ParagraphStyle('quote', fontName='Arial', fontSize=9.7, leading=14.5, textColor=INK, borderColor=TEAL, borderWidth=.8, borderPadding=12, backColor=CREAM, spaceBefore=8, spaceAfter=14),
    'cell': ParagraphStyle('cell', fontName='Arial', fontSize=8.5, leading=12, textColor=INK, splitLongWords=True),
    'th': ParagraphStyle('th', fontName='Arial-Bold', fontSize=8.5, leading=12, textColor=colors.white, splitLongWords=True),
    'code': ParagraphStyle('code', fontName='Mono', fontSize=8, leading=11.7, textColor=INK, backColor=CREAM, borderPadding=9, spaceAfter=12),
    'caption': ParagraphStyle('caption', fontName='Arial-Italic', fontSize=8.5, leading=12, textColor=MUTED, spaceAfter=12),
}

def clean(s):
    return s.translate(str.maketrans({'–': '-', '—': '-', '‑': '-', '→': '->', '←': '<-'}))

def inline(s):
    s = html.escape(clean(s))
    s = re.sub(r'`([^`]+)`', r'<font name="Mono" size="8.5">\1</font>', s)
    s = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', s)
    s = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<link href="\2" color="#227a80">\1</link>', s)
    return s

def p(s, kind='body'):
    return Paragraph(inline(s), styles[kind])

class Slices(Flowable):
    """Vector technical plate; not a substitute for a final game texture."""
    def __init__(self):
        super().__init__()
        self.width = WIDTH
        self.height = 205

    def draw(self):
        c = self.canv
        c.setFillColor(CREAM)
        c.roundRect(0, 0, WIDTH, 200, 8, fill=1, stroke=0)
        c.setFillColor(NAVY)
        c.setFont('Arial-Bold', 10)
        c.drawString(15, 180, 'HUD MODULAR | REGIÕES FIXAS E EXPANSÍVEIS')
        for y, w in [(130, 175), (93, 300)]:
            for x, sw, col in [(16, 30, TEAL), (46, w - 60, colors.HexColor('#e4ca8e')), (16 + w - 30, 30, TEAL)]:
                c.setFillColor(col)
                c.rect(x, y, sw, 26, fill=1, stroke=0)
            c.setFillColor(INK)
            c.setFont('Arial', 8)
            c.drawString(330, y + 8, 'pontas preservadas')
        c.setFillColor(INK)
        c.setFont('Arial', 9)
        c.drawString(16, 71, '3-slice: a largura muda no centro; a altura mantém a escala.')
        for row in range(3):
            for col in range(3):
                c.setFillColor(TEAL if row != 1 and col != 1 else colors.HexColor('#e4ca8e'))
                c.rect(16 + col * 23, 10 + row * 16, 21, 14, fill=1, stroke=0)
        c.setFillColor(INK)
        c.setFont('Arial', 9)
        c.drawString(100, 38, '9-slice: quatro cantos fixos, bordas em um eixo, centro em dois.')
        c.drawString(100, 22, 'O texto e a área clicável continuam fora da imagem.')

class Anchors(Flowable):
    def __init__(self):
        super().__init__()
        self.width = WIDTH
        self.height = 148

    def draw(self):
        c = self.canv
        c.setFillColor(CREAM)
        c.roundRect(0, 0, WIDTH, 145, 8, fill=1, stroke=0)
        c.setFont('Arial-Bold', 10)
        c.setFillColor(NAVY)
        c.drawString(15, 126, 'CÉLULA, SILHUETA E ÂNCORA | ESQUEMA TÉCNICO')
        for i, tilt in enumerate([0, -6, 6]):
            x = 18 + i * 90
            c.setStrokeColor(MUTED)
            c.setDash(2, 2)
            c.rect(x, 28, 75, 75, fill=0, stroke=1)
            c.setDash()
            c.setStrokeColor(TEAL)
            c.setFillColor(colors.HexColor('#e4ca8e'))
            path = c.beginPath()
            path.moveTo(x+37+tilt, 90)
            path.lineTo(x+57, 67)
            path.lineTo(x+37, 40)
            path.lineTo(x+18, 67)
            path.close()
            c.drawPath(path, fill=1, stroke=1)
            c.setFillColor(RUST)
            c.circle(x+37, 40, 3, fill=1, stroke=0)
            c.setStrokeColor(RUST)
            c.line(x+32, 40, x+42, 40)
            c.line(x+37, 35, x+37, 45)
        c.setFillColor(INK)
        c.setFont('Arial', 8.6)
        for j, line in enumerate(['Mesma célula.', 'Escala constante.', 'Âncora corporal estável.', 'Pose muda; recorte não salta.']):
            c.drawString(301, 91 - j*16, line)
        c.setFont('Arial-Italic', 8)
        c.drawString(18, 11, 'A âncora de uma criatura aérea pode diferir do ponto dos pés de um ator no chão.')

class ManualDoc(BaseDocTemplate):
    def afterFlowable(self, flowable):
        if isinstance(flowable, Paragraph) and flowable.style.name == 'chapter' and re.match(r'^\d{2}\.', flowable.getPlainText()):
            title = flowable.getPlainText()
            key = 'chapter-' + title[:2]
            self.canv.bookmarkPage(key)
            self.canv.addOutlineEntry(title, key, 0, False)
            self.notify('TOCEntry', (0, title, self.page, key))

def page_frame(c, doc):
    c.saveState()
    if doc.page > 1:
        c.setStrokeColor(colors.HexColor('#d8ddd9'))
        c.line(52, PAGE_H-39, PAGE_W-52, PAGE_H-39)
        c.setFillColor(MUTED)
        c.setFont('Arial', 8)
        c.drawString(52, PAGE_H-29, 'PIPAKLUB  /  MANUAL MESTRE DE ASSETS')
    c.setFillColor(MUTED)
    c.setFont('Arial', 8)
    c.drawString(52, 28, 'v1.0  |  18.10.2026  |  Direção, produção e auditoria')
    c.drawRightString(PAGE_W-52, 28, str(doc.page))
    c.restoreState()

story = []
cover_title = ParagraphStyle('cover-title', fontName='Arial-Bold', fontSize=38, leading=42, textColor=NAVY, spaceAfter=22)
cover_intro = ParagraphStyle('cover-intro', fontName='Arial', fontSize=15, leading=22, textColor=INK, spaceAfter=22)
story += [Spacer(1, 66), p('PIPAKLUB', 'section'),
          Paragraph('Manual mestre<br/>de produção<br/>de assets', cover_title),
          Paragraph('Um universo de papel, vento<br/>e identidade em cada detalhe.', cover_intro),
          Spacer(1, 20), p('Direção de arte • HUD • Tiles • Mapas • Objetos<br/>Personagens • Pipamons • Animação • VFX'.replace('<br/>', ' / ')),
          Spacer(1, 25), p('32 capítulos, contratos técnicos, prompts reutilizáveis e critérios de aprovação.'),
          Spacer(1, 38), p('Versão 1.0 | 18 de outubro de 2026', 'section'),
          p('A fonte editável desta edição é MANUAL-DE-ASSETS.md. O documento diferencia regras obrigatórias, contratos atuais do jogo e recomendações para novas produções.', 'caption'),
          PageBreak(), p('Índice de consulta', 'chapter')]
toc = TableOfContents()
toc.levelStyles = [ParagraphStyle('toc', fontName='Arial', fontSize=10, leading=15.7, textColor=INK, spaceBefore=4.2)]
story += [toc, Spacer(1, 24)]

lines = SOURCE.read_text(encoding='utf-8').splitlines()
i = 0
# Skip the redundant document title; retain the full editorial introduction.
while i < len(lines):
    line = lines[i].strip()
    if not line or line.startswith('# '):
        i += 1
        continue
    if line.startswith('## '):
        if not isinstance(story[-1], PageBreak):
            story.append(PageBreak())
        story.append(p(line[3:], 'chapter'))
        i += 1
        if line.startswith('## 10.'):
            story += [Anchors(), Spacer(1, 10)]
        if line.startswith('## 12.'):
            story += [Slices(), Spacer(1, 10)]
        continue
    if line.startswith('### '):
        story.append(p(line[4:], 'section'))
        i += 1
        continue
    if line.startswith('```'):
        code = []
        i += 1
        while i < len(lines) and not lines[i].startswith('```'):
            code += textwrap.wrap(clean(lines[i]), width=87, subsequent_indent='  ', replace_whitespace=False) or ['']
            i += 1
        # A single padded block can split naturally; do not box every line.
        code_html = '<br/>'.join(html.escape(code_line).replace(' ', '&#160;') or '&#160;' for code_line in code)
        story.append(Paragraph(code_html, styles['code']))
        i += 1
        continue
    if line.startswith('|'):
        rows = []
        while i < len(lines) and lines[i].strip().startswith('|'):
            cells = [cell.strip() for cell in lines[i].strip().strip('|').split('|')]
            if not all(re.fullmatch(r':?-+:?', cell) for cell in cells):
                rows.append(cells)
            i += 1
        n = len(rows[0])
        ratios = {2: [.31, .69], 3: [.25, .35, .40], 4: [.21, .22, .32, .25], 5: [.16, .21, .21, .21, .21]}.get(n, [1/n]*n)
        data = [[p(cell, 'th' if r == 0 else 'cell') for cell in row] for r, row in enumerate(rows)]
        table = Table(data, colWidths=[WIDTH*x for x in ratios], repeatRows=1, hAlign='LEFT')
        table.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), NAVY), ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, CREAM]),
            ('VALIGN', (0,0), (-1,-1), 'TOP'), ('LEFTPADDING', (0,0), (-1,-1), 8),
            ('RIGHTPADDING', (0,0), (-1,-1), 8), ('TOPPADDING', (0,0), (-1,-1), 8),
            ('BOTTOMPADDING', (0,0), (-1,-1), 8), ('LINEBELOW', (0,0), (-1,0), .6, TEAL),
        ]))
        story += [KeepTogether([table, Spacer(1, 12)]) if len(rows) <= 8 else table, Spacer(1, 12)]
        continue
    if line.startswith('>'):
        quote = []
        while i < len(lines) and lines[i].strip().startswith('>'):
            quote.append(lines[i].strip().lstrip('>').strip())
            i += 1
        story.append(p(' '.join(quote), 'quote'))
        continue
    if re.match(r'^(- |\d+\. )', line):
        label = re.sub(r'^- ', '• ', line)
        story.append(p(label, 'list'))
        i += 1
        continue
    paragraph = [line]
    i += 1
    while i < len(lines) and lines[i].strip() and not re.match(r'^(#|\||>|```|- |\d+\. )', lines[i].strip()):
        paragraph.append(lines[i].strip())
        i += 1
    story.append(p(' '.join(paragraph)))

doc = ManualDoc(str(OUTPUT), pagesize=A4, leftMargin=52, rightMargin=52, topMargin=58, bottomMargin=49,
                title='PipaKlub - Manual mestre de produção de assets', author='PipaKlub',
                subject='Regras de arte, formatos, integração e auditoria de assets')
doc.addPageTemplates(PageTemplate(id='manual', frames=[Frame(52, 49, WIDTH, PAGE_H-107, leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)], onPage=page_frame))
doc.multiBuild(story)
print(OUTPUT)

"""Render 48 narrative script pages, not finished comic artwork.

The full editorial brief and character direction remain in ROTEIRO.md.
Requires ReportLab; uses the Windows fonts already used for the asset manual.
"""
from pathlib import Path
import re
import html
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

ROOT = Path(__file__).resolve().parents[3]
SOURCE = Path(__file__).with_name('ROTEIRO.md')
OUTPUT = ROOT / 'output/pdf/PipaKlub-Tyler-Fios-do-Principio-Roteiro-48-paginas-v1.pdf'
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
for family, filename in [('Arial', 'arial.ttf'), ('Arial-Bold', 'arialbd.ttf'), ('Arial-Italic', 'ariali.ttf')]:
    pdfmetrics.registerFont(TTFont(family, 'C:/Windows/Fonts/' + filename))
pdfmetrics.registerFontFamily('Arial', normal='Arial', bold='Arial-Bold', italic='Arial-Italic', boldItalic='Arial-Bold')
NAVY = colors.HexColor('#203a48')
INK = colors.HexColor('#283339')
ROSE = colors.HexColor('#ad5973')
MUTED = colors.HexColor('#63717a')
PAPER = colors.HexColor('#f4f1e9')
W, H = A4
styles = {
    'label': ParagraphStyle('label', fontName='Arial-Bold', fontSize=9, leading=13, textColor=ROSE, spaceAfter=9),
    'title': ParagraphStyle('title', fontName='Arial-Bold', fontSize=22, leading=27, textColor=NAVY, spaceAfter=12),
    'meta': ParagraphStyle('meta', fontName='Arial-Italic', fontSize=10, leading=15, textColor=MUTED, spaceAfter=20),
    'body': ParagraphStyle('body', fontName='Arial', fontSize=10.5, leading=15.5, textColor=INK, spaceAfter=12),
    'note': ParagraphStyle('note', fontName='Arial', fontSize=9.2, leading=13.5, textColor=MUTED, backColor=PAPER, borderPadding=10, spaceBefore=12, spaceAfter=12),
}
chapters = ['O filho do professor', 'Onde o vento muda', 'A revoada de Hamelin', 'O dono do atalho',
            'A linha que cede', 'Um corte, duas escolhas', 'A parede que escuta', 'O primeiro laço']
def inline(s):
    s = s.translate(str.maketrans({'—':'-', '–':'-', '‑':'-'}))
    return re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', html.escape(s))

source = SOURCE.read_text(encoding='utf-8')
story_source = source.split('## Roteiro página a página\n', 1)[1].split('\n## Direção visual', 1)[0]
pages = re.findall(r'^### Página (\d{2}) — (.+)\n([\s\S]*?)(?=^### Página |\Z)', story_source, re.M)
assert [int(n) for n, _, _ in pages] == list(range(1, 49)), 'Exactly 48 sequential script pages required.'
flow = []
for index, (number, title, body) in enumerate(pages):
    chapter = index // 6
    if index:
        flow.append(PageBreak())
    flow.append(Paragraph(f'CAPÍTULO {chapter+1:02d} / {chapters[chapter].upper()}', styles['label']))
    flow.append(Paragraph(inline(f'{number}. {title}'), styles['title']))
    paragraphs = body.strip().split('\n\n')
    for j, paragraph in enumerate(paragraphs):
        kind = 'meta' if j == 0 else 'note' if paragraph.startswith('**Intenção') else 'body'
        flow.append(Paragraph(inline(paragraph), styles[kind]))

def furniture(c, doc):
    c.saveState()
    c.setFillColor(MUTED)
    c.setFont('Arial', 8)
    c.drawString(52, H-30, 'PIPAKLUB / FIOS DO PRINCÍPIO / ROTEIRO PARA STORYBOARD')
    c.setStrokeColor(colors.HexColor('#d9d9d3'))
    c.line(52, H-40, W-52, H-40)
    c.drawString(52, 28, 'Versão 1 | Proposta narrativa | Não contém arte final')
    c.drawRightString(W-52, 28, f'Página de história {doc.page:02d} / 48')
    if doc.page <= 48:
        chapter = (doc.page-1) // 6
        key = f'page-{doc.page:02d}'
        c.bookmarkPage(key)
        if (doc.page-1) % 6 == 0:
            c.addOutlineEntry(f'{chapter+1}. {chapters[chapter]}', key+'-chapter', 0, False)
            c.bookmarkPage(key+'-chapter')
        c.addOutlineEntry(f'{doc.page:02d}. {pages[doc.page-1][1]}', key, 1, False)
    c.restoreState()

doc = SimpleDocTemplate(str(OUTPUT), pagesize=A4, leftMargin=52, rightMargin=52, topMargin=63, bottomMargin=55,
                        title='PipaKlub: Fios do Princípio - Roteiro de 48 páginas', author='PipaKlub',
                        subject='One-shot de Tyler, Rai e Platyx. Proposta para storyboard, oito capítulos.')
doc.build(flow, onFirstPage=furniture, onLaterPages=furniture)
print(OUTPUT)

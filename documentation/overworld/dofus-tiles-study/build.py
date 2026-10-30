"""Build this reference notebook without external packages or remote assets.
The SVGs are original explanatory geometry, not game art or screenshot edits.
"""
from pathlib import Path
import hashlib
import html
import json
import re
import unicodedata

ROOT = Path(__file__).resolve().parent
DIAGRAMS = ROOT / "diagrams"
DIAGRAMS.mkdir(exist_ok=True)


def svg(name, body, height=430):
    (DIAGRAMS / name).write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 {height}" role="img">'
        '<style>text{font-family:Arial,sans-serif;fill:#19392f;font-size:18px}.title{font-size:23px;font-weight:bold}.small{font-size:15px}</style>'
        f'<rect width="1000" height="{height}" fill="#f7f2e6"/>{body}</svg>', encoding="utf-8")


grid = ''.join(f'<path d="M{x} 67V177 M{x} 267V377" stroke="#305a40" opacity=".15"/>' for x in range(30, 972, 47))
wave = 'M30 122' + ''.join(f' Q{x+23.5} {92 if i%2==0 else 152} {x+47} 122' for i,x in enumerate(range(30, 970, 47)))
svg('continuidade.svg', '<text x="30" y="34" class="title">01 · Fechado não significa visualmente contínuo</text>'
    '<rect x="30" y="67" width="940" height="110" rx="6" fill="#89a95a"/>'
    f'<path d="{wave} L970 177H30Z" fill="#d8ba82"/>{grid}'
    '<text x="30" y="211">A · Curvas locais repetidas: a frequência da grade aparece como ondulação.</text>'
    '<rect x="30" y="267" width="940" height="110" rx="6" fill="#89a95a"/>'
    '<path d="M30 325 C125 324 180 306 255 311 L272 316 285 310 C380 302 460 334 550 326 L562 331 576 326 C690 318 750 304 825 310 L837 307 851 313 C900 317 935 312 970 314 V377H30Z" fill="#d8ba82"/>'
    '<text x="30" y="411">B · Direção longa preservada; pequenas quebras concentradas e assimétricas.</text>')

body = '<text x="30" y="34" class="title">02 · Responsabilidades separadas</text>'
rows = [
    ('1', 'SUPORTE', 'Células, alturas, rampas e recortes', '#d0b99a'),
    ('2', 'MATERIAL', 'Grama / terra / piso, sem buracos', '#89a95a'),
    ('3', 'TRANSIÇÃO', 'Um contorno compartilhado entre materiais', '#d8ba82'),
    ('4', 'DECALQUES', 'Detalhes esparsos, sem mudar colisão', '#bfd099'),
    ('5', 'VOLUMES', 'Objetos apoiados e sombras coerentes', '#6e8c76'),
]
for i, (number, title, desc, color) in enumerate(rows):
    y = 60+i*72
    body += f'<rect x="30" y="{y}" width="940" height="59" rx="5" fill="{color}"/>'
    body += f'<text x="49" y="{y+36}" class="title">{number}</text><text x="92" y="{y+36}" font-weight="bold">{title}</text><text x="295" y="{y+36}">{desc}</text>'
svg('camadas.svg', body, 445)

shapes = [
    ('CENTRO', '<rect width="130" height="100" fill="#89a95a"/>'),
    ('LADO', '<path d="M0 49 L50 46 60 50 95 47 130 48 V100H0Z" fill="#d8ba82"/>'),
    ('CANTO EXTERNO', '<path d="M0 0H80 Q85 40 130 55V100H0Z" fill="#d8ba82"/>'),
    ('CANTO INTERNO', '<path d="M0 0H130V100H0Z" fill="#d8ba82"/><path d="M0 0H90 Q82 48 0 55Z" fill="#89a95a"/>'),
    ('PONTA', '<path d="M0 30H76 Q120 50 76 70H0Z" fill="#d8ba82"/>'),
    ('FAIXA ESTREITA', '<path d="M0 29L50 31 130 28V68L60 71 0 70Z" fill="#d8ba82"/>'),
    ('JUNÇÃO', '<path d="M0 0H130V50H60V100H0Z" fill="#d8ba82"/><path d="M130 50H60V100H130Z" fill="#d6d5be"/>'),
    ('ILHA', '<path d="M30 33L78 23 99 46 85 76 43 73 24 53Z" fill="#d8ba82"/>'),
]
body = '<text x="30" y="34" class="title">03 · Topologia antes da aparência</text><text x="30" y="62" class="small">Esquemas em planta lógica. Não são peças de um atlas final nem tiles de Dofus.</text>'
for i, (label, shape) in enumerate(shapes):
    x, y = 40+(i%4)*245, 88+(i//4)*175
    body += f'<g transform="translate({x},{y})"><rect width="130" height="100" fill="#89a95a"/>{shape}<rect width="130" height="100" fill="none" stroke="#46654b" stroke-width="1"/><text y="128" class="small">{label}</text></g>'
svg('topologia.svg', body, 420)


def inline(text):
    text = html.escape(text)
    text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
    text = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', text)
    text = re.sub(r'!\[([^\]]*)\]\(([^)]+)\)', r'<figure><a href="\2"><img loading="lazy" src="\2" alt="\1"></a><figcaption>\1</figcaption></figure>', text)
    return re.sub(r'(?<!!)\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', text)


source = (ROOT / 'README.md').read_text(encoding='utf-8')
lines = source.splitlines()
parts, toc = [], []
i = 0
while i < len(lines):
    line = lines[i]
    if not line.strip():
        i += 1
        continue
    if line.startswith('!['):
        parts.append(inline(line))
        i += 1
        continue
    if line.startswith('```'):
        code = []
        i += 1
        while i < len(lines) and not lines[i].startswith('```'):
            code.append(lines[i])
            i += 1
        parts.append('<pre><code>'+html.escape('\n'.join(code))+'</code></pre>')
        i += 1
        continue
    heading = re.match(r'^(#{1,3}) (.+)$', line)
    if heading:
        level, title = len(heading[1]), heading[2]
        slug = re.sub(r'[^a-z0-9]+', '-', unicodedata.normalize('NFKD', title).encode('ascii', 'ignore').decode().lower()).strip('-')
        parts.append(f'<h{level} id="{slug}">{inline(title)}</h{level}>')
        if level == 2:
            toc.append(f'<a href="#{slug}">{html.escape(title)}</a>')
        i += 1
        continue
    if line.startswith('|'):
        rows = []
        while i < len(lines) and lines[i].startswith('|'):
            cells = [c.strip() for c in lines[i].strip().strip('|').split('|')]
            if not all(re.fullmatch(r':?-+:?', c) for c in cells):
                tag = 'th' if not rows else 'td'
                rows.append('<tr>'+''.join(f'<{tag}>{inline(c)}</{tag}>' for c in cells)+'</tr>')
            i += 1
        parts.append('<div class="table"><table>'+''.join(rows)+'</table></div>')
        continue
    if re.match(r'^(?:- |\d+\. )', line):
        ordered = bool(re.match(r'^\d+\. ', line))
        tag = 'ol' if ordered else 'ul'
        items = []
        pattern = r'^\d+\. ' if ordered else r'^- '
        while i < len(lines) and re.match(pattern, lines[i]):
            items.append('<li>'+inline(re.sub(pattern, '', lines[i]))+'</li>')
            i += 1
        parts.append(f'<{tag}>'+''.join(items)+f'</{tag}>')
        continue
    paragraph = [line]
    i += 1
    while i < len(lines) and lines[i].strip() and not re.match(r'^(?:#|\||```|- |\d+\. )', lines[i]):
        paragraph.append(lines[i])
        i += 1
    parts.append('<p>'+inline(' '.join(paragraph))+'</p>')

css = '''
:root{color-scheme:light;--ink:#213c35;--muted:#69756c;--paper:#faf7ef;--line:#deddd1;--accent:#336b55}
*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:24px}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.75 Georgia,serif}
aside{position:fixed;inset:0 auto 0 0;width:278px;background:#e9eee5;padding:28px 22px;overflow:auto;font:13px/1.5 Arial,sans-serif;border-right:1px solid var(--line)}
aside b{display:block;font-size:18px;margin-bottom:16px}aside a{display:block;margin:0 0 9px;color:#365447;text-decoration:none}aside a:hover{text-decoration:underline}
main{max-width:1120px;padding:48px 64px 100px;margin-left:278px}h1{font-size:48px;line-height:1.12;font-weight:normal;letter-spacing:-1.3px;margin:12px 0 24px;max-width:850px}
h2{font:700 25px/1.3 Arial,sans-serif;margin:60px 0 22px;border-top:1px solid var(--line);padding-top:24px}h3{font:700 19px/1.4 Arial,sans-serif;margin:32px 0 12px}
a{color:#246951;text-underline-offset:3px}p{margin:0 0 20px}strong{font-weight:bold}code{font:13px/1.5 Consolas,monospace;background:#eceee5;padding:2px 5px;border-radius:3px;overflow-wrap:anywhere}
pre{background:#e9eee5;padding:22px;white-space:pre-wrap;overflow-wrap:anywhere;border-left:3px solid #82a386}pre code{padding:0;background:none}li{margin:9px 0}
.table{overflow-x:auto;margin:24px 0 30px}table{width:100%;border-collapse:collapse;font:14px/1.6 Arial,sans-serif}th{text-align:left;background:#e6ebdf}th,td{padding:12px 14px;border-bottom:1px solid var(--line);vertical-align:top;min-width:90px}
figure{margin:30px 0;background:#f0eee4;padding:15px;text-align:center}img{display:block;max-width:100%;height:auto;margin:auto}figcaption{font:13px/1.5 Arial,sans-serif;color:var(--muted);margin-top:12px}
.badge{font:11px Arial,sans-serif;letter-spacing:2px;color:var(--muted)}.tools{font:13px Arial,sans-serif;margin:20px 0 35px}.tools button{border:1px solid #b8c8b6;color:var(--ink);background:#eef2e8;padding:9px 14px;cursor:pointer;margin-right:14px}
@media(max-width:1000px){aside{position:relative;width:auto;max-height:260px}main{margin:0;padding:30px 22px}h1{font-size:36px}}
@media print{aside,.tools{display:none}main{margin:0;max-width:none;padding:0}body{font-size:11pt}h1{font-size:30pt}h2{break-before:auto;font-size:18pt}figure,tr,pre{break-inside:avoid}a{color:inherit}figure{max-height:none}img{max-height:220mm}}
'''
document = '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Estudo de pisos · Dofus e Soulmonsters</title><style>'+css+'</style></head><body><aside><b>Caderno de pisos</b>'+''.join(toc)+'</aside><main><div class="badge">SOULMONSTERS / PESQUISA DE CENÁRIOS / 29.10.2026</div><div class="tools"><button onclick="window.print()">Imprimir / salvar PDF</button><a href="README.md">Fonte em Markdown</a></div>'+''.join(parts)+'</main></body></html>'
(ROOT / 'index.html').write_text(document, encoding='utf-8')

references = []
for path in sorted((ROOT / 'references').glob('*.png')):
    references.append({'file': path.relative_to(ROOT).as_posix(), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'origin': 'existing local campaign capture; unchanged copy' if path.name.startswith('05-') else 'user attachment; unchanged copy', 'runtimeAsset': False})
(ROOT / 'provenance.json').write_text(json.dumps({'date': '2026-10-29', 'references': references, 'diagrams': 'Original technical SVG schematics generated by build.py; not production tiles', 'runtimeChanged': False}, indent=2, ensure_ascii=False), encoding='utf-8')

# Verify the deliverable's local targets; remote sources were inspected via web.
targets = re.findall(r'(?:src|href)="([^"#]+)"', document)
missing = [target for target in targets if not target.startswith(('http:', 'https:')) and not (ROOT / target).exists()]
if missing:
    raise SystemExit(f'Missing local references: {missing}')
print(json.dumps({'words': len(source.split()), 'sections': len(toc), 'figures': document.count('<figure>'), 'brokenLocalLinks': missing}, ensure_ascii=False))

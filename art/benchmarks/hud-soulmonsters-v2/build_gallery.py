"""Rebuild the offline research gallery. Python standard library only."""
from pathlib import Path
import hashlib
import html
import json
import re
from html.parser import HTMLParser

ROOT = Path(__file__).resolve().parent
catalog = json.loads((ROOT / 'fontes.json').read_text(encoding='utf-8-sig'))
report = (ROOT / 'ANALISE.md').read_text(encoding='utf-8-sig')
esc = html.escape


def inline(text):
    text = esc(text)
    text = re.sub(r'!\[([^\]]*)\]\(([^)]+)\)', r'<a href="\2"><img loading="lazy" alt="\1" src="\2"></a>', text)
    text = re.sub(r'(?<!!)\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', text)
    text = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', text)
    return re.sub(r'`([^`]+)`', r'<code>\1</code>', text)


def render_md(text):
    output, paragraph, list_open, table_open = [], [], False, False

    def flush():
        if paragraph:
            output.append('<p>' + inline(' '.join(paragraph)) + '</p>')
            paragraph.clear()

    for line in text.splitlines() + ['']:
        if line.startswith('|'):
            flush()
            if not table_open:
                output.append('<div class="table-scroll"><table>')
                table_open = True
            if re.fullmatch(r'[| :\-]+', line):
                continue
            output.append('<tr>' + ''.join('<td>' + inline(cell.strip()) + '</td>' for cell in line.strip('|').split('|')) + '</tr>')
            continue
        if table_open:
            output.append('</table></div>')
            table_open = False
        if line.startswith('- '):
            flush()
            if not list_open:
                output.append('<ul>')
                list_open = True
            output.append('<li>' + inline(line[2:]) + '</li>')
            continue
        if list_open:
            output.append('</ul>')
            list_open = False
        match = re.match(r'^(#{1,3}) (.+)$', line)
        if match:
            flush()
            level = len(match[1])
            output.append(f'<h{level}>' + inline(match[2]) + f'</h{level}>')
        elif not line.strip():
            flush()
        else:
            paragraph.append(line)
    return '\n'.join(output)


games = dict(bw='Black / White', dwds='Digimon World DS', pmd='Explorers of Sky', persona='Persona 5', yokai='Yo-kai Watch', ninokuni='Ni no Kuni', cyber='Cyber Sleuth')
cards = []
for record in catalog['records']:
    source = catalog['sources'][record['source']]
    cards.append(f'''<article class="card" data-game="{esc(record['game'])}">
      <a class="picture" href="{esc(record['file'])}" target="_blank" rel="noopener"><img loading="lazy" src="{esc(record['file'])}" alt="{esc(record['screen'])}"></a>
      <div class="caption"><span class="tag">{esc(record['id'])} · {esc(games[record['game']])}</span>
      <h3>{esc(record['screen'])}</h3><p>{esc(source['version'])}</p>
      <p>{esc(record['location'])} · consulta {esc(record['consulted'])}</p>
      <p class="credit">{esc(source['credit'])}</p>
      <a href="{esc(source['url'])}">Fonte e contexto</a> · <a href="{esc(record['directUrl'])}">Original</a></div></article>''')
filters = '<button type="button" data-filter="all" aria-pressed="true">Todos</button>' + ''.join(f'<button type="button" data-filter="{key}" aria-pressed="false">{esc(name)}</button>' for key, name in games.items())
page = '''<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Estudo de HUD · Soulmonsters · PIP-127</title>
<style>
:root{color-scheme:light;--ink:#172d36;--paper:#f6f3eb;--accent:#006d77}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.65 system-ui,sans-serif}header,main,footer{max-width:1440px;margin:auto;padding:32px clamp(20px,4vw,64px)}header{border-bottom:2px solid var(--ink)}header p{max-width:820px}h1{font-size:clamp(32px,5vw,62px);line-height:1.08;letter-spacing:-.04em;margin:20px 0}h2{font-size:30px;line-height:1.2;margin-top:50px}h3{line-height:1.35}a{color:var(--accent);text-underline-offset:3px}nav{display:flex;gap:12px;flex-wrap:wrap}nav a{padding:8px 12px;border:1px solid #a4b8bb;border-radius:6px}.eyebrow,.tag{text-transform:uppercase;font-size:12px;font-weight:750;letter-spacing:.08em}.notice{border-left:4px solid #b07019;background:#f4e6cd;padding:14px 20px;margin:24px 0}.filters{display:flex;flex-wrap:wrap;gap:8px;margin:24px 0}button{font:inherit;font-size:14px;border:1px solid #7e969a;padding:9px 14px;background:transparent;color:var(--ink);cursor:pointer;border-radius:6px}button[aria-pressed=true]{background:var(--ink);color:white}button:focus-visible,a:focus-visible{outline:3px solid #b1670b;outline-offset:4px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,330px),1fr));gap:24px}.card{border:1px solid #b3c1c2;background:#fff;border-radius:8px;overflow:hidden}.picture{height:260px;display:flex;background:#e4e9e7;align-items:center;justify-content:center;padding:12px}.picture img{max-width:100%;max-height:100%;object-fit:contain}.caption{padding:20px}.caption h3{margin:8px 0}.caption p{font-size:14px;margin:8px 0}.credit{color:#4d6469}[hidden]{display:none!important}.report{max-width:960px;margin:auto}.report img{max-width:100%;max-height:480px;object-fit:contain;background:white;margin:12px auto;display:block}code{font-size:.88em;overflow-wrap:anywhere}.table-scroll{overflow:auto}table{border-collapse:collapse;font-size:14px;min-width:650px}td{border:1px solid #bcc9c8;padding:10px;vertical-align:top}tr:first-child{font-weight:bold;background:#e4ece8}.summary{max-width:960px}.contact{width:100%;height:auto}footer{border-top:1px solid #b3c1c2;font-size:14px}html{scroll-behavior:auto}
</style></head><body><header><div class="eyebrow">Soulmonsters / Pesquisa visual / PIP-127 / 01.11.2026</div><h1>A interface como parte<br>do mundo.</h1><p>Sete famílias de HUD, 27 evidências e dez princípios para pipa, Kronasta, almática, Elo e Pipa TV. Este é um caderno de pesquisa, não uma proposta de HUD aprovada.</p><nav aria-label="Seções"><a href="#sintese">Síntese</a><a href="#evidencias">Evidências</a><a href="#analise">Estudo completo</a><a href="fontes.json">Fontes e hashes</a></nav></header><main>
<section id="sintese" class="summary"><h2>Identidade é uma gramática.</h2><p>Forma, comando, foco e ritmo precisam compartilhar uma lógica. A pipa pode explicar os recursos e suas relações; o bairro pode orientar a consulta; a Pipa TV pode marcar os grandes acontecimentos.</p><div class="notice"><strong>Escopo: observação estática.</strong> Não foram medidos animação, áudio, latência ou controle físico. Ni no Kuni tem cobertura parcial de campo e pausa; a intro VS de Black/White não foi comprovada. As versões analisadas estão identificadas em cada evidência.</div><a href="prancha-comparativa.jpg"><img class="contact" src="prancha-comparativa.jpg" alt="Sete referências representativas identificadas por jogo e código de evidência"></a></section>
<section id="evidencias"><h2>Evidências com procedência</h2><p>Abra uma imagem para ampliar. Referências de terceiros para estudo crítico; não são assets para integrar ao jogo.</p><div class="filters" role="group" aria-label="Filtrar evidências por jogo">FILTERS</div><p id="count" role="status" aria-live="polite">27 evidências</p><div class="grid">CARDS</div></section>
<section id="analise" class="report">REPORT</section></main><footer>Reconstruir: python build_gallery.py · Fontes consultadas em 01/11/2026 · Direitos das imagens pertencem aos titulares identificados. Sem alteração de gameplay, merge ou push nesta etapa.</footer><script>
const buttons=[...document.querySelectorAll('[data-filter]')],cards=[...document.querySelectorAll('[data-game]')];
buttons.forEach(button=>button.addEventListener('click',()=>{buttons.forEach(b=>b.setAttribute('aria-pressed',String(b===button)));let total=0;cards.forEach(card=>{card.hidden=button.dataset.filter!=='all'&&card.dataset.game!==button.dataset.filter;if(!card.hidden)total++});document.getElementById('count').textContent=`${total} evidências`;}));
</script></body></html>'''.replace('FILTERS', filters).replace('CARDS', '\n'.join(cards)).replace('REPORT', render_md(report))
(ROOT / 'index.html').write_text(page, encoding='utf-8')

errors = []
ids = [r['id'] for r in catalog['records']]
if len(ids) != len(set(ids)):
    errors.append('Duplicate evidence ID')
for r in catalog['records']:
    path = ROOT / r['file']
    if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != r['sha256']:
        errors.append('File/hash mismatch: ' + r['id'])
    if r['source'] not in catalog['sources']:
        errors.append('Unknown source: ' + r['id'])
if set(r['game'] for r in catalog['records']) != set(games):
    errors.append('Game coverage differs from seven required titles')
principles = re.findall(r'^### (\d+)\. ', report, re.M)
if principles != [str(n) for n in range(1, 11)]:
    errors.append('Expected exactly ten ordered principles')


class Links(HTMLParser):
    def handle_starttag(self, tag, attrs):
        for key, value in attrs:
            if key in ('href', 'src') and not value.startswith(('https://', 'http://', '#')):
                if not (ROOT / value).is_file():
                    errors.append('Broken local link: ' + value)


Links().feed(page)
result = dict(date=catalog['date'], evidence_count=len(ids), games=len(games), principles=len(principles), checks=['Unique IDs', 'Local files and SHA-256', 'Seven game groups', 'Exactly ten ordered principles', 'Local HTML links'], errors=errors, status='pass' if not errors else 'fail', limitations=['Artifact integrity only; no browser layout, input hardware, gameplay, sound or timing tests.'])
(ROOT / 'validacao.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(result, ensure_ascii=False))
raise SystemExit(bool(errors))

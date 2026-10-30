"""Build offline research report without dependencies or remote executable code."""
import hashlib
import html
import json
import re
import shutil
from pathlib import Path
from urllib.parse import urlparse, unquote
from PIL import Image
from collect_index import ROOT

def esc(value):
    return html.escape(str(value), quote=True)

def inline(text):
    text=esc(text)
    text=re.sub(r'\[([^\]]+)\]\(((?:[^()]|\([^()]*\))*)\)', lambda m:f'<a href="{m[2]}">{m[1]}</a>', text)
    text=re.sub(r'\*\*([^*]+)\*\*',r'<strong>\1</strong>',text)
    text=re.sub(r'`([^`]+)`',r'<code>\1</code>',text)
    return text

def markdown(text):
    result=[]
    lines=text.splitlines()
    n=0
    while n<len(lines):
        line=lines[n].strip()
        if not line:
            n+=1
            continue
        if line.startswith('#'):
            match=re.match(r'^(#{1,6})\s+(.*)',line)
            level=len(match[1])
            result.append(f'<h{level}>{inline(match[2])}</h{level}>')
            n+=1
        elif line.startswith('|'):
            rows=[]
            while n<len(lines) and lines[n].strip().startswith('|'):
                cells=[c.strip() for c in lines[n].strip().strip('|').split('|')]
                if not all(re.match(r'^:?-+:?$',c) for c in cells):
                    tag='th' if not rows else 'td'
                    rows.append('<tr>'+''.join(f'<{tag}>{inline(c)}</{tag}>' for c in cells)+'</tr>')
                n+=1
            result.append('<div class="tablewrap"><table>'+''.join(rows)+'</table></div>')
        elif re.match(r'^(- |\d+\. )',line):
            numbered=bool(re.match(r'^\d+\. ',line))
            tag='ol' if numbered else 'ul'
            items=[]
            while n<len(lines) and re.match(r'^(- |\d+\. )',lines[n].strip()):
                items.append('<li>'+inline(re.sub(r'^(- |\d+\. )','',lines[n].strip()))+'</li>')
                n+=1
            result.append(f'<{tag}>'+''.join(items)+f'</{tag}>')
        else:
            para=[line]
            n+=1
            while n<len(lines) and lines[n].strip() and not re.match(r'^(#|\||- |\d+\. )',lines[n].strip()):
                para.append(lines[n].strip())
                n+=1
            result.append('<p>'+inline(' '.join(para))+'</p>')
    return '\n'.join(result)

def main():
    refs=json.loads((ROOT/'reference-sources.json').read_text(encoding='utf-8'))
    notes=json.loads((ROOT/'case-notes.json').read_text(encoding='utf-8'))
    catalogue=json.loads((ROOT/'catalogue.json').read_text(encoding='utf-8'))
    targets=ROOT/'references'
    targets.mkdir(exist_ok=True)
    records=[]
    for ref in refs:
        source=Path(ref['local_research_file'])
        target=targets/source.name
        shutil.copy2(source,target)
        with Image.open(target) as im:
            size=list(im.size)
        assert hashlib.sha256(target.read_bytes()).hexdigest()==ref['sha256']
        ref['research_file']='references/'+target.name
        ref['dimensions']=size
        ref['visual_inspection']='comparative sheet; separate original enlarged' if ref['id'] in ['REF-01','REF-04','REF-07','REF-08','REF-22','REF-28','REF-34','REF-37'] else 'comparative sheet'
        records.append(ref)
    (ROOT/'reference-sources.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
    by_id={r['id']:r for r in records}
    md=['# Fichas de observação — 48 pranchas','', 'Observação visual, interpretação para Soulmonsters e limites de transferência. Não são comentários atribuídos aos artistas. Cada arquivo possui análise própria; notas em japonês não foram traduzidas.','']
    cards=[]
    for note in notes:
        ref=by_id[note['id']]
        title=note['id']+' · '+note['subject']
        md.extend(['## '+title,'','[Fonte: '+ref['name']+']('+ref['url']+') · [Original local]('+ref['research_file']+')','', '**Observação.** '+note['observation'],'','**Aplicação proposta.** '+note['lesson'],'','**Limite.** '+note['avoid'],''])
        cards.append(f'''<article class="ref" data-search="{esc(note['subject']+' '+note['tag']+' '+note['observation']+' '+note['lesson'])}"><header><span>{esc(note['id'])} · {esc(note['tag'])}</span><h3>{esc(note['subject'])}</h3></header><a href="{esc(ref['research_file'])}"><img loading="lazy" src="{esc(ref['research_file'])}" alt="Prancha de referência: {esc(note['subject'])}"></a><div class="notebody"><p><strong>Observação.</strong> {esc(note['observation'])}</p><p><strong>Aplicação.</strong> {esc(note['lesson'])}</p><p><strong>Limite.</strong> {esc(note['avoid'])}</p><a href="{esc(ref['url'])}" target="_blank" rel="noreferrer">Página de origem ↗</a> · <a href="{esc(ref['research_file'])}">Abrir original {ref['dimensions'][0]} × {ref['dimensions'][1]}</a></div></article>''')
    (ROOT/'FICHAS.md').write_text('\n'.join(md),encoding='utf-8')
    categories=''.join(f'<tr><td><a href="{esc(c["url"])}">{esc(c["title"].removeprefix("Category:"))}</a></td><td>{c["file_count"]}</td></tr>' for c in catalogue['subcategories'])
    indexed=''.join(f'<li data-file-search="{esc(f["name"])}"><a href="{esc(f["url"])}" target="_blank" rel="noreferrer">{esc(f["name"])}</a></li>' for f in catalogue['files'])
    study=markdown((ROOT/'ESTUDO.md').read_text(encoding='utf-8'))
    document='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Concept art · Estudo Bulbagarden / Soulmonsters</title><style>
    :root{color-scheme:light;--ink:#24303d;--line:#d7d9d8;--paper:#f9f7f1;--accent:#175d65}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.65 system-ui,sans-serif}a{color:var(--accent);text-underline-offset:3px}main{max-width:1440px;margin:auto;padding:36px 28px}h1,h2,h3{line-height:1.2;letter-spacing:-.025em}h1{font-size:clamp(32px,4vw,54px)}h2{font-size:30px;margin-top:54px}h3{font-size:25px;margin:8px 0}.eyebrow{letter-spacing:.12em;text-transform:uppercase;font-size:12px}.intro{max-width:85ch}.counts{display:flex;gap:36px;flex-wrap:wrap;border-top:1px solid var(--line);border-bottom:1px solid var(--line);padding:20px 0}.counts strong{display:block;font-size:36px;line-height:1.1}.counts span{font-size:14px}nav{display:flex;gap:24px;flex-wrap:wrap;padding:20px 0}section{scroll-margin-top:24px}.study{max-width:940px;margin:auto}.study h1{font-size:37px}.study li{margin-bottom:10px}.tablewrap{overflow:auto}table{border-collapse:collapse;width:100%;font-size:15px}th,td{text-align:left;vertical-align:top;padding:12px;border-bottom:1px solid var(--line)}th{background:#e9ece7}.filters{display:flex;gap:12px;flex-wrap:wrap;margin:20px 0}input,select{font:inherit;padding:12px;border:1px solid #b4bdb9;border-radius:4px;background:white;min-width:230px}input{flex:1}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:26px}.ref{border:1px solid var(--line);background:white;border-radius:5px;overflow:hidden}.ref header,.notebody{padding:20px}.ref header span{font-size:13px;color:#5b646b}.ref img{display:block;width:100%;height:400px;object-fit:contain;background:#f0f0ee}.notebody{font-size:16px}.notebody p{margin-top:0}.countlabel{font-size:14px;color:#56616a}.comparison{display:grid;grid-template-columns:1fr 1fr;gap:20px}.comparison img{display:block;width:100%;background:white}#catalogue-list{columns:2;list-style:none;padding:0;font-size:14px}#catalogue-list li{break-inside:avoid;margin:8px 0}footer{margin-top:50px;padding-top:20px;border-top:1px solid var(--line);font-size:14px}.empty{padding:25px;background:#ecefe8}details{margin:20px 0}summary{cursor:pointer;font-weight:600}@media(max-width:850px){main{padding:22px 16px}.grid,.comparison{grid-template-columns:1fr}.ref img{height:auto}#catalogue-list{columns:1}.counts{gap:20px}}[hidden]{display:none!important}
    </style><main><header><p class="eyebrow">Soulmonsters · pesquisa de personagem · 30 outubro 2026</p><h1>O conceito vem antes da prancha.</h1><p class="intro">Estudo do acervo indicado pelo usuário: o que torna um personagem específico, como preservar nosso mangá 2D e por que Zuric V1 ainda ficou genérico.</p><div class="counts"><div><strong>725</strong><span>arquivos únicos indexados</span></div><div><strong>15</strong><span>subcategorias percorridas</span></div><div><strong>48</strong><span>pranchas inspecionadas</span></div><div><strong>8</strong><span>originais também ampliados</span></div></div><nav><a href="#study">Estudo completo</a><a href="#gallery">48 fichas visuais</a><a href="#comparison">Kael × Zuric V1</a><a href="#catalogue">Índice completo</a><a href="ESTUDO.md">Markdown</a></nav><p class="countlabel">Índice completo não significa análise individual das 725 imagens. As 48 pranchas examinadas estão identificadas, com fontes e limites.</p></header>
    <section id="comparison"><h2>Acabamento compartilhado, identidade própria.</h2><p>A referência do Kael define o desenho. Zuric precisa de decisões próprias de corpo, cabeça e comportamento.</p><div class="comparison"><figure><img src="../../characters/parque-pipeiros-v3/references/kael-estilo.png" alt="Referência do Kael escolhida pelo usuário"><figcaption>Kael · referência de tratamento mangá 2D.</figcaption></figure><figure><img src="../../characters/zuric-v1/zuric-e-motoca-sheet.png" alt="Zuric V1, considerado genérico pelo usuário"><figcaption>Zuric V1 · versão criticada, mantida para comparação.</figcaption></figure></div></section>
    <section id="study" class="study">'''+study+'''</section><section id="gallery"><h2>48 fichas de leitura visual</h2><p>Abra uma imagem para consultar a resolução original. As notas distinguem observação e proposta para nosso jogo.</p><div class="filters"><input id="reference-search" type="search" placeholder="Buscar pessoa, tema ou observação" aria-label="Buscar referências"><select id="tag" aria-label="Filtrar tema"><option value="">Todos os temas</option>'''+''.join(f'<option>{esc(tag)}</option>' for tag in sorted({n['tag'] for n in notes}))+'''</select></div><p class="countlabel" id="ref-count" aria-live="polite">48 referências</p><p id="empty" class="empty" hidden>Nenhuma referência para esse filtro.</p><div class="grid">'''+''.join(cards)+'''</div></section><section id="catalogue"><h2>Catálogo completo · 725 arquivos únicos</h2><p>602 arquivos na categoria principal. A união com as 15 subcategorias acrescenta referências; arquivos repetidos entram uma vez. Os números de cada subcategoria não devem ser somados para obter arquivos únicos.</p><details><summary>Subcategorias e quantidades</summary><table><thead><tr><th>Família</th><th>Arquivos na listagem</th></tr></thead><tbody>'''+categories+'''</tbody></table></details><input id="file-search" type="search" placeholder="Buscar no índice completo" aria-label="Buscar no catálogo"><p id="file-count" class="countlabel" aria-live="polite">725 arquivos</p><ul id="catalogue-list">'''+indexed+'''</ul></section><footer>Pesquisa e interpretações para Soulmonsters. As artes Pokémon pertencem a seus respectivos titulares; páginas de origem preservadas em cada ficha. Referências fora do runtime. Consulta não estabelece autoria individual, canon ou aprovação do nosso elenco. <a href="reference-sources.json">Fontes, dimensões e hashes</a> · <a href="catalogue.json">Índice em JSON</a></footer></main><script>
    const norm=s=>s.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase();const cards=[...document.querySelectorAll('.ref')];const search=document.getElementById('reference-search');const tag=document.getElementById('tag');function filter(){let count=0;for(const c of cards){const term=norm(search.value);const content=norm(c.dataset.search);const ok=content.includes(term)&&(!tag.value||content.includes(norm(tag.value)));c.hidden=!ok;if(ok)count++}document.getElementById('ref-count').textContent=count+' referências';document.getElementById('empty').hidden=count>0}search.addEventListener('input',filter);tag.addEventListener('change',filter);const files=[...document.querySelectorAll('[data-file-search]')];document.getElementById('file-search').addEventListener('input',e=>{let count=0;for(const f of files){f.hidden=!norm(f.dataset.fileSearch).includes(norm(e.target.value));if(!f.hidden)count++}document.getElementById('file-count').textContent=count+' arquivos'});
    </script></html>'''
    (ROOT/'index.html').write_text(document,encoding='utf-8')
    print(json.dumps({'references':len(records),'indexed':len(catalogue['files']),'report_bytes':len(document.encode()),'originals_bytes':sum(r['bytes'] for r in records)}))

if __name__=='__main__':
    main()

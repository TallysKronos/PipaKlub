"""Publica o estudo offline. Miniaturas de inspeção preservam os originais."""
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
import json, re, html, hashlib

B=Path(__file__).resolve().parent
R=json.loads((B/'referencias.json').read_text(encoding='utf-8'))
valid=[]
for r in R:
    try:
        with Image.open(B/r['path']) as im:
            im.verify()
        # Excluir logos da navegação e representações repetidas de uma mesma URL.
        lowkey=r['path']=='referencias/toxtricity-4.webp'
        if r['series']=='pokemon' and (r['alt'] in ('','Pokédex') or (r['path'].endswith('.webp') and not lowkey)):continue
        r['inspecao']='Inspeção visual realizada em painel por franquia; originais vinculados na galeria.'
        valid.append(r)
    except Exception: pass
R=valid
(B/'referencias-selecionadas.json').write_text(json.dumps(R,ensure_ascii=False,indent=2),encoding='utf-8')

for series in ['pokemon','digimon','yokai','persona']:
    rows=[r for r in R if r['series']==series]
    cols=3; w,h=420,360
    board=Image.new('RGB',(cols*w,((len(rows)+cols-1)//cols)*h),'#edf1ef');d=ImageDraw.Draw(board)
    for i,r in enumerate(rows):
        x=(i%cols)*w;y=(i//cols)*h
        im=Image.open(B/r['path']).convert('RGBA');im.thumbnail((w-28,h-46))
        board.paste(im,(x+(w-im.width)//2,y+12),im)
        d.text((x+12,y+h-28),r['path'].split('/')[-1],fill='#152738')
    board.save(B/f'inspecao-{series}.jpg',quality=91)

cases=[
 ('pokemon','Rowlet → Dartrix → Decidueye','Premissa que amadurece','Penas, disco facial e verde/bege ligam três arquiteturas. A especialidade de precisão participa do corpo e do gesto.',['rowlet','dartrix','decidueye']),
 ('pokemon','Applin → Flapple / Appletun','Ramificação estrutural','Um tema material produz soluções diferentes de corpo, alimentação e mobilidade.',['applin','flapple','appletun']),
 ('pokemon','Toxel → Toxtricity','Temperamento e atuação','O peito e a postura tornam a música uma atuação da criatura; duas formas adultas não são dois estágios.',['toxel','toxtricity']),
 ('digimon','Veemon / Flamedramon / Lighdramon','Armor e especialização','A configuração pode reorganizar apoio, distribuição de massa e modo de ataque.',['fladramon','lighdramon']),
 ('digimon','Paildramon / Dinobeemon','DNA com hierarquia diferente','Os mesmos participantes produzem ênfases dracônicas e insetoides diferentes. Não basta colar partes.',['paildramon','dinobeemon']),
 ('digimon','Gallantmon × Megidramon','Contraste, sem inferir uma cadeia universal','Proteção controlada e ameaça catastrófica. Perfis não provam caminhos idênticos entre títulos.',['dukemon','megidramon']),
 ('yokai','Jibanyan + Roughraff → Baddinyan','Fusão de personalidades','Um traço focal dominante comunica atitude. O comportamento pode organizar a transformação.',['yokai-nintendo:1','yokai-nintendo:2']),
 ('yokai','Chansin + lâmina → Sheen','Síntese com objeto','O material deve transformar a atuação, não somente ocupar uma mão.',['yokai-nintendo:3']),
 ('yokai','Komasan / Komane','Maturidade com parentesco','Presença e atitude mudam, mas a leitura de família sobrevive. Recorte: primeiro jogo.',['yokai-nintendo:4']),
 ('persona','Captain Kidd / William','Releitura moderna','O instrumento central de atuação muda. Comparação inicial/terceira forma, não dois estágios consecutivos.',['persona-ryuji']),
 ('persona','Johanna / Agnes','Corpo como função','A criatura inteira pode encarnar uma ideia; sem tratar despertar como crescimento biológico.',['persona-makoto']),
 ('persona','Zorro / Diego','Continuidade de uma aspiração','A transformação preserva uma ambição de elegância e confiança.',['persona-morgana']),
]

def selected(ids):
    out=[]
    for id in ids:
        if ':' in id:
            k,num=id.split(':');out.extend(r for r in R if r['id']==k and r['path'].split('-')[-1].split('.')[0]==num)
        else:out.extend(r for r in R if r['id']==id)
    return out
def esc(s):return html.escape(s,quote=True)
cards=[]
for i,(series,title,kind,note,ids) in enumerate(cases):
    imgs=selected(ids)
    assert imgs, title
    figs=''.join(f'<figure><a href="{esc(r["path"])}"><img loading="lazy" src="{esc(r["path"])}" alt="{esc(r["alt"] or r["id"])}"></a><figcaption><a href="{esc(r["page"])}">Fonte da imagem · {esc(r["id"])}</a></figcaption></figure>' for r in imgs)
    cards.append(f'<section class="case {series}" data-series="{series}" id="caso-{i+1}"><small>{series.upper()} · {esc(kind)}</small><h2>{esc(title)}</h2><div class="images">{figs}</div><p>{esc(note)}</p></section>')

def inline(s):
    s=esc(s)
    s=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',r'<a href="\2">\1</a>',s)
    s=re.sub(r'\*\*(.*?)\*\*',r'<strong>\1</strong>',s)
    return s
def markdown(s):
    lines=s.splitlines();out=[];i=0;in_list=False
    while i<len(lines):
        l=lines[i]
        if l.startswith('|'):
            if in_list:out.append('</ul>');in_list=False
            table=[]
            while i<len(lines) and lines[i].startswith('|'):
                table.append([v.strip() for v in lines[i].strip('|').split('|')]);i+=1
            out.append('<div class="table-wrap"><table>')
            for j,row in enumerate(table):
                if all(re.match(r'^:?-+:?$',v) for v in row):continue
                tag='th' if j==0 else 'td';out.append('<tr>'+''.join(f'<{tag}>{inline(v)}</{tag}>' for v in row)+'</tr>')
            out.append('</table></div>');continue
        if l.startswith('- '):
            if not in_list:out.append('<ul>');in_list=True
            out.append('<li>'+inline(l[2:])+'</li>')
        else:
            if in_list:out.append('</ul>');in_list=False
            if l.startswith('#'):
                n=len(l)-len(l.lstrip('#'));out.append(f'<h{n}>{inline(l[n:].strip())}</h{n}>')
            elif l.strip():out.append('<p>'+inline(l)+'</p>')
        i+=1
    if in_list:out.append('</ul>')
    return '\n'.join(out)

style='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f3efe6;color:#142b3c;font:17px/1.65 system-ui,sans-serif}header,main,footer{max-width:1420px;margin:auto;padding:38px clamp(20px,4vw,64px)}header{border-bottom:3px solid #142b3c}h1{font-size:clamp(30px,4.4vw,66px);line-height:1.08;letter-spacing:-.04em;max-width:950px}h2{line-height:1.25}a{color:#075d7b;text-underline-offset:3px}a:focus-visible,select:focus-visible{outline:3px solid #b12c57;outline-offset:4px}nav{display:flex;flex-wrap:wrap;gap:12px 24px}small{font-weight:700;letter-spacing:.09em}label{font-weight:650}select{font:inherit;padding:8px;margin-left:12px;border:2px solid #142b3c;background:#fffdf7}#cases{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:30px}.case{padding:24px;border-top:7px solid #216b83;background:#fffdf7;min-width:0}.digimon{border-color:#9c4527}.yokai{border-color:#56742e}.persona{border-color:#982943}.images{display:flex;flex-wrap:wrap;justify-content:center;gap:12px}.images figure{margin:0;flex:1 1 130px;min-width:0}.images img{display:block;width:100%;height:230px;object-fit:contain;background:#edf1ef}.images figcaption{font-size:12px;line-height:1.5;margin-top:6px}.callout{border-left:6px solid #cd9627;padding:18px 24px;background:#fff9de;margin:30px 0}.reading{max-width:1020px;margin:70px auto}.reading h2{margin-top:60px;border-top:1px solid #b8b4aa;padding-top:24px}.reading h3{margin-top:36px}.reading p{max-width:85ch}.table-wrap{overflow:auto}table{border-collapse:collapse;width:100%;font-size:15px}th,td{text-align:left;vertical-align:top;border-bottom:1px solid #ccc5b8;padding:14px;min-width:140px}th{background:#e4dfd4}.own{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:20px}.own figure{margin:0}.own img{width:100%;height:auto}.own figcaption{font-size:14px}[hidden]{display:none!important}footer{border-top:2px solid #142b3c;font-size:14px}@media(max-width:850px){#cases,.own{grid-template-columns:1fr}.images img{height:190px}}@media(prefers-reduced-motion:reduce){html{scroll-behavior:auto}}'''
article=markdown((B/'ANALISE.md').read_text(encoding='utf-8'))
own=[]
for id,name in [('azultor','Azultor A · estrutura escolhida; especialidade por desenvolver'),('azulaculo','Azuláculo · proposta criticada; função ainda abstrata')]:
    src=f'../../../art/creatures/azulao-family-v1/{id}/prancha-manga-v1/prancha.png'
    assert (B/src).is_file()
    own.append(f'<figure><a href="{src}"><img src="{src}" alt="{esc(name)}" loading="lazy"></a><figcaption>{esc(name)}</figcaption></figure>')
page=f'''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Design evolutivo · estudo Soulmonsters</title><style>{style}</style><header><small>SOULMONSTERS · PESQUISA DE DIREÇÃO · 03.11.2026</small><h1>O corpo muda.<br>O que ele passa a fazer?</h1><p>12 estudos de Pokémon, Digimon, Yo-kai Watch e Persona, com crítica das evoluções do Azulão.</p><nav><a href="#comparacoes">Comparações visuais</a><a href="#nosso-lote">Nosso lote</a><a href="#analise">Estudo completo</a><a href="ANALISE.md">Documento Markdown</a><a href="referencias-selecionadas.json">Proveniência</a></nav></header><main><aside class="callout">Conclusão de direção: atributos organizam a rota; comportamento, anatomia e personalidade precisam tornar a especialidade visível. As fontes documentam os exemplos. As recomendações para o nosso jogo são propostas.</aside><section id="comparacoes"><h2>Comparações visuais</h2><p><label for="series">Mostrar<select id="series"><option value="all">Todas as franquias</option><option value="pokemon">Pokémon</option><option value="digimon">Digimon</option><option value="yokai">Yo-kai Watch</option><option value="persona">Persona</option></select></label> <span id="count" aria-live="polite">12 estudos</span></p><div id="cases">{''.join(cards)}</div></section><section id="nosso-lote"><h2>Onde nosso lote precisa evoluir</h2><p>As imagens anteriores são preservadas. A escolha de Azultor A não aprova automaticamente acabamento, poderes ou as outras formas.</p><div class="own">{''.join(own)}</div></section><article id="analise" class="reading">{article}</article></main><footer>Ilustrações externas de seus respectivos titulares, reunidas para análise com origem identificada. Não são assets de jogo nem inputs de geração. Sem alteração de código do jogo. Validação local de arquivos e estrutura; não houve auditoria visual do HTML em navegador.</footer><script>const select=document.getElementById('series');select.addEventListener('change',()=>{{let n=0;document.querySelectorAll('[data-series]').forEach(card=>{{card.hidden=select.value!=='all'&&card.dataset.series!==select.value;if(!card.hidden)n++;}});document.getElementById('count').textContent=n+' estudos';}});</script></html>'''
(B/'index.html').write_text(page,encoding='utf-8')
assert len(cases)==12
for r in R:assert hashlib.sha256((B/r['path']).read_bytes()).hexdigest()==r['sha256']
print(json.dumps({'casos':len(cases),'imagens_selecionadas':len(R),'franquias':sorted(set(r['series'] for r in R)),'fontes_e_hashes_validos':True},ensure_ascii=False))

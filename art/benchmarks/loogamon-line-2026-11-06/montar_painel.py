"""Monta documentação visual de estudo; não gera nem pinta concepts."""
from pathlib import Path
import hashlib
import html
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
DATA = [
    ('fusamon', 'Fusamon', 'Baby I', 'Massa de repouso, curvas macias, poucos tufos. A expressão sustenta a simplicidade.'),
    ('bowmon', 'Bowmon', 'In-Training II', 'Primeiros apoios e exploração. Pés escuros separam corpo e chão.'),
    ('loogamon', 'Loogamon', 'Rookie', 'Mandíbula atuante, peito agrupado e patas de filhote com capacidade própria.'),
    ('loogarmon', 'Loogarmon', 'Champion', 'Vetor de avanço e contraste nos membros. Perspectiva não é proporção ortográfica.'),
    ('soloogarmon', 'Soloogarmon', 'Ultimate · controle', 'Arquitetura bípede. Proteção e energia reorganizam a ação.'),
    ('helloogarmon', 'Helloogarmon', 'Ultimate · excesso', 'Mesmo nível, outra condição. Contorno instável e mãos escuras enormes.'),
    ('fenriloogamon', 'Fenriloogamon', 'Mega', 'Besta e proteção coexistem. A pose baixa não prova locomoção exclusivamente quadrúpede.'),
    ('fenriloogamon_takemikazuchi', 'Fenriloogamon: Takemikazuchi', 'Mega · combinação', 'Arma e energia mudam gesto e silhueta; preservar a criatura principal.'),
    ('kazuchimon', 'Kazuchimon', 'Mega · contraparte', 'Comparação de função e acento cromático. Não é ancestral de Loogamon.'),
]


def profile(slug):
    lang = 'reference' if slug == 'fusamon' else 'reference_en'
    return f'https://digimon.net/{lang}/detail.php?directory_name={slug}'


def run():
    sources = []
    for slug, name, stage, note in DATA:
        file = ROOT / 'referencias' / f'{slug}.jpg'
        with Image.open(file) as im:
            size = list(im.size)
        sources.append(dict(id=slug, title=name, stage=stage, profile=profile(slug),
            image_url=f'https://digimon.net/cimages/digimon/{slug}.jpg',
            local=f'referencias/{slug}.jpg', dimensions=size,
            sha256=hashlib.sha256(file.read_bytes()).hexdigest(),
            consulted='2026-11-06', kind='official-encyclopedia', visually_inspected=True))
    for code in ['BT20-080', 'BT20-081']:
        file = ROOT / 'referencias' / f'{code}.png'
        with Image.open(file) as im:
            size = list(im.size)
        sources.append(dict(id=code, title=code, profile=f'https://world.digimoncard.com/cards/?card_no={code}&search=true',
            image_url=f'https://world.digimoncard.com/images/cardlist/card/{code}.png',
            local=f'referencias/{code}.png', dimensions=size,
            sha256=hashlib.sha256(file.read_bytes()).hexdigest(),
            consulted='2026-11-06', kind='official-card', visually_inspected=True))
    meta = dict(scope='8 formas da família + Kazuchimon de apoio; 2 cartas em outros enquadramentos',
        limitations=['Estudo estático; sem medição de marcha ou rig.', 'Enciclopédia 320×320; cartas 868×1213.',
            'Romance Seekers não lido por inteiro.', 'Fusamon em inglês redirecionou para manutenção; usada página japonesa.',
            'Não é árvore universal de evolução de todos os produtos.'],
        rights='Artes externas dos respectivos titulares. Referências de estudo, não assets de jogo ou inputs de geração.',
        sources=sources,
        contextual_sources=[
            'https://digimon.net/digimonseekers/',
            'https://world.digimoncard.com/cards/?card_no=BT20-064&search=true',
            'https://world.digimoncard.com/cards/?card_no=BT20-070&search=true',
            'https://world.digimoncard.com/cards/?category=522027&search=true',
            'https://world.digimoncard.com/products/pack/ver14/special/'],
        navigation_only=['https://wikimon.net/Fenriloogamon:_Takemikazuchi'],
        network_notes=['As imagens das duas cartas falharam no cache web; download direto oficial foi bem-sucedido.'])
    (ROOT / 'fontes.json').write_text(json.dumps(meta, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

    # Contato em resolução nativa das ilustrações; legenda fora da arte.
    board = Image.new('RGB', (1080, 1290), '#f2eee4')
    d = ImageDraw.Draw(board)
    font_path = Path('C:/Windows/Fonts/arial.ttf')
    font = ImageFont.truetype(str(font_path), 18) if font_path.exists() else ImageFont.load_default()
    small = ImageFont.truetype(str(font_path), 14) if font_path.exists() else ImageFont.load_default()
    for i, (slug, name, stage, _) in enumerate(DATA):
        x, y = (i % 3)*360+20, (i // 3)*420+12
        board.paste(Image.open(ROOT/'referencias'/f'{slug}.jpg').convert('RGB'), (x, y))
        label = name.replace(': ', ':\n')
        d.multiline_text((x, y+326), label, font=font, fill='#142a37')
        d.text((x, y+374), stage, font=small, fill='#4c5460')
    d.text((20, 1264), 'Digimon · artes oficiais 320x320 · estudo estático · não usar como input de geração', font=small, fill='#4c5460')
    board.save(ROOT/'prancha-comparativa.jpg', quality=95)

    cards = ''.join(f'''<article class="stage" data-slug="{slug}"><a href="referencias/{slug}.jpg"><img width="320" height="320" src="referencias/{slug}.jpg" alt="Ilustração oficial de {html.escape(name)}"></a><div class="copy"><small>{html.escape(stage)}</small><h3>{html.escape(name)}</h3><p>{html.escape(note)}</p><a href="{profile(slug)}">Perfil oficial ↗</a></div></article>''' for slug,name,stage,note in DATA)
    own = [
        ('lince-de-cerco', 'Lince de cerco', 'Arcos e linha têm intenção; corpo e face precisam receber a tração. Preservar a arquitetura aprovada.'),
        ('tamandua-tear', 'Tamanduá-tear', 'Equipamento e cauda dominam. Demonstrar peso, apoio e operação pelo corpo vivo.'),
        ('ibex-astrolabio', 'Íbex-astrolábio', 'Ornamento regular domina. Pescoço, orelhas e apoios podem trazer comportamento sem mais círculos.'),
    ]
    own_cards=''.join(f'''<article class="own"><a href="../../creatures/{slug}/concept-v1/concept.png"><img src="../../creatures/{slug}/concept-v1/concept.png" alt="Concept próprio: {name}"></a><div class="copy"><h3>{name}</h3><p>{note}</p></div></article>''' for slug,name,note in own)
    options=''.join(f'<option value="{slug}">{html.escape(name)}</option>' for slug,name,_,_ in DATA)
    page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Loogamon · estudo de corpo vivo</title>
<style>
:root{color-scheme:light;--ink:#142a37;--paper:#f5f1e8;--muted:#53616a;--line:#d5cec0;--accent:#9c3925}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.6 system-ui,sans-serif}header,main,footer{max-width:1240px;margin:auto;padding:32px}header{padding-top:64px;border-bottom:1px solid var(--line)}h1{font-size:clamp(36px,6vw,70px);line-height:1.05;margin:16px 0;max-width:950px}h2{font-size:30px;line-height:1.2;margin-top:0}h3{font-size:21px;line-height:1.25;margin:6px 0 12px}p{margin:0 0 16px}small,.eyebrow{color:var(--muted);font-size:13px;letter-spacing:.04em}.lead{max-width:830px;font-size:21px}a{color:var(--accent);text-underline-offset:4px}nav{display:flex;gap:18px;flex-wrap:wrap;margin:24px 0}section{padding:36px 0;border-bottom:1px solid var(--line)}.note{padding:18px 22px;border-left:4px solid var(--accent);background:#eae4d8;max-width:1000px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(285px,1fr));gap:24px}.stage,.own,.compare{background:#fff;border:1px solid var(--line);min-width:0}.stage img{display:block;max-width:100%;object-fit:contain;margin:auto;transition:filter .15s}.copy{padding:22px}.own img{width:100%;height:310px;object-fit:contain;background:#e6e5df}.toolbar{display:flex;gap:16px;align-items:center;flex-wrap:wrap;margin:20px 0}button,select{font:inherit;padding:10px 14px;background:white;color:var(--ink);border:1px solid #63727b;border-radius:3px;max-width:100%}button{cursor:pointer}button:focus-visible,select:focus-visible,a:focus-visible{outline:3px solid #c5682d;outline-offset:4px}.compact .stage img{width:96px;height:96px;margin:30px auto}.mono img{filter:grayscale(1)}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.compare img{width:100%;max-width:480px;display:block;margin:auto}.compare figcaption{padding:16px 24px}.cards .compare img{max-width:434px}.checks{display:grid;grid-template-columns:repeat(auto-fit,minmax(245px,1fr));gap:20px}.check{border-top:3px solid var(--ink);padding-top:16px}.check strong{display:block}footer{font-size:14px;color:var(--muted)}@media(max-width:650px){header,main,footer{padding:24px}.pair{grid-template-columns:1fr}.grid{grid-template-columns:1fr}.lead{font-size:19px}}@media(prefers-reduced-motion:reduce){*{transition:none!important}}
</style>
<header><div class="eyebrow">SOULMONSTERS / BENCHMARK 06.11.2026</div><h1>Construção limpa.<br>Uma criatura viva.</h1><p class="lead">A família Loogamon como estudo de massa, rosto, matéria e amadurecimento. Como enriquecer nossos quadrúpedes sem sujar o 2D mangá.</p><nav><a href="#familia">Família</a><a href="#comparar">Comparar formas</a><a href="#face">Face adulta</a><a href="#nossos">Nossos desenhos</a><a href="ANALISE.md">Estudo completo</a><a href="DIRETRIZES-QUADRUPEDES.md">Diretrizes</a></nav><p class="note">8 formas da família + Kazuchimon de apoio. Nem todas são quadrúpedes. Níveis, ramos e poses não são equivalentes a uma árvore universal de evolução. Artes externas são estudo, nunca inputs de geração.</p></header>
<main><section><h2>O que estava faltando</h2><div class="checks"><div class="check"><strong>Forma intermediária</strong>Bochecha, gola, escápula e punho ligam a massa grande ao detalhe pequeno.</div><div class="check"><strong>Atuação corporal</strong>Mandíbula, apoio, compressão e direção do olhar dão intenção além do equipamento.</div><div class="check"><strong>Matéria em estados diferentes</strong>Papel tensiona, pelo agrupa, proteção sobrepõe. Não usar o mesmo contorno em tudo.</div><div class="check"><strong>Evolução funcional</strong>Capacidade, arquitetura e autocontrole mudam. Tamanho e acessórios sozinhos não bastam.</div></div></section>
<section id="familia"><h2>Uma família, arquiteturas diferentes</h2><p>Perfis e artes oficiais inspecionados. A grade agrupa fases para estudo; não representa setas de evolução.</p><div class="toolbar"><button id="size" aria-pressed="false">Ver miniaturas de 96 px</button><button id="value" aria-pressed="false">Comparar valores sem cor</button><a href="prancha-comparativa.jpg">Prancha de contato</a></div><div class="grid" id="gallery">__CARDS__</div></section>
<section id="comparar"><h2>O que mudou entre as formas?</h2><p>Observe massa do peito, raiz do focinho, antebraço, material e direção da cauda. Não compare tamanho absoluto: a escala editorial das imagens é diferente.</p><div class="toolbar"><label>Forma 1 <select id="left">__OPTIONS__</select></label><label>Forma 2 <select id="right">__OPTIONS__</select></label></div><div class="pair"><figure class="compare"><img id="left-img" alt=""><figcaption id="left-caption"></figcaption></figure><figure class="compare"><img id="right-img" alt=""><figcaption id="right-caption"></figcaption></figure></div><p class="note">Soloogarmon e Helloogarmon são Ultimate: contenção e excesso no mesmo nível. Fenriloogamon tem leitura bestial e anatomia híbrida; uma pose baixa não prova marcha exclusivamente quadrúpede.</p></section>
<section id="face"><h2>Face adulta em outro enquadramento</h2><p>As duas cartas ajudam a ler a raiz do focinho, a mandíbula e a proteção. Seu acabamento pintado não é o novo acabamento de Soulmonsters. Abra para inspecionar na resolução original.</p><div class="pair cards"><figure class="compare"><a href="referencias/BT20-080.png"><img src="referencias/BT20-080.png" alt="Carta oficial BT20-080 de Fenriloogamon"></a><figcaption>Testa → órbita → focinho → mandíbula. <a href="https://world.digimoncard.com/cards/?card_no=BT20-080&search=true">Fonte oficial</a></figcaption></figure><figure class="compare"><a href="referencias/BT20-081.png"><img src="referencias/BT20-081.png" alt="Carta oficial BT20-081 de Fenriloogamon Takemikazuchi"></a><figcaption>Pega na boca, dentes e cabo: função exige encaixe. <a href="https://world.digimoncard.com/cards/?card_no=BT20-081&search=true">Fonte oficial</a></figcaption></figure></div></section>
<section id="nossos"><h2>Onde nossos desenhos ficaram secos</h2><p>Diagnóstico de construção, sem substituir as aprovações existentes. Não precisamos enfeitar mais: precisamos fazer o corpo participar.</p><div class="grid">__OWN__</div></section>
<section><h2>Aplicar com autoria</h2><p>45% criatura · 45% pipa viva · 10% pixel / 2D mangá. São pesos de direção, não contagem de área. Preservar cor e sombra em blocos; acrescentar sobreposição, tensão e atuação.</p><p><a href="DIRETRIZES-QUADRUPEDES.md">Abrir o protocolo do próximo concept</a> · <a href="ANALISE.md">Ler a análise detalhada</a> · <a href="fontes.json">Fontes, dimensões e hashes</a></p></section></main>
<footer>Referências Digimon dos respectivos titulares. Imagens da enciclopédia: 320×320; cartas: 868×1213. Nenhum detalhe novo é criado por ampliação. Estudo estático, sem validação de marcha, rig ou animação. O romance completo não foi lido. Página offline, sem dependências de rede.</footer>
<script>const rows=__DATA__;const data=Object.fromEntries(rows.map(r=>[r[0],r]));function pair(id){const slug=document.getElementById(id).value,r=data[slug];const img=document.getElementById(id+'-img');img.src='referencias/'+slug+'.jpg';img.alt='Arte oficial de '+r[1];document.getElementById(id+'-caption').textContent=r[1]+' · '+r[2]+' — '+r[3]}for(const id of ['left','right'])document.getElementById(id).addEventListener('change',()=>pair(id));document.getElementById('left').value='loogamon';document.getElementById('right').value='loogarmon';pair('left');pair('right');document.getElementById('size').onclick=function(){const on=document.getElementById('gallery').classList.toggle('compact');this.setAttribute('aria-pressed',on);this.textContent=on?'Voltar à imagem de 320 px':'Ver miniaturas de 96 px'};document.getElementById('value').onclick=function(){const on=document.querySelector('main').classList.toggle('mono');this.setAttribute('aria-pressed',on);this.textContent=on?'Restaurar cores':'Comparar valores sem cor'};</script></html>'''
    for key,value in [('__CARDS__',cards),('__OWN__',own_cards),('__OPTIONS__',options),('__DATA__',json.dumps(DATA,ensure_ascii=False))]:
        page=page.replace(key,value)
    (ROOT/'index.html').write_text(page,encoding='utf-8')
    print(f'Painel montado: {len(DATA)} perfis, 2 cartas, 3 concepts próprios.')


if __name__ == '__main__':
    run()

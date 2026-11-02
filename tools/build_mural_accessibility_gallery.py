"""Verify PIP-138 native evidence and create a local review gallery."""
from pathlib import Path
import json
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'documentation/hud-v2/pip-138'
cards=[]
for resolution in ['1280x720','1920x1080','1024x768','1280x800']:
    dimensions=tuple(map(int,resolution.split('x')))
    for scale in ['', '-150']:
        for mode in ['settings-top','settings-bottom','dialogue-focus','boss-contrast','versus']:
            name=f'{resolution}-{mode}{scale}.png'
            with Image.open(OUT/'capturas'/name) as im:
                assert im.size==dimensions, name
            title=f'{resolution} · {mode} · {150 if scale else 100}%'
            cards.append(f'<figure data-resolution="{resolution}"><a href="capturas/{name}"><img loading="lazy" src="capturas/{name}"></a><figcaption>{title}</figcaption></figure>')
    evidence=json.loads((OUT/f'padding-{resolution}.json').read_text(encoding='utf-8'))
    assert not evidence['failures'], evidence
contrast=json.loads((OUT/'contraste.json').read_text(encoding='utf-8'))
assert not contrast['failures'], contrast
(OUT/'index.html').write_text('''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>PIP-138 · Acessibilidade</title>
<style>body{background:#0c2530;color:#fff1d2;margin:32px;font:18px system-ui}a{color:#77d0bc}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(380px,1fr));gap:20px}img{width:100%}figure{margin:0}figcaption{padding:12px}select{font:inherit;padding:10px}</style>
<h1>PIP-138 · Leitura, foco e movimento</h1><p>150% disponível e persistido; rótulos completos nas configurações; indicação de foco com forma; dano estático por 800 ms no modo reduzido; apresentações com texto ampliado e botão de pular dentro da margem.</p>
<p>40 capturas nativas · quatro resoluções · texto 100/150%. As configurações cabem sem rolagem vertical em alguns tamanhos, por isso topo e rodapé podem ser iguais.</p>
<p><a href="REVISAO.md">Relatório e limites</a> · <a href="contraste.json">20 medições de contraste</a> · <a href="testes.json">Testes novos</a></p>
<label>Resolução <select onchange="document.querySelectorAll('figure').forEach(f=>f.hidden=this.value!=='all'&&f.dataset.resolution!==this.value)"><option value="all">Todas</option><option>1280x720</option><option>1920x1080</option><option>1024x768</option><option>1280x800</option></select></label><main>''' + ''.join(cards)+'</main></html>',encoding='utf-8')
print(f'PIP138 gallery: {len(cards)} verified native captures; contrast passed')

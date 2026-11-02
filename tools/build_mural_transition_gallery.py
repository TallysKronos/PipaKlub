"""Verify native captures and build the local PIP-137 review gallery."""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'documentation/hud-v2/pip-137'
cards = []
for resolution in ['1280x720', '1920x1080', '1024x768', '1280x800']:
    expected = tuple(map(int, resolution.split('x')))
    for scale in ['', '-150']:
        for state in ['loading', 'reveal', 'reduced']:
            name = f'{resolution}-{state}{scale}.png'
            with Image.open(OUT / 'capturas' / name) as picture:
                assert picture.size == expected, name
            caption = f'{resolution} · {state} · texto {150 if scale else 100}%'
            cards.append(f'<figure><a href="capturas/{name}"><img loading="lazy" src="capturas/{name}"></a><figcaption>{caption}</figcaption></figure>')
catalog = json.loads((ROOT / 'godot/assets/audio/sfx-v1/catalog.json').read_text(encoding='utf-8'))
audio = []
for event in catalog['events']:
    if event['id'] in ['world.transition', 'ui.focus', 'ui.confirm', 'ui.cancel', 'progress.level_up', 'progress.save_error']:
        source = event['files'][0]['path'].replace('res://', '../../../godot/')
        audio.append(f'<p>{event["id"]}<br><audio controls preload="none" src="{source}"></audio></p>')
(OUT / 'index.html').write_text('''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>PIP-137 · Transições e sons</title>
<style>body{background:#0c2530;color:#fff1d2;font:18px system-ui;margin:32px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(340px,1fr));gap:16px}figure{margin:0}img{width:100%}figcaption{padding:12px}a{color:#77d0bc}audio{width:300px}</style>
<h1>PIP-137 · Caminhos de Kronasta</h1><p>Cortina de tinta e papel; pipa no canto inferior direito. A abertura aguarda o primeiro frame do mapa. Movimento reduzido usa fade, com indicador estático.</p>
<p>24 capturas nativas; quatro resoluções, texto 100/150%. “Reveal” é uma fase congelada; o fundo verde serve para conferir a saída do recorte.</p>
<details><summary>Sons existentes reutilizados · ouvir amostras</summary>''' + ''.join(audio) + '''<p>Amostras isoladas, sem os volumes do mixer do jogo. O som de viagem usa UI a −5 dB; recompensas simultâneas priorizam o marco principal.</p></details>
<p><a href="REVISAO.md">Relatório e limites</a> · <a href="testes.json">Verificações</a></p><main>''' + ''.join(cards) + '</main></html>', encoding='utf-8')
print(f'Gallery: {len(cards)} verified captures')

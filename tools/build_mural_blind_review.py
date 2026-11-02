"""Build ten unbranded real-screen references for an external human review."""
from pathlib import Path
import json, shutil, hashlib
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'documentation/hud-v2/pip-139/teste-cego'
OUT.mkdir(parents=True,exist_ok=True)
review_path=OUT.parent/'blind-review-key.json'
if review_path.exists() and json.loads(review_path.read_text(encoding='utf-8')).get('responses'):
    print('Existing reviewed set and responses preserved. Create a new review version before replacing it.')
    raise SystemExit(0)
sources=['live','pause','team','dex','evolution','bag','identity','emblems','workshop','kronasta']
cards=[];key=[]
for index,source in enumerate(sources,1):
    filename=f'{index:02}.png'
    origin=OUT.parent/'capturas/100'/f'{source}.png'
    assert origin.exists(), origin
    shutil.copyfile(origin,OUT/filename)
    key.append({'number':index,'source':str(origin.relative_to(ROOT)),'sha256':hashlib.sha256(origin.read_bytes()).hexdigest()})
    cards.append(f'<figure><a href="{filename}"><img src="{filename}" loading="lazy"></a><figcaption>Tela {index:02}</figcaption></figure>')
(OUT/'index.html').write_text('''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Revisão visual · 10 telas</title><style>body{background:#171b20;color:#eee;font:18px system-ui;margin:32px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(420px,1fr));gap:24px}figure{margin:0}img{width:100%}figcaption{padding:12px}</style>
<h1>Revisão visual</h1><p>Sem consultar o nome do projeto: estas telas parecem pertencer ao mesmo jogo? Quais destoam? Que elementos fizeram você agrupá-las?</p><p>Registre também se já conhecia o projeto. Não há resposta certa predefinida: queremos as associações espontâneas.</p><main>''' + ''.join(cards) + '</main>',encoding='utf-8')
(OUT.parent/'blind-review-key.json').write_text(json.dumps({'status':'awaiting-external-human','responses':[],'screens':key},indent=2),encoding='utf-8')
print('Ten-screen unbranded review ready.')

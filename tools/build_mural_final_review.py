"""Verify final audit evidence, source links and build the review entry point."""
from pathlib import Path
import json,re,hashlib,html
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'documentation/hud-v2/pip-139'
data=json.loads((OUT/'campaign-audit.json').read_text(encoding='utf-8'))
assert data['fullMatrix'] and len(data['batches'])==16
cards=[];failures=[];native_labels=0;glyphs=0;hashes=[]
for batch in sorted(data['batches'],key=lambda b:b['batch']):
    size,scale,group=batch['batch'].split('-')
    if batch['exitCode']!=0 or batch['scriptError'] or batch['nativeFindings']:
        failures.append(batch['batch'])
    assert len({i['shot'] for i in batch['images']})==len(batch['images'])
    summaries={}
    paths=[OUT/'logs'/f'{batch["batch"]}.log']
    latest=OUT/batch.get('latestLog',f'logs/{batch["batch"]}.log')
    if latest not in paths:paths.append(latest)
    for path in paths:
        for line in path.read_text(encoding='utf-8',errors='replace').splitlines():
            match=re.match(r'AUDIT_DONE (\S+) textos=(\d+) problemas=(\d+)',line)
            if match:summaries[match[1]]=int(match[2])
    native_labels+=sum(summaries.values())
    glyphs+=sum(p['glyphs'] for p in batch['paper'])
    if any(p['failures'] for p in batch['paper']):failures.append(batch['batch']+' canvas')
    for entry in sorted(batch['images'],key=lambda e:e['shot']):
        path=OUT/entry['file']
        with Image.open(path) as im:
            if list(im.size)!=entry['expected']:failures.append(entry['file'])
        hashes.append({'file':entry['file'],'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
        caption=f'{entry["shot"]} · {size} · {scale}%'
        cards.append(f'<figure data-size="{size}" data-scale="{scale}" data-shot="{entry["shot"]}"><a href="{entry["file"]}"><img loading="lazy" src="{entry["file"]}" alt="{caption}"></a><figcaption>{caption}</figcaption></figure>')
assert len(cards)==296, len(cards)
link_checks=0
for doc in [ROOT/'HUD-KIT-v2.md',ROOT/'godot/assets/ui/mural-v1/README.md']:
    for target in re.findall(r'\]\(([^)]+)\)',doc.read_text(encoding='utf-8')):
        if '://' in target or target.startswith('#'):continue
        link_checks+=1
        if not (doc.parent/target.split('#')[0]).exists():failures.append(str(doc.relative_to(ROOT))+' -> '+target)
review_status=json.loads((OUT/'blind-review-key.json').read_text(encoding='utf-8'))['status']
review_copy='A revisão humana relatou problemas; o dono solicitou reconstruir todas as telas no Figma.' if review_status=='review-reported-problems' else 'A avaliação externa de identidade continua pendente.'
summary={'images':296,'nativeTextObservations':native_labels,'instrumentedGlyphObservations':glyphs,'localLinkChecks':link_checks,'failures':failures,'campaignIsolated':True,'humanReview':review_status,'physicalController':False,'migrationComplete':False}
(OUT/'integridade.json').write_text(json.dumps({'summary':summary,'images':hashes},ensure_ascii=False,indent=2),encoding='utf-8')
(OUT/'index.html').write_text('''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>HUD-KIT v2 · Auditoria final</title><style>body{background:#0c2530;color:#fff1d2;font:18px system-ui;margin:32px}a{color:#77d0bc}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(400px,1fr));gap:20px}figure{margin:0}img{width:100%}figcaption{padding:10px}select{padding:10px;font:inherit;margin:10px}.status{border-left:5px solid #ffc53e;padding:16px;background:#123442}</style>
<h1>HUD-KIT v2 · Mural de Kronasta</h1><p><a href="../../../HUD-KIT-v2.md">Guia de implementação</a> · <a href="REVISAO.md">Relatório de aceite e limites</a> · <a href="../ABSORCAO-PIP-61.md">17 tarefas antigas e destinos</a> · <a href="integridade.json">Integridade</a></p>
<p class="status">Auditoria técnica local: ''' + str(len(failures)) + ''' falhas nas verificações executadas. 296 capturas em quatro resoluções e texto 100/150%. ''' + review_copy + ''' O épico antigo não foi encerrado e há consumidores de compatibilidade registrados.</p>
<p><a href="teste-cego/index.html">Abrir as dez telas sem logo para uma pessoa externa</a></p><label>Resolução <select id="size"><option value="all">Todas</option><option>1280x720</option><option>1920x1080</option><option>1024x768</option><option>1280x800</option></select></label><label>Texto <select id="scale"><option value="all">Ambos</option><option value="100">100%</option><option value="150">150%</option></select></label><main>''' + ''.join(cards) + '''</main><script>for(const select of document.querySelectorAll('select'))select.onchange=()=>document.querySelectorAll('figure').forEach(f=>f.hidden=(size.value!=='all'&&f.dataset.size!==size.value)||(scale.value!=='all'&&f.dataset.scale!==scale.value));</script></html>''',encoding='utf-8')
print(json.dumps(summary,ensure_ascii=False))
raise SystemExit(bool(failures))

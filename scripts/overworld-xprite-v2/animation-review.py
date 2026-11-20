"""Batch QA, GIFs and a browser-native animation gallery; never alters sprite pixels."""
from pathlib import Path
from PIL import Image, ImageDraw
import json, argparse, html, shutil, hashlib
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/creatures/soulmonsters-overworld-v2'
OUT=ROOT/'art/creatures/overworld-animacoes-v1'
args=argparse.ArgumentParser();args.add_argument('--publish',action='store_true');args=args.parse_args()
roster=json.loads((OUT/'anatomias.json').read_text(encoding='utf-8'))
report=[]
def components(im):
    left={(x,y) for y in range(112) for x in range(112) if im.getpixel((x,y))[3]}
    groups=[]
    while left:
        todo=[left.pop()];group=[]
        while todo:
            x,y=todo.pop();group.append((x,y))
            for dx,dy in [(1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)]:
                p=x+dx,y+dy
                if p in left:left.remove(p);todo.append(p)
        groups.append(len(group))
    return sorted(groups,reverse=True)
cards=['<article data-kind="bipede"><h3>azulfazo</h3><small>Piloto articulado específico · integrado anteriormente</small><div><figure><img loading="lazy" src="../soulmonsters-overworld-v2/azulfazo/animacoes-v1/idle.gif"><figcaption>Idle · SW / NW</figcaption></figure><figure><img loading="lazy" src="../soulmonsters-overworld-v2/azulfazo/animacoes-v1/walk.gif"><figcaption>Walk · SW / NW</figcaption></figure></div></article>']
for entry in roster:
    id=entry['id'];folder=ART/id/'animacoes-v1'
    if not (folder/'walk.png').exists(): continue
    signature=hashlib.sha256(b'animation-qa-v2'+(ART/id/'duas-vistas.png').read_bytes()+(folder/'idle.png').read_bytes()+(folder/'walk.png').read_bytes()+json.dumps(entry,sort_keys=True).encode()).hexdigest()
    cached=json.loads((folder/'validacao.json').read_text(encoding='utf-8')) if (folder/'validacao.json').exists() else {}
    if cached.get('source_signature')==signature and (folder/'idle.gif').exists() and (folder/'walk.gif').exists():
        report.append(cached)
        cards.append(f'<article data-kind="{entry["anatomy"]}"><h3>{html.escape(id)}</h3><small>{entry["anatomy"]} · {cached["status"]}</small><div><figure><img loading="lazy" src="../soulmonsters-overworld-v2/{id}/animacoes-v1/idle.gif"><figcaption>Idle · SW / NW</figcaption></figure><figure><img loading="lazy" src="../soulmonsters-overworld-v2/{id}/animacoes-v1/walk.gif"><figcaption>Walk · SW / NW</figcaption></figure></div></article>')
        continue
    source=Image.open(ART/id/'duas-vistas.png').convert('RGBA')
    palette={c for c in source.getdata() if c[3]}
    base=[source.crop((v*112,0,(v+1)*112,112)) for v in range(2)]
    basen=[sum(c[3]>0 for c in im.getdata()) for im in base]
    basec=[components(im) for im in base]
    issues=[];max_drift=0;new_small=0;states={}
    for state in ['idle','walk']:
        sheet=Image.open(folder/f'{state}.png').convert('RGBA');frames=[];records=[]
        for f in range(8):
            pair=Image.new('RGBA',(224,112))
            for v in range(2):
                im=sheet.crop((f*112,v*112,(f+1)*112,(v+1)*112));pair.paste(im,(v*112,0))
                cs={c for c in im.getdata() if c[3]};n=sum(c[3]>0 for c in im.getdata());bb=im.getbbox()
                drift=abs(n-basen[v])/basen[v];max_drift=max(max_drift,drift)
                comp=components(im)
                small=max(0,sum(n<5 for n in comp)-sum(n<5 for n in basec[v]));new_small+=small
                if small:issues.append(f'{state}/{v}/{f}: fragmento')
                if cs-palette:issues.append(f'{state}/{v}/{f}: paleta')
                if bb[3]>100:issues.append(f'{state}/{v}/{f}: apoio')
                if drift>.05:issues.append(f'{state}/{v}/{f}: volume {drift:.1%}')
                if sum(n>=5 for n in comp)>sum(n>=5 for n in basec[v]):issues.append(f'{state}/{v}/{f}: parte separada')
                records.append(dict(view=v,frame=f,bounds=bb,pixels=n))
            bg=Image.new('RGBA',pair.size,'#263d48');bg.alpha_composite(pair);frames.append(bg.convert('RGB'))
        frames[0].save(folder/f'{state}.gif',save_all=True,append_images=frames[1:],duration=([320,140,220,320,140,220,200,240] if state=='idle' else [110,90,90,100,110,90,90,100]),loop=0,disposal=2)
        states[state]=records
    record=dict(id=id,anatomy=entry['anatomy'],source_signature=signature,max_volume_drift=round(max_drift,4),issues=issues,status='checagem-tecnica-ok' if not issues else 'corrigir',states=states)
    (folder/'validacao.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
    (folder/'animacoes.json').write_text(json.dumps(dict(id=id,anatomy=entry['anatomy'],cell=[112,112],anchor=[56,100],frames=8,views=['sw','nw'],method='rig regional semiautomatico no Aseprite; parametros por criatura; articulacoes reconectadas',status=record['status']),ensure_ascii=False,indent=2),encoding='utf-8')
    report.append(record)
    cards.append(f'<article data-kind="{entry["anatomy"]}"><h3>{html.escape(id)}</h3><small>{entry["anatomy"]} · {record["status"]}</small><div><figure><img loading="lazy" src="../soulmonsters-overworld-v2/{id}/animacoes-v1/idle.gif"><figcaption>Idle · SW / NW</figcaption></figure><figure><img loading="lazy" src="../soulmonsters-overworld-v2/{id}/animacoes-v1/walk.gif"><figcaption>Walk · SW / NW</figcaption></figure></div></article>')
summary=dict(total=len(report),previous_pilot=1,total_with_pilot=len(report)+1,technical_ok=sum(not r['issues'] for r in report),pending=[dict(id=r['id'],issues=r['issues']) for r in report if r['issues']],assets=report)
(OUT/'validacao.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
(OUT/'index.html').write_text('''<!doctype html><meta charset="utf-8"><title>Soulmonsters · movimento</title><style>body{background:#112b34;color:#f6e9ce;font:16px system-ui;margin:24px}header{position:sticky;top:0;background:#112b34;padding:12px;z-index:1}input,select{padding:10px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(470px,1fr));gap:16px}article{background:#263d48;padding:14px;border-radius:8px}article>div{display:flex;gap:12px}figure{margin:0}img{width:224px;height:112px;image-rendering:pixelated}small,figcaption{color:#c2d6d5}</style><header><h1>Soulmonsters · idle e deslocamento</h1><p>112px nativos · apoio (56,100) · rigs regionais por anatomia. Revisão técnica não equivale a aprovação visual.</p><input placeholder="Buscar Soulmonster" oninput="filter()" id="q"><select id="kind" onchange="filter()"><option value="">Todas as anatomias</option>'''+''.join(f'<option>{k}</option>' for k in sorted({r['anatomy'] for r in roster}))+'''</select></header><main>'''+''.join(cards)+'''</main><script>function filter(){document.querySelectorAll('article').forEach(a=>a.hidden=!a.textContent.toLowerCase().includes(q.value.toLowerCase())||(kind.value&&a.dataset.kind!==kind.value))}</script>''',encoding='utf-8')
# Compact key-pose boards for visual review; actual GIFs remain in the gallery.
for start in range(0,len(report),24):
    chunk=report[start:start+24];board=Image.new('RGB',(1120,len(chunk)*126),'#263d48');draw=ImageDraw.Draw(board)
    for row,r in enumerate(chunk):
        draw.text((2,row*126+2),r['id']+' / '+r['anatomy'],fill='white')
        sheet=Image.open(ART/r['id']/'animacoes-v1/walk.png').convert('RGBA')
        for view in range(2):
            for n,f in enumerate([0,2,4,6]):
                im=sheet.crop((f*112,view*112,(f+1)*112,(view+1)*112))
                board.paste(im,(224+view*448+n*112,row*126+12),im)
    board.save(OUT/f'lote-{start//24+1:02d}.png')
print(json.dumps(dict(total=summary['total'],technical_ok=summary['technical_ok'],pending=summary['pending']),ensure_ascii=False))
if args.publish:
    assert not summary['pending'], 'Resolve technical failures before publishing'
    path=ROOT/'godot/assets/campaign/overworld-animations-v1';manifest=json.loads((path/'manifest.json').read_text())
    for r in report:
        id=r['id']
        # New approved redraws take precedence over this older regional batch.
        if manifest.get(id,{}).get('art_version','').startswith(('hybrid-','sheet-')): continue
        dest=path/id;dest.mkdir(exist_ok=True)
        manifest[id]={}
        for state in ['idle','walk']:
            source=ART/id/'animacoes-v1'/f'{state}.png';target=dest/f'{state}.png'
            if not target.exists() or source.read_bytes()!=target.read_bytes(): shutil.copy2(source,target)
            manifest[id][state]=f'res://assets/campaign/overworld-animations-v1/{id}/{state}.png'
    (path/'manifest.json').write_text(json.dumps(manifest,indent=2))

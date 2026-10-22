"""Package original generated PNGs without changing their pixels. Draft assets only."""
import hashlib
import json
import shutil
import sys
import zipfile
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent
OUT = ROOT / 'revisao'
OUT.mkdir(exist_ok=True)
STATES = {
    'idle': ([0,1,2,3], [220,150,220,220], True),
    'flight': ([4,5,6,7], [130,110,130,110], True),
    'skill': ([8,9,10,11], [160,180,110,180], False),
    'hurt': ([12,13], [150,210], False),
    'victory': ([14,15], [300,420], True),
}
manifest = {'version': 1, 'tool': 'pipamonsters', 'status': 'needs-cleanup', 'atlases': {}}
reports = []
for identifier, name in [('urso-menta', 'Urso verde-menta (nome provisório)'), ('olho-origami', 'Ciclope de papel (nome provisório)')]:
    source = ROOT / 'sources' / (identifier + '-v2.png')
    shutil.copy2(source, OUT / (identifier + '.png'))
    with Image.open(source) as im:
        width, height = im.size
        xs = [round(i * width / 4) for i in range(5)]
        ys = [round(i * height / 4) for i in range(5)]
        frames, checks = {}, []
        for state, (indices, durations, loop) in STATES.items():
            for pos, idx in enumerate(indices):
                x, y = xs[idx % 4], ys[idx // 4]
                w, h = xs[idx % 4 + 1] - x, ys[idx // 4 + 1] - y
                bounds = im.crop((x,y,x+w,y+h)).getchannel('A').point(lambda a:255 if a>96 else 0).getbbox()
                margin = min(bounds[0], bounds[1], w-bounds[2], h-bounds[3])
                checks.append({'frame':idx,'margin':margin,'meets8pxMargin':margin>=8})
                frames[f'{identifier}_{idx:02d}'] = {'frame':{'x':x,'y':y,'w':w,'h':h}, 'rotated':False, 'trimmed':False, 'spriteSourceSize':{'x':0,'y':0,'w':w,'h':h}, 'sourceSize':{'w':w,'h':h}, 'pivot':{'x':.5,'y':.5}, 'state':state, 'duration':durations[pos]}
        atlas = {'status':'needs-cleanup', 'frames':frames, 'animations':{s:[f'{identifier}_{i:02d}' for i in v[0]] for s,v in STATES.items()}, 'meta':{'app':'PipaKlub Soul Art - DRAFT', 'image':identifier+'.png','size':{'w':width,'h':height},'scale':'1','format':'RGBA8888','columns':4,'rows':4,'name':name}, 'playback':{s:{'durations':v[1],'loop':v[2],'returnTo':None if v[2] else 'idle'} for s,v in STATES.items()}}
        manifest['atlases'][identifier] = atlas
        (OUT/(identifier+'.json')).write_text(json.dumps(atlas,ensure_ascii=False,indent=2),encoding='utf-8')
        reports.append({'id':identifier,'approvedForGame':False,'status':'needs-cleanup','size':[width,height],'alphaRange':list(im.getchannel('A').getextrema()),'sourceSHA256':hashlib.sha256(source.read_bytes()).hexdigest(),'frameChecks':checks,'issues':['Visible colored/white edge contamination persists after two correction attempts.','8px safe cell margins fail; do not load these draft atlases into production.','Fixed pivots and animation continuity require final review after edge cleanup.']})
manifest.update(characterCount=2,frameCount=32)
for name, value in [('atlas.json',manifest),('validacao.json',reports)]:
    (OUT/name).write_text(json.dumps(value,ensure_ascii=False,indent=2),encoding='utf-8')
(OUT/'atlas-data.js').write_text('window.SOUL_ATLAS = '+json.dumps(manifest,ensure_ascii=False)+';\n',encoding='utf-8')
skill_assets = Path(sys.argv[1])
for filename in ['preview.html','sprite-player.js']:
    shutil.copy2(skill_assets/filename,OUT/filename)
preview = (OUT/'preview.html').read_text(encoding='utf-8')
preview = preview.replace('<body>', '<body><p style="padding:16px;background:#6d3500;color:white;font:16px sans-serif">RASCUNHOS PARA REVISÃO — resíduos nas bordas; ainda não aprovados para o jogo. Nomes provisórios.</p>')
(OUT/'preview.html').write_text(preview,encoding='utf-8')
for filename in ['README.md','generation-log.json']:
    shutil.copy2(ROOT/filename,OUT/filename)
with zipfile.ZipFile(ROOT/'pipamons-anime-revisao.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for f in OUT.iterdir():
        if f.is_file(): archive.write(f, f.name)
print(json.dumps({'out':str(OUT),'status':'needs-cleanup','characters':2,'frames':32,'zip':str(ROOT/'pipamons-anime-revisao.zip')},ensure_ascii=False))

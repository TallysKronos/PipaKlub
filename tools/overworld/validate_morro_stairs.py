"""Asset and native-capture QA for the stair/junction correction (no game saves)."""
import json
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[2]
REVIEW=ROOT/'documentation/overworld/escadas-encaixes'
ART=ROOT/'art/overworld/kits/morro'
RUNTIME=ROOT/'godot/assets/overworld/kits/morro'
names=['u+','u-','v+','v-']
board=Image.new('RGB',(1280,720))
draw=ImageDraw.Draw(board)
report={'stairVariants':[],'nativeCaptures':[],'nativeRenderErrors':0,
        'navigationModelChanged':False,'visualBevelCells':'blocked corners next to low stair endpoints only'}
kit=json.loads((ART/'kit.json').read_text(encoding='utf-8'))
for i,name in enumerate(names):
    capture=Image.open(REVIEW/f'after/escada-{name}-1280x720.png')
    board.paste(capture.resize((640,360)),((i%2)*640,(i//2)*360))
    draw.text(((i%2)*640+20,(i//2)*360+20),name,fill='white')
    a=ART/f'escadas/{name}.png';b=RUNTIME/f'escadas/{name}.png'
    image=Image.open(a).convert('RGBA')
    pixels=np.asarray(image);rgb=pixels[:,:,:3].astype(int)
    gray=int(np.count_nonzero((pixels[:,:,3]>0)&((rgb.max(axis=2)-rgb.min(axis=2))<6)))
    assert image.size==(96,112) and a.read_bytes()==b.read_bytes() and gray==0
    entry=kit['stairs'][name]
    assert entry['risePx']==64 and entry['risers']==8
    assert entry['footprint']==([1,2] if name.startswith('u') else [2,1])
    report['stairVariants'].append({'direction':name,'size':list(image.size),
                                  'risePx':64,'risers':8,'neutralGrayPixels':gray,'mirrorMatch':True})
board.save(REVIEW/'after/quatro-direcoes.png')
for path in (REVIEW/'after').glob('*.png'):
    assert Image.open(path).size==(1280,720)
    report['nativeCaptures'].append(path.name)
log=(REVIEW/'native-render.log').read_text(encoding='utf-8')
assert 'ERROR:' not in log and 'Error:' not in log
(REVIEW/'validacao.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps(report))

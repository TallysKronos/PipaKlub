"""Register existing generated facial art; preserve saved rig transforms."""
import json, shutil
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
root=Path('art/soulgen/keys/lobo-cordeiro')
source=root/'source'
base=Image.open(source/'head.png').convert('RGBA')
windows=[[200,180,126,57]]
mask=Image.new('L',base.size)
for x,y,w,h in windows:
    patch=Image.new('L',(w,h)); ImageDraw.Draw(patch).rounded_rectangle((3,3,w-4,h-4),radius=5,fill=255)
    mask.paste(patch.filter(ImageFilter.GaussianBlur(1)),(x,y))
report={}
for name in ['happy','fierce','hurt']:
    variant=Image.open(source/(name+'.png')).convert('RGBA').resize(base.size,Image.Resampling.LANCZOS)
    result=Image.composite(variant,base,mask)
    result.putalpha(base.getchannel('A'))
    outside=alpha=0
    for original,changed,m in zip(base.getdata(),result.getdata(),mask.getdata()):
        alpha+=original[3]!=changed[3]
        outside+=not m and original!=changed
    if alpha or outside: raise ValueError('Registro facial alterou a geometria canônica')
    report[name]={'size':list(result.size),'alpha_changes':alpha,'outside_window_changes':outside}
    result.save(source/('head-'+name+'-registered.png'))
saved=Path('C:/Users/user/Downloads/lobo-em-pele-de-cordeiro-papel-vivo.soulgen (4).json')
archive=root/'user-adjustment'; archive.mkdir(exist_ok=True)
shutil.copyfile(saved,archive/'user-saved.soulgen.json')
p=json.loads(saved.read_text(encoding='utf-8'))
head=next(q for q in p['parts'] if q['id']=='head')
head['faceWindows']=windows
for name in ['happy','fierce','hurt']:
    asset='registered-'+name
    p['assets'][asset]={'name':'Expressão registrada · '+name,'src':'/'+(source/('head-'+name+'-registered.png')).as_posix(),'width':base.width,'height':base.height}
    head['faces'][name]={'asset':asset,'source':[0,0,*base.size]}
p['expressionRevision']=2
out=root/'color-rig-v2'
(out/'lobo-cordeiro.soulgen.json').write_text(json.dumps(p,ensure_ascii=False,indent=2),encoding='utf-8')
import base64
portable=json.loads(json.dumps(p))
for a in portable['assets'].values():
    if not a['src'].startswith('data:'): a['src']='data:image/png;base64,'+base64.b64encode(Path(a['src'][1:]).read_bytes()).decode()
(out/'lobo-cordeiro.portable.soulgen.json').write_text(json.dumps(portable,ensure_ascii=False),encoding='utf-8')
preview=Image.new('RGBA',(base.width*4,base.height),(231,234,216,255))
for i,name in enumerate(['normal','happy','fierce','hurt']):
    im=base if name=='normal' else Image.open(source/('head-'+name+'-registered.png'))
    preview.alpha_composite(im,(i*base.width,0))
preview.save(out/'faces-registered-review.png')
(out/'face-registration.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('Expressões registradas. Transformações, hierarquia e animações salvas preservadas.')

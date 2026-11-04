"""Normalize approved-identity static cutouts, preserving generated alpha and sources."""
from pathlib import Path
from PIL import Image
import json, shutil
root=Path(__file__).resolve().parents[1]
sources=Path('C:/Users/Usuário/.codex/generated_images/01a14877-9409-75b3-93cd-2047414947c3')
inputs={'gollia':('exec-df0a2380-2075-4795-8b18-d2d12aead1b8.png',112),'dragon':('exec-ede94742-0fa6-4934-a037-17c9233fb3da.png',320)}
art=root/'art/characters/warehouse-runtime-v1';art.mkdir(parents=True,exist_ok=True)
out=root/'godot/assets/campaign/warehouse-v1';out.mkdir(parents=True,exist_ok=True)
report={}
for name,(file,height) in inputs.items():
    source=art/(name+'-source.png')
    if not source.exists():shutil.copy2(sources/file,source)
    im=Image.open(source).convert('RGBA');alpha=im.getchannel('A');box=alpha.point(lambda a:255 if a>32 else 0).getbbox()
    assert alpha.getextrema()[0]==0 and alpha.getextrema()[1]>=250 and box
    im=im.crop(box);width=round(im.width*height/im.height);im=im.resize((width,height),Image.Resampling.LANCZOS)
    im.save(out/(name+'.png'))
    report[name]={'size':[width,height],'source':str(source.relative_to(root)),'alpha':im.getchannel('A').getextrema(),'frames':1,'facing':'left' if name=='dragon' else 'southeast','status':'integrated draft; static pose; not a rig'}
(art/'manifest.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
content_path=root/'godot/assets/campaign/content.json';content=json.loads(content_path.read_text(encoding='utf-8'))
w,h=report['dragon']['size'];frame={'x':0,'y':0,'w':w,'h':h}
content['combat']['pipa-dragao-desatada']={'image':'warehouse-v1/dragon.png','animations':{key:[frame] for key in ['idle','flight','attack','hurt','defeat','victory']}}
content_path.write_text(json.dumps(content,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
for filename,value in [('sprite-bounds.json',[0,0,w,h]),('portrait-regions.json',[0,round(h*.36),round(w*.34),round(h*.5)])]:
    path=root/'godot/assets/campaign/battle-ink'/filename;data=json.loads(path.read_text(encoding='utf-8'));data['pipa-dragao-desatada']=value;path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))

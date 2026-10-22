"""Audit the PNG exported by Soulgen UI and build a diagnostic contact sheet."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,hashlib,sys

root=Path(__file__).resolve().parent
revision=int(sys.argv[1]) if len(sys.argv)>1 else 2
assert revision in (2,3)
file=root/f'exports/eremor-v{revision}.png';meta=root/f'exports/eremor-v{revision}.atlas.json'
atlas=json.loads(meta.read_text(encoding='utf8'));im=Image.open(file).convert('RGBA')
assert list(im.size)==[atlas['width'],atlas['height']]
atlas['image']=file.name;meta.write_text(json.dumps(atlas,indent=2)+'\n',encoding='utf8')
clipped=[];empty=[]
for frame in atlas['frames']:
    x,y,w,h=[frame[k] for k in ('x','y','w','h')]
    assert x>=0 and y>=0 and x+w<=im.width and y+h<=im.height
    box=im.crop((x,y,x+w,y+h)).getchannel('A').getbbox()
    if box is None:empty.append(frame['name'])
    elif min(box[0],box[1],w-box[2],h-box[3])<2:clipped.append(frame['name'])
assert not empty,empty
assert not clipped,clipped
sheet=Image.new('RGB',(256*3,286*2),'#e9e4d9');d=ImageDraw.Draw(sheet)
selections=[('idle',0,'Repouso'),('flight',.7,'Planagem'),('skill',.85,'Preparacao'),('skill',1.05,'Impacto'),('hurt',.14,'Dano'),('victory',1.3,'Vitoria')]
for i,(clip,time,label) in enumerate(selections):
    frame=min((f for f in atlas['frames'] if f['clip']==clip),key=lambda f:abs(f['time']-time))
    cell=im.crop((frame['x'],frame['y'],frame['x']+256,frame['y']+256))
    x=i%3*256;y=i//3*286
    d.rectangle((x,y,x+255,y+255),fill='#263c48')
    sheet.paste(cell,(x,y),cell);d.text((x+12,y+263),label+'  '+str(round(frame['time'],2))+' s',fill='#213440')
sheet.save(root/f'review-poses-v{revision}.png')
report={'artRevision':revision,'exportedBy':'Soulgen Studio UI','file':f'exports/eremor-v{revision}.png','size':list(im.size),'frames':len(atlas['frames']),'clips':list(atlas['animations']),'alpha':list(im.getchannel('A').getextrema()),'emptyFrames':empty,'clippedFrames':clipped,'pngSHA256':hashlib.sha256(file.read_bytes()).hexdigest(),'scope':'Alpha, exported bounds and presence of frames; anatomy is reviewed separately.'}
(root/f'export-audit-v{revision}.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps(report,indent=2))

"""Normalize generated layer artwork to the explicitly requested pixel-art contract.
No procedural creature drawing; crops, nearest resampling, binary alpha, palette mapping.
"""
from pathlib import Path
from PIL import Image
import json

ROOT = Path(__file__).resolve().parent
source = Image.open(ROOT / 'source/layers-generated.png').convert('RGBA')
palette = ['#281811','#603126','#a24722','#e77227','#ffa840',
           '#b99b79','#fff1c5','#412421','#78513d','#8c3d22',
           '#ee8b33','#ffd482','#c58b35','#ffe874','#e4bd8b']
rgb = [tuple(bytes.fromhex(c[1:])) for c in palette]

def normalized(box, size):
    part = source.crop(box)
    bounds = part.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox()
    part = part.crop(bounds).resize(size, Image.Resampling.NEAREST)
    px = []
    for r,g,b,a in part.getdata():
        color = min(rgb, key=lambda c:(r-c[0])**2+(g-c[1])**2+(b-c[2])**2)
        px.append((*color,255) if a>=128 else (0,0,0,0))
    part.putdata(px)
    return part

def layer(name, part=None, at=(0,0)):
    im = Image.new('RGBA',(96,96))
    if part: im.paste(part,at)
    im.save(ROOT / name)
    return im

body = layer('body.png',normalized((70,60,400,470),(26,34)),(35,24))
near = layer('wing-near.png',normalized((470,110,790,418),(23,21)),(54,32))
far = layer('wing-far.png',normalized((910,140,1190,418),(18,18)),(21,33))
tail = layer('tail.png',normalized((70,490,410,835),(24,20)),(45,54))
layer('face-normal.png')
face_boxes = {'blink':(534,580,738,791),'fierce':(950,580,1154,791),
              'hurt':(145,942,354,1155),'happy':(538,942,744,1153)}
for expression,box in face_boxes.items():
    face=normalized(box,(26,27))
    # Only eye/eyebrow pixels and their immediate paper backing overlay the body.
    overlay=face.crop((1,10,20,16))
    layer('face-'+expression+'.png',overlay,(36,39))

key={'id':'carcara','name':'Carcará','placeholder':False,'canvas':96,'cell':64,
     'sizeClass':'medium','tier':2,'shadowSize':1,'palette':palette,
     'variants':{'noturno':['#281811','#303652','#5f609e','#9289d2','#bcacef',
         '#a8adcc','#f1ecff','#182037','#423d63','#232e49','#5b5fae','#b8aff0',
         '#a18e67','#ffe874','#d3d0ec']},
     'parts':{'body':{'file':'body.png'},
        'wing_near':{'file':'wing-near.png','pivot':[56,41],'side':'right'},
        'wing_far':{'file':'wing-far.png','pivot':[37,41],'side':'left'},
        'tail':{'file':'tail.png','pivot':[48,56]}},
     'faces':{e:'face-'+e+'.png' for e in ['normal','blink','fierce','hurt','happy']},
     'anchors':{'head':[46,40],'center':[48,42],'effect':[39,45],'tail':[48,56]},
     'fx':{'hot':palette[6],'mid':palette[13],'dim':palette[11],'edge':palette[2]}}
(ROOT/'key.json').write_text(json.dumps(key,ensure_ascii=False,indent=2),encoding='utf-8')
composite=Image.new('RGBA',(96,96))
for part in [tail,far,body,near]:composite.alpha_composite(part)
composite.save(ROOT/'pose.png')
composite.resize((576,576),Image.Resampling.NEAREST).save(ROOT/'pose-preview.png')
print('Normalized nine 96x96 layers; 15-color palette; pose bounds',composite.getbbox())

"""Read approved rest references; emit native-pixel Aseprite draw operations.

No sprite/image files are written here: Aseprite owns all art exports.
"""
from pathlib import Path
import argparse, importlib.util, json
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'art/characters/kael-locomotion-v1'
DIRS=['s','sw','w','nw','n','ne','e','se']
LAYERS=['Pernas · apoio fixo','Tronco e braços','Cabeça']
TIMES=[480,150,320,150,480,150,320,150]
spec=importlib.util.spec_from_file_location('video_sheet',ROOT/'tools/pixelgen/video-to-sheet.py')
video=importlib.util.module_from_spec(spec);spec.loader.exec_module(video)

def calls(frame,layer):
    palette=json.loads((OUT/'palette.json').read_text(encoding='utf-8'))
    colors=[tuple(bytes.fromhex(c[1:7])) for c in palette[1:]]
    chars='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    legend={'.':'#00000000',**{chars[i]:c for i,c in enumerate(palette[1:])}}
    cache={}
    def index(c):
        rgb=tuple(c[:3])
        if rgb not in cache:cache[rgb]=min(range(len(colors)),key=lambda i:sum((rgb[k]-colors[i][k])**2 for k in range(3)))
        return chars[cache[rgb]]
    phase=frame-1
    torso=[0,1,1,0,0,1,1,0][phase]
    head=[0,0,1,1,0,0,1,1][phase]
    start,end,offset=[(67,96,0),(36,67,torso),(0,37,head)][layer]
    ops=[{'kind':'clear'}]
    for row,d in enumerate(DIRS):
        source=video.key_image(Image.open(OUT/'references'/f'kael-rest-{d}.png'))
        box=source.getchannel('A').getbbox();source=source.crop(box)
        height=86;size=(round(source.width*height/source.height),height)
        source=source.resize(size,Image.Resampling.NEAREST)
        native=Image.new('RGBA',(64,96));native.paste(source,((64-size[0])//2,94-height))
        rows=[]
        for y in range(start,end):
            rows.append(''.join(index(native.getpixel((x,y))) if native.getpixel((x,y))[3] else '.' for x in range(64)))
        for yy,line in enumerate(rows):
            import re
            for run in re.finditer(r'[^.]+',line):
                ops.append({'kind':'grid','x':run.start(),'y':row*96+start+offset+yy,'rows':[run.group()],'legend':{c:legend[c] for c in set(run.group())}})
    return {'sprite':'#8','layer':LAYERS[layer],'frame':frame,'createCel':True,'paletteLock':True,'label':f'Idle {frame}: {LAYERS[layer]}','ops':ops}

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--frame',type=int,required=True);p.add_argument('--layer',type=int,required=True);a=p.parse_args()
    print(json.dumps(calls(a.frame,a.layer),ensure_ascii=True))

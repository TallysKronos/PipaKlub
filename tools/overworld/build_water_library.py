"""Normalize generated water paintings, project static shore masks, pack atlases.
No campaign edits. Animation is performed by Godot shaders, not baked banks.
"""
from pathlib import Path
import json, shutil
import numpy as np
from PIL import Image,ImageDraw
from build_terrain_library import periodic,project,shape,MASKS,port_report
from build_urban_library import write,font

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/aguas-v1'
GAME=ROOT/'godot/assets/overworld/kits/aguas-v1'
REVIEW=ROOT/'documentation/overworld/aguas-v1'

def save(im,path):
    for folder in [ART,GAME]:
        dest=folder/path;dest.parent.mkdir(parents=True,exist_ok=True);im.save(dest)

def shore_mask(mask):
    yy,xx=np.meshgrid(np.arange(32)+.5,np.arange(64)+.5,indexing='ij')
    u=(xx/64+yy/32-.5)*64;v=(yy/32-xx/64+.5)*64
    inside=shape(mask,u,v)
    near=np.zeros_like(u,dtype=float)
    for dx,dy in [(2,0),(-2,0),(0,2),(0,-2),(4,0),(-4,0),(0,4),(0,-4)]:
        near=np.maximum(near,(~shape(mask,u+dx,v+dy))*(.8 if abs(dx+dy)==2 else .35))
    diamond=(u>=0)&(u<64)&(v>=0)&(v<64)
    return Image.fromarray(np.dstack([(near*255).astype('uint8'),np.zeros_like(u,dtype='uint8'),np.zeros_like(u,dtype='uint8'),(inside&diamond).astype('uint8')*255]))

def build():
    REVIEW.mkdir(parents=True,exist_ok=True)
    specs=json.loads((ART/'briefs.json').read_text(encoding='utf-8-sig'))['assets']
    manifest={'schema':'animated-water-1','grid':[64,32],'levelPx':64,'loopSeconds':4,'campaignIntegrated':False,'waters':{},'falls':{},'effects':{}}
    records=[]
    atlas=Image.new('RGBA',(512,192))
    masks=[]
    for i,m in enumerate(MASKS):
        tile=shore_mask(m);atlas.alpha_composite(tile,((i%8)*64,(i//8)*32))
        masks.append({'mask':m,'atlas':[i%8,i//8]})
    save(atlas,'masks/shore-atlas.png')
    manifest['tiles']=masks
    for spec in specs:
        id=spec['id'];kind=spec['kind'];im=Image.open(ART/f'fontes/{id}.png').convert('RGBA')
        if kind in ['water','fall']:
            surface=periodic(im,512);save(Image.fromarray(surface),f'surfaces/{id}.png')
            records.append({'id':id,'oppositeXError':int(np.abs(surface[:,0].astype(int)-surface[:,-1]).max()),'oppositeYError':int(np.abs(surface[0].astype(int)-surface[-1]).max())})
            if kind=='water':
                rgb=np.asarray(Image.fromarray(surface).resize((64,64),Image.Resampling.LANCZOS))
                colored=Image.new('RGBA',(512,192))
                for i,m in enumerate(MASKS):
                    tile=project(rgb,m);save(tile,f'tiles/{id}/blob-{m:03}.png');colored.alpha_composite(tile,((i%8)*64,(i//8)*32))
                save(colored,f'atlas/{id}.png')
                speed=0 if id.startswith('lago') else (2 if id=='corredeira' else 1)
                manifest['waters'][id]={'name':spec['name'],'surface':f'surfaces/{id}.png','atlas':f'atlas/{id}.png','flow':[0,speed],'tileset':f'tilesets/{id}.tres'}
            else:manifest['falls'][id]={'name':spec['name'],'surface':f'surfaces/{id}.png','flow':2 if id.endswith('forte') else 1}
        else:
            bbox=im.getbbox()
            if not bbox:raise ValueError('Empty effect '+id)
            cropped=im.crop(bbox);cropped.thumbnail((384,192),Image.Resampling.LANCZOS)
            out=Image.new('RGBA',(400,208));out.alpha_composite(cropped,((400-cropped.width)//2,(208-cropped.height)//2))
            save(out,f'effects/{id}.png');manifest['effects'][id]={'name':spec['name'],'texture':f'effects/{id}.png','pivot':[.5,.5]}
    write(ART/'library.json',manifest);write(GAME/'library.json',manifest)
    write(REVIEW/'preparacao.json',{'surfaces':records,'shoreGeometry':port_report(),'fixedMask':True,'sourceCount':len(specs),'projectedTiles':len(MASKS)*6})
    board=Image.new('RGB',(1440,1260),'#142E38');d=ImageDraw.Draw(board)
    d.text((32,18),'ÁGUAS VIVAS · SOULMONSTERS',font=font(32),fill='#F1D99E')
    for i,s in enumerate(specs):
        x=24+(i%4)*354;y=90+(i//4)*380
        src=Image.open(ART/f"fontes/{s['id']}.png").convert('RGBA');src.thumbnail((330,290))
        board.paste(src,(x+(330-src.width)//2,y),src)
        d.text((x,y+300),s['name'],font=font(21),fill='#F1D99E')
        d.text((x,y+333),'Fonte gerada · '+s['kind'],font=font(15),fill='#AFCAD0')
    board.save(REVIEW/'CATALOGO-12-FONTES.png')
    print(json.dumps({'generatedSources':len(specs),'waterMaterials':6,'fallMaterials':2,'effects':4,'shoreStates':47,'projectedTiles':282}))

if __name__=='__main__':build()

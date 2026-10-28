"""Prepare fruit-tree scenery, preserve original generation sources."""
from pathlib import Path
import json, shutil
from PIL import Image, ImageDraw
from build_art import kit, studio, shadow, pack_prop, kael_image
from build_urban_library import write, font

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/frutiferas'
RUNTIME=ROOT/'godot/assets/overworld/kits/frutiferas'
REVIEW=ROOT/'documentation/overworld/frutiferas-v1'

def build():
    specs=json.loads((ART/'briefs.json').read_text(encoding='utf-8-sig'))['assets']
    k=json.loads((ART/'kit.json').read_text(encoding='utf-8'));shadow(ART)
    audit=[]
    for s in specs:
        source=ART/f"fontes/geradas/{s['id']}.png"
        im=Image.open(source).convert('RGBA')
        if im.getchannel('A').getextrema()[0]!=0:raise ValueError('Opaque background '+s['id'])
        e=k['pieces'][s['id']]['variants']['default']
        audit.append({'id':s['id'],'sourceSize':list(im.size),'sourceAlphaMin':im.getchannel('A').getextrema()[0],
                      'size':e['size'],'rasterSize':e['rasterSize'],'anchor':e['anchor'],
                      'footprint':e['footprint'],'visualFootprint':e['visualFootprint']})
    for folder in ['pecas','sombras']:
        (RUNTIME/folder).mkdir(parents=True,exist_ok=True)
        for p in (ART/folder).glob('*.png'):shutil.copy2(p,RUNTIME/folder/p.name)
    write(ART/'kit.json',k);write(RUNTIME/'kit.json',k);write(REVIEW/'preparacao-raster.json',audit)
    studio(k)
    p=ART/'frutiferas.isostudio.json';data=json.loads(p.read_text(encoding='utf-8'))
    data['name']='Soulmonsters — 12 árvores frutíferas';write(p,data)
    boards(k,specs)
    print('12 articulated fruit trees catalogued; originals retained; no campaign placement.')

def boards(k,specs):
    REVIEW.mkdir(parents=True,exist_ok=True)
    overview=Image.new('RGB',(1760,1680),'#ECDFC1');d=ImageDraw.Draw(overview)
    native=Image.new('RGB',(1760,1380),'#ECDFC1');nd=ImageDraw.Draw(native)
    avatar=kael_image();avatar=avatar.resize((round(avatar.width*84/avatar.height),84),Image.Resampling.LANCZOS)
    avatar.save(REVIEW/'KAEL-ESCALA.png')
    for i,s in enumerate(specs):
        e=k['pieces'][s['id']]['variants']['default'];im=Image.open(ART/e['file']).convert('RGBA')
        tight=im.crop(im.getchannel('A').getbbox());f=min(390/tight.width,425/tight.height)
        thumb=tight.resize((round(tight.width*f),round(tight.height*f)),Image.Resampling.LANCZOS)
        x=i%4*440;y=i//4*560
        overview.paste(thumb,(x+(440-thumb.width)//2,y+20+425-thumb.height),thumb)
        d.text((x+20,y+470),s['name'],font=font(23),fill='#23394A')
        d.text((x+20,y+510),'Copa própria • frutos conectados',font=font(17),fill='#56645A')
        foot=i//4*460+320
        native.paste(avatar,(x+16,foot-84),avatar)
        native.paste(im,(x+250-e['anchor'][0],foot-e['anchor'][1]),im)
        nd.text((x+16,foot+45),s['name'],font=font(21),fill='#23394A')
        nd.text((x+16,foot+82),'Escala 1:1 • Kael 84 px • tronco 1×1',font=font(16),fill='#56645A')
    overview.save(REVIEW/'CATALOGO-12-FRUTIFERAS.png');native.save(REVIEW/'ESCALA-NATIVA.png')

if __name__=='__main__':build()

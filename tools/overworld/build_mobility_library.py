"""Prepare parked mobility cutouts and catalogues. No campaign map changes."""
from pathlib import Path
import json, math, shutil
from PIL import Image, ImageDraw
from build_art import kit, studio, shadow, kael_image
from build_urban_library import write, font

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/mobilidade'
RUNTIME=ROOT/'godot/assets/overworld/kits/mobilidade'
REVIEW=ROOT/'documentation/overworld/mobilidade-v1'
LABELS={'brasileiros':'CARROS DE REFERÊNCIA BRASILEIRA','jipes-utilitarios':'JIPES E UTILITÁRIOS','soulmonsters':'VERSÕES SOULMONSTERS','mobilidade-rua':'MOBILIDADE E RUA'}

def build():
    specs=json.loads((ART/'briefs.json').read_text(encoding='utf-8'))['assets']
    collection=kit('mobilidade'); shadow(ART)
    collection.update(role='parked_mobility_library',campaignIntegrated=False,viewsPerAsset=1,animated=False,
                      placementStatus='proposed_footprints_and_pivots_require_map_fit')
    audit=[]
    for s in specs:
        src=ART/f"fontes/geradas/{s['id']}.png"
        raw=Image.open(src).convert('RGBA')
        if raw.getchannel('A').getextrema()[0]!=0: raise ValueError(f"Opaque background: {s['id']}")
        im=raw.copy(); im.putalpha(im.getchannel('A').point(lambda a:0 if a<160 else a))
        bounds=im.getchannel('A').getbbox()
        if not bounds: raise ValueError(s['id'])
        im=im.crop(bounds)
        fu,fv=s['footprint']; width=(fu+fv)*32
        factor=min((width-4)/im.width,(s['bodyHeight']+(fu+fv)*16)/im.height)
        raster=[max(1,round(im.width*factor)),max(1,round(im.height*factor))]
        im=im.resize(raster,Image.Resampling.LANCZOS)
        pad=(fu+fv)*8; height=math.ceil((raster[1]+16+pad)/32)*32
        art_bottom=height-pad
        # A vehicle occupies a ground plane; its centre is above its nearest tyre.
        # Exact tyre contact/collision fit remains a per-map art placement decision.
        pivot_lift=round(min(pad,raster[1]*.22)) if s['kind']=='vehicle' else 0
        anchor=[width//2,art_bottom-pivot_lift]
        canvas=Image.new('RGBA',(width,height));canvas.alpha_composite(im,(width//2-raster[0]//2,art_bottom-raster[1]))
        dest=f"pecas/{s['id']}-default.png";(ART/'pecas').mkdir(exist_ok=True);canvas.save(ART/dest)
        e={'file':dest,'size':[width,height],'footprint':s['footprint'],'visualFootprint':s['footprint'],
           'bloqueia':True,'height':math.ceil(max(0,raster[1]-(fu+fv)*16)/32),'anchor':anchor,
           'isoAnchor':[fu*32,height],'groundAnchor':'center','shadow':'sombras/contato.png',
           'rasterSize':raster,'category':s['category'],'displayName':s['name'],'kind':s['kind'],
           'facing':s['facing'],'approval':'pending_owner_review','pivotStatus':'provisional_projected_ground_center' if s['kind']=='vehicle' else 'provisional_lowest_visible_contact',
           'source':{'file':f"fontes/geradas/{s['id']}.png",'geometryGuide':f"fontes/geometria/{s['id']}.png",
                     'tool':'image_gen.imagegen','normalization':'alpha threshold 160; tight crop; uniform fit; original retained'}}
        collection['pieces'][s['id']]={'default':'default','variants':{'default':e}}
        audit.append({'id':s['id'],'sourceSize':list(raw.size),'alphaBounds':list(bounds),'rasterSize':raster,
                      'canvas':e['size'],'anchor':anchor,'footprint':s['footprint']})
    for folder in ['pecas','sombras']:
        (RUNTIME/folder).mkdir(parents=True,exist_ok=True)
        for p in (ART/folder).glob('*.png'):shutil.copy2(p,RUNTIME/folder/p.name)
    write(ART/'kit.json',collection);write(RUNTIME/'kit.json',collection)
    write(REVIEW/'preparacao-raster.json',audit)
    studio(collection)
    project=ART/'mobilidade.isostudio.json';p=json.loads(project.read_text(encoding='utf-8'))
    p['name']='Soulmonsters — 32 veículos e peças de mobilidade';write(project,p)
    boards(collection,specs)
    print(f'{len(specs)} mobility assets prepared.')

def boards(k,specs):
    REVIEW.mkdir(parents=True,exist_ok=True)
    avatar=kael_image();avatar=avatar.resize((round(avatar.width*84/avatar.height),84),Image.Resampling.LANCZOS)
    avatar.save(REVIEW/'KAEL-ESCALA.png')
    overview=Image.new('RGB',(2560,1760),'#ECDFC1');d=ImageDraw.Draw(overview)
    for row,(cat,label) in enumerate(LABELS.items()):
        group=[s for s in specs if s['category']==cat]
        d.text((20,row*440+10),label,font=font(24),fill='#23394A')
        native=Image.new('RGB',(1760,840),'#ECDFC1');nd=ImageDraw.Draw(native)
        for i,s in enumerate(group):
            e=k['pieces'][s['id']]['variants']['default'];im=Image.open(ART/e['file']).convert('RGBA')
            tight=im.crop(im.getchannel('A').getbbox());factor=min(292/tight.width,278/tight.height)
            thumb=tight.resize((round(tight.width*factor),round(tight.height*factor)),Image.Resampling.LANCZOS)
            overview.paste(thumb,(i*320+(320-thumb.width)//2,row*440+52+278-thumb.height),thumb)
            d.text((i*320+14,row*440+350),s['name'],font=font(18),fill='#23394A')
            d.text((i*320+14,row*440+380),f"Base proposta {s['footprint'][0]}×{s['footprint'][1]}",font=font(15),fill='#56645A')
            nx=(i%4)*440;foot=(i//4)*420+290
            native.paste(avatar,(nx+18,foot-84),avatar)
            native.paste(im,(nx+260-e['anchor'][0],foot-e['anchor'][1]),im)
            nd.text((nx+15,foot+35),s['name'],font=font(19),fill='#23394A')
            nd.text((nx+15,foot+65),'Escala 1:1 • Kael 84 px • pivô provisório',font=font(15),fill='#56645A')
        native.save(REVIEW/f'ESCALA-{cat}.png')
    overview.save(REVIEW/'CATALOGO-32-ASSETS.png')

if __name__=='__main__':build()

"""Normalize original generated architecture; prepare library, not campaign maps."""
from pathlib import Path
import json,math,shutil
from PIL import Image,ImageDraw,ImageFont
from build_art import kit,studio,shadow,kael_image

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/urbano'
RUNTIME=ROOT/'godot/assets/overworld/kits/urbano'
REVIEW=ROOT/'documentation/overworld/arquitetura-moderna-v1'
FONT=ROOT/'godot/assets/campaign/ui-modern/fonts/Nunito.ttf'

def write(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def font(size):
    f=ImageFont.truetype(str(FONT),size);f.set_variation_by_axes([700]);return f

def build():
    specs=json.loads((ART/'briefs.json').read_text(encoding='utf-8'))['assets']
    collection=kit('urbano');shadow(ART)
    collection.update(role='reusable_architecture_library',campaignIntegrated=False,approval='pending_owner_review')
    audit=[]
    for s in specs:
        source=ART/f"fontes/geradas/{s['id']}.png"
        if not source.exists():raise FileNotFoundError(source)
        raw=Image.open(source).convert('RGBA')
        if raw.getchannel('A').getextrema()[0]!=0:raise ValueError(f"Opaque background: {s['id']}")
        # Remove only faint generated haze. Do not paint missing geometry.
        im=raw.copy();im.putalpha(im.getchannel('A').point(lambda a:0 if a<160 else a))
        bounds=im.getchannel('A').getbbox()
        if not bounds:raise ValueError(f"Empty source: {s['id']}")
        im=im.crop(bounds)
        fu,fv=s['footprint'];width=(fu+fv)*32
        factor=(width-4)/im.width
        raster=(round(im.width*factor),round(im.height*factor))
        im=im.resize(raster,Image.Resampling.LANCZOS)
        top_padding=16;bottom_padding=(fu+fv)*8
        height=math.ceil((raster[1]+top_padding+bottom_padding)/32)*32
        anchor=[width//2,height-bottom_padding]
        canvas=Image.new('RGBA',(width,height))
        canvas.alpha_composite(im,(anchor[0]-raster[0]//2,anchor[1]-raster[1]))
        dest=f"pecas/{s['id']}-default.png";(ART/'pecas').mkdir(exist_ok=True)
        canvas.save(ART/dest)
        entry={'file':dest,'size':[width,height],'footprint':s['footprint'],'visualFootprint':s['footprint'],'bloqueia':True,
               'height':math.ceil(max(0,raster[1]-(fu+fv)*16)/32),'anchor':anchor,'isoAnchor':[fu*32,height],
               'groundAnchor':'front','shadow':'sombras/contato.png','rasterSize':list(raster),'doorFace':s['doorFace'],
               'category':s['category'],'displayName':s['name'],'stories':s['stories'],'approval':'pending_owner_review',
               'source':{'file':f"fontes/geradas/{s['id']}.png",'geometryGuide':f"fontes/geometria/{s['id']}.png",'tool':'image_gen.imagegen','normalization':'alpha haze cleanup; tight crop; uniform width fit; front anchor; original retained'}}
        collection['pieces'][s['id']]={'default':'default','variants':{'default':entry}}
        audit.append({'id':s['id'],'sourceSize':list(raw.size),'alphaBounds':list(bounds),'rasterSize':list(raster),'canvas':entry['size'],'footprint':s['footprint'],'anchor':anchor,'status':'raster_prepared_visual_review_required'})
    for folder in ['pecas','sombras']:
        (RUNTIME/folder).mkdir(parents=True,exist_ok=True)
        for p in (ART/folder).glob('*.png'):shutil.copy2(p,RUNTIME/folder/p.name)
    write(ART/'kit.json',collection);write(RUNTIME/'kit.json',collection)
    write(REVIEW/'preparacao-raster.json',audit)
    studio(collection)
    project=ART/'urbano.isostudio.json';p=json.loads(project.read_text(encoding='utf-8'));p['name']='Soulmonsters — 24 construções modernas';write(project,p)
    boards(collection,specs)
    print(f"{len(specs)} prepared cutouts, kit, Iso Studio and catalogue boards.")

def boards(collection,specs):
    REVIEW.mkdir(parents=True,exist_ok=True)
    avatar=kael_image();avatar=avatar.resize((round(avatar.width*84/avatar.height),84),Image.Resampling.LANCZOS)
    overview=Image.new('RGB',(2160,2000),'#ECDFC1');d=ImageDraw.Draw(overview)
    labels={'casas':'CASAS MODERNAS','comercios':'ESTABELECIMENTOS','empresariais':'PRÉDIOS EMPRESARIAIS','laboratorios':'LABORATÓRIOS'}
    for row,category in enumerate(labels):
        group=[s for s in specs if s['category']==category]
        d.text((24,row*500+12),labels[category],font=font(25),fill='#23394A')
        tallest=max(collection['pieces'][s['id']]['variants']['default']['rasterSize'][1] for s in group)
        # Native scale board: one shared pixel scale for building and Kael.
        cellw=470;cellh=tallest+180;native=Image.new('RGB',(cellw*3,cellh*2),'#ECDFC1');nd=ImageDraw.Draw(native)
        for i,s in enumerate(group):
            e=collection['pieces'][s['id']]['variants']['default'];im=Image.open(ART/e['file']).convert('RGBA');tight=im.crop(im.getchannel('A').getbbox())
            scale=min(320/tight.width,360/tight.height)
            thumb=tight.resize((round(tight.width*scale),round(tight.height*scale)),Image.Resampling.LANCZOS)
            x=i*360+(360-thumb.width)//2;y=row*500+55+360-thumb.height
            overview.paste(thumb,(x,y),thumb)
            d.text((i*360+16,row*500+425),s['name'],font=font(17),fill='#23394A')
            d.text((i*360+16,row*500+454),f"{s['footprint'][0]}×{s['footprint'][1]} • {s['stories']} pav. • prévia reduzida",font=font(14),fill='#56645A')
            nx=(i%3)*cellw;foot=(i//3)*cellh+tallest+36
            native.paste(avatar,(nx+15,foot-84),avatar)
            native.paste(im,(nx+260-e['anchor'][0],foot-e['anchor'][1]),im)
            nd.text((nx+15,foot+32),s['name'],font=font(19),fill='#23394A')
            nd.text((nx+15,foot+62),f"Kael 84 px • base {s['footprint']} • apoio frontal",font=font(15),fill='#56645A')
        native.save(REVIEW/f'ESCALA-{category}.png')
    overview.save(REVIEW/'CATALOGO-24-CONSTRUCOES.png')

if __name__=='__main__':build()

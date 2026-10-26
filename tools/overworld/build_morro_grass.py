"""PIP-88: editable, pixel-complete terrain and normalized decorative decals.

Run directly to rebuild only this grass family, preserving the rest of the kit.
"""
import json
import shutil
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'art/overworld/kits/morro'
RUNTIME = ROOT / 'godot/assets/overworld/kits/morro'
REVIEW = ROOT / 'documentation/overworld/grama-morro'
BASE = '#95B773'
SOURCE_NAMES = {
    'capim-alto-0': 'exec-e9a34e8d-052b-4715-81de-fadc1c9b9e9d.png',
    'capim-alto-1': 'exec-a05bc241-1738-42bf-b704-947f060e0930.png',
    'capim-alto-2': 'exec-648376db-1942-43a1-8a31-1ad16d091727.png',
    'terra-batida-0': 'exec-b5756fcd-f2f8-4dcd-83dc-a31d8b980ff6.png',
    'terra-batida-1': 'exec-f238d7a5-d142-4fde-a727-13c02f520e95.png',
    'trevo-flor-0': 'exec-05edd7fd-b5f7-4af7-a1f4-b4a61f0338c0.png',
    'trevo-flor-1': 'exec-d94bee1c-2f7f-46bd-9821-6ae12225a1cc.png',
}


def mask():
    result = Image.new('L', (64, 32))
    # Pixel centres, not clipped vertices at x=64/y=32. Exactly 1024 opaque
    # pixels; complements both neighbours at (+/-32,+/-16).
    result.putdata([255 if abs(2*x+1-64)+2*abs(2*y+1-32) <= 64 else 0
                    for y in range(32) for x in range(64)])
    return result


def tiles(directory):
    directory.mkdir(parents=True, exist_ok=True)
    layouts = [
        [(20,15,1),(39,21,-1),(43,12,1)],
        [(31,9,-1),(17,18,1),(43,18,-1)],
        [(25,22,1),(46,16,-1),(24,12,-1)],
        [(15,16,-1),(35,16,1),(34,25,-1)],
        [(28,7,1),(44,20,1),(25,18,-1)],
        [(20,20,-1),(38,10,1),(39,23,-1)],
        [(37,17,1)], [(25,16,-1)],
    ]
    alpha = mask()
    for n, layout in enumerate(layouts):
        scale = 4
        im = Image.new('RGB', (256,128), BASE)
        draw = ImageDraw.Draw(im)
        svg = ['<svg xmlns="http://www.w3.org/2000/svg" width="64" height="32" viewBox="0 0 64 32">',
               '<defs><clipPath id="tile"><path d="M32 0L64 16 32 32 0 16Z"/></clipPath></defs>',
               '<g clip-path="url(#tile)">',f'<path d="M32 0L64 16 32 32 0 16Z" fill="{BASE}"/>']
        def polygon(points, color):
            draw.polygon([(round(x*scale), round(y*scale)) for x,y in points],fill=color)
            svg.append('<polygon points="'+ ' '.join(f'{x},{y}' for x,y in points)+f'" fill="{color}"/>')
        for x,y,flip in layout:
            # Small, low-contrast blades in unequal groups, with rounded bends.
            # Last two variants are intentionally near-smooth, without tufts.
            if n >= 6:
                polygon([(x-2,y),(x,y-.5),(x+3,y),(x+1,y+.5)], '#99B977')
                continue
            polygon([(x-4,y+1),(x-1,y),(x+4,y+.3),(x+2,y+1.3)], '#91B16F')
            polygon([(x,y+1),(x-2*flip,y-.5),(x-3*flip,y-2),(x-.8*flip,y-1.4),(x+flip,y+.7)], '#85A969')
            polygon([(x,y+1),(x+flip,y-1.5),(x+3*flip,y-2.2),(x+2*flip,y-.3)], '#A5BF80')
        svg.extend(['</g>','</svg>'])
        im = im.resize((64,32),Image.Resampling.LANCZOS).convert('RGBA')
        im.putalpha(alpha)
        im.save(directory/f'grama-{n}.png')
        (directory/f'grama-{n}.svg').write_text('\n'.join(svg),encoding='utf-8',newline='\n')
    return {'variants':[f'chao/grama-{n}.png' for n in range(8)], 'size':[64,32],
            'filter':'linear', 'smoothVariants':[6,7], 'shadowBaked':False,
            'source':'tools/overworld/build_morro_grass.py'}


def decals():
    dest = ART/'decalques'
    dest.mkdir(exist_ok=True)
    records = []
    for name in SOURCE_NAMES:
        source = ART/'fontes/grama-morro'/f'{name}.png'
        im = Image.open(source).convert('RGBA')
        # Remove low-alpha generation halos, retain the actual sprite. This is
        # alpha cleanup and fit/anchor normalization, not a repaint.
        a = im.getchannel('A').point(lambda v: 255 if v >= 210 else 0)
        bounds = a.getbbox()
        im.putalpha(a)
        im = im.crop(bounds)
        tall = name.startswith('capim')
        size = (40,30) if tall else (48,22) if name.startswith('terra') else (32,20)
        im.thumbnail(size,Image.Resampling.LANCZOS)
        canvas = Image.new('RGBA',(64,48))
        # Feet of tall grass at (32,32); flat patches centred on that same point.
        at = ((64-im.width)//2, 33-im.height if tall else 32-im.height//2)
        if tall:
            feet = [x for y in range(max(0,im.height-2),im.height)
                    for x in range(im.width) if im.getpixel((x,y))[3]>=128]
            if feet: at = (32-round(sum(feet)/len(feet)),33-im.height)
        canvas.alpha_composite(im,at)
        canvas.save(dest/f'{name}.png')
        records.append({'id':name,'file':f'decalques/{name}.png','size':[64,48],
                        'anchor':[32,32],'collision':False,
                        'source':f'fontes/grama-morro/{name}.png'})
    return records


def validate():
    REVIEW.mkdir(parents=True,exist_ok=True)
    images = [Image.open(ART/f'chao/grama-{i}.png').convert('RGBA') for i in range(8)]
    expected = mask()
    assert all(im.size==(64,32) and im.getchannel('A').tobytes()==expected.tobytes() for im in images)
    field = Image.new('RGBA',(512,256))
    for v in range(8):
        for u in range(8):
            # All eight variants mixed across an 8x8 field.
            index = (u+v*(v+1)//2) % 8
            at = (224+(u-v)*32,(u+v)*16)
            field.alpha_composite(images[index],at)
    outer = Image.new('L',(512,256))
    outer.putdata([255 if abs(2*x+1-512)+2*abs(2*y+1-256)<=512 else 0
                   for y in range(256) for x in range(512)])
    holes = sum(a==255 and b!=255 for a,b in zip(outer.tobytes(),field.getchannel('A').tobytes()))
    assert holes==0, holes
    pair_checks=0
    for first in images:
        for second in images:
            for dx,dy in [(32,16),(-32,16),(32,-16),(-32,-16)]:
                pair=Image.new('RGBA',(128,96))
                pair.alpha_composite(first,(32,32))
                pair.alpha_composite(second,(32+dx,32+dy))
                # Both source supports must survive composition fully opaque.
                for image,ox,oy in [(first,32,32),(second,32+dx,32+dy)]:
                    for y in range(32):
                        for x in range(64):
                            if expected.getpixel((x,y)):
                                assert pair.getpixel((x+ox,y+oy))[3]==255
                pair_checks+=1
    field.save(REVIEW/'grama-8x8.png')
    field.resize((1024,512),Image.Resampling.NEAREST).save(REVIEW/'grama-8x8-ampliada.png')
    board = Image.new('RGB',(768,256),'#273D34')
    d=ImageDraw.Draw(board)
    for i,im in enumerate(images):
        x=(i%4)*192+32;y=(i//4)*112+18
        board.paste(im.resize((128,64),Image.Resampling.NEAREST),(x,y),im.resize((128,64),Image.Resampling.NEAREST))
        d.text((x,y+70),f'grama-{i}'+(' / quase lisa' if i>=6 else ''),fill='white')
    board.save(REVIEW/'variacoes.png')
    board=Image.new('RGB',(896,160),BASE)
    d=ImageDraw.Draw(board)
    for i,name in enumerate(SOURCE_NAMES):
        im=Image.open(ART/f'decalques/{name}.png')
        board.paste(im.resize((128,96)),(i*128,12),im.resize((128,96)))
        d.text((i*128+4,120),name,fill='#243B2F')
    board.save(REVIEW/'decalques.png')
    mirrored=[]
    for folder in ('chao','decalques'):
        for file in (ART/folder).glob('*.png'):
            if folder=='chao' and not file.name.startswith('grama-'):continue
            assert file.read_bytes()==(RUNTIME/folder/file.name).read_bytes()
            mirrored.append(str(file.relative_to(ART)))
    report={'tileSize':[64,32],'variants':8,'nearlySmooth':[6,7],
            'opaquePixelsPerDiamond':sum(v==255 for v in expected.tobytes()),
            'transparentInteriorPixels8x8':holes,'adjacencyChecks':pair_checks,'field':[8,8], 'decals':7,
            'decalSize':[64,48],'decalAnchor':[32,32],'decalCollision':False,
            'bakedYardShadow':False,'mirroredAssets':mirrored}
    gpu_path=REVIEW/'after/grama-8x8-godot-1280x720.png'
    if gpu_path.exists():
        gpu=Image.open(gpu_path).convert('RGB')
        assert gpu.size==(1280,720)
        holes=0
        tested=0
        for y in range(720):
            for x in range(1280):
                # Exclude outer silhouette antialiasing; include every inner seam.
                if abs((x+.5-640)/358.4)+abs((y+.5-360)/179.2)<.99:
                    tested+=1
                    holes+=max(gpu.getpixel((x,y)))<20
        assert holes==0, f'{holes} holes in native Godot field'
        report['nativeGodotField']={'zoom':1.4,'underlay':False,'size':[1280,720],
                                   'interiorPixelsTested':tested,'blackGaps':holes}
    (REVIEW/'validacao.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(json.dumps(report,ensure_ascii=False))


def build():
    if (ART/'fontes/pisos-v2/grama.png').exists():
        from build_morro_floors import build as build_floors
        build_floors()
        return
    grass = tiles(ART/'chao')
    detail = decals()
    for target in (ART,RUNTIME):
        path=target/'kit.json'
        kit=json.loads(path.read_text(encoding='utf-8'))
        kit['materials']['grama']=grass
        kit['decals']=detail
        path.write_text(json.dumps(kit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    for folder in ('chao','decalques'):
        (RUNTIME/folder).mkdir(exist_ok=True)
        for file in (ART/folder).iterdir():
            if folder=='decalques' or file.name.startswith('grama-'):
                shutil.copy2(file,RUNTIME/folder/file.name)
    validate()


if __name__=='__main__':build()

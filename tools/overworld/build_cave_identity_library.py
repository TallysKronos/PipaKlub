"""Generated cave paintings -> exact modular geometry, pivots and Godot scenes.
No campaign edits. Raster operations only crop/scale/project/normalize sources.
"""
from pathlib import Path
import json,shutil
import numpy as np
from PIL import Image,ImageDraw
from build_terrain_library import periodic,variants,project,panel,corner,termination,MASKS,port_report,mosaic
from build_urban_library import write,font

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/cavernas-v2'
GAME=ROOT/'godot/assets/overworld/kits/cavernas-v2'
REVIEW=ROOT/'documentation/overworld/cavernas-v2'

def save(im,path):
    for base in [ART,GAME]:
        dest=base/path;dest.parent.mkdir(parents=True,exist_ok=True);im.save(dest)

def build():
    REVIEW.mkdir(parents=True,exist_ok=True)
    specs=json.loads((ART/'briefs.json').read_text(encoding='utf-8-sig'))['assets']
    manifest={'schema':'cave-library-2','grid':[64,32],'levelPx':64,'campaignIntegrated':False,'collision':'not-authored','approval':'owner-review-pending','floors':{},'walls':{},'props':{},'waterArt':{}}
    report={'geometry':port_report(),'materials':[],'props':[]}
    for s in specs:
        id=s['id'];kind=s['kind'];im=Image.open(ART/f'fontes/{id}.png').convert('RGBA')
        if kind=='prop':
            bbox=im.getbbox()
            if not bbox:raise ValueError('Empty source '+id)
            alpha=np.asarray(im)[:,:,3]
            if alpha.min()==255:raise ValueError('Missing real transparency '+id)
            cropped=im.crop(bbox);height=round(cropped.height*s['width']/cropped.width)
            cropped=cropped.resize((s['width'],height),Image.Resampling.LANCZOS)
            output=Image.new('RGBA',(s['width']+16,height+16));output.alpha_composite(cropped,(8,8))
            file=f'props/{id}.png';save(output,file)
            pixels=np.asarray(output)[:,:,3];ys,xs=np.where(pixels>80)
            # Depth anchor is the bottom footprint, never the sprite centre.
            bottom=int(ys.max());near=xs[ys>=bottom-4];pivot=[round(float(np.median(near)),2),bottom]
            manifest['props'][id]={'name':s['name'],'file':file,'size':list(output.size),'pivot':pivot,'footprintCells':[2,2] if s['width']>90 else [1,1],'collision':'none-provisional-footprint','source':f'fontes/{id}.png'}
            scene=f'''[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path="res://assets/overworld/kits/cavernas-v2/{file}" id="1"]\n\n[node name="{id}" type="Node2D"]\n\n[node name="Visual" type="Sprite2D" parent="."]\ntexture_filter = 1\ntexture = ExtResource("1")\ncentered = false\nposition = Vector2({-pivot[0]}, {-pivot[1]})\n'''
            dest=ROOT/f'godot/scenes/overworld/caves-v2/props/{id}.tscn';dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(scene,encoding='utf-8')
            report['props'].append({'id':id,'size':list(output.size),'realAlpha':True,'pivot':pivot})
            continue
        surface=periodic(im,512);save(Image.fromarray(surface),f'surfaces/{id}.png')
        report['materials'].append({'id':id,'xBoundaryError':int(np.abs(surface[:,0].astype(int)-surface[:,-1]).max()),'yBoundaryError':int(np.abs(surface[0].astype(int)-surface[-1]).max())})
        if kind in ['water','fall']:
            manifest['waterArt'][id]={'name':s['name'],'kind':kind,'surface':f'surfaces/{id}.png'}
            continue
        if kind=='floor':
            textures=variants(im);atlas=Image.new('RGBA',(512,224));tiles=[];centers=[];tile_images={}
            for i,m in enumerate(MASKS):
                tile=project(textures[0],m);tile_images[m]=tile;file=f'tiles/{id}/blob-{m:03}.png';save(tile,file)
                atlas.alpha_composite(tile,((i%8)*64,(i//8)*32));tiles.append({'mask':m,'file':file,'atlas':[i%8,i//8]})
            for i,rgb in enumerate(textures):
                tile=project(rgb);file=f'tiles/{id}/centro-{i}.png';save(tile,file);atlas.alpha_composite(tile,(i*64,192));centers.append({'file':file,'atlas':[i,6]})
            save(atlas,f'atlas/{id}.png')
            manifest['floors'][id]={'name':s['name'],'atlas':f'atlas/{id}.png','tiles':tiles,'centers':centers,'surface':f'surfaces/{id}.png'}
            uv=Image.new('RGB',(512,512))
            for y in range(8):
                for x in range(8):uv.paste(Image.fromarray(textures[(x*3+y*5)%8]),(x*64,y*64))
            uv.save(REVIEW/f'{id}-repeticao-8x8.png')
            layout=[[int(0<x<9 and 0<y<9 and not(x>5 and y>5) and not(x==3 and y==3)) for x in range(10)] for y in range(10)]
            mosaic(tile_images,layout).save(REVIEW/f'{id}-encaixes.png')
        else:
            files=[]
            for side in ['u','v']:
                for phase in range(4):
                    file=f'walls/{id}/{side}-{phase}.png';save(panel(surface,side,phase),file);files.append({'file':file,'role':'face','side':side,'phase':phase})
            for inner in [False,True]:
                for phase in range(2):
                    file=f'walls/{id}/canto-{"interno" if inner else "externo"}-{phase}.png';save(corner(surface,inner,phase),file);files.append({'file':file,'role':'inner-corner' if inner else 'outer-corner'})
            for side in ['u','v']:
                for end in [False,True]:
                    file=f'walls/{id}/{side}-{"fim" if end else "inicio"}.png';save(termination(surface,side,end),file);files.append({'file':file,'role':'termination'})
            manifest['walls'][id]={'name':s['name'],'surface':f'surfaces/{id}.png','files':files,'height':64}
    write(ART/'library.json',manifest);write(GAME/'library.json',manifest);write(REVIEW/'preparacao.json',report)
    board=Image.new('RGB',(1440,90+330*((len(specs)+3)//4)),'#19262D');d=ImageDraw.Draw(board)
    d.text((25,18),'GRUTA DOS ELOS · SOULMONSTERS · REVISÃO FLAT',font=font(31),fill='#E6D8B3')
    for i,s in enumerate(specs):
        x=20+(i%4)*355;y=85+(i//4)*330
        if s['kind']=='floor':src=Image.open(REVIEW/f"{s['id']}-encaixes.png")
        elif s['kind']=='wall':src=Image.open(ART/f"walls/{s['id']}/canto-externo-0.png").resize((192,288),Image.Resampling.NEAREST)
        elif s['kind']=='prop':src=Image.open(ART/f"props/{s['id']}.png")
        else:src=Image.open(ART/f"surfaces/{s['id']}.png")
        src=src.convert('RGBA');src.thumbnail((330,250),Image.Resampling.LANCZOS);board.paste(src,(x+(330-src.width)//2,y+250-src.height),src)
        d.text((x+10,y+263),s['name'],font=font(22),fill='#E6D8B3')
        d.text((x+10,y+293),{'floor':'47 encaixes + 8 centros','wall':'16 faces, cantos e tampas','prop':'Sprite recortado + pivô','water':'Pintura para água animada','fall':'Pintura para cortina animada'}[s['kind']],font=font(15),fill='#A3B6BA')
    board.save(REVIEW/'CATALOGO-CAVERNAS.png')
    print('4 floors ×55 + 4 walls ×16 + 8 props = 292 cutouts; plus 2 animated water paintings.')

if __name__=='__main__':build()

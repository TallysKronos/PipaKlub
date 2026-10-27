"""PIP-85: exact ground samples and normalized park sprites; source paintings retained."""
from pathlib import Path
import json,shutil,base64
import numpy as np
from PIL import Image,ImageDraw
from build_art import kit,shadow,studio,scale_board
from collections import deque
from build_morro_floors import periodic,project,save_tile
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/parque'
RUNTIME=ROOT/'godot/assets/overworld/kits/parque'
MATERIALS=['grama','terra','mato','piso','bosque']

def write(p,data):
    p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')

def main():
    for name in ['chao','superficies','transicoes','pecas','decalques','sombras']:(ART/name).mkdir(parents=True,exist_ok=True)
    k=kit('parque');shadow(ART)
    k.update({'issue':'PIP-85','approval':'volume_revision_pending_owner_review','surfaceShader':'res://shaders/parque_ground.gdshader','surfaceAtlas':'superficies/atlas.png','surfaceOrder':MATERIALS,'context':{'radius':8,'color':'6B894B','houses':False,'asset':'arvore','automaticTrees':False,'authoredTrees':[[9.5,-.5],[19.5,-.5]]},'encounterGrass':{'files':['decalques/capim-a.png','decalques/capim-b.png'],'anchor':[26,45],'size':[52,48],'shader':'res://shaders/parque_grass.gdshader'}})
    # All foliage is upright artwork on separate depth-sorted nodes. No leaf
    # canopy is ever sampled into a floor polygon or the context ground plane.
    border=[[u+.5,15.5] for u in range(1,24,2)]+[[.5,v+.5] for v in range(3,15,2)]+[[23.5,v+.5] for v in range(3,15,2)]+[[u+.5,2.0] for u in range(1,24,2)]+[[4.5,.5],[10.5,.5],[17.5,.5],[22.5,.5]]
    k['boundaryShrubs']={'points':border,'anchor':[48,45],'files':['decalques/arbusto-baixo-a.png','decalques/arbusto-baixo-b.png'],'role':'upright low shrub props, separate contact shadows; only inside blocked bosque; no new blockers'}
    sources={'grama':'canteiro','terra':'terra','piso':'calcada-placas'}
    surfaces={}
    for name,source in sources.items():
        source_file=ROOT/f'art/overworld/kits/bairro/fontes/pisos-v2/{source}.png'
        target=ART/f'fontes/{name}.png';shutil.copy2(source_file,target)
        surfaces[name]=periodic(Image.open(target))
    for name,tint in [('mato',(.72,.85,.73)),('bosque',(.54,.68,.59))]:
        surfaces[name]=Image.fromarray(np.clip(np.asarray(surfaces['grama'])*np.array(tint),0,255).astype('uint8'))
    atlas=Image.new('RGB',(512*5,512));samples={}
    for i,name in enumerate(MATERIALS):
        surface=surfaces[name];surface.save(ART/f'superficies/{name}.png');atlas.paste(surface,(512*i,0));samples[name]=[]
        for variant,(u,v) in enumerate([(0,0),(2,1),(5,3),(3,6)]):
            tile=project(surface,u,v);samples[name].append(tile);save_tile(tile,ART/f'chao/{name}-{variant}')
        k['materials'][name]={'variants':[f'chao/{name}-{i}.png' for i in range(4)],'size':[64,32],'surfaceIndex':i,'repeatCells':8,'source':f'fontes/{name if name in sources else "grama"}.png','derivation':'original floor family restored; periodic seam normalization; base tint only for mato/bosque'}
    atlas.save(ART/'superficies/atlas.png')
    yy,xx=np.mgrid[:32,:64];u=np.clip((xx+.5)/64+(yy+.5)/32-.5,0,1);v=np.clip((yy+.5)/32-(xx+.5)/64+.5,0,1)
    weights=[(1-u)*(1-v),u*(1-v),u*v,(1-u)*v]
    for a,b in [('bosque','grama'),('grama','terra'),('grama','mato'),('grama','piso'),('mato','terra'),('piso','terra'),('bosque','terra'),('mato','piso')]:
        files=[];first=np.array(samples[a][0]);second=np.array(samples[b][0])
        for mask in range(16):
            amount=sum(weights[bit] for bit in range(4) if mask&(1<<bit)) if mask else np.zeros_like(u)
            im=Image.fromarray(np.where((amount>=.5)[:,:,None],second,first));file=f'transicoes/{a}-{b}-{mask}.png';im.save(ART/file);files.append(file)
        k['transitions'][f'{a}/{b}']={'files':files,'size':[64,32],'bits':['top','right','bottom','left']}
    # Uniform normalization only; the painting itself is generated, not redrawn.
    for name,size,anchor in [('coreto',(280,304),(140,236)),('capim-a',(52,48),(26,45)),('capim-b',(52,48),(26,45))]:
        file=ART/f'fontes/{name}.png'
        if not file.exists():raise FileNotFoundError(file)
        source=Image.open(file).convert('RGBA')
        if name.startswith('capim'):
            # Cutout alpha normalization removes the generated translucent halo;
            # the original RGB painting and original file remain untouched.
            source.putalpha(source.getchannel('A').point(lambda a:0 if a<192 else 255))
        box=source.getchannel('A').point(lambda a:255 if a>24 else 0).getbbox()
        if not box:raise ValueError(f'{name}: no visible alpha')
        source=source.crop(box)
        if name=='coreto':
            guide=Image.open(ART/'fontes/coreto-guia.png').convert('RGBA');target=guide.getchannel('A').getbbox()
        else:target=(2,2,size[0]-2,anchor[1]+1)
        scale=min((target[2]-target[0])/source.width,(target[3]-target[1])/source.height)
        source=source.resize((round(source.width*scale),round(source.height*scale)),Image.Resampling.LANCZOS)
        out=Image.new('RGBA',size);out.alpha_composite(source,((size[0]-source.width)//2,target[3]-source.height))
        folder='pecas' if name=='coreto' else 'decalques';out.save(ART/f'{folder}/{name}.png')
        if name=='coreto':
            k['pieces']['coreto']={'default':'default','variants':{'default':{'file':'pecas/coreto.png','size':list(size),'footprint':[4,4],'visualFootprint':[4,4],'bloqueia':False,'height':6,'anchor':list(anchor),'isoAnchor':[128,304],'shadow':'sombras/contato.png','source':{'generator':'image_gen.imagegen','file':'fontes/coreto.png','guide':'fontes/coreto-guia.svg','normalization':'uniform fit to architectural guide alpha bounds'},'collision':'five separate coreto-pilar map pieces','approval':'pending_visual_review'}}}
            mask=Image.new('L',size);ImageDraw.Draw(mask).polygon([(0,0),(280,0),(280,128),(140,185),(0,128)],fill=255)
            rgba=np.asarray(out).copy();alpha=rgba[:,:,3].astype('uint16');roof=rgba.copy();pillars=rgba.copy();m=np.asarray(mask).astype('uint16')
            roof[:,:,3]=(alpha*m//255).astype('uint8');pillars[:,:,3]=(alpha*(255-m)//255).astype('uint8')
            Image.fromarray(roof).save(ART/'pecas/coreto-telhado.png');Image.fromarray(pillars).save(ART/'pecas/coreto-pilares.png')
            k['pieces']['coreto']['variants']['default'].update({'roofFile':'pecas/coreto-telhado.png','supportsFile':'pecas/coreto-pilares.png'})
            # Split disconnected visible pillars for individual ground-depth sorting.
            seen=set();parts=[];valid=pillars[:,:,3]>24
            for y,x in zip(*np.where(valid)):
                if (x,y) in seen:continue
                queue=deque([(x,y)]);seen.add((x,y));pixels=[]
                while queue:
                    xx,yy=queue.popleft();pixels.append((xx,yy))
                    for nx,ny in [(xx-1,yy),(xx+1,yy),(xx,yy-1),(xx,yy+1)]:
                        if 0<=nx<size[0] and 0<=ny<size[1] and valid[ny,nx] and (nx,ny) not in seen:seen.add((nx,ny));queue.append((nx,ny))
                if len(pixels)<35:continue
                layer=np.zeros_like(pillars)
                for xx,yy in pixels:layer[yy,xx]=pillars[yy,xx]
                bottom=max(yy for xx,yy in pixels);feet=[xx for xx,yy in pixels if yy>=bottom-2]
                file=f'pecas/coreto-pilar-{len(parts)}.png';Image.fromarray(layer).save(ART/file)
                parts.append({'file':file,'foot':[int(round(sum(feet)/len(feet))),int(bottom)]})
            k['pieces']['coreto']['variants']['default']['supportParts']=parts
    # The biome owns smaller, tightly framed copies of the shared tree family.
    # Cropping empty source margins also makes occlusion match visible artwork.
    common=json.loads((ROOT/'art/overworld/kits/comum/kit.json').read_text(encoding='utf-8'))
    tree_variants={}
    for variant in ['a','b','florida']:
        old=common['pieces']['arvore']['variants'][variant]
        src=ROOT/'art/overworld/kits/comum'/old['file'];im=Image.open(src).convert('RGBA')
        bbox=im.getchannel('A').point(lambda a:255 if a>24 else 0).getbbox();im=im.crop(bbox)
        height=144 if variant=='florida' else 132
        scale=height/im.height;im=im.resize((round(im.width*scale),height),Image.Resampling.LANCZOS)
        anchor=[round((old['anchor'][0]-bbox[0])*scale),round((old['anchor'][1]-bbox[1])*scale)]
        file=f'pecas/arvore-{variant}.png';im.save(ART/file)
        tree_variants[variant]={'file':file,'size':list(im.size),'footprint':[1,1],'visualFootprint':[3,3],'height':5,'bloqueia':True,'anchor':anchor,'shadow':'sombras/contato.png','source':{'file':str(src.relative_to(ROOT)).replace('\\','/'),'normalization':'alpha crop and uniform rescale; source retained'},'foliageQuiet':True}
    k['pieces']['arvore']={'default':'a','variants':tree_variants}
    for name in ['arbusto-baixo-a','arbusto-baixo-b']:
        im=Image.open(ART/f'fontes/{name}.png').convert('RGBA');im.putalpha(im.getchannel('A').point(lambda a:0 if a<180 else 255))
        im=im.crop(im.getchannel('A').getbbox());scale=min(92/im.width,43/im.height)
        im=im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.LANCZOS)
        canvas=Image.new('RGBA',(96,48));canvas.alpha_composite(im,((96-im.width)//2,46-im.height));canvas.save(ART/f'decalques/{name}.png')
    write(ART/'kit.json',k);studio(k);scale_board(k)
    RUNTIME.mkdir(parents=True,exist_ok=True)
    for folder in ['chao','superficies','transicoes','pecas','decalques','sombras']:shutil.copytree(ART/folder,RUNTIME/folder,dirs_exist_ok=True)
    write(RUNTIME/'kit.json',k)
    print('Parque: 20 samples, 128 transitions, continuous surface atlas, coreto and two wind grass cutouts.')

if __name__=='__main__':main()

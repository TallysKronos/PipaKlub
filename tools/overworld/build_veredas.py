"""PIP-86 pilot. Normalize generated paintings into exact source-map geometry."""
from pathlib import Path
import json,shutil
import numpy as np
from PIL import Image,ImageDraw
from build_art import kit,shadow,studio,scale_board
from build_morro_floors import periodic,project,save_tile
from build_morro_walls import face
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/veredas'
RUNTIME=ROOT/'godot/assets/overworld/kits/veredas'
ORDER=['grama','terra','mato','piso','agua','ponte','bosque']
def write(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def main():
    for name in ['chao','superficies','transicoes','pecas','sombras','muros','pontes','decalques']:(ART/name).mkdir(parents=True,exist_ok=True)
    k=kit('veredas');shadow(ART)
    k.update({'issue':'PIP-86','approval':'pilot_pending_visual_review','surfaceShader':'res://shaders/veredas_ground.gdshader','surfaceAtlas':'superficies/atlas.png','surfaceOrder':ORDER,'context':{'radius':3,'color':'586841','houses':False,'automaticTrees':False},'encounterGrass':{'files':['decalques/capim-a.png','decalques/capim-b.png'],'anchor':[26,45],'shader':'res://shaders/parque_grass.gdshader'}})
    lawn=periodic(Image.open(ART/'fontes/grama.png'))
    # Palette normalization only. Source painting remains untouched; there is
    # no flat canopy, and no change to the approved Parque floor family.
    lawn=Image.fromarray(np.clip(np.asarray(lawn)*[.96,1,.95],0,255).astype('uint8'))
    surfaces={'grama':lawn,'terra':periodic(Image.open(ART/'fontes/terra.png')),'piso':periodic(Image.open(ART/'fontes/patio.png')),'agua':periodic(Image.open(ART/'fontes/agua.png')),'ponte':periodic(Image.open(ART/'fontes/madeira.png'))}
    water=np.asarray(surfaces['agua']).astype(float);mean=water.mean(axis=(0,1))
    surfaces['agua']=Image.fromarray(np.clip(mean+(water-mean)*.72,0,255).astype('uint8'))
    for name,tint in [('mato',(.82,.88,.73)),('bosque',(.64,.73,.64))]:surfaces[name]=Image.fromarray(np.clip(np.asarray(lawn)*tint,0,255).astype('uint8'))
    atlas=Image.new('RGB',(512*len(ORDER),512));samples={}
    for index,name in enumerate(ORDER):
        surface=surfaces[name];surface.save(ART/f'superficies/{name}.png');atlas.paste(surface,(512*index,0));samples[name]=[]
        for variant,(u,v) in enumerate([(0,0),(2,1),(5,3),(3,6)]):
            tile=project(surface,u,v);samples[name].append(tile);save_tile(tile,ART/f'chao/{name}-{variant}')
        k['materials'][name]={'variants':[f'chao/{name}-{n}.png' for n in range(4)],'size':[64,32],'surfaceIndex':index,'repeatCells':8}
    atlas.save(ART/'superficies/atlas.png')
    # Exact mask samples for the Studio; native renderer uses world UVs and
    # the same shared corner materials, with a solid unbroken diamond polygon.
    yy,xx=np.mgrid[:32,:64];u=np.clip((xx+.5)/64+(yy+.5)/32-.5,0,1);v=np.clip((yy+.5)/32-(xx+.5)/64+.5,0,1)
    weights=[(1-u)*(1-v),u*(1-v),u*v,(1-u)*v]
    pairs=[('grama','terra'),('bosque','grama'),('grama','mato'),('bosque','piso'),('agua','grama'),('bosque','terra'),('agua','ponte'),('grama','piso'),('grama','ponte'),('piso','terra'),('agua','bosque'),('mato','terra'),('mato','piso')]
    for a,b in pairs:
        files=[]
        for mask in range(16):
            amount=sum(weights[bit] for bit in range(4) if mask&(1<<bit)) if mask else np.zeros_like(u)
            im=Image.fromarray(np.where((amount>=.5)[:,:,None],np.asarray(samples[b][0]),np.asarray(samples[a][0])))
            file=f'transicoes/{a}-{b}-{mask}.png';im.save(ART/file);files.append(file)
        k['transitions'][a+'/'+b]={'files':files,'size':[64,32],'bits':['top','right','bottom','left']}
    wall_surface=periodic(Image.open(ART/'fontes/arenito.png'));wall_surface.save(ART/'superficies/barranco.png')
    k['walls']['pedra']={}
    for side in ['u','v']:
        files=[]
        for variant in range(2):
            file=f'muros/arenito-{side}-{variant}.png';face(wall_surface,side,variant).save(ART/file);files.append(file)
        k['walls']['pedra'][side]=files
    k['wallSurfaces']={'pedra':{'file':'superficies/barranco.png','repeatTexelsPerCell':[96,160]}}
    k['rampGeometry']={'directions':['u+','u-','v+','v-'],'source':'source map rampa_comprimento; compiled cell.rampFrom/rampTo; map_model.height_at','runCells':4,'topMaterial':'terra','cheekMaterial':'superficies/barranco.png','levelPx':64,'rasterNotStretched':True}
    for axis in ['u','v']:
        tile=project(surfaces['ponte']);tile.save(ART/f'pontes/tabuleiro-{axis}.png')
        k['bridges'][axis]={'file':f'pontes/tabuleiro-{axis}.png','axis':axis,'footprint':[1,1],'surface':'superficies/ponte.png','geometry':'continuous source-cell deck; native exposed beams and end supports'}
    im=Image.open(ART/'fontes/buriti.png').convert('RGBA');im=im.crop(im.getchannel('A').point(lambda a:255 if a>24 else 0).getbbox())
    height=172;im=im.resize((round(im.width*height/im.height),height),Image.Resampling.LANCZOS);im.save(ART/'pecas/buriti.png')
    entry={'file':'pecas/buriti.png','size':list(im.size),'footprint':[1,1],'visualFootprint':[2,2],'height':6,'bloqueia':True,'anchor':[im.width//2,im.height-2],'shadow':'sombras/contato.png','source':{'file':'fontes/buriti.png','generator':'image_gen.imagegen','normalization':'alpha crop; uniform rescale'},'approval':'pending_native_visual_review'}
    # Variant names preserve source-map objects and blockers. Different canopy
    # silhouettes are not scattered as new navigation obstacles.
    common=json.loads((ROOT/'art/overworld/kits/comum/kit.json').read_text(encoding='utf-8'))
    old=common['pieces']['arvore']['variants']['b']
    original=Image.open(ROOT/'art/overworld/kits/comum'/old['file']).convert('RGBA')
    box=original.getchannel('A').point(lambda a:255 if a>24 else 0).getbbox();small=original.crop(box)
    factor=108/small.height;small=small.resize((round(small.width*factor),108),Image.Resampling.LANCZOS);small.save(ART/'pecas/arvore-cerrado.png')
    cerrado={**entry,'file':'pecas/arvore-cerrado.png','size':list(small.size),'anchor':[round((old['anchor'][0]-box[0])*factor),round((old['anchor'][1]-box[1])*factor)],'foliageQuiet':True,'source':{'file':'../comum/'+old['file'],'normalization':'alpha crop and uniform scale'}}
    k['pieces']['arvore']={'default':'a','variants':{'a':entry,'b':entry,'cerrado':cerrado}}
    k['treeMix']=['a','a','cerrado','a']
    k['pieces']['buriti']={'default':'a','variants':{'a':entry}}
    for name,size,anchor in [('capim-margem',(68,52),(34,49)),('canos-patio',(128,104),(64,97))]:
        image=Image.open(ART/f'fontes/{name}.png').convert('RGBA')
        image.putalpha(image.getchannel('A').point(lambda a:0 if a<100 else a))
        image=image.crop(image.getchannel('A').point(lambda a:255 if a>24 else 0).getbbox())
        scale=min((size[0]-4)/image.width,(anchor[1]-2)/image.height)
        image=image.resize((round(image.width*scale),round(image.height*scale)),Image.Resampling.LANCZOS)
        canvas=Image.new('RGBA',size);canvas.alpha_composite(image,((size[0]-image.width)//2,anchor[1]-image.height))
        file=f'pecas/{name}.png';canvas.save(ART/file)
        k['pieces'][name]={'default':'a','variants':{'a':{'file':file,'size':list(size),'anchor':list(anchor),'footprint':[1,1],'visualFootprint':[2,1],'height':3,'bloqueia':False,'shadow':'sombras/contato.png','source':{'file':f'fontes/{name}.png','generator':'image_gen.imagegen','normalization':'alpha crop and uniform fit'},'approval':'pending_visual_review'}}}
    # Sparse decoration candidates from actual material adjacency. No terrain,
    # original blockers, events or reward locations are moved by the kit.
    k['dressing']={}
    for area in ['veredas-piloto','veredas-do-encanamento']:
        data=json.loads((ROOT/f'godot/assets/overworld/maps/{area}.json').read_text(encoding='utf-8'))
        occupied={(p['u'],p['v']) for p in data['pieces']}|{(e['u'],e['v']) for e in data['events']}
        points=[]
        for i,cell in enumerate(data['cells']):
            u,v=i%data['w'],i//data['w'];seed=(u*137+v*71+u*v*13)%101
            if (u,v) in occupied or cell['material'] not in ['grama','bosque'] or cell.get('ramp'):continue
            neighbors=[data['cells'][vv*data['w']+uu] for uu,vv in [(u-1,v),(u+1,v),(u,v-1),(u,v+1)] if 0<=uu<data['w'] and 0<=vv<data['h']]
            bank=any(n['material']=='agua' for n in neighbors)
            border=cell['material']=='bosque' and any(n['material']=='grama' for n in neighbors)
            if not ((bank and seed<45) or (border and seed<16)):continue
            points.append({'asset':'capim-margem','point':[u+.5,v+.5],'footprint':[1,1],'role':'visual_only_bank' if bank else 'visual_only_woodland_edge'})
        if area=='veredas-do-encanamento':
            points += [{'asset':'canos-patio','point':p,'footprint':[1,1],'role':'visual_only_existing_blocked_courtyard_edge'} for p in [[43.5,1.5],[47.5,2.5]]]
        k['dressing'][area]=points
    for name in ['capim-a','capim-b']:
        shutil.copy2(ROOT/f'art/overworld/kits/parque/decalques/{name}.png',ART/f'decalques/{name}.png')
    write(ART/'kit.json',k);studio(k);scale_board(k)
    RUNTIME.mkdir(parents=True,exist_ok=True)
    for folder in ['chao','superficies','transicoes','pecas','sombras','muros','pontes','decalques']:shutil.copytree(ART/folder,RUNTIME/folder,dirs_exist_ok=True)
    write(RUNTIME/'kit.json',k)
    print('Veredas pilot: 28 floor samples, 208 transition masks, sandstone banks, buriti and bridge materials.')
if __name__=='__main__':main()

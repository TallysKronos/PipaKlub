"""Original 2D kit sources + deterministic normalization; no painted map geometry.
Python/Pillow. AI paintings stay unchanged in fontes; exact terrain is code-native.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json, math, base64, io, shutil
from collections import deque
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld'; KITS=ART/'kits'
INK='#26394D'; PAPER='#F5E9CB'

class Canvas:
    def __init__(self,w,h):
        self.im=Image.new('RGBA',(int(w),int(h)));self.d=ImageDraw.Draw(self.im)
        self.svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">']
    def poly(self,pts,c,stroke=INK,sw=1):
        self.d.polygon(pts,fill=c)
        if stroke:self.d.line(pts+[pts[0]],fill=stroke,width=sw,joint='curve')
        self.svg.append(f'<polygon points="{" ".join(f"{x:.3f},{y:.3f}" for x,y in pts)}" fill="{c}" stroke="{stroke or "none"}" stroke-width="{sw}" stroke-linejoin="round"/>')
    def line(self,pts,c=INK,sw=1):
        self.d.line(pts,fill=c,width=sw)
        self.svg.append(f'<polyline points="{" ".join(f"{x:.3f},{y:.3f}" for x,y in pts)}" fill="none" stroke="{c}" stroke-width="{sw}"/>')
    def ellipse(self,box,c,stroke=INK,sw=1):
        self.d.ellipse(box,fill=c,outline=stroke,width=sw)
        x,y,x1,y1=box;self.svg.append(f'<ellipse cx="{(x+x1)/2}" cy="{(y+y1)/2}" rx="{(x1-x)/2}" ry="{(y1-y)/2}" fill="{c}" stroke="{stroke or "none"}" stroke-width="{sw}"/>')
    def save(self,path):
        path.parent.mkdir(parents=True,exist_ok=True);self.im.save(path.with_suffix('.png'))
        path.with_suffix('.svg').write_text('\n'.join(self.svg+['</svg>']),encoding='utf-8')

def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,obj):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def clean_alpha(im):
    im=im.convert('RGBA');im.putalpha(im.getchannel('A').point(lambda v:0 if v<=8 else v));return im
def slot(sheet,i,columns,rows):
    im=clean_alpha(Image.open(sheet));col=i%columns;row=i//columns
    crop=im.crop((round(col*im.width/columns),round(row*im.height/rows),round((col+1)*im.width/columns),round((row+1)*im.height/rows)))
    # Ignore slivers from neighbouring slots by finding the main connected
    # silhouette. Keep original paint/alpha within that source bounding box.
    aa=crop.getchannel('A');ww,hh=crop.size
    pixels=bytearray(1 if v>32 else 0 for v in aa.get_flattened_data())
    largest=[]
    for seed in range(len(pixels)):
        if not pixels[seed]:continue
        pixels[seed]=0;q=deque([seed]);component=[]
        while q:
            n=q.popleft();component.append(n);x=n%ww;y=n//ww
            for dy in [-1,0,1]:
                for dx in [-1,0,1]:
                    xx=x+dx;yy=y+dy
                    if 0<=xx<ww and 0<=yy<hh:
                        j=yy*ww+xx
                        if pixels[j]:pixels[j]=0;q.append(j)
        if len(component)>len(largest):largest=component
    bbox=(max(0,min(n%ww for n in largest)-1),max(0,min(n//ww for n in largest)-1),min(ww,max(n%ww for n in largest)+2),min(hh,max(n//ww for n in largest)+2)) if largest else None
    if not bbox:raise ValueError(f'Slot vazio {sheet}:{i}')
    return crop.crop(bbox),{'file':str(sheet.relative_to(ROOT)).replace('\\','/'),'slot':i,'grid':[columns,rows],'alpha_bbox':bbox}

def kit(name):return {'schema':'overworld-kit-1','biome':name,'grid':{'cell':[64,32],'height':32,'levelPx':64},'approval':'pending_owner_review','styleBoard':'../../estilo/PRANCHA-ESTILO.png','pieces':{},'materials':{},'transitions':{},'walls':{},'stairs':{},'bridges':{}}
def shadow(dir,w=64,h=32):
    c=Canvas(w,h);c.poly([(w*.2,h*.3),(w*.68,h*.12),(w*.88,h*.5),(w*.42,h*.77)],'#26394D33',None);c.save(dir/'sombras/contato')

def pack_prop(k,asset,variant,image,height,foot=(1,1),blocks=True,visual=None,source=None):
    directory=KITS/k['biome'];visual=visual or foot
    # Studio volume and navigation footprint are separate. Foliage can overhang
    # the trunk collision without expanding the walkable-map blocker.
    vu,vv=visual;w=(vu+vv)*32;floor_h=(vu+vv)*16
    cells=math.ceil((height+floor_h/2)/32)
    h=cells*32+floor_h;anchor=[w//2,round(h-floor_h/2)]
    image=clean_alpha(image);image=image.crop(image.getchannel('A').getbbox())
    scale=min(height/image.height,(w-4)/image.width)
    size=(max(1,round(image.width*scale)),max(1,round(image.height*scale)))
    tile=Image.new('RGBA',(w,h));tile.alpha_composite(image.resize(size,Image.Resampling.LANCZOS),(anchor[0]-size[0]//2,anchor[1]-size[1]))
    name=f'{asset}-{variant}';dest=directory/'pecas'/f'{name}.png';dest.parent.mkdir(parents=True,exist_ok=True);tile.save(dest)
    entry={'file':f'pecas/{name}.png','size':[w,h],'footprint':list(foot),'visualFootprint':list(visual),'bloqueia':blocks,'height':cells,'anchor':anchor,'isoAnchor':[vu*32,h],'shadow':'sombras/contato.png','source':source,'rasterSize':list(size),'approval':'pending_owner_review'}
    group=k['pieces'].setdefault(asset,{'default':variant,'variants':{}});group['variants'][variant]=entry
    return entry

def common():
    k=kit('comum');shadow(KITS/'comum')
    s1=KITS/'comum/fontes/familia-1.png';s2=KITS/'comum/fontes/familia-2.png'
    base=ART/'estilo/fontes/manga-v2'
    specs=[('arvore','a',base/'arvore-fonte.png',160,(1,1),(3,3),True),('banco','madeira',base/'banco-fonte.png',56,(2,1),(2,1),False),('poste','ferro',base/'poste-fonte.png',144,(1,1),(1,1),True)]
    for asset,var,file,hh,foot,vis,block in specs:pack_prop(k,asset,var,Image.open(file),hh,foot,block,vis,{'file':str(file.relative_to(ROOT)).replace('\\','/')})
    specs1=[('arvore','b',160,(1,1),(3,3),True),('arvore','florida',160,(1,1),(3,3),True),('arvore','tronco-largo',160,(1,1),(3,3),True),('banco','concreto',56,(2,1),(2,1),False),('poste','rua',160,(1,1),(2,2),True),('placa-mapa','parque',88,(2,1),(2,2),False),('placa-mapa','veredas',88,(1,1),(2,2),False),('vaso','ceramica',50,(1,1),(1,1),True),('vaso','pneu',36,(1,1),(1,1),True)]
    specs2=[('lixeira','parque',48,(1,1),True),('lixeira','rua',48,(1,1),True),('flores','coral',24,(1,1),False),('flores','amarela',24,(1,1),False),('flores','azul',24,(1,1),False),('bau','fechado',40,(1,1),True),('bau','aberto',48,(1,1),True),('biruta','default',128,(1,1),False),('pipa-presa','default',56,(1,1),False)]
    for i,(asset,var,hh,foot,vis,block) in enumerate(specs1):
        image,src=slot(s1,i,3,3);pack_prop(k,asset,var,image,hh,foot,block,vis,src)
    for i,(asset,var,hh,foot,block) in enumerate(specs2):
        image,src=slot(s2,i,3,3);pack_prop(k,asset,var,image,hh,foot,block,foot,src)
    # Large tree shares the same drawing family, not a separately generated tree.
    image,src=slot(s1,2,3,3)
    pack_prop(k,'arvore-grande','default',image,208,(2,2),True,(4,4),src)
    for n in range(3):
        c=Canvas(64,96);c.poly([(18,77),(12,66),(23,51+n*2),(40,54),(50,68),(42,79),(28,83)],'#AD9D88')
        c.poly([(12,66),(23,51+n*2),(40,54),(29,65)],'#D5C9AD')
        pack_prop(k,'pedra',str(n),c.im,30,(1,1),True,(1,1),{'generator':'tools/overworld/build_art.py'})
    for axis in ['u','v']:
        c=Canvas(64,32);c.poly(DIAMOND,'#BC8A55',INK)
        pp=lambda u,v:(32+(u-v)*32,(u+v)*16)
        for t in [.2,.4,.6,.8]:c.line([pp(t,0),pp(t,1)] if axis=='u' else [pp(0,t),pp(1,t)],'#775340')
        file=f'pontes/tabuleiro-{axis}';c.save(KITS/'comum'/file)
        k['bridges'][axis]={'file':file+'.png','axis':axis,'footprint':[1,1]}
        c=Canvas(64,32);c.poly(DIAMOND,'#8AAE62',None)
        c.poly([(32,0),(64,16),(32,32),(24,20)],'#BC8A55',INK)
        file=f'pontes/cabeceira-{axis}';c.save(KITS/'comum'/file)
        k['bridges'][axis]['head']=file+'.png'
    write(KITS/'comum/kit.json',k);return k

def architecture(k,variant,fu=3,fv=3):
    directory=KITS/'morro';height=7;w=(fu+fv)*32;h=height*32+(fu+fv)*16
    c=Canvas(w,h)
    def p(u,v,z=0):return ((fv+u-v)*32,height*32+(u+v)*16-z)
    def face(vertices,color):c.poly([p(*v) for v in vertices],color,INK,2)
    a,b=.16,2.84;z=128
    light,dark=('#E7C295','#BA9272') if variant=='telha' else ('#EB916C','#BA6759') if variant=='laje' else ('#E8CA82','#B49F70')
    face([(a,b,0),(b,b,0),(b,b,z),(a,b,z)],dark)
    face([(b,a,0),(b,b,0),(b,b,z),(b,a,z)],light)
    # Door and window stay on exact projected wall planes.
    face([(.55,b,0),(1.35,b,0),(1.35,b,96),(.55,b,96)],'#245C78')
    c.line([p(.95,b,0),p(.95,b,96)],INK,2)
    q=p(1.2,b,45);c.ellipse((q[0]-2,q[1]-2,q[0]+2,q[1]+2),'#E8BC58')
    face([(b,.55,55),(b,1.45,55),(b,1.45,103),(b,.55,103)],'#245C78')
    c.line([p(b,1.0,55),p(b,1.,103)],PAPER,2)
    c.line([p(b,.55,79),p(b,1.45,79)],PAPER,2)
    if variant=='telha':
        face([(a,b,128),(1.5,b,176),(b,b,128)],dark)
        face([(.04,.04,128),(1.5,.04,176),(1.5,2.96,176),(.04,2.96,128)],'#E87842')
        face([(1.5,.04,176),(2.96,.04,128),(2.96,2.96,128),(1.5,2.96,176)],'#BC6749')
        for v in [.5,1.,1.5,2.,2.5]:c.line([p(.04,v,128),p(1.5,v,176),p(2.96,v,128)],'#743F3B',2)
        c.line([p(1.5,.04,176),p(1.5,2.96,176)],'#E8BC58',2)
        c.line([p(.04,2.96,128),p(1.5,2.96,176),p(2.96,2.96,128)],INK,3)
    else:
        face([(.04,.04,128),(2.96,.04,128),(2.96,2.96,128),(.04,2.96,128)],'#D6D2B8')
        c.line([p(.04,.04,131),p(2.96,.04,131),p(2.96,2.96,131)],INK,3)
        c.line([p(.04,.04,131),p(.04,2.96,131),p(2.96,2.96,131)],'#F5E9CB',3)
        if variant=='muro-chapisco':
            for u,v,zz in [(.2,2.84,38),(1.7,2.84,26),(2.3,2.84,66),(2.84,1.7,24),(2.84,2.4,88)]:
                x,y=p(u,v,zz);c.line([(x-2,y),(x,y-2),(x+2,y)],'#927C62')
    # Original paper diamond by the doorway, and a terracotta flowerpot.
    q=p(1.8,b,86);c.poly([(q[0],q[1]-9),(q[0]+5,q[1]),(q[0],q[1]+9),(q[0]-5,q[1])],'#2EC8E3',INK)
    c.line([(q[0],q[1]+9),(q[0]-2,q[1]+15),(q[0]+2,q[1]+21)],'#E8BC58')
    q=p(2.5,b,0);c.poly([(q[0]-5,q[1]-15),(q[0]+5,q[1]-15),(q[0]+4,q[1]),(q[0]-4,q[1])],'#BC6749')
    c.poly([(q[0],q[1]-13),(q[0]-8,q[1]-25),(q[0]-2,q[1]-23),(q[0]+3,q[1]-30),(q[0]+6,q[1]-22)],'#668A55')
    file=directory/'fontes/geometria'/f'casa-morro-{variant}';c.save(file)
    entry={'file':f'pecas/casa-morro-{variant}.png','size':[w,h],'footprint':[3,3],'visualFootprint':[3,3],'bloqueia':True,'height':height,'anchor':[w//2,h-(fu+fv)*8],'isoAnchor':[fu*32,h],'shadow':'sombras/contato.png','source':{'generator':'tools/overworld/build_art.py','editable':f'pecas/casa-morro-{variant}.svg'},'approval':'pending_concept_review'}
    k['pieces'].setdefault('casa-morro',{'default':'telha','variants':{}})['variants'][variant]=entry

COLORS={'calcada':'#DAD7C5','piso':'#CCBEA5','grama':'#8AAE62','construcao':'#B98165','terra':'#C7A16D','mato':'#557C42','agua':'#77B3AF','rocha':'#AD9D88','ponte':'#BC8A55','asfalto':'#637F91','bosque':'#476643','canteiro':'#668A55'}
DIAMOND=[(32,0),(64,16),(32,32),(0,16)]
WEDGES=[[(32,0),(48,8),(32,16),(16,8)],[(64,16),(48,24),(32,16),(48,8)],[(32,32),(16,24),(32,16),(48,24)],[(0,16),(16,8),(32,16),(16,24)]]
def terrain(k):
    directory=KITS/k['biome']
    for mat in ['calcada','piso','grama','construcao']:
        if mat == 'grama' and k['biome'] == 'morro':
            from build_morro_grass import tiles, decals
            k['materials']['grama'] = tiles(directory/'chao')
            k['decals'] = decals()
            continue
        files=[]
        for n in range(4):
            c=Canvas(64,32);c.poly(DIAMOND,COLORS[mat],None)
            if mat=='piso':c.line([(16+n*3,12),(27+n*3,17)],'#B2A38C')
            if mat=='grama':c.line([(27+n*4,19),(29+n*4,16),(31+n*4,19)],'#668A55')
            file=f'chao/{mat}-{n}';c.save(directory/file);files.append(file+'.png')
        k['materials'][mat]={'variants':files,'size':[64,32]}
    for a,b in [('calcada','construcao'),('construcao','piso'),('construcao','grama')]:
        states=[]
        for mask in range(16):
            c=Canvas(64,32);c.poly(DIAMOND,COLORS[a],None)
            for bit,pts in enumerate(WEDGES):
                if mask&(1<<bit):c.poly(pts,COLORS[b],None)
            file=f'transicoes/{a}-{b}-{mask}';c.save(directory/file);states.append(file+'.png')
        k['transitions'][a+'/'+b]={'corners':['top','right','bottom','left'],'maskBits':[1,2,4,8],'files':states}
    for material in ['pedra','chapisco']:
        k['walls'][material]={}
        for side in ['u','v']:
            files=[]
            for n in range(2):
                c=Canvas(32,80);pts=[(32,0),(0,16),(0,80),(32,64)] if side=='u' else [(0,0),(32,16),(32,80),(0,64)]
                c.poly(pts,'#B8A58D' if side=='u' else '#8F7C6E',INK)
                if material=='pedra':
                    for yy in [24,48,72]:c.line([(0,yy),(32,yy-16 if side=='u' else yy+16)],'#76665E')
                else:c.line([(12,30+n*7),(15,28+n*7),(17,30+n*7)],'#79695F')
                file=f'muros/{material}-{side}-{n}';c.save(directory/file);files.append(file+'.png')
            k['walls'][material][side]=files
        for kind in ['interno','externo']:
            files=[]
            for n in range(2):
                c=Canvas(64,96);c.poly([(0,0),(32,16),(32,80),(0,64)],'#8F7C6E');c.poly([(32,16),(64,0),(64,64),(32,80)],'#B8A58D')
                if kind=='interno':c.line([(32,16),(32,80)],'#F5E9CB',2)
                file=f'muros/{material}-canto-{kind}-{n}';c.save(directory/file);files.append(file+'.png')
            k['walls'][material][kind]=files
    for direction in ['u+','u-','v+','v-']:
        fu,fv=(1,2) if direction[0]=='u' else (2,1);w=(fu+fv)*32;h=(fu+fv)*16+64;c=Canvas(w,h)
        p=lambda u,v,z:((fv+u-v)*32,64+(u+v)*16-z)
        zz=lambda u,v:64*(u/fu if direction=='u+' else 1-u/fu if direction=='u-' else v/fv if direction=='v+' else 1-v/fv)
        c.poly([p(fu,0,zz(fu,0)),p(fu,fv,zz(fu,fv)),p(fu,fv,0),p(fu,0,0)],'#AEB3A7')
        c.poly([p(0,fv,zz(0,fv)),p(fu,fv,zz(fu,fv)),p(fu,fv,0),p(0,fv,0)],'#87918A')
        for i in range(8):
            t=i/8;t1=(i+1)/8;z=(i+1)*8
            if direction=='u+':q=[(t,0),(t1,0),(t1,2),(t,2)]
            elif direction=='u-':q=[(1-t1,0),(1-t,0),(1-t,2),(1-t1,2)]
            elif direction=='v+':q=[(0,t),(2,t),(2,t1),(0,t1)]
            else:q=[(0,1-t1),(2,1-t1),(2,1-t),(0,1-t)]
            c.poly([p(u,v,z) for u,v in q],'#DAD7C5',INK)
            edge=[q[0],q[3]] if direction=='u+' else [q[1],q[2]] if direction=='u-' else [q[0],q[1]] if direction=='v+' else [q[2],q[3]]
            c.poly([p(*edge[0],z-8),p(*edge[1],z-8),p(*edge[1],z),p(*edge[0],z)],'#AEB3A7',INK)
        file=f'escadas/{direction}';c.save(directory/file);k['stairs'][direction]={'file':file+'.png','footprint':[fu,fv],'risePx':64,'risers':8,'widthCells':2}

def morro():
    k=kit('morro');shadow(KITS/'morro');terrain(k)
    k['context']={'radius':12,'material':'canteiro','color':'668A55','asset':'casa-morro','spacing':5,'role':'non-playable gardens and background houses, no collision or events'}
    for v in ['telha','laje','muro-chapisco']:architecture(k,v)
    houses=KITS/'morro/fontes/casas-morro-v2.png'
    for i,variant in enumerate(['telha','laje','muro-chapisco']):
        image,src=slot(houses,i,3,1)
        entry=k['pieces']['casa-morro']['variants'][variant]
        w,h=entry['size'];factor=min((w-4)/image.width,250/image.height)
        size=(round(image.width*factor),round(image.height*factor))
        canvas=Image.new('RGBA',(w,h))
        # House occupies its complete diamond: lowest visible front corner
        # aligns to the Studio front anchor, not to the centre of the lot.
        canvas.alpha_composite(image.resize(size,Image.Resampling.LANCZOS),(w//2-size[0]//2,h-size[1]-1))
        destination=KITS/'morro'/entry['file'];destination.parent.mkdir(parents=True,exist_ok=True);canvas.save(destination)
        entry['source']={**src,'geometryGuide':f'fontes/geometria/casa-morro-{variant}.svg','normalization':'uniform, lowest base at front anchor','tool':'image_gen.imagegen'}
        entry['rasterSize']=list(size)
    sheet=KITS/'morro/fontes/pecas-morro.png'
    for i,(asset,hh) in enumerate([('caixa-dagua',96),('varal',96),('banca-pipas',112),('toldo-bandeirolas',128),('mirante-guarda-corpo',56),('mesa-artesao',64)]):
        image,src=slot(sheet,i,3,2);pack_prop(k,asset,'default',image,hh,(2,2),True,(3,3) if asset in ['banca-pipas','toldo-bandeirolas'] else (2,2),src)
    # Gate is drawn natively so its four-cell footprint and opening stay exact.
    c=Canvas(160,208);p=lambda u,z:(31+u*31.5,128+u*16-z)
    for u in [0,4]:c.line([p(u,0),p(u,112)],INK,4)
    c.line([p(0,20),p(4,20)],INK,3);c.line([p(0,100),p(4,100)],INK,3)
    for u in [.5,1,1.5,2,2.5,3,3.5]:c.line([p(u,20),p(u,100)],INK,2)
    c.save(KITS/'morro/pecas/portao-default')
    k['pieces']['portao']={'default':'default','variants':{'default':{'file':'pecas/portao-default.png','size':[160,208],'footprint':[4,1],'visualFootprint':[4,1],'height':4,'bloqueia':False,'anchor':[80,168],'isoAnchor':[128,208],'shadow':'sombras/contato.png','source':{'generator':'tools/overworld/build_art.py'},'approval':'pending_concept_review'}}}
    for direction in ['u+','u-','v+','v-']:
        c=Canvas(64,96);p=lambda u,v,z:(32+(u-v)*32,64+(u+v)*16-z)
        a,b=((1,0),(1,1)) if direction=='u+' else ((0,0),(0,1)) if direction=='u-' else ((0,1),(1,1)) if direction=='v+' else ((0,0),(1,0))
        c.poly([p(*a,0),p(*b,0),p(*b,32),p(*a,32)],'#D5C4A3' if direction[0]=='u' else '#B6A58F')
        c.line([p(*a,32),p(*b,32)],PAPER,2)
        file=f'pecas/muro-quintal-{direction}';c.save(KITS/'morro'/file)
        entry={'file':file+'.png','size':[64,96],'footprint':[1,1],'visualFootprint':[1,1],'height':2,'bloqueia':False,'anchor':[32,80],'isoAnchor':[32,96],'shadow':'sombras/contato.png','source':{'generator':'tools/overworld/build_art.py'},'approval':'pending_concept_review','role':'prop boundary on already-blocked construction, not a terrain cliff'}
        k['pieces'].setdefault('muro-quintal',{'default':'u+','variants':{}})['variants'][direction]=entry
    if (KITS/'morro/fontes/pisos-v2/grama.png').exists():
        from build_morro_floors import update_kit
        k=update_kit(k)
    if (KITS/'morro/fontes/muros-v2/pedra.png').exists():
        from build_morro_walls import update_kit as update_walls
        k=update_walls(k)
        from build_morro_stairs import update_kit as update_stairs
        k=update_stairs(k)
    write(KITS/'morro/kit.json',k);return k

def studio(k):
    pieces=[]
    for asset,group in k['pieces'].items():
        for variant,entry in group['variants'].items():
            i=len(pieces);file=KITS/k['biome']/entry['file']
            safe_variant={'u+':'u-mais','u-':'u-menos','v+':'v-mais','v-':'v-menos'}.get(variant,variant)
            pieces.append({'id':asset+'-'+safe_variant,'name':asset+' / '+variant,'assetId':asset,'variant':variant,'kind':'floor','footprint':entry['visualFootprint'],'height':entry['height'],'cell':[6+(i%7)*8,6+(i//7)*8],'elevation':0,'image':'data:image/png;base64,'+base64.b64encode(file.read_bytes()).decode(),'scale':1,'offset':[0,0],'navigationFootprint':entry['footprint'],'anchorCenter':entry['anchor']})
    project={'name':'PIP-83/87 — '+k['biome'],'room':{'cells':[64,64],'wall':12,'origin':[2048,384],'image':None},'pieces':pieces}
    write(KITS/k['biome']/(k['biome']+'.isostudio.json'),project)

def scale_board(k):
    entries=[(a,v,e) for a,g in k['pieces'].items() for v,e in g['variants'].items()]
    width=1600;cellw=400;cellh=390;h=80+math.ceil(len(entries)/4)*cellh
    im=Image.new('RGB',(width,h),PAPER);d=ImageDraw.Draw(im)
    font=ImageFont.truetype(str(ROOT/'godot/assets/campaign/ui-modern/fonts/Nunito.ttf'),17);font.set_variation_by_axes([700])
    # Use the actual approved Kael composition from the style board's crop.
    native=Image.open(ART/'estilo/ESCALA-NATIVA.png').convert('RGBA').crop((0,70,70,173));bbox=native.getchannel('A').getbbox();native=native.crop(bbox) if bbox else native
    d.text((25,20),'KIT '+k['biome'].upper()+' • Kael junto de cada peça • escala nativa • revisão pendente',font=font,fill=INK)
    for i,(asset,var,e) in enumerate(entries):
        x=(i%4)*cellw;y=80+(i//4)*cellh;foot_y=y+260
        # Reuse source Kael atlas composition, not the opaque native-board crop.
        avatar=kael_image();avatar=avatar.resize((round(avatar.width*84/avatar.height),84),Image.Resampling.LANCZOS)
        im.paste(avatar,(x+18,foot_y-84),avatar)
        prop=Image.open(KITS/k['biome']/e['file']).convert('RGBA')
        im.paste(prop,(x+155-e['anchor'][0],foot_y-e['anchor'][1]),prop)
        d.text((x+15,foot_y+68),asset+' / '+var,font=font,fill=INK)
        d.text((x+15,foot_y+94),'pé '+str(e['footprint'])+' • volume '+str(e['height'])+' ×32',font=font,fill=INK)
    im.save(KITS/k['biome']/'PRANCHA-ESCALA.png')

def kael_image():
    root=ROOT/'godot/assets/kael';m=read(root/'manifest.json');f=m['actions']['parado']['directions']['se'][0];im=Image.new('RGBA',(180,180))
    for key in ['mochila-pipa','base','alcas-mochila','cabelo-kael']:
        if key=='base':im.alpha_composite(Image.open(root/f['image']).convert('RGBA'),(20,20));continue
        layer=m['layers'][key];mount=f['head' if layer['kind']=='head' else 'torso'];anchor=layer['anchor']['se'];im.alpha_composite(Image.open(root/layer['images']['se']).convert('RGBA'),(20+mount[0]-anchor[0],20+mount[1]-anchor[1]))
    return im.crop(im.getchannel('A').getbbox())

def export_runtime(k):
    dest=ROOT/'godot/assets/overworld/kits'/k['biome'];shutil.copytree(KITS/k['biome'],dest,dirs_exist_ok=True,ignore=shutil.ignore_patterns('fontes','*.isostudio.json','PRANCHA-ESCALA.png'))

def debug_atlas():
    im=Image.new('RGBA',(256,len(COLORS)*32));ids={}
    for row,(mat,color) in enumerate(COLORS.items()):
        ids[mat]=row
        for n in range(4):
            c=Canvas(64,32);c.poly(DIAMOND,color,'#26394D44')
            if n:c.line([(26+n,15),(31+n,17)],'#26394D33')
            im.alpha_composite(c.im,(n*64,row*32))
    directory=ROOT/'godot/assets/overworld';directory.mkdir(parents=True,exist_ok=True)
    im.save(directory/'rascunho-atlas.png');write(directory/'rascunho-atlas.json',ids)

def actor_metadata():
    root=ROOT/'godot/assets';result={}
    for key,file in [('nina','nina.png'),('assis','campaign/assis-overworld.png')]:
        image=Image.open(root/file).convert('RGBA');x,y,x1,y1=image.getchannel('A').getbbox()
        result[key]={'image':'res://assets/'+file,'bounds':{'x':x,'y':y,'w':x1-x,'h':y1-y},'name':'Nina' if key=='nina' else 'Sr. Assis'}
    result['morro']={}
    for scene,area in read(root/'campaign/morro/maps.json').items():
        result['morro'][scene]=[{**npc,'image':'res://assets/campaign/morro/'+npc['image']} for npc in area['npcs']]
    boss=read(root/'campaign/content.json')['combat']['lacertubo']
    result['lacertubo']={'name':'Lacertubo','image':'res://assets/campaign/'+boss['image'],'bounds':boss['animations']['idle'][0]}
    write(root/'overworld/npcs.json',result)

if __name__=='__main__':
    for k in [common(),morro()]:studio(k);scale_board(k);export_runtime(k)
    debug_atlas()
    actor_metadata()
    print('Kits comum e morro, fontes vetoriais, projetos Iso Studio e réguas gerados.')

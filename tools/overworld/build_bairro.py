"""PIP-84: editable SVG Bairro kit on the approved 64x32 grid.
Extends the repository's code-native architectural source, not a raster paintover.
No source map, event, save, shared kit or campaign replacement is modified.
"""
from pathlib import Path
import json, math, shutil, base64
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from build_art import Canvas, kit, shadow, studio, kael_image
ROOT=Path(__file__).resolve().parents[2]
DEST=ROOT/'art/overworld/kits/bairro'
INK='#26394D'; PAPER='#F5E9CB'

class Ink:
    """Editable 1x vector source with a supersampled raster of those same paths."""
    def __init__(self,w,h):self.c=Canvas(w,h);self.hi=Canvas(w*4,h*4);self.size=(w,h)
    def poly(self,p,c,s=INK,sw=1):
        p=list(p);self.c.poly(p,c,s,max(1,round(sw)));self.hi.poly([(x*4,y*4) for x,y in p],c,s,max(1,round(sw*4)))
    def line(self,p,c=INK,sw=1):
        p=list(p);self.c.line(p,c,max(1,round(sw)));self.hi.line([(x*4,y*4) for x,y in p],c,max(1,round(sw*4)))
    def ellipse(self,p,c,s=INK,sw=1):self.c.ellipse(p,c,s,max(1,round(sw)));self.hi.ellipse(tuple(n*4 for n in p),c,s,max(1,round(sw*4)))
    def save(self,path):
        self.c.save(path)
        self.hi.im.resize(self.size,Image.Resampling.LANCZOS).save(path.with_suffix('.png'))

def record(k,asset,c,foot,height,door=None,blocks=True):
    c.save(DEST/'pecas'/f'{asset}-default')
    painted=DEST/'fontes/pinturas'/f'{asset}.png'
    if painted.exists():
        # Retain the editable geometric template, then fit the isolated painting
        # uniformly into its visible box. No map or geometry is extracted from AI.
        guides=DEST/'fontes/guias';guides.mkdir(parents=True,exist_ok=True)
        for ext in ['png','svg']:
            shutil.copyfile(DEST/'pecas'/f'{asset}-default.{ext}',guides/f'{asset}-default.{ext}')
        with Image.open(painted) as source:
            im=source.convert('RGBA');bounds=im.getchannel('A').point(lambda x:255 if x>24 else 0).getbbox();im=im.crop(bounds)
        guide=Image.open(guides/f'{asset}-default.png').convert('RGBA');box=guide.getchannel('A').point(lambda x:255 if x>24 else 0).getbbox()
        # Small props get a readable visual envelope while keeping their logical
        # one-cell footprint and the Studio canvas unchanged.
        box={'mural':(1,32,63,152),'bancada-rua':(2,52,62,120),'cerca-viva':(2,42,62,90)}.get(asset,box)
        width=box[2]-box[0];height_px=box[3]-box[1];scale=min(width/im.width,height_px/im.height)
        im=im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.LANCZOS)
        output=Image.new('RGBA',c.size);output.alpha_composite(im,(round((box[0]+box[2]-im.width)/2),box[3]-im.height));output.save(DEST/'pecas'/f'{asset}-default.png')
        # Truthful SVG counterpart of the normalized artwork; geometric paths
        # remain in fontes/guias rather than masquerading as the final painting.
        encoded=base64.b64encode((DEST/'pecas'/f'{asset}-default.png').read_bytes()).decode()
        (DEST/'pecas'/f'{asset}-default.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{c.size[0]}" height="{c.size[1]}"><image width="100%" height="100%" href="data:image/png;base64,{encoded}"/></svg>\n',encoding='utf-8')
    fu,fv=foot;w,h=c.size
    entry={'file':f'pecas/{asset}-default.png','size':[w,h],'footprint':[fu,fv],'visualFootprint':[fu,fv],'bloqueia':blocks,'height':height,'anchor':[w/2,h-(fu+fv)*8],'isoAnchor':[fu*32,h],'shadow':'sombras/contato.png','source':{'generator':'tools/overworld/build_bairro.py','editable':f'pecas/{asset}-default.svg'},'approval':'pending_kit_visual_review'}
    if door:entry['door']=door
    if painted.exists():entry['source']={'generator':'image_gen.imagegen','file':f'fontes/pinturas/{asset}.png','geometry':f'fontes/guias/{asset}-default.svg','normalization':'tools/overworld/build_bairro.py; uniform fit to guide alpha box'}
    k['pieces'][asset]={'default':'default','variants':{'default':entry}}

def house(k,asset,fu,fv,door_u,wall,shade,shop=False):
    height=7;w=(fu+fv)*32;h=height*32+(fu+fv)*16;c=Ink(w,h)
    p=lambda u,v,z=0:((fv+u-v)*32,height*32+(u+v)*16-z)
    face=lambda vertices,col,sw=1.3:c.poly([p(*v) for v in vertices],col,INK,sw)
    a=.16;right=fu-.16;front=fv-.16;top=126;ridge=183;mid=fu/2
    # Front v+ (left-facing screen wall) is the authoritative entrance facade.
    face([(a,front,0),(right,front,0),(right,front,top),(a,front,top)],wall)
    face([(right,a,0),(right,front,0),(right,front,top),(right,a,top)],shade)
    face([(a,front,top),(mid,front,ridge),(right,front,top)],wall)
    # Low plaster plinth, no invented raised platform or stairs.
    face([(a,front,0),(right,front,0),(right,front,12),(a,front,12)],'#D3B58D')
    face([(right,a,0),(right,front,0),(right,front,12),(right,a,12)],'#B59C7C')
    def front_rect(u0,u1,z0,z1,col):face([(u0,front,z0),(u1,front,z0),(u1,front,z1),(u0,front,z1)],col,1)
    # Door is drawn on the wall directly behind its fixed map entry cell.
    lo=max(.27,door_u-.43);hi=min(fu-.27,door_u+.43)
    front_rect(lo-.07,hi+.07,0,105,'#D9BB89');front_rect(lo,hi,0,100,'#176D78')
    for t in [1/3,2/3]:c.line([p(lo+(hi-lo)*t,front,3),p(lo+(hi-lo)*t,front,97)],'#245260',.8)
    for z0,z1 in [(12,44),(56,88)]:front_rect(lo+.11,hi-.11,z0,z1,'#277D84')
    q=p(hi-.12,front,47);c.ellipse([q[0]-1.7,q[1]-1.7,q[0]+1.7,q[1]+1.7],'#E8BC58')
    # Window / retail recess on the remaining facade, away from the door.
    wl=.38;wr=min(1.7,lo-.24)
    if wr-wl>.45:
        front_rect(wl-.06,wr+.06,40,98,'#E8D3A9');front_rect(wl,wr,44,94,'#164659')
        if shop:
            for i in range(5):
                u=wl+.1+i*(wr-wl-.2)/4
                for z in [54,74]:
                    face([(u,front,z),(u+.13,front,z),(u+.13,front,z+10),(u,front,z+10)],['#EB8053','#DFBC57','#36B3B6','#F4D2B1','#4F7892'][i],.7)
            c.line([p(wl,front,68),p(wr,front,68)],'#BC8252',2)
        else:
            midw=(wl+wr)/2
            front_rect(wl,midw-.025,44,94,'#267581');front_rect(midw+.025,wr,44,94,'#267581')
            for z in [51,59,67,75,83,91]:c.line([p(wl+.06,front,z),p(wr-.06,front,z)],'#174E63',.8)
            if asset=='casa-assis':
                for i in range(4):c.line([p(wr-.2+i*.04,front,44),p(wr-.25+i*.05,front,82+i*2)],'#D0A765',1)
        front_rect(wl-.1,wr+.1,38,42,'#BC8252')
    # Side window: same material/ink family, plane-accurate shutters.
    vs=.45;ve=min(front-.35,1.55)
    face([(right,vs,44),(right,ve,44),(right,ve,99),(right,vs,99)],'#D9BB89')
    face([(right,vs+.06,48),(right,ve-.06,48),(right,ve-.06,95),(right,vs+.06,95)],'#236675')
    for z in [55,63,71,79,87]:c.line([p(right,vs+.12,z),p(right,ve-.12,z)],'#173E53',.8)
    # Both roof planes, overhanging eaves and ridge. Grouped rows, no grey gable.
    ra=.025;rb=fu-.025;va=.025;vb=fv-.025
    face([(ra,va,top),(mid,va,ridge),(mid,vb,ridge),(ra,vb,top)],'#EAA35B')
    face([(mid,va,ridge),(rb,va,top),(rb,vb,top),(mid,vb,ridge)],'#E47C42')
    for vv in np.arange(.28,fv,.43):
        c.line([p(ra,vv,top),p(mid,vv,ridge),p(rb,vv,top)],'#8E4C38',1.1)
    for uu in np.arange(.28,fu,.42):
        zz=top+(ridge-top)*(1-abs(uu-mid)/(mid-ra))
        c.line([p(uu,va,zz),p(uu,vb,zz)],'#B05C3E',.75)
    c.line([p(ra,vb,top-3),p(mid,vb,ridge-3),p(rb,vb,top-3)],INK,3)
    c.line([p(ra,vb,top),p(mid,vb,ridge),p(rb,vb,top)],'#F6C178',1)
    c.line([p(mid,va,ridge),p(mid,vb,ridge)],'#F6C178',3)
    # Small wall lamp and material details are native paths, not ground shadows.
    q=p(max(.3,lo-.2),front,91);x,y=q
    c.line([(x,y-5),(x,y-13),(x+4,y-13)],INK,1.5)
    c.poly([(x-3,y-7),(x+3,y-4),(x+3,y+7),(x-3,y+4)],'#E8BC58',INK,1)
    if shop:
        for u,col in [(.6,'#F1C64A'),(1.18,'#24B7C2'),(1.74,'#ED7960')]:
            if abs(u-door_u)<.6:continue
            verts=[(u,front+.035,112),(u+.18,front+.035,97),(u,front+.035,80),(u-.18,front+.035,97)]
            face(verts,col,.9);c.line([p(u,front+.035,80),p(u+.12,front+.035,71),p(u,front+.035,65)],'#E8BC58',1)
    record(k,asset,c,(fu,fv),height,{'front':'v+','wallPoint':[door_u,front,0],'thresholdPx':list(p(door_u,front,0)),'approachCellRelative':[door_u,fv+.5],'leafHeight':100})

def furniture(k,asset):
    c=Ink(64,160 if asset=='mural' else 128)
    base=144 if asset=='mural' else 112
    p=lambda u,v,z=0:(32+(u-v)*32,base+(u+v-1)*16-z)
    face=lambda pts,col:c.poly([p(*q) for q in pts],col,INK,1)
    if asset=='mural':
        for u in [.13,.87]:face([(u,.45,0),(u+.07,.45,0),(u+.07,.45,103),(u,.45,103)],'#A7754F')
        face([(.05,.45,32),(.95,.45,32),(.95,.45,103),(.05,.45,103)],'#A7754F')
        face([(.11,.45,39),(.89,.45,39),(.89,.45,96),(.11,.45,96)],'#D5B57A')
        for u,z,col in [(.17,67,PAPER),(.51,65,'#C4DFD4'),(.2,43,'#F4CA76'),(.57,42,PAPER)]:
            face([(u,.47,z),(u+.22,.47,z),(u+.22,.47,z+20),(u,.47,z+20)],col)
            c.line([p(u+.04,.48,z+14),p(u+.18,.48,z+14)],'#839796',.7)
        height=4
    else:
        for u,v in [(.14,.14),(.8,.14),(.14,.8),(.8,.8)]:face([(u,v,0),(u+.06,v,0),(u+.06,v,43),(u,v,43)],'#AC764A')
        face([(.08,.08,43),(.9,.08,43),(.9,.9,43),(.08,.9,43)],'#E6B471')
        face([(.9,.08,37),(.9,.9,37),(.9,.9,43),(.9,.08,43)],'#B77B4B')
        for n in [.25,.48,.71]:c.line([p(n,.08,43),p(n,.9,43)],'#C39258',.7)
        for u,v,col in [(.35,.3,'#F2C55B'),(.55,.45,'#33B8BD')]:
            face([(u-.12,v,44),(u,v-.2,44),(u+.12,v,44),(u,v+.2,44)],col)
            c.line([p(u-.12,v,44),p(u+.12,v,44)],INK,.6)
        for i in range(4):c.line([p(.16+i*.04,.7,44),p(.32+i*.04,.4,44)],'#C9A35F',1)
        height=3
    record(k,asset,c,(1,1),height,blocks=False)
    k['pieces'][asset]['variants']['default']['anchor']=[32,base]

def hedge(k):
    c=Ink(64,96)
    c.poly([(5,76),(28,62),(58,75),(35,89)],'#567A49',None)
    for x,y,r,col in [(15,67,12,'#668A55'),(33,61,15,'#668A55'),(49,71,12,'#668A55'),(19,63,12,'#8EB65B'),(36,59,13,'#9CBC5D')]:
        points=[(x+math.cos(t*math.pi/5)*(r if t%2==0 else r*.72),y+math.sin(t*math.pi/5)*(r*.65 if t%2==0 else r*.46)) for t in range(10)]
        c.poly(points,col,'#3D6149',.65)
    record(k,'cerca-viva',c,(1,1),2,blocks=False)
    k['pieces']['cerca-viva']['variants']['default']['anchor']=[32,80]

def terrain(k,brief):
    colors={'calcada':'#E9DCB6','asfalto':'#5A758E','terra':'#CFAC73','canteiro':'#8FAF65','construcao':'#D6BE95'}
    alpha=np.array([255 if abs(2*x+1-64)+2*abs(2*y+1-32)<=64 else 0 for y in range(32) for x in range(64)],dtype=np.uint8).reshape(32,64)
    arrays={}
    for mat,col in colors.items():
        arrays[mat]=[];files=[]
        for variant in range(4):
            c=Ink(64,32);c.poly([(32,0),(64,16),(32,32),(0,16)],col,None)
            # Variations are quiet marks confined away from the tile boundary.
            x,y=[(22,15),(37,17),(29,12),(38,19)][variant]
            if mat=='calcada' and variant<2:c.line([(x-4,y-2),(x+4,y+2)],'#DCCCA4',.7)
            if mat=='terra':c.poly([(x-3,y),(x+1,y-1),(x+4,y+1),(x,y+2)],'#C5A16C',None)
            if mat=='asfalto' and variant<2:c.line([(x-3,y),(x+2,y)],'#607B93',.6)
            if mat=='canteiro' and variant<2:c.poly([(x-3,y),(x-1,y-1),(x+4,y),(x+1,y+1)],'#86A55E',None)
            path=DEST/'chao'/f'{mat}-{variant}';c.save(path)
            image=Image.open(path.with_suffix('.png')).convert('RGBA');image.putalpha(Image.fromarray(alpha));image.save(path.with_suffix('.png'));arrays[mat].append(np.array(image));files.append(f'chao/{mat}-{variant}.png')
        k['materials'][mat]={'variants':files,'size':[64,32],'outline':False,'shadowBaked':False,'source':'tools/overworld/build_bairro.py'}
    yy,xx=np.mgrid[:32,:64];u=(xx+.5)/64+(yy+.5)/32-.5;v=(yy+.5)/32-(xx+.5)/64+.5
    for transition in brief['transitions']:
        a,b=transition['pair'].split('/');files=[]
        for mask in range(16):
            # Four-corner masks use a continuous bilinear field in ground UV.
            corners=[bool(mask&(1<<bit)) for bit in range(4)]
            field=(1-u)*(1-v)*corners[0]+u*(1-v)*corners[1]+u*v*corners[2]+(1-u)*v*corners[3]
            rgb=np.where((field>=.5)[:,:,None],arrays[b][0],arrays[a][0]).copy();rgb[:,:,3]=alpha
            path=f'transicoes/{a}-{b}-{mask}.png';(DEST/path).parent.mkdir(exist_ok=True);Image.fromarray(rgb).save(DEST/path);files.append(path)
        k['transitions'][a+'/'+b]={'corners':['top','right','bottom','left'],'maskBits':[1,2,4,8],'files':files,'source':'tools/overworld/build_bairro.py'}

def main():
    brief=json.loads((ROOT/'art/overworld/conceitos/bairro/brief.json').read_text(encoding='utf-8'))
    k=kit('bairro');k['approval']='concept_approved_kit_pending_visual_review';k['concept']='../../conceitos/bairro/rua-estudo-v2.png';k['sourceMapSha256']=brief['sourceSha256']
    k['context']={'radius':8,'color':'8FAF65','asset':'casa-kael'}
    k['dressing']=[{'asset':'poste','variant':'rua','point':point} for point in [[3.5,9.5],[40.5,9.5]]]+[{'asset':'vaso','variant':'ceramica','point':point} for point in [[4.5,9.5],[9.5,9.5],[18.5,9.5],[23.5,9.5],[31.5,9.5],[36.5,9.5]]]
    shadow(DEST);terrain(k,brief)
    house(k,'casa-kael',4,4,2.5,'#F3E5BF','#D8C69F')
    house(k,'casa-assis',4,3,2.5,'#ECA58B','#C48373')
    house(k,'loja-pipas',4,3,3.5,'#F3E5BF','#D8C69F',True)
    furniture(k,'mural');furniture(k,'bancada-rua')
    hedge(k)
    k['sharedPieces']={'banco':'comum/banco/madeira','poste':'comum/poste/rua','vaso':'comum/vaso/ceramica','arvore':'comum/arvore/a','lixeira':'comum/lixeira/rua'}
    if (DEST/'fontes/pisos-v2/calcada.png').exists():
        from build_bairro_floors import update_kit
        k=update_kit(k)
    (DEST/'kit.json').write_text(json.dumps(k,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    studio(k)
    # Compare all architectural props next to the actual Kael at 84 px.
    board=Image.new('RGB',(1800,590),PAPER);d=ImageDraw.Draw(board);font=ImageFont.truetype(str(ROOT/'godot/assets/campaign/ui-modern/fonts/Nunito.ttf'),18)
    avatar=kael_image();avatar=avatar.resize((round(avatar.width*84/avatar.height),84),Image.Resampling.LANCZOS)
    for i,(asset,group) in enumerate(k['pieces'].items()):
        e=group['variants']['default'];x=20+i*295;baseline=470
        prop=Image.open(DEST/e['file']);ax,ay=e['anchor'];board.paste(prop,(int(x+150-ax),int(baseline-ay)),prop);board.paste(avatar,(x+8,baseline-84),avatar)
        d.text((x,baseline+34),asset,font=font,fill=INK);d.text((x,baseline+61),f"{e['footprint'][0]}×{e['footprint'][1]} · âncora do piso",font=font,fill=INK)
    d.text((20,20),'BAIRRO · kit modular com fontes e guias · revisão visual',font=font,fill=INK);board.save(DEST/'PRANCHA-ESCALA.png')
    runtime=ROOT/'godot/assets/overworld/kits/bairro';shutil.copytree(DEST,runtime,dirs_exist_ok=True,ignore=shutil.ignore_patterns('*.isostudio.json','PRANCHA-ESCALA.png','fontes','README.md'))
    print('Bairro: 20 pisos, 112 transições, 3 casas e 2 peças; fontes SVG e projeto Iso Studio. Sem mudanças de navegação.')

if __name__=='__main__':main()

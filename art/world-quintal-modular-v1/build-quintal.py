"""Author editable courtyard geometry and measured atlas; never change image pixels."""
from pathlib import Path
import json
from zipfile import ZipFile, ZIP_DEFLATED
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/world/quintal-modular-v1'
def read(p):return json.loads((ROOT/p).read_text(encoding='utf-8'))
def write(p,v):(ROOT/p).write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
kit=read('assets/world/morro-kit-v1/manifest.json')
# All joins come from a single connected frame, with shared fixed cut lines.
with Image.open(ROOT/'assets/world/quintal-kit-v1/walls-v2.png') as wall:
    kit['sheets']['quintal-walls']={'image':'world/quintal-kit-v1/walls-v2.png','width':wall.width,'height':wall.height}
for name,x,y,w,h,axis in [
    ('wall-horizontal',352,128,544,224,'x'),('wall-south',352,896,544,224,'x'),
    ('wall-vertical',128,352,224,544,'y'),('wall-east',896,352,224,544,'y'),
    ('wall-corner',128,128,224,224,None),('wall-ne',896,128,224,224,None),
    ('wall-sw',128,896,224,224,None),('wall-se',896,896,224,224,None)]:
    kit['frames'][name]={'sheet':'quintal-walls','x':x,'y':y,'w':w,'h':h,'anchor':{'x':0,'y':0},'recommendedWidth':w*3/16,'layer':'object','wallAxis':axis}
definitions=[('quintal-buildings','buildings-v1.png',816,[('club-veranda',540,'object'),('club-roof',580,'foreground'),('club-gate',416,'foreground'),('line-stall',288,'object')]),('quintal-furniture','furniture-v1.png',832,[('craft-table',208,'object'),('spool-rack',176,'object'),('summon-dais',384,'foreground'),('friends-board',256,'object')])]
audit=[]
for sheet,filename,split,entries in definitions:
    image='world/quintal-kit-v1/'+filename
    with Image.open(ROOT/'assets'/image) as im:
        w,h=im.size;kit['sheets'][sheet]={'image':image,'width':w,'height':h,'columns':2,'rows':2}
        xs=[0,split,w];ys=[0,512,h]
        for i,(id,width,layer) in enumerate(entries):
            c,r=i%2,i//2;x,y=xs[c],ys[r];cw,ch=xs[c+1]-x,ys[r+1]-y
            b=im.crop((x,y,x+cw,y+ch)).getchannel('A').point(lambda a:255 if a>96 else 0).getbbox()
            assert b
            left,top=max(0,b[0]-2),max(0,b[1]-2);right,bottom=min(cw,b[2]+2),min(ch,b[3]+2)
            kit['frames'][id]={'sheet':sheet,'x':x+left,'y':y+top,'w':right-left,'h':bottom-top,'anchor':{'x':.5,'y':1},'recommendedWidth':width,'layer':layer}
            audit.append({'id':id,'sheet':sheet,'bounds':kit['frames'][id],'cell':{'x':x,'y':y,'w':cw,'h':ch}})
write('assets/world/quintal-kit-v1/manifest.json',kit)
write('art/world-quintal-modular-v1/atlas-audit.json',audit)
map={'type':'map','version':'1.10','tiledversion':'1.11.0','orientation':'orthogonal','renderorder':'right-down','width':48,'height':32,'tilewidth':32,'tileheight':32,'infinite':False,'tilesets':[],'layers':[{'id':i+1,'name':n,'type':'objectgroup','draworder':'topdown','opacity':1,'visible':True,'x':0,'y':0,'objects':[]} for i,n in enumerate(['Walkable','Solids','Foreground','Interactions','Spawns','Exits'])],'properties':[]}
def props(values):return [{'name':k,'type':'bool' if isinstance(v,bool) else 'int' if isinstance(v,int) else 'string','value':v} for k,v in values.items()]
map['properties']=props({'scene_name':'Quintal do Clube','scene_id':'quintal','overview':True,'ground_corner_radius':24,'actor_height':72,'foot_radius':10,'professor_x':416,'professor_y':608,'nozinho_x':466,'nozinho_y':626})
layout={'bindings':{},'decorations':[],'audit':{'enforce':True}};nextid=1
def rect(layer,name,x,y,w,h,**values):
    global nextid
    o={'id':nextid,'name':name,'x':x,'y':y,'width':w,'height':h,'rotation':0,'visible':True,'properties':props(values)};nextid+=1
    next(l for l in map['layers'] if l['name']==layer)['objects'].append(o);return o['id']
def solid(name,x,y,w,h,frame=None,width=None,footX=None,footY=None,sortY=None):
    id=rect('Solids',name,x,y,w,h,level=0,sort_y=sortY if sortY is not None else y+h)
    layout['bindings'][str(id)]={'frame':frame,'width':width,'footX':footX,'footY':footY} if frame else {'hidden':True}
    return id
def deco(frame,x,y,width,sortY=None,**rest):layout['decorations'].append({'frame':frame,'width':width,'footX':x,'footY':y,'sortY':y if sortY is None else sortY,'level':0,**rest})
def front(name,frame,x,y,width,sortY):
    id=rect('Foreground',name,max(0,x-4),max(0,min(1016,y-4)),8,8,level=0,sort_y=sortY)
    layout['bindings'][str(id)]={'frame':frame,'width':width,'footX':x,'footY':y}
# A walkable lawn under the dirt paths: the entire yard is explorable; real bases block feet.
rect('Walkable','Gramado do quintal',64,224,1408,736,level=0,ground_frame='grass')
for name,x,y,w,h in [('Caminho do portao',704,224,192,512),('Rua da varanda',192,480,1056,160),('Patio de voo',512,608,576,224),('Caminho do mural',928,800,416,160),('Caminho dos carreteis',160,704,512,128)]:rect('Walkable',name,x,y,w,h,level=0,ground_frame='dirt')
solid('Varanda do clube',96,256,480,224,'club-veranda',540,336,480)
front('Telhado do clube','club-roof',336,274,580,480)
# An open gate has two independent physical side posts, leaving the center free.
solid('Pilar esquerdo do portao',592,192,96,96)
solid('Pilar direito do portao',912,192,96,96)
solid('Folha aberta esquerda',688,224,72,64)
solid('Folha aberta direita',840,224,72,64)
front('Portao aberto','club-gate',800,288,416,288)
solid('Banca de linhas',1136,304,224,96,'line-stall',288,1248,416)
solid('Mesa do Sr. Assis',240,512,144,48,'craft-table',208,312,560)
solid('Expositor de carreteis',192,736,112,48,'spool-rack',176,248,800)
solid('Banco e mural dos amigos',1136,832,160,48,'friends-board',256,1216,896)
# Dais is floor art: sorted before feet and deliberately has no central collider.
deco('summon-dais',1248,672,384,0)
# One uniform scale; short ends crop their source instead of shrinking or overlapping.
wall_scale=3/16
def wall_run(name,frame,start,end,fixed,vertical=False):
    for pos in range(start,end,102):
        length=min(102,end-pos)
        if vertical:
            id=solid(name,48 if fixed==36 else 1472,pos,16,length,frame,42,fixed,pos)
            layout['bindings'][str(id)]['sourceHeight']=round(length/wall_scale)
        else:
            id=solid(name,pos,216 if fixed==198 else 960,length,16,frame,length,pos,fixed)
            layout['bindings'][str(id)]['sourceWidth']=round(length/wall_scale)
for start,end in [(78,594),(1008,1455)]:wall_run('Muro norte '+str(start),'wall-horizontal',start,end,198)
wall_run('Muro sul','wall-south',78,1455,939)
wall_run('Muro lateral oeste','wall-vertical',240,939,36,True)
wall_run('Muro lateral leste','wall-east',240,939,1455,True)
for frame,x,y,cx,cy,cw,ch in [
    ('wall-corner',36,198,48,216,30,24),('wall-ne',1455,198,1455,216,33,24),
    ('wall-sw',36,939,48,939,30,37),('wall-se',1455,939,1455,939,33,37)]:
    solid('Quina '+frame,cx,cy,cw,ch,frame,42,x,y)
# Trees: trunks block, canopies have their own visual support and depth.
for x,y,size in [(112,288,248),(1440,304,256),(96,688,208),(1440,752,224),(432,928,208),(800,944,176),(1328,240,192),(80,176,260),(432,160,256),(1056,168,264),(1312,176,260),(1488,176,248)]:
    solid('Tronco de arvore',x-14,y-22,28,28,'trunk',42,x,y+6)
    front('Copa de arvore','canopy',x,y-20,size,y+6)
    layout['bindings'][str(nextid-1)]['anchorY']=1
# Bench back faces north; its south-facing seat opens onto the flight patio.
for frame,x,y,width in [('banana',1088,352,96),('banana',1408,512,112),('banana',128,912,96),('flowerpot',624,288,56),('flowerpot',976,288,56),('flowerpot',592,480,48),('flowerpot',1104,448,48),('flowerpot',1376,672,56),('bench',960,672,144),('lamp',1024,544,30),('lamp',672,320,30)]:
    base=96 if frame=='bench' else 16
    solid(frame,x-base/2,y-12,base,16,frame,width,x,y)
for frame,x,y,width in [('pennants',800,208,288),('shrub',1040,928,128),('shrub',1344,912,128),('shrub',1152,240,96),('shrub',352,848,112),('shrub',576,928,112),('shrub',96,512,120),('shrub',1408,896,112),('shrub',1104,256,96)]:deco(frame,x,y,width)
# Keep the six original actions; no invented rewards or account operations.
for id,name,x,y,w,h,action in [('collection','Varanda dos parceiros',256,480,128,96,'collection'),('professor','Sr. Assis e Nozinho',384,592,128,96,'professor'),('shop','Banca de linhas',1184,432,128,96,'shop'),('summon','Círculo de invocação',1216,576,96,96,'summon'),('friends','Mural dos amigos',1152,896,128,64,'friends')]:
    rect('Interactions',name,x,y,w,h,action=action,level=0,place_id=id)
rect('Exits','Portão para Kronasta',752,240,96,96,action='city',level=0,place_id='gate')
rect('Spawns','Chegada ao clube',736,688,64,64,level=0)
map['nextobjectid']=nextid;map['nextlayerid']=7
write('assets/world/quintal-modular-v1/blockout.tmj',map)
write('assets/world/quintal-modular-v1/art.json',layout)
project={'schema':'pipaklub-atelier','version':1,'name':'Quintal do Clube · modular','map':map,'layout':layout,'kit':kit,'images':{}}
write('assets/world/quintal-modular-v1/project.json',project)
with ZipFile(ROOT/'art/world-quintal-modular-v1/quintal-modular-editavel-v1.zip','w',ZIP_DEFLATED) as bundle:
    for name in ['project.json','blockout.tmj','art.json','README.md']:
        bundle.write(OUT/name,name)
    bundle.write(ROOT/'assets/world/quintal-kit-v1/manifest.json','kit.json')
    bundle.write(ROOT/'tools/atelie/AUDIT-RULES.md','AUDIT-RULES.md')
    for sheet in kit['sheets'].values():
        bundle.write(ROOT/'assets'/sheet['image'],'assets/'+sheet['image'])
print('Quintal: 1536x1024,',nextid-1,'objetos,',len(layout['decorations']),'decoracoes,',len(kit['frames']),'pecas no kit.')

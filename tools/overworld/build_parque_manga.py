"""Native editable flat 2D terrain/bridge art. No raster paintover or geometry edits."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2]
FOLDERS=[ROOT/'art/overworld/kits/parque',ROOT/'godot/assets/overworld/kits/parque']
kit=json.loads((FOLDERS[0]/'kit.json').read_text(encoding='utf-8'))
files=[]
def svg(name,w,h,body):
    path='manga-v3/'+name+'.svg'
    text=f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>\n'
    for folder in FOLDERS:
        target=folder/path;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(text,encoding='utf-8')
    files.append(path)
    return path
colors={'grama':'#85AD58','terra':'#DFB86F','mato':'#5B9147','piso':'#E9D5A3','bosque':'#4C7445'}
diamond='32,0 64,16 32,32 0,16'
for key,color in colors.items():
    # Continuous details live on one world-space sheet, not on each tile.
    path=svg(key,64,32,f'<polygon points="{diamond}" fill="{color}" stroke="{color}" stroke-width="1.5"/>')
    kit['materials'][key]['variants']=[path]*4
water_tile=svg('agua-base',64,32,f'<polygon points="{diamond}" fill="#328D98"/>')
kit['materials']['agua']['variants']=[water_tile]*4
wedges=['32,0 48,8 32,16 16,8','64,16 48,24 32,16 48,8','32,32 16,24 32,16 48,24','0,16 16,8 32,16 16,24']
for pair,entry in kit['transitions'].items():
    a,b=pair.split('/')
    masks=[]
    for mask in range(16):
        body=f'<polygon points="{diamond}" fill="{colors[a]}" stroke="{colors[a]}" stroke-width="1.5"/>'
        for bit,wedge in enumerate(wedges):
            if mask&(1<<bit): body+=f'<polygon points="{wedge}" fill="{colors[b]}" stroke="{colors[b]}" stroke-width="1.5"/>'
        masks.append(svg('transicao-'+a+'-'+b+'-'+str(mask),64,32,body))
    entry['files']=masks
patterns={}
for key in colors:
    body='<rect width="512" height="256" fill="#808080"/>'
    for i in range(31 if key in ['grama','bosque','mato'] else 15):
        x=14+(i*137)%480;y=12+(i*79)%230
        if key in ['grama','bosque','mato']:
            body+=f'<path d="M{x-4} {y+2}q2 -3 -1 -6m5 6q1 -5 4 -6m-4 6l5 -1" fill="none" stroke="#555555" stroke-width="1.4" stroke-linecap="round"/>'
            if i%5==0: body+=f'<path d="M{x-9} {y+4}q7 2 18 -1" fill="none" stroke="#999999" stroke-width="3" stroke-linecap="round"/>'
        else:
            body+=f'<path d="M{x-4} {y}l3 -2 5 1 1 3 -6 1z" fill="#A3A3A3"/><path d="M{x-4} {y}l3 3 6 -1m4 5h5" fill="none" stroke="#606060" stroke-width="1.2" stroke-linecap="round"/>'
    patterns[key]=svg('marcas-'+key,512,256,body)
kit['paintSurfaces']=patterns
# One full deck, native 3 x 11 source cells. Never rescale a shorter bridge.
RUN=11
ORIGIN=16+32*RUN
WIDTH=32*(3+RUN)+32
HEIGHT=16*(3+RUN)+52
def p(u,v,lift=0): return (ORIGIN+32*u-32*v,28+16*u+16*v-lift)
def point(q): return f'{q[0]:g},{q[1]:g}'
def poly(points,fill,stroke='#203A40',width=2): return f'<polygon points="{" ".join(point(q) for q in points)}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round"/>'
body=poly([p(0,0),p(3,0),p(3,RUN),p(0,RUN)],'#8D643E',width=3)
body+=poly([p(3,0),p(3,RUN),p(3,RUN,-6),p(3,0,-6)],'#785038')
body+=poly([p(0,RUN),p(3,RUN),p(3,RUN,-6),p(0,RUN,-6)],'#A47542')
for i in range(RUN*2):
    v=i*.5+.025;end=(i+1)*.5-.025
    body+=poly([p(.035,v),p(2.965,v),p(2.965,end),p(.035,end)],['#D7AC63','#E5BE79','#CFA363'][i%3],width=1.8)
    a,b=p(.45,v+.2),p(1.55,v+.2)
    body+=f'<path d="M{point(a)}L{point(b)}" fill="none" stroke="#A57745" stroke-width="1.2" stroke-linecap="round"/>'
    for u in [.18,2.82]:
        x,y=p(u,v+.2);body+=f'<circle cx="{x}" cy="{y}" r="1.2" fill="#35434A"/>'
deck=svg('ponte-tabuleiro-3x11',WIDTH,HEIGHT,body)
rails={}
for name,u in [('fundo',.08),('frente',2.92)]:
    body=''
    rope='M'+point(p(u,0,19))
    for start in [0,RUN/4,RUN/2,RUN*3/4]:
        rope+=' Q'+point(p(u,start+RUN/8,7))+' '+point(p(u,start+RUN/4,19))
    body+=f'<path d="{rope}" fill="none" stroke="#203A40" stroke-width="4" stroke-linecap="round"/>'
    body+=f'<path d="{rope}" fill="none" stroke="#D8BF82" stroke-width="1.8" stroke-linecap="round"/>'
    for v in [0,RUN/4,RUN/2,RUN*3/4,RUN]:
        x,y=p(u,v)
        body+=poly([(x-3,y+3),(x+3,y),(x+3,y-23),(x-3,y-21)],'#B88A4F',width=1.6)
        body+=f'<path d="M{x-4} {y-14}l8 -4m-8 7l8 -4" stroke="#F0D49B" stroke-width="1.5"/>'
    rails[name]=svg('ponte-corda-'+name,WIDTH,HEIGHT,body)
kit['mangaWater']={'depthPx':18,'palette':['#246272','#328D98','#70C6BB'],'style':'flat cut banks; drawn current marks; no water photo'}
kit['continuousBridge']={'footprint':[3,RUN],'file':deck,'rails':rails,'origin':[ORIGIN,28],'size':[WIDTH,HEIGHT]}
kit['surfaceTreatment']={'kind':'native-editable-manga-v3','colors':colors,'source':'tools/overworld/build_parque_manga.py','note':'flat surfaces; world-space drawn marks; continuous bridge with separate rails'}
kit['approval']='pending_owner_review_manga_v3'
for folder in FOLDERS: (folder/'kit.json').write_text(json.dumps(kit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(FOLDERS[0]/'manga-v3/MANIFESTO.json').write_text(json.dumps({'files':files,'source':'original repository-native SVG art','style':'flat manga: navy contour, two wood tones, no gradient; quiet drawn terrain marks','bridge':'native 3x11 cells; never stretch to other footprints','approval':'pending_owner_review'},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'{len(files)} native SVG assets')

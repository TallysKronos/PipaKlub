"""Code-native proportion guides; no final vehicle art is painted here."""
from build_art import Canvas
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2];ART=ROOT/'art/overworld/kits/mobilidade'
specs=json.loads((ART/'briefs.json').read_text(encoding='utf-8'))['assets']
for s in specs:
    fu,fv=s['footprint'];z=s['bodyHeight'];w=(fu+fv)*32+16;h=z+(fu+fv)*16+48
    c=Canvas(w,h)
    def p(u,v,zz=0):return (8+(fv+u-v)*32,24+z+(u+v)*16-zz)
    def face(points,color):c.poly([p(*q) for q in points],color,'#26394D',1)
    a,b=.14,fu-.14;v0,v1=.15,fv-.15
    if s['kind']=='vehicle' and s['id']!='moto-entregas':
        body=z*.45
        face([(a,v1,18),(b,v1,18),(b,v1,body),(a,v1,body)],'#B97054')
        face([(b,v0,18),(b,v1,18),(b,v1,body),(b,v0,body)],'#DCA878')
        face([(a,v0,body),(b,v0,body),(b,v1,body),(a,v1,body)],'#E8C496')
        cab0,cab1=fv*.30,fv*.70
        face([(a,cab1,body),(b,cab1,body),(b,cab1,z),(a,cab1,z)],'#295D78')
        face([(b,cab0,body),(b,cab1,body),(b,cab1,z),(b,cab0,z)],'#417A93')
        face([(a,cab0,z),(b,cab0,z),(b,cab1,z),(a,cab1,z)],'#E9DBB8')
        for v in [fv*.20,fv*.80]:
            x,y=p(b+.02,v,15)
            c.ellipse((x-9,y-15,x+9,y+15),'#26394D','#172D3C',2)
            c.ellipse((x-4,y-8,x+4,y+8),'#ADB6AE','#26394D',1)
    else:
        face([(a,v1,0),(b,v1,0),(b,v1,z),(a,v1,z)],'#C6B692')
        face([(b,v0,0),(b,v1,0),(b,v1,z),(b,v0,z)],'#E8D5AF')
        face([(a,v0,z),(b,v0,z),(b,v1,z),(a,v1,z)],'#E4DFCD')
    c.save(ART/'fontes/geometria'/s['id'])
print(f'{len(specs)} vehicle/prop geometry guides.')

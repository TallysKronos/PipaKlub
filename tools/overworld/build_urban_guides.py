"""Geometry guides only: stable 2:1 bases, storey/door scale, no final artwork."""
from build_art import Canvas
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/urbano'
specs=json.loads((ART/'briefs.json').read_text(encoding='utf-8'))['assets']
for s in specs:
    fu,fv=s['footprint'];z=s['stories']*128
    w=(fu+fv)*32+16;h=z+(fu+fv)*16+96+16
    c=Canvas(w,h)
    def p(u,v,zz=0):return (8+(fv+u-v)*32,8+z+96+(u+v)*16-zz)
    def face(points,col):c.poly([p(*q) for q in points],col,'#26394D',2)
    a,b=.12,fu-.12
    face([(a,b,0),(b,b,0),(b,b,z),(a,b,z)],'#CBB99B')
    face([(b,a,0),(b,b,0),(b,b,z),(b,a,z)],'#E8D5AF')
    face([(a,a,z),(b,a,z),(b,b,z),(a,b,z)],'#E4DFCD')
    for floor in range(s['stories']):
        if floor:
            for v0,v1 in [((a,b),(b,b)),((b,a),(b,b))]:c.line([p(*v0,floor*128),p(*v1,floor*128)],'#26394D',2)
        for offset in [fu*.55,fu*.8]:
            face([(offset-.25,b,floor*128+48),(offset+.25,b,floor*128+48),(offset+.25,b,floor*128+104),(offset-.25,b,floor*128+104)],'#336D86')
            face([(b,offset-.25,floor*128+48),(b,offset+.25,floor*128+48),(b,offset+.25,floor*128+104),(b,offset-.25,floor*128+104)],'#336D86')
    if s['doorFace']=='v+':face([(.55,b,0),(1.35,b,0),(1.35,b,96),(.55,b,96)],'#173C56')
    else:face([(b,.55,0),(b,1.35,0),(b,1.35,96),(b,.55,96)],'#173C56')
    c.save(ART/'fontes/geometria'/s['id'])
print(f'{len(specs)} architecture guides.')

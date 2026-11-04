"""Refine the existing code-native SVG gate; preserve its 4x1 opening."""
from build_art import Canvas, studio, scale_board
from refine_morro_facades import ART, RUNTIME
import json, shutil

kit=json.loads((ART/'kit.json').read_text(encoding='utf-8'))
c=Canvas(160,208)
def p(u,z):return (16+u*32,136+u*16-z)
# Two short side leaves, leaving the central passage visibly open.
for lo,hi in [(0,.75),(3.25,4)]:
    for z in [18,85]:
        c.line([p(lo,z),p(hi,z)],'#19374B',4)
        c.line([p(lo,z+1),p(hi,z+1)],'#39758A',1)
    for n in range(5):
        u=lo+(hi-lo)*n/4
        c.line([p(u,18),p(u,85)],'#19374B',2)
    c.poly([p((lo+hi)/2,67),p(hi-.12,50),p((lo+hi)/2,33),p(lo+.12,50)],'#347184','#19374B',1)
# No overhead rail across the neighbouring facade: open sky above the path.
for u in [0,4]:
    x,y=p(u,0)
    c.poly([(x-8,y-4),(x,y),(x,y-100),(x-8,y-104)],'#D3BD92','#26394D',1)
    c.poly([(x,y),(x+8,y-4),(x+8,y-104),(x,y-100)],'#EAD4AC','#26394D',1)
    c.poly([(x-10,y-104),(x,y-109),(x+10,y-104),(x,y-99)],'#FFF0CE','#26394D',1)
    c.line([(x-7,y-25),(x,y-21),(x+7,y-25)],'#B49A73',1)
    c.line([(x-7,y-66),(x,y-62),(x+7,y-66)],'#B49A73',1)
    c.ellipse((x-3,y-116,x+3,y-110),'#E9AF50','#26394D',1)
c.save(ART/'pecas/portao-v2')
entry=kit['pieces']['portao']['variants']['default']
entry['file']='pecas/portao-v2.png'
entry['source']={'generator':'tools/overworld/refine_morro_gate.py','editable':'pecas/portao-v2.svg','note':'Existing SVG geometry refined; central 2.5-cell opening, no overhead rail across the neighbouring window'}
entry['approval']='pending_owner_review'
kit['automaticLotSmall']=False
shutil.copy2(ART/entry['file'],RUNTIME/entry['file'])
for file in [ART/'kit.json',RUNTIME/'kit.json']:file.write_text(json.dumps(kit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
studio(kit);scale_board(kit)

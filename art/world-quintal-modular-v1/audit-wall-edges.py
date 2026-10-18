"""Read-only pixel seam audit. Never modify the generated RGBA source."""
import json
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[2]
im=Image.open(root/'assets/world/quintal-kit-v1/walls-v2.png').convert('RGBA')
alpha=im.getchannel('A')
report={'image':'world/quintal-kit-v1/walls-v2.png','size':im.size,'alpha':alpha.getextrema(),'emptyCenter':alpha.getpixel((640,640))==0,'edges':{}}
for name,vertical,fixed0,fixed1 in [('west',True,128,352),('east',True,896,1120),('north',False,128,352),('south',False,896,1120)]:
    def mask(pos):
        return [alpha.getpixel((v,pos) if vertical else (pos,v))>=128 for v in range(fixed0,fixed1)]
    first,last=mask(352),mask(895)
    union=sum(a or b for a,b in zip(first,last));intersection=sum(a and b for a,b in zip(first,last))
    extents=[]
    for pos in range(352,896):
        values=[i for i,a in enumerate(mask(pos)) if a]
        assert values,name+' has an empty slice'
        extents.append((min(values),max(values)))
    edge={'repeatAlphaIoU':intersection/union,'outerEdgeVariationSourcePixels':max(v[0] for v in extents)-min(v[0] for v in extents),'innerEdgeVariationSourcePixels':max(v[1] for v in extents)-min(v[1] for v in extents)}
    report['edges'][name]=edge
    assert edge['repeatAlphaIoU']>=.97,(name,edge)
    assert max(edge['outerEdgeVariationSourcePixels'],edge['innerEdgeVariationSourcePixels'])<=4,(name,edge)
assert report['emptyCenter'] and report['alpha'][0]==0
(root/'art/world-quintal-modular-v1/walls-v2-edge-audit.json').write_text(json.dumps(report,indent=2)+'\n')
print('Wall alpha and silhouette audit passed:',report['edges'])

"""Diagnostic rest compositions from existing parts; does not alter source PNGs."""
from pathlib import Path
from PIL import Image,ImageDraw
import json
root=Path(__file__).resolve().parent
p=json.loads((root/'eremor-v3.soulgen.json').read_text(encoding='utf8'))
variants=[(104,125,62),(78,118,50),(85,123,45),(86,133,43)]
sheet=Image.new('RGBA',(680,616),'#263c48');d=ImageDraw.Draw(sheet)
for i,(kx,ky,kw) in enumerate(variants):
    cell=Image.new('RGBA',(340,280))
    for part in sorted(p['parts'],key=lambda p:p['z']):
        im=Image.open(root/'parts'/(part['asset']+'.png')).convert('RGBA')
        x,y,w,h=part['rect']
        if part['id']=='knot':x,y,w,h=kx,ky,kw,kw*im.height/im.width
        cell.alpha_composite(im.resize((round(w),round(h)),Image.Resampling.LANCZOS),(round(x),round(y)))
    ox=i%2*340;oy=i//2*308
    sheet.alpha_composite(cell,(ox,oy));d.text((ox+10,oy+283),str(i)+'  '+str((kx,ky,kw)),fill='white')
sheet.save(root/'source/knot-placement-diagnostic.png')

"""Register complete generated heads, then composite a fixed eye window only."""
from pathlib import Path
from PIL import Image,ImageChops
import cv2,numpy as np,json
root=Path(__file__).resolve().parent/'cutout-rig-v1'
source=Image.open(root/'expressions-source.png').convert('RGBA');head=Image.open(root/'head.png').convert('RGBA')
count,labels,stats,centers=cv2.connectedComponentsWithStats((np.array(source)[:,:,3]>=160).astype('uint8'),8)
bounds=sorted([list(map(int,s[:4])) for s in stats[1:] if s[4]>1000],key=lambda s:s[0]);assert len(bounds)==3
canonical=head.getchannel('A').point(lambda a:255 if a>=160 else 0).getbbox()
window=(48,105,104,140)
report={'method':'Full generated-head connected components, not equal thirds; fixed eye window with 2px inner seam blend; canonical alpha retained.','windows':[[48,105,56,35]],'expressions':{}}
review=Image.new('RGBA',(head.width*4,head.height),'#f3ead6');review.alpha_composite(head)
for index,(face,box) in enumerate(zip(['fierce','hurt','happy'],bounds)):
    x,y,w,h=box;piece=source.crop((x,y,x+w,y+h));aligned=Image.new('RGBA',head.size)
    aligned.paste(piece.resize((canonical[2]-canonical[0],canonical[3]-canonical[1]),Image.Resampling.NEAREST),canonical[:2])
    mask=Image.new('L',(window[2]-window[0],window[3]-window[1]));pixels=mask.load()
    for yy in range(mask.height):
        for xx in range(mask.width):pixels[xx,yy]=min(255,max(0,min(xx,yy,mask.width-1-xx,mask.height-1-yy))*128)
    result=head.copy();result.paste(aligned.crop(window),window[:2],mask);result.putalpha(head.getchannel('A'))
    outside=ImageChops.difference(head,result);outside.paste((0,0,0,0),window)
    assert not outside.convert('RGB').getbbox()
    assert not ImageChops.difference(head.getchannel('A'),result.getchannel('A')).getbbox()
    result.save(root/('head-'+face+'.png'));review.alpha_composite(result,((index+1)*head.width,0))
    report['expressions'][face]={'alpha_identical':True,'outside_windows_identical':True,'source_bounds':box}
review.convert('RGB').save(root/'expressions-review.png');(root/'registration.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')

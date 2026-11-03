"""Only generated eye regions replace canonical pixels; full alpha remains canonical."""
from pathlib import Path
from PIL import Image,ImageChops
import json
root=Path(__file__).resolve().parent/'cutout-rig-v1'
source=Image.open(root/'expressions-source.png').convert('RGBA')
head=Image.open(root/'head.png').convert('RGBA')
windows=[(169,148,273,219),(327,196,362,240)]
canonical=head.getchannel('A').point(lambda a:255 if a>=160 else 0).getbbox()
report={'method':'Generated eye windows aligned by silhouette bounds; canonical alpha and external pixels unchanged.','windows':[[x,y,r-x,b-y] for x,y,r,b in windows],'expressions':{}}
review=Image.new('RGBA',(head.width*4,head.height),'#f3ead6');review.alpha_composite(head)
for i,face in enumerate(['fierce','hurt','happy']):
    piece=source.crop((round(i*source.width/3),0,round((i+1)*source.width/3),source.height))
    bounds=piece.getchannel('A').point(lambda a:255 if a>=160 else 0).getbbox();assert bounds
    aligned=Image.new('RGBA',head.size)
    aligned.paste(piece.crop(bounds).resize((canonical[2]-canonical[0],canonical[3]-canonical[1]),Image.Resampling.NEAREST),canonical[:2])
    result=head.copy()
    for window in windows:result.paste(aligned.crop(window),window[:2])
    result.putalpha(head.getchannel('A'))
    difference=ImageChops.difference(head,result)
    for window in windows:difference.paste((0,0,0,0),window)
    assert not difference.convert('RGB').getbbox()
    assert not ImageChops.difference(head.getchannel('A'),result.getchannel('A')).getbbox()
    result.save(root/('head-'+face+'.png'));review.alpha_composite(result,((i+1)*head.width,0))
    report['expressions'][face]={'alpha_identical':True,'outside_windows_identical':True,'source_bounds':bounds}
review.convert('RGB').save(root/'expressions-review.png')
(root/'registration.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')

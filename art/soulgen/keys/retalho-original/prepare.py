"""Mechanical crops and registration; no painting or invented anatomy."""
from pathlib import Path
from PIL import Image, ImageChops
import json
P=Path(__file__).parent/'cutout-rig-v1'
source=Image.open(P/'source.png').convert('RGBA')
boxes={'body':(116,42,310,406),'head':(370,67,738,402),'armNear':(814,42,1033,405),'armFar':(96,415,288,766),'legNear':(484,423,669,796),'legFar':(829,419,1028,792),'tail':(27,797,393,1093),'fierce':(395,812,741,1114),'hurt':(743,812,1072,1114),'happy':(33,1093,396,1424)}
for name,box in boxes.items(): source.crop(box).save(P/(name+'.png'))
# Source heads have slightly different outer ear geometry. Preserve the neutral
# head outside the face: only generated eyes and mouth enter fixed windows.
head=Image.open(P/'head.png');windows=[(251,126,301,168),(291,169,362,213)]
report={'method':'Generated face pixels registered by neutral head bounds; canonical alpha and outside-window pixels retained.','windows':[[a,b,c-a,d-b] for a,b,c,d in windows],'expressions':{}}
for face in ['fierce','hurt','happy']:
 raw=Image.open(P/(face+'.png')).convert('RGBA')
 raw=raw.crop(raw.getbbox()).resize((352,321),Image.Resampling.NEAREST)
 aligned=Image.new('RGBA',head.size);aligned.alpha_composite(raw,(8,8))
 result=head.copy()
 for box in windows:result.paste(aligned.crop(box),box[:2])
 result.putalpha(head.getchannel('A'));result.save(P/('head-'+face+'.png'))
 diff=ImageChops.difference(head,result)
 for box in windows:diff.paste((0,0,0,0),box)
 assert not diff.convert('RGB').getbbox()
 report['expressions'][face]={'outside_window_identical':True,'alpha_identical':True}
(P/'registration.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(P/'slices.json').write_text(json.dumps({'sourceSize':source.size,'boxes':boxes},indent=2),encoding='utf-8')

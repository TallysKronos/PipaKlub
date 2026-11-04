"""Retalho: normalize generated alpha without color-keying or altering the source."""
from pathlib import Path
from PIL import Image
import json
root=Path(__file__).resolve().parent.parent
source=root/'art/characters/retalho/game-v1'
image=Image.open(source/'source.png').convert('RGBA')
assert image.getchannel('A').getextrema()==(0,255)
box=image.getchannel('A').point(lambda a:255 if a>32 else 0).getbbox()
assert box and box[0]>0 and box[1]>0 and box[2]<image.width and box[3]<image.height
image=image.crop(box)
out=root/'godot/assets/campaign/retalho-v1'
out.mkdir(parents=True,exist_ok=True)
for name,height in [('overworld',112),('battle',320)]:
 image.resize((round(image.width*height/image.height),height),Image.Resampling.LANCZOS).save(out/(name+'.png'))
(source/'qa.json').write_text(json.dumps({'alpha':[0,255],'crop':box,'static':True,'heights':[112,320]},indent=2)+'\n',encoding='utf-8')
print('PASS Retalho: original alpha, complete margins, static 112/320px')

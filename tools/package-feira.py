"""Crop the six generated market NPCs; preserve alpha and record output sizes."""
from pathlib import Path
from PIL import Image
import json
root=Path(__file__).resolve().parent.parent
source=root/'art/characters/feira-v1/source.png'
image=Image.open(source).convert('RGBA')
names=['veyra','orven','zafri','nymel','lalau','zulmira']
cuts=[0,350,730,1080,1420,1780,image.width]
target=root/'godot/assets/npc-ds/feira-v1'
target.mkdir(parents=True,exist_ok=True)
report=[]
for i,name in enumerate(names):
    tile=image.crop((cuts[i],0,cuts[i+1],image.height))
    box=tile.getchannel('A').point(lambda a:255 if a>32 else 0).getbbox()
    assert box is not None
    tile=tile.crop(box)
    tile=tile.resize((round(tile.width*112/tile.height),112),Image.Resampling.LANCZOS)
    tile.save(target/(name+'.png'))
    report.append({'name':name,'size':tile.size,'alpha':tile.getchannel('A').getextrema()})
(source.parent/'qa.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('PASS: six sprites with original alpha; height 112; source preserved')

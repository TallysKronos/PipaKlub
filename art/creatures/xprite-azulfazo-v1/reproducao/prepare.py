from PIL import Image
from pathlib import Path
import json
p=Path("tmp/xprite-azulfazo")
p.mkdir(parents=True,exist_ok=True)
im=Image.open("art/creatures/xprite-azulfazo-v1/geracao-original.png").convert("RGBA")
(p/"source.rgba").write_bytes(im.tobytes())
(p/"source.json").write_text(json.dumps(dict(width=im.width,height=im.height,path="art/creatures/xprite-azulfazo-v1/geracao-original.png")))
source=[]
for i in range(2):
    panel=im.crop((i*im.width//2,0,(i+1)*im.width//2,im.height))
    mask=panel.getchannel("A").point(lambda a:255 if a>=128 else 0)
    box=mask.getbbox()
    panel=panel.crop(box)
    alpha=panel.getchannel("A").point(lambda a:255 if a>=128 else 0)
    panel.putalpha(alpha)
    width=round(panel.width*70/panel.height)
    (p/f"pose-{i}.rgba").write_bytes(panel.tobytes())
    source.append(dict(width=panel.width,height=panel.height,box=box,targetWidth=width,targetHeight=70))
(p/"poses.json").write_text(json.dumps(source,indent=2))

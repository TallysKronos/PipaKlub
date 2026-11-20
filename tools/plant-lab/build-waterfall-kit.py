from pathlib import Path
from PIL import Image
import shutil
import base64

root=Path(__file__).resolve().parents[2]
kit=root/'art/environment/kronasta-waterfalls-v1'
(kit/'sources').mkdir(parents=True,exist_ok=True)
(kit/'sprites').mkdir(exist_ok=True)
source=Path(r'C:/Users/user/.codex/generated_images/01a1ad88-b69d-7193-848a-ce0f89456ef0/exec-bd851b06-eb7a-494d-9930-45e818606832.png')
shutil.copy2(source,kit/'sources/waterfalls.png')
im=Image.open(source).convert('RGBA')
atlas=Image.new('RGBA',(192,96))
for frame in range(4):
    piece=im.crop((frame*543+101,36,frame*543+442,698)).resize((48,96),Image.Resampling.NEAREST)
    # Remove faint generated alpha noise; keep a strict pixel silhouette.
    piece.putalpha(piece.getchannel('A').point(lambda a:255 if a>=128 else 0))
    colors=piece.convert('RGB').quantize(colors=24,dither=Image.Dither.NONE).convert('RGBA')
    colors.putalpha(piece.getchannel('A'))
    atlas.paste(colors,(frame*48,0))
atlas.save(kit/'atlas.png')
(root/'tools/plant-lab/waterfall-data.mjs').write_text("export const WATERFALL_RGBA='"+base64.b64encode(atlas.tobytes()).decode()+"';\n",encoding='utf-8')
for id in ['cachoeira-fina','cachoeira-dupla','cachoeira-ampla']:
    atlas.crop((0,0,48,96)).save(kit/'sprites'/f'{id}.png')
preview=atlas.resize((768,384),Image.Resampling.NEAREST)
preview.save(kit/'preview.png')
print(kit/'atlas.png')

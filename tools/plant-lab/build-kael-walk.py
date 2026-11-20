from pathlib import Path
from PIL import Image
import shutil
root=Path(__file__).resolve().parents[2]
kit=root/'art/characters/kael/overworld-walk-v1'
kit.mkdir(parents=True,exist_ok=True)
source=Path(r'C:/Users/user/.codex/generated_images/01a1ad88-b69d-7193-848a-ce0f89456ef0/exec-3f2bef83-ec4e-4ebe-bfb4-ee37335a5085.png')
shutil.copy2(source,kit/'source.png')
im=Image.open(source).convert('RGBA');sheet=Image.new('RGBA',(320,160))
for row in range(2):
    for frame in range(4):
        piece=im.crop((frame*im.width//4,row*im.height//2,(frame+1)*im.width//4,(row+1)*im.height//2))
        alpha=piece.getchannel('A').point(lambda a:255 if a>=128 else 0)
        box=alpha.getbbox()
        piece.putalpha(alpha);piece=piece.crop(box)
        height=44;width=round(piece.width*height/piece.height)
        piece=piece.resize((width,height),Image.Resampling.NEAREST)
        rgb=piece.convert('RGB').quantize(colors=28,dither=Image.Dither.NONE).convert('RGBA');rgb.putalpha(piece.getchannel('A'))
        sheet.paste(rgb,(frame*80+40-width//2,row*80+65-height))
sheet.save(kit/'walk.png');sheet.resize((960,480),Image.Resampling.NEAREST).save(kit/'preview.png')
print(kit/'walk.png')

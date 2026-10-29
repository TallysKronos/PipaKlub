"""Normalize the generated 4x2 professor art without repainting its pixels."""
import json
from pathlib import Path
import shutil
from PIL import Image, ImageOps

ROOT=Path(__file__).resolve().parents[1]
SOURCE=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-5f4dd1e5-4dfc-4e93-88c6-ba568988bdb7.png')
OUT=ROOT/'art/professor-overworld-v4'
OUT.mkdir(parents=True,exist_ok=True)
shutil.copy2(SOURCE,OUT/'source-sheet.png')
image=Image.open(SOURCE).convert('RGBA')
directions=['south','west','east','north']
pieces=[]
for row in range(2):
    for col in range(4):
        box=(col*image.width//4,row*image.height//2,(col+1)*image.width//4,(row+1)*image.height//2)
        cell=image.crop(box)
        bounds=cell.getchannel('A').point(lambda a:255 if a>24 else 0).getbbox()
        if not bounds:raise ValueError(f'Empty cell {row},{col}')
        if bounds[0]==0 or bounds[1]==0 or bounds[2]==cell.width or bounds[3]==cell.height:
            raise ValueError(f'Foreground touches cell border: {row},{col}')
        pieces.append({'image':cell.crop(bounds),'source_rect':box,'source_bounds':bounds,
                       'direction':directions[col],'pose':'idle' if row==0 else 'step'})
# One scale for every pose, fixed canvas and ground anchor; do not fit each frame separately.
factor=min(248/max(p['image'].width for p in pieces),364/max(p['image'].height for p in pieces))
sheet=Image.new('RGBA',(1024,768))
frames={}
preview=Image.new('RGBA',(1024,768),(20,32,43,255))
for index,piece in enumerate(pieces):
    art=piece['image']
    art=art.resize((round(art.width*factor),round(art.height*factor)),Image.Resampling.LANCZOS)
    frame=Image.new('RGBA',(256,384))
    frame.alpha_composite(art,((256-art.width)//2,376-art.height))
    key=piece['direction']+'-'+piece['pose']
    frame.save(OUT/(key+'.png'))
    x,y=(index%4)*256,(index//4)*384
    sheet.alpha_composite(frame,(x,y))
    preview.alpha_composite(frame,(x,y))
    frames[key]={'frame':{'x':x,'y':y,'w':256,'h':384},'anchor':{'x':128,'y':376},
                 'source_rect':piece['source_rect'],'source_bounds':piece['source_bounds']}
sheet.save(OUT/'professor-overworld.png')
preview.convert('RGB').save(OUT/'preview.png')
runtime=ROOT/'godot/assets/campaign/assis-overworld.png'
shutil.copy2(runtime,OUT/'previous-active.png')
old_size=Image.open(runtime).size
front=pieces[0]['image']
front=ImageOps.contain(front,(old_size[0]-4,old_size[1]-4),Image.Resampling.LANCZOS)
idle=Image.new('RGBA',old_size)
idle.alpha_composite(front,((old_size[0]-front.width)//2,old_size[1]-front.height-2))
idle.save(runtime)
idle.save(OUT/'active-idle.png')
shutil.copy2(OUT/'professor-overworld.png',ROOT/'godot/assets/campaign/professor-overworld-v4.png')
data={'image':'professor-overworld-v4.png','frames':frames,
      'directions':directions,'poses':['idle','step'],'cell_size':[256,384],
      'common_scale':factor,'source_size':image.size,'source_alpha':image.getchannel('A').getextrema(),
      'status':'Directional poses prepared; front idle integrated. Not a complete walk cycle.',
      'active_idle_size':old_size}
(OUT/'atlas.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
shutil.copy2(OUT/'atlas.json',ROOT/'godot/assets/campaign/professor-overworld-v4.json')
print(json.dumps({k:v for k,v in data.items() if k!='frames'},indent=2))

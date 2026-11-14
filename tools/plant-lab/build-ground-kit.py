"""Prepare generated ground textures, sharing opposing edges across all variants."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import os,subprocess,json,base64
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'art/environment/kronasta-ground-v1';(OUT/'textures').mkdir(exist_ok=True)
node=os.environ.get('PIXEL_NODE','node');catalog=json.loads(subprocess.check_output([node,'--input-type=module','-e',"import{GROUNDS}from'./tools/plant-lab/ground-kit.mjs';console.log(JSON.stringify(GROUNDS))"],cwd=ROOT,text=True,encoding='utf-8'))
payload={};colors={};board=Image.new('RGB',(1080,660),'#203632');draw=ImageDraw.Draw(board);font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',13)
for k,g in enumerate(catalog):
 source=Image.open(OUT/'sources'/(['grass','earth','stone'][k//9]+'.png')).convert('RGB');n=k%9;x=n%3;y=n//3
 crop=source.crop((round(x*source.width/3),round(y*source.height/3),round((x+1)*source.width/3),round((y+1)*source.height/3))).resize((64,64),Image.Resampling.NEAREST)
 frames=[crop.crop((0,0,32,32)),crop.crop((16,16,48,48)),crop.crop((32,32,64,64))]
 # Keep a reference edge strip; pair its opposite edges to make the period seamless.
 reference=frames[0].copy()
 for yy in range(32):
  c=tuple((reference.getpixel((0,yy))[j]+reference.getpixel((31,yy))[j])//2 for j in range(3));reference.putpixel((0,yy),c);reference.putpixel((31,yy),c)
 for xx in range(32):
  c=tuple((reference.getpixel((xx,0))[j]+reference.getpixel((xx,31))[j])//2 for j in range(3));reference.putpixel((xx,0),c);reference.putpixel((xx,31),c)
 palette=crop.quantize(colors=24,dither=Image.Dither.NONE)
 finished=[]
 for frame in frames:
  for yy in range(32):
   for xx in range(32):
    distance=min(xx,31-xx,yy,31-yy)
    if distance<4:
     weight=(4-distance)/4;a=frame.getpixel((xx,yy));b=reference.getpixel((xx,yy));frame.putpixel((xx,yy),tuple(round(a[j]*(1-weight)+b[j]*weight) for j in range(3)))
  frame=frame.quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA');finished.append(frame)
 texture=Image.new('RGBA',(32,96))
 for v,frame in enumerate(finished):texture.paste(frame,(0,v*32))
 texture.save(OUT/'textures'/f"{g['id']}.png");payload[g['id']]=base64.b64encode(texture.tobytes()).decode('ascii')
 rgb=tuple(sum(c[j] for c in finished[0].getdata())//1024 for j in range(3));shade=lambda f:'#'+''.join(f'{min(255,round(c*f)):02x}' for c in rgb);colors[g['id']]={'color':shade(1),'dark':shade(.70),'light':shade(1.22)}
 bx=k%9*120;by=k//9*220;board.paste(finished[0].resize((96,96),Image.Resampling.NEAREST).convert('RGB'),(bx+12,by+12));draw.text((bx+4,by+116),g['name'],font=font,fill='#e3e9cf')
 # Put a 2x2 repeat below each label to show continuity at native scale.
 for yy in range(2):
  for xx in range(2):board.paste(finished[(xx+yy)%3].convert('RGB'),(bx+28+xx*32,by+145+yy*32))
(ROOT/'tools/plant-lab/ground-data.mjs').write_text('export const GROUND_BYTES='+json.dumps(payload)+';\nexport const GROUND_COLORS='+json.dumps(colors)+';\n',encoding='utf-8')
(OUT/'kit.json').write_text(json.dumps({'id':'kronasta-ground-v1','materials':[{**g,**colors[g['id']]} for g in catalog],'tile':[32,32],'variants':3,'masks':47,'recipe':'Generated artwork, crop, nearest neighbor, shared opposing edge strips, 24-color palettes.'},ensure_ascii=False,indent=2),encoding='utf-8');board.save(OUT/'catalog-preview.png');print('27 materials, three compatible texture variations each.')

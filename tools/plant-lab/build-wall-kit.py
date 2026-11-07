"""Prepare generated front-elevation textures; preserve the source's vertical direction."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import os,subprocess,json,base64
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'art/environment/kronasta-walls-v1';(OUT/'textures').mkdir(exist_ok=True)
node=os.environ.get('PIXEL_NODE','node');catalog=json.loads(subprocess.check_output([node,'--input-type=module','-e',"import{WALLS}from'./tools/plant-lab/wall-kit.mjs';console.log(JSON.stringify(WALLS))"],cwd=ROOT,text=True,encoding='utf-8'))
source=Image.open(OUT/'sources/walls.png').convert('RGB');payload={};colors={};board=Image.new('RGB',(960,660),'#203632');draw=ImageDraw.Draw(board);font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',14)
for k,w in enumerate(catalog):
 x=k%4;y=k//4;tile=source.crop((round(x*source.width/4)+3,round(y*source.height/3)+3,round((x+1)*source.width/4)-3,round((y+1)*source.height/3)-3)).resize((64,64),Image.Resampling.NEAREST)
 ref=tile.copy()
 for yy in range(64):
  c=tuple((ref.getpixel((0,yy))[j]+ref.getpixel((63,yy))[j])//2 for j in range(3));ref.putpixel((0,yy),c);ref.putpixel((63,yy),c)
 for xx in range(64):
  c=tuple((ref.getpixel((xx,0))[j]+ref.getpixel((xx,63))[j])//2 for j in range(3));ref.putpixel((xx,0),c);ref.putpixel((xx,63),c)
 for yy in range(64):
  for xx in range(64):
   d=min(xx,63-xx,yy,63-yy)
   if d<4:
    weight=(4-d)/4;a=tile.getpixel((xx,yy));b=ref.getpixel((xx,yy));tile.putpixel((xx,yy),tuple(round(a[j]*(1-weight)+b[j]*weight) for j in range(3)))
 tile=tile.quantize(colors=32,dither=Image.Dither.NONE).convert('RGBA');tile.save(OUT/'textures'/f"{w['id']}.png");payload[w['id']]=base64.b64encode(tile.tobytes()).decode('ascii')
 rgb=tuple(sum(c[j] for c in tile.getdata())//4096 for j in range(3));shade=lambda f:'#'+''.join(f'{min(255,round(c*f)):02x}' for c in rgb);colors[w['id']]={'dark':shade(.65),'light':shade(1.18)}
 bx=x*240;by=y*220;board.paste(tile.resize((192,192),Image.Resampling.NEAREST).convert('RGB'),(bx+24,by+4));draw.text((bx+12,by+198),w['name'],font=font,fill='#e3e9cf')
(ROOT/'tools/plant-lab/wall-data.mjs').write_text('export const WALL_BYTES='+json.dumps(payload)+';\nexport const WALL_COLORS='+json.dumps(colors)+';\n',encoding='utf-8');(OUT/'kit.json').write_text(json.dumps({'id':'kronasta-walls-v1','materials':[{**w,**colors[w['id']]} for w in catalog],'texture':[64,64],'orientation':'front-elevation; source rows follow screen-down, renderer samples negative world height','recipe':'Generated art; explicit crops; nearest-neighbor; periodic edge strips; 32-color palettes.'},ensure_ascii=False,indent=2),encoding='utf-8');board.save(OUT/'catalog-preview.png');print('12 vertical wall textures prepared.')

"""Crop generated sprite sheets, normalize their scale, and assemble tree connections."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,subprocess,os
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'art/environment/kronasta-nature-v1'
for d in ['sprites','atlases','parts']: (OUT/d).mkdir(exist_ok=True)
# The JS catalog is authoritative for names, target scale, pivots and consumers.
node=os.environ.get('PIXEL_NODE','node')
catalog=json.loads(subprocess.check_output([node,'--input-type=module','-e',"import{NATURE_ASSETS}from'./tools/plant-lab/nature-kit.mjs';console.log(JSON.stringify(NATURE_ASSETS))"],cwd=ROOT,text=True,encoding='utf-8'))
def norm(m):
 n=m&15
 for bit,a,b in [(16,1,2),(32,2,4),(64,4,8),(128,8,1)]:
  if m&bit and m&a and m&b:n|=bit
 return n
masks=sorted({norm(m) for m in range(256)})
offsets=[(-1,-1,128),(0,-1,1),(1,-1,16),(-1,0,8),(0,0,0),(1,0,2),(-1,1,64),(0,1,4),(1,1,32)]
for group,cols,rows,items in [('trees',3,2,catalog[:6]),('plants',4,3,catalog[6:18]),('props',4,3,catalog[18:])]:
 source=Image.open(OUT/'sources'/f'{group}.png').convert('RGBA')
 for i,spec in enumerate(items):
  x=i%cols;y=i//cols
  tile=source.crop((round(x*source.width/cols),round(y*source.height/rows),round((x+1)*source.width/cols),round((y+1)*source.height/rows)))
  alpha=tile.getchannel('A').point(lambda a:255 if a>=210 else 0);assert alpha.getbbox(),spec['id'];tile.putalpha(alpha);tile=tile.crop(alpha.getbbox());tile.thumbnail(tuple(spec['size']),Image.Resampling.NEAREST)
  alpha=tile.getchannel('A');tile=tile.convert('RGB').quantize(colors=40,dither=Image.Dither.NONE).convert('RGBA');tile.putalpha(alpha)
  if spec['tree']:
   # Remove isolated sheet-edge fragments introduced by neighboring cells.
   seen=set();pixels=tile.load()
   for yy in range(tile.height):
    for xx in range(tile.width):
     if (xx,yy) in seen or pixels[xx,yy][3]==0:continue
     component=[];pending=[(xx,yy)];seen.add((xx,yy))
     while pending:
      px,py=pending.pop();component.append((px,py))
      for qx,qy in [(px-1,py),(px+1,py),(px,py-1),(px,py+1)]:
       if 0<=qx<tile.width and 0<=qy<tile.height and (qx,qy) not in seen and pixels[qx,qy][3]:seen.add((qx,qy));pending.append((qx,qy))
     if len(component)<9:
      for px,py in component:pixels[px,py]=(0,0,0,0)
  base=Image.new('RGBA',(64,96 if spec['tree'] else 64));base.alpha_composite(tile,((64-tile.width)//2,spec['anchor'][1]-tile.height));base.save(OUT/'sprites'/f"{spec['id']}.png")
  if spec['tree']:
   canopy=base.copy();canopy.paste((0,0,0,0),(0,64,64,96));trunk=base.copy();trunk.paste((0,0,0,0),(0,0,64,64))
   canopy.save(OUT/'parts'/f"{spec['id']}-copa.png");trunk.save(OUT/'parts'/f"{spec['id']}-tronco.png")
   atlas=Image.new('RGBA',(512,576))
   for k,m in enumerate(masks):
    frame=trunk.copy()
    for dx,dy,bit in offsets:
     if bit and not m&bit:continue
     frame.alpha_composite(canopy,(dx*32,dy*32))
    atlas.alpha_composite(frame,((k%8)*64,(k//8)*96))
   atlas.save(OUT/'atlases'/f"{spec['id']}.png")
(OUT/'kit.json').write_text(json.dumps(dict(id='kronasta-nature-v1',assets=catalog,masks=masks,treeFrame=[64,96],propFrame=[64,64],sourceGrid={'trees':[3,2],'plants':[4,3],'props':[4,3]},method='Generated art, explicit sheet cuts, nearest-neighbor resampling, 40-color palettes, binary alpha. No procedural redrawing.'),indent=2,ensure_ascii=False),encoding='utf-8')
board=Image.new('RGBA',(1080,880),'#203632');draw=ImageDraw.Draw(board);font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',15)
for i,spec in enumerate(catalog):
 col=i%6;row=i//6;x=col*180;y=0 if row==0 else 240+(row-1)*155
 sprite=Image.open(OUT/'sprites'/f"{spec['id']}.png").convert('RGBA');sprite=sprite.resize((sprite.width*2,sprite.height*2),Image.Resampling.NEAREST)
 board.alpha_composite(sprite,(x+26,y+8));draw.text((x+8,y+(208 if row==0 else 136)),spec['name'],fill='#e3e9cf',font=font)
board.save(OUT/'catalog-preview.png');print('30 generated assets and 6 connected tree atlases prepared.')

"""Slice the generated artwork into a connected canopy atlas; never redraw its leaves."""
from pathlib import Path
import json
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/environment/topdown-forest-v2'
im=Image.open(OUT/'source-tree.png').convert('RGBA')
alpha=im.getchannel('A').point(lambda a:255 if a>=210 else 0)
im.putalpha(alpha)
im=im.crop(alpha.getbbox())
im.thumbnail((64,80),Image.Resampling.NEAREST)
alpha=im.getchannel('A')
im=im.convert('RGB').quantize(colors=32,dither=Image.Dither.NONE).convert('RGBA')
im.putalpha(alpha)
base=Image.new('RGBA',(64,96))
base.alpha_composite(im,((64-im.width)//2,80-im.height))
canopy=base.copy();canopy.paste((0,0,0,0),(0,64,64,96))
trunk=base.copy();trunk.paste((0,0,0,0),(0,0,64,64))
for name,picture in [('tree-64x96.png',base),('canopy.png',canopy),('trunk.png',trunk)]:
    picture.save(OUT/name)
base.save(ROOT/'art/environment/topdown-plants-pixel-v1/arvore-kronasta.png')
base.resize((384,576),Image.Resampling.NEAREST).save(OUT/'tree-preview-6x.png')

def normalize(m):
    n=m&15
    for bit,a,b in [(16,1,2),(32,2,4),(64,4,8),(128,8,1)]:
        if m&bit and m&a and m&b:n|=bit
    return n

masks=sorted({normalize(m) for m in range(256)})
atlas=Image.new('RGBA',(512,576))
neighbors=[(-1,-1,128),(0,-1,1),(1,-1,16),(-1,0,8),(0,0,0),(1,0,2),(-1,1,64),(0,1,4),(1,1,32)]
for index,mask in enumerate(masks):
    frame=trunk.copy()
    # Identical artwork and exact 32px offsets make overlaps coincide in world space.
    # Painter order matches rows from back to front and columns left to right.
    for dx,dy,bit in neighbors:
        if bit and not mask&bit:continue
        frame.alpha_composite(canopy,(dx*32,dy*32))
    atlas.alpha_composite(frame,((index%8)*64,(index//8)*96))
atlas.save(OUT/'trees.png')
(OUT/'kit.json').write_text(json.dumps(dict(id='arvores-kronasta-v2',tile=[32,32],frame=[64,96],anchor=[32,80],columns=8,rowsPerVariant=6,variants=1,masks=masks,source='source-tree.png',parts=['canopy.png','trunk.png'],method='Recortes da arte gerada, transparência binária, paleta de 32 cores, sem folhas procedurais.'),indent=2),encoding='utf-8')
print('Árvore gerada fatiada: copa, tronco e 47 conexões. Sem redesenho procedural.')

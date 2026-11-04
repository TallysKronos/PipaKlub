"""Crop regular generated cells, preserve alpha, normalize one shared scale and pack."""
from pathlib import Path
import json
from PIL import Image

root = Path(__file__).resolve().parent.parent
folder = root / 'art/characters/platyx/animation-v1'
source = Image.open(folder / 'source.png').convert('RGBA')
assert source.width == source.height
tiles = []
for row in range(4):
    strip=source.crop((0,row*source.height//4,source.width,(row+1)*source.height//4))
    alpha=strip.getchannel('A')
    counts=[sum(v>32 for v in alpha.crop((x,0,x+1,strip.height)).getdata()) for x in range(source.width)]
    cuts=[0]
    for column in range(1,4):
        nominal=column*source.width//4
        choices=range(nominal-45,nominal+46)
        cut=min(choices,key=lambda x:(sum(counts[max(0,x-3):x+4]),abs(x-nominal)))
        assert sum(counts[cut-3:cut+4])==0, (row,column,'no empty cut')
        cuts.append(cut)
    cuts.append(source.width)
    for col in range(4):
        tile = strip.crop((cuts[col],0,cuts[col+1],strip.height))
        box = tile.getchannel('A').point(lambda a: 255 if a > 32 else 0).getbbox()
        assert box and min(box[0], box[1], tile.width-box[2], tile.height-box[3]) >= 3, (row, col, box)
        tiles.append((tile, box))
scale = min(220/max(b[2]-b[0] for _, b in tiles), 184/max(b[3]-b[1] for _, b in tiles))
sheet = Image.new('RGBA', (1024, 1024))
frames = []
for i, (tile, box) in enumerate(tiles):
    crop = tile.crop(box)
    crop = crop.resize((round(crop.width*scale), round(crop.height*scale)), Image.Resampling.LANCZOS)
    x, y = (i%4)*256+(256-crop.width)//2, (i//4)*256+228-crop.height
    sheet.alpha_composite(crop, (x, y))
    frames.append({'x': (i%4)*256, 'y': (i//4)*256, 'w':256, 'h':256})
target = root / 'godot/assets/campaign/beira-canal-v1/platyx-v2.png'
sheet.save(target)
content_path = root / 'godot/assets/campaign/content.json'
content = json.loads(content_path.read_text(encoding='utf-8'))
groups = {'idle':frames[:4], 'flight':frames[:4], 'attack':frames[4:8], 'hurt':frames[8:11], 'defeat':[frames[11]], 'victory':frames[12:]}
old_keys = content['combat']['platyx-draft']['animations'].keys()
assert set(old_keys) <= groups.keys(), list(old_keys)
content['combat']['platyx-draft'] = {'image':'beira-canal-v1/platyx-v2.png', 'animations':groups,
    'playback':{key:{'fps':6 if key=='idle' else 8, 'loop':key in ['idle','flight','victory']} for key in groups}}
content_path.write_text(json.dumps(content, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
# Diagnostic animated previews over a neutral background; sprite art remains unchanged.
for action, entries in groups.items():
    previews=[]
    for frame in entries:
        bg=Image.new('RGBA',(256,256),(224,228,232,255))
        bg.alpha_composite(sheet.crop((frame['x'],frame['y'],frame['x']+256,frame['y']+256)))
        previews.append(bg.convert('RGB'))
    previews[0].save(folder/(action+'.gif'), save_all=True, append_images=previews[1:], duration=160 if action=='idle' else 125, loop=0)
(folder/'qa.json').write_text(json.dumps({'sourceSize':source.size,'atlasSize':sheet.size,'frames':16,'sharedScale':scale,'alphaRange':sheet.getchannel('A').getextrema(),'bounds':[b for _,b in tiles]},indent=2)+'\n')
print('PASS: 16 padded cells; shared scale; transparent 1024 atlas; 6 action mappings; previews written')

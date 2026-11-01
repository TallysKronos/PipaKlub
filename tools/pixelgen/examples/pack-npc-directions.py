"""Prepare directional NPC drafts for native Aseprite finishing and export.

Not an animation generator: eight static directions per identity. Source artwork
is retained; palette/grid checks do not certify anatomy or visual approval.
"""
import json
import statistics
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'art/characters/npc-ds-directions-v1'
W, H = 64, 96
DIRS = ['S', 'SO', 'O', 'NO', 'N', 'NE', 'E', 'SE']
INK = (10, 14, 29, 255)
GLYPHS = '.ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef'

def prepare(entry):
    source = Image.open(OUT / 'fontes' / (entry['id'] + '.png')).convert('RGBA')
    assert source.width % 4 == 0 and source.height % 2 == 0
    cw, ch = source.width // 4, source.height // 2
    cells = []
    bounds = []
    for index in entry['sourceOrder']:
        cell = source.crop((index % 4 * cw, index // 4 * ch, (index % 4 + 1) * cw, (index // 4 + 1) * ch))
        cell.putalpha(cell.getchannel('A').point(lambda a: 255 if a >= 180 else 0))
        box = cell.getbbox()
        if not box: raise ValueError(f"Empty direction: {entry['id']} / {index}")
        bounds.append(box)
        cells.append(cell.crop(box))
    scale = min(entry['height'] / max(im.height for im in cells), (W-6) / max(im.width for im in cells))
    drafts = []
    for cell in cells:
        sized = cell.resize((max(1, round(cell.width * scale)), max(1, round(cell.height * scale))), Image.Resampling.NEAREST)
        frame = Image.new('RGBA', (W,H))
        frame.paste(sized, ((W-sized.width)//2, 95-sized.height))
        drafts.append(frame)
    # One palette for all views, weighted by opaque material pixels only.
    samples = [rgb[:3] for im in drafts for rgb in im.getdata() if rgb[3]]
    swatch = Image.new('RGB',(len(samples),1));swatch.putdata(samples)
    reduced = swatch.quantize(colors=30, method=Image.Quantize.MEDIANCUT)
    raw = reduced.getpalette()
    used = sorted(set(reduced.getdata()))
    palette = [(0,0,0,0), INK] + [tuple(raw[i*3:i*3+3])+(255,) for i in used]
    frames=[]; clean_reports=[]
    for image in drafts:
        cache={}; indices=[]
        for pixel in image.getdata():
            if not pixel[3]:indices.append(0);continue
            if pixel not in cache:
                cache[pixel]=min(range(1,len(palette)),key=lambda i:sum((pixel[c]-palette[i][c])**2 for c in range(3)))
            indices.append(cache[pixel])
        # Proposal only: native draw applies the complete grid, including cleanup.
        fixed=indices.copy();visited=set();removed=0
        for at,value in enumerate(indices):
            if not value or at in visited:continue
            component=[];stack=[at];visited.add(at)
            while stack:
                p=stack.pop();component.append(p);x,y=p%W,p//W
                for dy in [-1,0,1]:
                    for dx in [-1,0,1]:
                        xx,yy=x+dx,y+dy;q=yy*W+xx
                        if 0<=xx<W and 0<=yy<H and indices[q] and q not in visited:
                            visited.add(q);stack.append(q)
            if len(component)<=2:
                for p in component:fixed[p]=0;removed+=1
        solid=fixed.copy();changed=0
        for at,value in enumerate(solid):
            if not value:continue
            x,y=at%W,at//W
            if any(xx<0 or xx>=W or yy<0 or yy>=H or not solid[yy*W+xx] for xx,yy in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]):
                if fixed[at]!=1:fixed[at]=1;changed+=1
        frames.append(fixed);clean_reports.append({'detachedPixelsRemoved':removed,'edgePixelsInked':changed})
    target=OUT/'pacote'/entry['id'];target.mkdir(parents=True,exist_ok=True)
    project={'kind':'pixelgen','version':2,'name':entry['name']+' · bases direcionais','width':W,'height':H,'cols':4,'rows':2,
             'palette':palette,'layers':[{'name':'Arte','visible':True,'locked':False}],
             'frames':[{'name':'idle-'+direction+'-1','duration':200,'indices':ind,'cels':[ind]} for direction,ind in zip(DIRS,frames)],
             'sequences':[{'name':'idle-'+d,'start':i,'end':i,'loop':True,'direction':'forward'} for i,d in enumerate(DIRS)],
             'settings':{'width':W,'height':H,'cols':4,'rows':2,'margin':2,'colors':32}}
    (target/(entry['id']+'.pixelgen.json')).write_text(json.dumps(project,ensure_ascii=False),encoding='utf8')
    legend={GLYPHS[i]:'#'+''.join(f'{c:02x}' for c in rgba) for i,rgba in enumerate(palette)}
    plans=[{'kind':'grid','x':0,'y':0,'legend':legend,'rows':[''.join(GLYPHS[v] for v in ind[y*W:(y+1)*W]) for y in range(H)]} for ind in frames]
    (target/'native-plan.json').write_text(json.dumps({'palette':list(legend.values()),'grids':plans}),encoding='utf8')
    manifest={'id':entry['id'],'name':entry['name'],'source':'../../fontes/'+entry['id']+'.png','identityReference':entry['ref'],
              'cell':[W,H],'pivot':[32,94],'directions':DIRS,'sourceOrder':entry['sourceOrder'],'sharedScale':scale,
              'sourceBounds':bounds,'colors':len(palette)-1,'cleanup':clean_reports,'animation':'static directional bases; no walk cycle',
              'status':'draft awaiting native Aseprite review/export'}
    (target/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
    sheet=Image.new('RGBA',(W*4,H*2))
    for i,ind in enumerate(frames):
        im=Image.new('RGBA',(W,H));im.putdata([palette[v] for v in ind]);sheet.paste(im,(i%4*W,i//4*H))
    sheet.save(target/'candidate.png')
    return {'id':entry['id'],'opaqueColors':len(palette)-1,'frames':8,'height':entry['height']}

if __name__=='__main__':
    brief=json.loads((OUT/'brief.json').read_text(encoding='utf8'))
    reports=[prepare(e) for e in brief['characters'] if (OUT/'fontes'/(e['id']+'.png')).exists()]
    print(json.dumps(reports,ensure_ascii=False))

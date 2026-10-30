"""Non-generative research layout: scaled source previews, never redraws source art."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from collect_index import ROOT

entries=json.loads((ROOT/'reference-sources.json').read_text(encoding='utf-8'))
output=Path(entries[0]['local_research_file']).parent
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',21)
available=[e for e in entries if e['status']=='available_for_visual_inspection']
for first in range(0,len(available),4):
    canvas=Image.new('RGB',(1600,1240),'#e2e4e7')
    draw=ImageDraw.Draw(canvas)
    group=available[first:first+4]
    for i,e in enumerate(group):
        x=(i%2)*800
        y=(i//2)*620
        source=Image.open(e['local_research_file']).convert('RGB')
        source.thumbnail((780,574),Image.Resampling.LANCZOS)
        canvas.paste(source,(x+(800-source.width)//2,y+38+(574-source.height)//2))
        draw.text((x+12,y+8),e['id']+' '+e['name'][:52],font=font,fill='#172635')
    path=output/f'review-{first//4+1:02}.jpg'
    canvas.save(path,quality=92)
    print(path)

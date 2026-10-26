"""Detecta quatro silhuetas separadas no alpha e uniformiza altura, nunca proporção."""
from pathlib import Path
from PIL import Image
import json
HERE=Path(__file__).resolve().parent/'manga-v2'
source=Image.open(HERE/'PROPS-MANGA.png').convert('RGBA')
assert source.getchannel('A').getextrema()[0]==0, 'Fonte precisa ter transparência real'
# Generated sheet has <=8/255 alpha noise outside the silhouettes; normalize
# only that invisible padding before finding bounds. Original source preserved.
source.putalpha(source.getchannel('A').point(lambda v:0 if v<=8 else v))
report=[]
alpha=source.getchannel('A')
occupied=[x for x in range(source.width) if sum(v>32 for v in alpha.crop((x,0,x+1,source.height)).get_flattened_data())>4]
groups=[];start=last=occupied[0]
for x in occupied[1:]:
    if x-last>5: groups.append((start,last+1));start=x
    last=x
groups.append((start,last+1))
assert len(groups)==4, f'Esperadas quatro peças separadas; encontrado {groups}'
cuts=[0]+[(groups[i][1]+groups[i+1][0])//2 for i in range(3)]+[source.width]
for i,(name,height) in enumerate([('arvore',160),('banco',56),('poste',144),('porta',112)]):
    column=source.crop((cuts[i],0,cuts[i+1],source.height))
    bbox=column.getchannel('A').getbbox()
    assert bbox and bbox[0]>0 and bbox[1]>0 and bbox[2]<column.width and bbox[3]<column.height, f'{name}: peça tocando limite de coluna'
    crop=column.crop(bbox)
    width=round(crop.width*height/crop.height)
    native=crop.resize((width,height),Image.Resampling.LANCZOS)
    native.save(HERE/f'{name}-nativo.png')
    crop.save(HERE/f'{name}-fonte.png')
    report.append({'name':name,'source_x_range':[cuts[i],cuts[i+1]],'source_alpha_bbox':bbox,'padding_alpha_noise_threshold':8,'size':[width,height],'pivot':[width//2,height],'preserve_aspect':True,'role':'style and scale reference; not runtime asset','approval':'pending_family_review'})
(HERE/'props-normalizacao.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print('Quatro props normalizados por altura, com alpha e proporção preservados.')

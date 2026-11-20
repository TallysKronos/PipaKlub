from pathlib import Path
import json,hashlib
from PIL import Image,ImageOps,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parent
data=json.loads((ROOT/'coleta.json').read_text(encoding='utf-8'))
for item in data:
 for extra in item['images'][1:]:
  path=(ROOT/extra['file']).resolve()
  assert path.parent==(ROOT/'referencias').resolve()
  if path.is_file()and hashlib.sha256(path.read_bytes()).hexdigest()==extra['sha256']:path.unlink()
 item['images']=item['images'][:1]
(ROOT/'coleta.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',27)
for n,group in enumerate([data[:5],data[5:9],data[9:]],1):
 sheet=Image.new('RGB',(len(group)*440,650),'white');draw=ImageDraw.Draw(sheet)
 for i,item in enumerate(group):
  im=Image.open(ROOT/item['images'][0]['file']).convert('RGB')
  thumb=ImageOps.contain(im,(420,570));sheet.paste(thumb,(i*440+(440-thumb.width)//2,(570-thumb.height)//2))
  draw.text((i*440+10,600),item['name'],font=font,fill='#182030')
 sheet.save(ROOT/f'comparativo-{n}.jpg',quality=94)
print('13 artes principais; 3 comparativos de estudo. Imagens relacionadas removidas da coleta própria.')

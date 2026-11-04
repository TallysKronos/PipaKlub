"""Compose audit screenshots without redrawing or altering the game art."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps
import json, html, math, os

root=Path(__file__).resolve().parents[1]
source=root/'tmp/player-audit-2026-10-26/pip78-final'
records=json.loads((source/'measurements.json').read_text(encoding='utf-8-sig'))
destination=root/'godot/assets/ui/recorte-v1/mockups/revisao'
destination.mkdir(parents=True,exist_ok=True)
review=root/'mockups/revisao/pip78'
review.mkdir(parents=True,exist_ok=True)
font_path=root/'godot/assets/campaign/ui-modern/fonts/Nunito.ttf'
font=ImageFont.truetype(str(font_path),16)
heading=ImageFont.truetype(str(font_path),32)
cards=[r for r in records if r['requested_pixels']==[1280,720]]
cols=6; w=320; h=214; gap=16
board=Image.new('RGB',(cols*w+(cols+1)*gap,120+math.ceil(len(cards)/cols)*(h+gap)), '#141e29')
draw=ImageDraw.Draw(board)
draw.text((20,18),'SOULMONSTERS · REVISÃO PIP-78',fill='#f4e9d2',font=heading)
draw.text((20,65),f'{len(cards)} telas · capturas reais do Godot · versões ampliadas na galeria HTML',fill='#2ec8e3',font=font)
for index,record in enumerate(cards):
    x=gap+(index%cols)*(w+gap); y=110+(index//cols)*(h+gap)
    with Image.open(source/record['image']) as image:
        thumbnail=ImageOps.contain(image.convert('RGB'),(w,180),Image.Resampling.LANCZOS)
        board.paste(thumbnail,(x+(w-thumbnail.width)//2,y))
    draw.rectangle((x,y,x+w-1,y+179),outline='#33475a',width=2)
    draw.text((x,y+185),record['scenario'],fill='#f4e9d2',font=font)
board.save(destination/'PRANCHA.png')
(review/'auditoria.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
gallery=[]
for record in records:
    path=os.path.relpath(source/record['image'],review).replace('\\','/')
    size='×'.join(map(str,record['requested_pixels']))
    gallery.append(f'<a href="{html.escape(path)}" data-size="{size}"><img loading="lazy" src="{html.escape(path)}"><span>{html.escape(record["scenario"])} · {size}</span></a>')
sizes=['×'.join(map(str,x)) for x in dict.fromkeys(tuple(r['requested_pixels']) for r in records)]
document='''<!doctype html><meta charset="utf-8"><title>PIP-78 · Prancha de revisão</title>
<style>body{background:#141e29;color:#f4e9d2;font:18px system-ui;margin:24px}header{position:sticky;top:0;background:#141e29;padding:12px;z-index:1}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(330px,1fr));gap:18px}a{color:inherit;text-decoration:none}img{width:100%;border:1px solid #33475a}span{display:block;padding:8px}select,input{font:inherit;margin:8px;padding:8px}</style>
<header><h1>Soulmonsters · PIP-78</h1><p>Capturas reais. Clique para abrir em tamanho original. Revisão visual aguardando aprovação.</p>
<label>Resolução <select id="size">'''+''.join(f'<option>{s}</option>' for s in sizes)+'''</select></label><label>Tela <input id="search" placeholder="batalha, opening, menu…"></label></header><main>'''+''.join(gallery)+'''</main><script>function filter(){for(const card of document.querySelectorAll('main a'))card.hidden=card.dataset.size!==size.value||!card.textContent.toLowerCase().includes(search.value.toLowerCase())}size.onchange=filter;search.oninput=filter;filter()</script>'''
(review/'index.html').write_text(document,encoding='utf-8')
def luminance(value):
    rgb=[int(value[i:i+2],16)/255 for i in (0,2,4)]
    rgb=[x/12.92 if x<=.04045 else ((x+.055)/1.055)**2.4 for x in rgb]
    return sum(x*k for x,k in zip(rgb,[.2126,.7152,.0722]))
pairs=[('papel/tinta','f4e9d2','141e29'),('papel/tinta2','f4e9d2','22303f'),('papel2/tinta2','d8c9ac','22303f'),('ceu/tinta','2ec8e3','141e29'),('sol/tinta','ffc23d','141e29'),('nanquim/rabiola','0b1017','ff5a36')]
contrast=[]
for name,foreground,background in pairs:
    a,b=sorted([luminance(foreground),luminance(background)])
    contrast.append({'pair':name,'ratio':round((b+.05)/(a+.05),2),'body_text_pass':(b+.05)/(a+.05)>=4.5})
(review/'contraste.json').write_text(json.dumps(contrast,indent=2),encoding='utf-8')
print(json.dumps({'screens':len(cards),'renders':len(records),'severe':sum(f['priority'] in ['P1','P2'] for r in records for f in r['findings']),'board':str(destination/'PRANCHA.png')}))

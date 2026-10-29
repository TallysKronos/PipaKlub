"""Review board from real Godot captures; never generates/repaints game art."""
from pathlib import Path
import json, html
from PIL import Image,ImageDraw,ImageFont,ImageOps
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/overworld/revisao/parque-abc'
report=json.loads((OUT/'conferencia.json').read_text(encoding='utf-8'))
ids=['jardim-das-pipas','clareira-do-papel','veredas-do-encanamento']
names=['A · Jardim / Nina e chegada','B · Clareira / riacho e desvios','C · Veredas / pátio de Lacertubo']
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',23)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',20)
heading=ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf',36)
board=Image.new('RGB',(1920,1110),'#141e29');d=ImageDraw.Draw(board)
d.text((28,22),'PARQUE DOS VENTOS · PLANTAS A / B / C',fill='#f4e9d2',font=heading)
d.text((28,77),'Capturas reais do Godot · pisos mangá v3 · riacho rebaixado · pontes contínuas desenhadas',fill='#2ec8e3',font=font)
for col,(id,name,data) in enumerate(zip(ids,names,report['areas'])):
    x=24+col*636
    d.text((x,130),name,fill='#ffc23d',font=font)
    for suffix,y,h in [('kit-estudo-1x',170,365),('escala-jogo',615,343)]:
        with Image.open(OUT/f'{id}-{suffix}.png') as im:
            thumb=ImageOps.contain(im.convert('RGB'),(608,h),Image.Resampling.LANCZOS)
            board.paste(thumb,(x+(608-thumb.width)//2,y+(h-thumb.height)//2))
        d.rectangle((x,y,x+608,y+h),outline='#33475a',width=2)
    d.text((x,545),f'{data["size"][0]}×{data["size"][1]} · alto {data["raised_percent"]}% · 3 itens',fill='#f4e9d2',font=small)
d.text((28,585),'CÂMERAS NA ESCALA DE JOGO · personagens em posições de revisão, sem alterar a campanha',fill='#2ec8e3',font=small)
d.text((28,990),'Conferido: acessos, retornos, 9 itens, rampas e rotas sem mato obrigatório. IDs antigos preservados.',fill='#f4e9d2',font=font)
d.text((28,1032),'Pendente: ritmo cronometrado, condições da missão, coleta/saves e revisão final das transições.',fill='#ffc23d',font=small)
board.save(OUT/'PRANCHA.png')

parts=[]
for id,name,data in zip(ids,names,report['areas']):
    cards=[]
    for suffix,label in [('geometria-1x','Planta geométrica 1×'),('kit-estudo-1x','Montagem com kit atual 1×'),('escala-jogo','Escala de jogo (fixture)'),('rampa-3x','Junta da rampa 3×'),('referencia','Referência anterior do Mapa Studio'),('legendas','Legenda anterior de eventos e coordenadas')]:
        file=f'{id}-{suffix}.png'
        cards.append(f'<figure><a href="{file}"><img loading="lazy" src="{file}" alt="{html.escape(label)}"></a><figcaption>{html.escape(label)}</figcaption></figure>')
    if id=='clareira-do-papel':
        cards.append('<figure><a href="clareira-do-papel-ponte-3x.png"><img loading="lazy" src="clareira-do-papel-ponte-3x.png" alt="Ponte em 3×"></a><figcaption>Cabeceiras da ponte · 3×</figcaption></figure>')
        cards.append('<figure><a href="clareira-do-papel-riacho-manga.png"><img loading="lazy" src="clareira-do-papel-riacho-manga.png" alt="Ponte mangá e leito rebaixado"></a><figcaption>Revisão v3 · personagem sobre o tabuleiro · 1,5×</figcaption></figure>')
    parts.append(f'<section id="{id}"><h2>{html.escape(name)}</h2><p>{data["size"][0]}×{data["size"][1]} células · {data["raised_percent"]}% elevado · {data["item_count"]} eventos de item · {data["preserved_ids"]} IDs anteriores preservados. <a href="http://127.0.0.1:5244/?mapa={id}">Percorrer na bancada local</a></p><div class="grid">'+''.join(cards)+'</div></section>')
page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Parque dos Ventos · revisão regional</title>
<style>body{margin:28px;background:#141e29;color:#f4e9d2;font:18px/1.5 system-ui}p{max-width:1100px}a{color:#2ec8e3}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(400px,1fr));gap:24px}figure{margin:0}img{width:100%;background:#22303f}figcaption{padding:8px}strong{color:#ffc23d}nav{display:flex;gap:24px;flex-wrap:wrap;padding:16px 0}section{margin-top:40px}</style>
<h1>Parque dos Ventos · A ↔ B ↔ C</h1><p><strong>Proposta de plantas conectadas, não campanha final.</strong> Assets naturais aplicados, incluindo barrancos, água, pontes e margens. B/C têm rotas baixa e alta com chegadas próprias; as transições ainda aguardam revisão final. A meta de duração e as condições de coleta/atalho continuam pendentes de integração.</p>
<p><a href="RELATORIO.md">Relatório completo</a> · <a href="conferencia.json">Medições regionais</a> · <a href="PRANCHA.png">Abrir prancha</a> · <a href="../../briefs/parque-dos-ventos-abc.md">Brief de narrativa e exploração</a></p><nav>'''+''.join(f'<a href="#{id}">{name}</a>' for id,name in zip(ids,names))+'''</nav>'''+''.join(parts)+'</html>'
(OUT/'index.html').write_text(page,encoding='utf-8')
print(OUT/'PRANCHA.png')

"""Review composition only: never repaints or changes the generated assets."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json, hashlib
root=Path(__file__).resolve().parents[2]
folder=root/'art/overworld/conceitos'
files=sorted(folder.glob('*-conceito.png'))
board=Image.new('RGB',(1800,180+len(files)*730),'#f5e9cb')
draw=ImageDraw.Draw(board)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',30)
draw.text((40,30),'MORRO • estudos de montagem no Godot',font=font,fill='#26394d')
draw.text((40,85),'Revisão: composição e repetição ainda em refinamento',font=font,fill='#26394d')
for i,file in enumerate(files):
    y=180+i*730
    draw.text((40,y),file.stem.removesuffix('-conceito'),font=font,fill='#26394d')
    for j,suffix in enumerate(['referencia','conceito']):
        image=Image.open(file.with_name(file.name.replace('conceito',suffix))).convert('RGB')
        image.thumbnail((850,650))
        board.paste(image,(40+j*890,y+50))
board.save(folder/'PRANCHA-REVISAO.jpg',quality=92)
style=root/'art/overworld/estilo'
approval={'issue':'PIP-82','status':'approved_direction','evidence':'User: ótimo continue; next three production issues attached','scope':'style direction, not approval of later kits or final campaign replacement','board_sha256':hashlib.sha256((style/'PRANCHA-ESTILO.png').read_bytes()).hexdigest()}
(style/'aprovacao.json').write_text(json.dumps(approval,ensure_ascii=False,indent=2),encoding='utf-8')

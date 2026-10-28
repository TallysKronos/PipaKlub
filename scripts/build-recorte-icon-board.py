"""Assemble the PIP-65 review board from the actual Godot-rendered PNG exports."""
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'godot/assets/ui/recorte-v1'
TOKENS = {'ink': '#141e29', 'paper': '#f4e9d2', 'sky': '#2ec8e3'}
FONT = ROOT / 'godot/assets/campaign/ui-modern/fonts/Nunito.ttf'
def font(size):
    face = ImageFont.truetype(str(FONT), size)
    face.set_variation_by_axes([650])
    return face

manifest = json.loads((ART / 'icons/manifest.json').read_text(encoding='utf8'))
assets = manifest['assets']
board = Image.new('RGB', (1864, 136 + math.ceil(len(assets)/3)*174), TOKENS['ink'])
draw = ImageDraw.Draw(board)
draw.text((32,20), 'RECORTE / ICONES PARA JOGAR', font=font(32), fill=TOKENS['paper'])
draw.text((32,68), '24 / 48 / 96 px  ·  tinta / céu claro  ·  fontes: SVGs exportados pelo Godot', font=font(21), fill=TOKENS['paper'])
for index, asset in enumerate(assets):
    x, y = 32+(index%3)*600, 128+(index//3)*174
    draw.text((x+4,y), asset['id'], font=font(18), fill=TOKENS['paper'])
    draw.rectangle((x,y+28,x+289,y+165),fill=TOKENS['ink'],outline='#33475a')
    draw.rectangle((x+290,y+28,x+589,y+165),fill=TOKENS['sky'])
    icon = Image.open(ART / 'icons' / asset['png96']).convert('RGBA')
    for offset in (0,290):
        for size, dx in ((24,12),(48,58),(96,132)):
            scaled = icon.resize((size,size), Image.Resampling.LANCZOS)
            board.paste(scaled,(x+offset+dx,y+44+(96-size)//2),scaled)
(ART / 'mockups').mkdir(exist_ok=True)
board.save(ART / 'mockups/icones.png')
(ROOT / 'godot/mockups').mkdir(exist_ok=True)
board.save(ROOT / 'godot/mockups/icones.png')

glyphs = Image.new('RGB',(1280,620),TOKENS['ink'])
draw = ImageDraw.Draw(glyphs)
draw.text((30,16),'INPUT / MESMAS ACOES, SIMBOLOS CORRETOS',font=font(26),fill=TOKENS['paper'])
families=['kbd','xbox','ps','switch']
routes=json.loads((ART/'mockups/input-routes.json').read_text(encoding='utf8'))
for row, family in enumerate(families):
    draw.text((30,94+row*128),{'kbd':'Teclado','xbox':'Xbox','ps':'PlayStation','switch':'Nintendo Switch'}[family],font=font(20),fill=TOKENS['paper'])
    for col,(name,action) in enumerate([('Interagir','interact'),('Cortar','cut'),('Habilidade','skill'),('Esquiva','dodge'),('Guarda','guard'),('Assinatura','signature'),('Pausa','pause')]):
        key=routes[family][action]['glyph']
        image=Image.open(ART/'glyphs/png64'/family/(key+'.png')).convert('RGBA')
        x,y=245+col*144,66+row*128
        glyphs.paste(image,(x,y),image)
        draw.text((x-12,y+69),name,font=font(16),fill=TOKENS['paper'])
glyphs.save(ART / 'mockups/glyphs.png')
print('Review boards exported: icones.png, glyphs.png')

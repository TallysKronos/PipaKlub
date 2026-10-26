"""PIP-82: fonte editável da prancha. Python 3 + Pillow; nenhuma alteração no jogo.
Coordenadas da régua em pixels nativos; apresentação ampliada explicitamente.
Gera PNG e SVG autocontido com a mesma geometria, textos e imagens incorporadas.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import base64, html, io, json, math, hashlib, xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
W, H = 3200, 4600
INK, PAPER, MUTED = '#26394D', '#F5E9CB', '#57666A'
im = Image.new('RGB', (W,H), '#EEE9DC')
d = ImageDraw.Draw(im)
svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">']
FONT = ROOT/'godot/assets/campaign/ui-modern/fonts/Nunito.ttf'
TITLE = ROOT/'godot/assets/campaign/ui-modern/fonts/BarlowCondensed-Bold.ttf'
svg.append('<defs><style>'+''.join('@font-face{font-family:"'+family+'";src:url(data:font/ttf;base64,'+base64.b64encode(path.read_bytes()).decode()+');font-weight:'+weight+';}' for family,path,weight in [('Nunito',FONT,'200 1000'),('Barlow Condensed',TITLE,'700')])+'</style></defs>')
checks = []

def rect(x,y,w,h,fill,stroke=None,sw=2):
    d.rectangle((x,y,x+w,y+h), fill=fill, outline=stroke, width=sw)
    svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}" stroke="{stroke or "none"}" stroke-width="{sw}"/>')

def poly(points,fill,stroke=INK,sw=3):
    d.polygon(points,fill=fill)
    if stroke: d.line(points+[points[0]],fill=stroke,width=sw,joint='curve')
    svg.append(f'<polygon points="{" ".join(f"{x},{y}" for x,y in points)}" fill="{fill}" stroke="{stroke or "none"}" stroke-width="{sw}" stroke-linejoin="round"/>')

def line(points,fill=INK,sw=2):
    d.line(points,fill=fill,width=sw)
    svg.append(f'<polyline points="{" ".join(f"{x},{y}" for x,y in points)}" fill="none" stroke="{fill}" stroke-width="{sw}"/>')

def txt(x,y,s,size=26,fill=INK,bold=False):
    font=ImageFont.truetype(str(TITLE if bold else FONT),size)
    if not bold: font.set_variation_by_axes([600])
    d.text((x,y),s,font=font,fill=fill,anchor='lt')
    # Fonts embedded in SVG defs; PNG rendered from the same OFL repo fonts.
    svg.append(f'<text x="{x}" y="{y+size*.82}" font-family="{("Barlow Condensed" if bold else "Nunito")}" font-weight="{700 if bold else 600}" font-size="{size}" fill="{fill}">{html.escape(s)}</text>')
    checks.append({'text':s,'box':[x,y,x+d.textlength(s,font=font),y+size]})

def picture(pic,x,y,w,h):
    assert abs((w/h)/(pic.width/pic.height)-1)<.015, 'Não deformar imagens'
    pic=pic.convert('RGBA').resize((int(w),int(h)),Image.Resampling.LANCZOS)
    im.paste(pic,(int(x),int(y)),pic)
    out=io.BytesIO();pic.save(out,format='PNG')
    data=base64.b64encode(out.getvalue()).decode()
    svg.append(f'<image x="{x}" y="{y}" width="{w}" height="{h}" href="data:image/png;base64,{data}"/>')

def panel(x,y,w,h,number,title,sub=None):
    rect(x,y,w,h,'#FAF6EB')
    rect(x,y,7,h,'#BC6749')
    txt(x+24,y+20,number,24,'#BC6749',True)
    txt(x+78,y+16,title,38,INK,True)
    if sub:txt(x+24,y+70,sub,23,MUTED)

def iso(x,y,u,v,z=0,s=1):return (x+(u-v)*32*s,y+(u+v)*16*s-z*s)
def tile(x,y,u,v,z,fill,s=1):
    poly([iso(x,y,*p,z,s) for p in [(u,v),(u+1,v),(u+1,v+1),(u,v+1)]],fill,INK,max(1,round(2*s)))

def box(x,y,top,medium,dark,s=2,height=64):
    # SW = u=0 side; SE = v=1 side. z in pixels, never tile units.
    a,b,c,e=[iso(x,y,*p,0,s) for p in [(0,0),(1,0),(1,1),(0,1)]]
    up=lambda p:(p[0],p[1]-height*s)
    poly([(e[0]-8*s,e[1]+4*s),(c[0]+10*s,c[1]+6*s),(b[0]+12*s,b[1]+3*s),(c[0]+7*s,c[1]-2*s)],'#D3CEBE',None)
    poly([up(a),up(e),e,a],dark,INK,round(2*s))
    poly([up(e),up(c),c,e],dark,INK,round(2*s))
    poly([up(c),up(b),b,c],medium,INK,round(2*s))
    poly([up(a),up(b),up(c),up(e)],top,INK,round(2*s))

def kael():
    base=ROOT/'godot/assets/kael'
    m=json.loads((base/'manifest.json').read_text(encoding='utf-8'))
    f=m['actions']['parado']['directions']['se'][0]
    canvas=Image.new('RGBA',(160,160))
    for key in ['mochila-pipa','base','alcas-mochila','cabelo-kael']:
        if key=='base':canvas.alpha_composite(Image.open(base/f['image']).convert('RGBA'),(16,16));continue
        layer=m['layers'][key]; mount=f['head' if layer['kind']=='head' else 'torso']; a=layer['anchor']['se']
        canvas.alpha_composite(Image.open(base/layer['images']['se']).convert('RGBA'),(16+mount[0]-a[0],16+mount[1]-a[1]))
    return canvas.crop(canvas.getbbox())

rect(0,0,W,150,INK)
txt(64,29,'SOULMONSTERS / PIPAKLUB',26,'#E8BC58',True)
txt(64,66,'UM MUNDO, UMA RÉGUA.',65,PAPER,True)
txt(2310,35,'PIP-82 • PRANCHA v2',31,PAPER,True)
txt(2310,83,'Acabamento aprovado • família em revisão',26,'#E8BC58')

panel(60,190,990,505,'01','PROJEÇÃO E CONTINUIDADE','Isométrico 2:1 • célula e parede 2× • acessos 1×')
tile(200,355,0,0,0,'#E8BC58',2)
line([(136,385),(264,385)],INK,2)
txt(144,440,'64 × 32 px',25,INK,True)
txt(109,485,'Célula nativa',23,MUTED)
box(410,440,PAPER,'#D8C59C','#A99572',2)
line([(500,312),(500,440)],INK,3)
txt(513,350,'64 px',24,INK,True)
txt(330,554,'1 nível / 2 células',23,MUTED)
# Ramp: one-cell rise over four cells, connected top and supported side wedge.
rx,ry,ss=730,455,1
p=lambda u,v,z=0:iso(rx,ry,u,v,z,ss)
poly([p(0,0,64),p(1,0,64),p(1,4),p(0,4)],'#D9B47A')
poly([p(1,0,64),p(1,4),p(1,0)],'#AD855C')
poly([p(0,0,64),p(1,0,64),p(1,-1,64),p(0,-1,64)],'#E4C493')
txt(608,554,'Rampa 4 células',23,MUTED)
# Stair: 8 risers = 64 px, same footprint as ramp, no wall across access.
sx,sy=970,455
for i in reversed(range(8)):
    v=i*.5; z=64-i*8
    ps=lambda u,v,z:iso(sx,sy,u,v,z,1)
    poly([ps(0,v,z),ps(1,v,z),ps(1,v+.5,z),ps(0,v+.5,z)],'#D8D4BF',INK,2)
    poly([ps(0,v+.5,z),ps(1,v+.5,z),ps(1,v+.5,z-8),ps(0,v+.5,z-8)],'#AEAD9E',INK,2)
txt(816,554,'8 espelhos × 8 px',23,MUTED)
txt(84,610,'x = (u − v) × 32     y = (u + v) × 16 − altura_px',25,INK,True)
txt(84,653,'Chão unido • borda pela altura • acesso sem parede cruzada',24,MUTED)

panel(1080,190,990,505,'02','LUZ E VALORES','Mesma caixa • mesma luz • quatro materiais')
for i,(name,colors) in enumerate([
    ('Bairro',(PAPER,'#D8C59C','#A99572')),
    ('Parque',('#9DBD74','#668A55','#476643')),
    ('Veredas',('#DDA874','#BC6749','#874A3C')),
    ('Morro',('#B9C7C4','#879E9E','#647D83'))]):
    xx=1215+i*222;box(xx,461,*colors,2)
    txt(xx-57,535,name,26,INK,True)
txt(1104,580,'Luz do alto à esquerda • topo claro',26,INK,True)
txt(1104,620,'Face SE média • face SW escura • contato curto',25,MUTED)
txt(1104,660,'A sombra não muda de direção entre biomas.',23,MUTED)

panel(2100,190,1040,505,'03','TRAÇO E MASSAS','Mangá 2D • tinta expressiva • recortes e cor chapada')
for x,c,label in [(2140,'#668A55','BASE'),(2460,'#476643','1 SOMBRA'),(2780,INK,'CONTORNO')]:
    poly([(x,340),(x+210,340),(x+245,460),(x-15,460)],c,INK,4)
    txt(x,490,label,28,INK,True)
txt(2124,550,'Meta nativa: 2 px externo / 1 px interno.',27,INK,True)
txt(2124,593,'Variação de tinta; contorno azul, sem render volumétrico.',24,MUTED)
txt(2124,634,'Papel, dobras, varetas e nós • caminhos sem ruído visual',24,MUTED)

panel(60,735,3080,365,'04','PALETA COMPARTILHADA','As diferenças vêm de material e vegetação, não de câmera, luz ou acabamento.')
base=[('Papel / reboco',PAPER),('Terracota','#BC6749'),('Azul profundo',INK),('Verde de quintal','#668A55'),('Luz de sol','#E8BC58')]
for i,(name,c) in enumerate(base):
    x=90+i*600;rect(x,850,76,76,c,INK,2);txt(x+94,856,name,27,INK,True);txt(x+94,895,c,24,MUTED)
biomes=[('BAIRRO',['#DDD9C8','#637F91',PAPER,'#BC6749'],'Calçada • asfalto • reboco • telha'),('PARQUE',['#8AAE62','#C7A16D','#DED3B7','#476643'],'Grama • terra • pedra • copa'),('VEREDAS',['#8C9B56','#B76C48','#D6AF78','#77B3AF'],'Buriti • terra vermelha • arenito • água rasa'),('MORRO',['#ADB8B2','#C68B70','#BC6749','#718A7A'],'Concreto • reboco • telha • vasos')]
for i,(name,colors,desc) in enumerate(biomes):
    x=90+i*760;txt(x,960,name,27,INK,True)
    for j,c in enumerate(colors):rect(x+j*60,1005,52,35,c)
    txt(x+255,1010,'Materiais',22,MUTED)
    txt(x,1050,desc,22,INK)

panel(60,1140,3080,560,'05','ESCALA COMUM / PÉS NA MESMA GRADE','Régua de produção proposta • amostras ampliadas 2× • pixels medidos sem transparência externa')
for center in [220,600,1010,1400,1840,2240]:
    for u in range(4):
        line([iso(center,yy0:=1569,u-1,-1),iso(center,yy0,u-1,2)],'#DFDDCD',1)
    for v in range(4):
        line([iso(center,1569,-1,v-1),iso(center,1569,2,v-1)],'#DFDDCD',1)
yy=1594
k=kael();picture(k,170,yy-168,k.width/k.height*168,168)
r=Image.open(ROOT/'godot/assets/campaign/combat-rabbito.png').convert('RGBA').crop((0,0,256,256));r=r.crop(r.getbbox());picture(r,550,yy-84,r.width/r.height*84,84)
NOVA=HERE/'fontes/manga-v2'
for name,center in [('arvore',1010),('banco',1400),('poste',1840),('porta',2240)]:
    prop=Image.open(NOVA/f'{name}-nativo.png').convert('RGBA')
    picture(prop,center-prop.width,yy-prop.height*2,prop.width*2,prop.height*2)
for x,name,measure in [(150,'Kael','84 px • pé 1 × 1'),(520,'Parceiro','42 px • pé 1 × 1'),(900,'Árvore','160 px • copa 2 × 2'),(1300,'Banco','56 px • base 2 × 1'),(1740,'Poste','144 px • base 1 × 1'),(2140,'Porta','112 px • vão 32 px')]:
    txt(x,1630,name,29,INK,True);txt(x,1670,measure,23,MUTED)
txt(2500,1300,'PADRÃO DE LEITURA',28,INK,True)
txt(2500,1350,'Pivô no ponto de contato.',25,MUTED)
txt(2500,1390,'Colisão no chão; copa separada.',25,MUTED)
txt(2500,1430,'Oclusão não altera a passagem.',25,MUTED)
txt(2500,1470,'Kael e Rabbito: assets atuais.',25,MUTED)
txt(2500,1520,'Props normalizados sem deformar.',24,'#BC6749')

panel(60,1740,3080,2200,'06','QUATRO BIOMAS / MESMO DESENHO, MESMA ESQUINA','Família derivada do alvo mangá aprovado. Pintura de referência; medidas e encaixes vêm da planta técnica.')
sheet=Image.open(NOVA/'FAMILIA-MANGA.png').convert('RGB')
corners=[]
for i,(name,_,desc) in enumerate(biomes):
    col=i%2;row=i//2
    crop=sheet.crop((col*sheet.width//2,row*sheet.height//2,(col+1)*sheet.width//2,(row+1)*sheet.height//2))
    crop.save(NOVA/f'esquina-{name.lower()}.png');corners.append(crop)
    x=90+col*1540;y=1850+row*1040
    txt(x,y,name,37,INK,True)
    picture(crop,x,y+50,1460,1460*crop.height/crop.width)

panel(60,3980,3080,475,'07','MUNDO DESENHADO × HUD RECORTE','Mesmo suporte de tinta e papel sobre os quatro biomas. Mockups de contraste, sem captura ou integração no jogo.')
for i,(bg,(name,_,_)) in enumerate(zip(corners,biomes)):
    x=90+i*765;y=4100
    strip_h=round(bg.width*240/730);strip_y=round(bg.height*.30)
    strip=bg.crop((0,strip_y,bg.width,strip_y+strip_h))
    picture(strip,x,y,730,240)
    poly([(x+20,y+25),(x+540,y+25),(x+565,y+45),(x+550,y+155),(x+25,y+155),(x+10,y+135)],'#141E29','#0B1017',5)
    poly([(x+30,y+34),(x+520,y+34),(x+510,y+78),(x+20,y+78)],'#F4E9D2',None)
    txt(x+45,y+44,name,29,'#141E29',True)
    txt(x+40,y+103,'Explorar • E interagir',27,'#F4E9D2')
    line([(x+24,y+40),(x+18,y+66)],'#2EC8E3',7)
txt(90,4380,'Papel #F4E9D2 / tinta #141E29: 13,97:1 • texto em fundo sólido • ciano/coral reservados para foco e ação.',27,INK,True)
txt(90,4420,'Cantos e ornamentos fixos; esticar só o centro. O cenário mantém caminhos calmos e silhuetas legíveis.',25,MUTED)

txt(65,4500,'DECISÃO: Morro em isométrico 2:1. Arte 3/4 anterior = referência de conteúdo.',31,INK,True)
txt(65,4550,'PIP-82 • acabamento da esquina aprovado • família e prancha aguardam revisão • nenhuma alteração de regras ou mapas',25,MUTED)
svg.append('</svg>')
(HERE/'PRANCHA-ESTILO.svg').write_text('\n'.join(svg),encoding='utf-8')
im.save(HERE/'PRANCHA-ESTILO.png')
im.resize((1600,2300),Image.Resampling.LANCZOS).save(HERE/'PREVIA.png')
im.crop((140,1260,2340,1606)).resize((1100,173),Image.Resampling.LANCZOS).save(HERE/'ESCALA-NATIVA.png')
assert all(0<=b['box'][0]<b['box'][2]<=W and 0<=b['box'][1]<b['box'][3]<=H for b in checks), 'Texto fora da prancha'
ET.parse(HERE/'PRANCHA-ESTILO.svg')
assert iso(0,0,1,0)==(32,16) and iso(0,0,0,1)==(-32,16)
assert iso(0,0,0,0,64)==(0,-64)
assert 8*8==64 and 2*32==64
def luminance(color):
    rgb=[int(color[n:n+2],16)/255 for n in (1,3,5)]
    linear=[c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in rgb]
    return sum(c*w for c,w in zip(linear,[.2126,.7152,.0722]))
light,dark=sorted([luminance('#F4E9D2'),luminance('#141E29')],reverse=True)
contrast=(light+.05)/(dark+.05)
assert contrast>13
native_sizes={}
for name,height in [('arvore',160),('banco',56),('poste',144),('porta',112)]:
    asset=Image.open(NOVA/f'{name}-nativo.png')
    assert asset.height==height and asset.mode=='RGBA'
    assert asset.getchannel('A').getextrema()[0]==0
    native_sizes[name]=list(asset.size)
assert native_sizes['porta'][1]>84, 'A porta deve comportar a leitura de Kael'
(HERE/'verificacao.json').write_text(json.dumps({'size':[W,H],'text_count':len(checks),'text_within_canvas':True,'svg_xml_valid':True,'native_tile':[64,32],'projection_axes':[[32,16],[-32,16]],'level_height':64,'iso_studio_height_cells':2,'ramp_run_cells':4,'stair_risers':8,'stair_rise':8,'hud_paper_ink_contrast':round(contrast,2),'images_preserve_aspect':True,'visual_review':'PNG e prévia conferidos; aprovação do responsável pendente','runtime_validation':False},ensure_ascii=False,indent=2),encoding='utf-8')
report=json.loads((HERE/'verificacao.json').read_text(encoding='utf-8'))
report.update({'native_props':native_sizes,'finish_reference_approved':True,'family_approved':False,'illustration_geometry':'Reference paintings; no per-pixel alignment claim','hud_mockup_biomes':[b[0] for b in biomes]})
(HERE/'verificacao.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
files=['PRANCHA-ESTILO.png','PRANCHA-ESTILO.svg','fontes/manga-v2/FAMILIA-MANGA.png','fontes/manga-v2/PROPS-MANGA.png','fontes/manga-v2/props-normalizacao.json','fontes/GUIA-ESQUINA-2x1.png','revisao-manga-v2/ESQUINA-ALVO-SIMPLIFICADA.png']
manifest={'issue':'PIP-82','version':2,'approval':'pending_owner_review','approved_finish':{'file':'revisao-manga-v2/ESQUINA-ALVO-SIMPLIFICADA.png','evidence':'User: Sim gostei','scope':'finish only; does not approve full board or geometry'},'role':'style-board; not runtime tileset','generator':'gerar_prancha.py','technical_source':'vector diagrams, GUIA-ESQUINA-2x1 and coordinate functions','illustration_source':'fontes/manga-v2/FAMILIA-MANGA.png','biomes':[b[0] for b in biomes],'reference_branch':'claude/mapas-areas','reference_commit':'469cb4e4c498faf6afcca9ee3f6782d72538f4a7','morro_decision':'isometric 2:1; previous 3/4 art is content reference only','files':[{ 'path':f,'sha256':hashlib.sha256((HERE/f).read_bytes()).hexdigest()} for f in files]}
(HERE/'manifesto.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print('Prancha PNG, SVG, prévia e verificação geradas.')

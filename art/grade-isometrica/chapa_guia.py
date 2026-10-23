# Chapa-guia isométrica 2:1: célula de piso 64×32 px, 1 célula de altura = 32 px (≈ 50 cm).
# Uso: python3 art/grade-isometrica/chapa_guia.py [--vazia]  (requer Pillow e a fonte DejaVu)
import sys
from PIL import Image,ImageDraw,ImageFont
S=2                                   # exporta em 2× para leitura; a grade nativa é 64×32
TW,TH,ZH=64,32,32                      # largura e altura do losango, altura de 1 célula
NU,NV,WALL=10,8,5                      # quarto 10 × 8 células, paredes de 5 células
blank='--vazia' in sys.argv
W,H=(NU+NV)*TW//2+80,(NU+NV)*TH//2+WALL*ZH+70
ox,oy=NV*TW//2+40,WALL*ZH+40
im=Image.new('RGB',(W*S,H*S),(238,232,218));d=ImageDraw.Draw(im,'RGBA')
F=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',10*S);Fs=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',9*S)
def p(u,v,h=0):return ((ox+(u-v)*TW/2)*S,(oy+(u+v)*TH/2-h*ZH)*S)
def poly(pts,fill=None,line=None,w=1):d.polygon(pts,fill=fill,outline=None);(line and d.line(pts+[pts[0]],fill=line,width=w*S))
INK=(41,61,57);GRID=(196,90,160,150);WALLC=(246,234,205)
# paredes (direita v=0, esquerda u=0)
poly([p(0,0),p(NU,0),p(NU,0,WALL),p(0,0,WALL)],WALLC,INK,1)
poly([p(0,0),p(0,NV),p(0,NV,WALL),p(0,0,WALL)],(236,222,190),INK,1)
for u in range(NU+1):d.line([p(u,0),p(u,0,WALL)],fill=GRID,width=1)
for v in range(NV+1):d.line([p(0,v),p(0,v,WALL)],fill=GRID,width=1)
for h in range(WALL+1):d.line([p(0,0,h),p(NU,0,h)],fill=GRID,width=1);d.line([p(0,0,h),p(0,NV,h)],fill=GRID,width=1)
# piso
poly([p(0,0),p(NU,0),p(NU,NV),p(0,NV)],(222,178,120),INK,1)
for u in range(NU+1):d.line([p(u,0),p(u,NV)],fill=GRID,width=1)
for v in range(NV+1):d.line([p(0,v),p(NU,v)],fill=GRID,width=1)
def label(t,xy,f=F,c=INK):d.text(xy,t,font=f,fill=c,anchor='mm',stroke_width=2*S,stroke_fill=(255,250,238) if c==INK else (30,30,30))
if not blank:
  def box(name,u0,v0,u1,v1,h,col,tag=None,z=0,above=False):
    top=[p(u0,v0,h),p(u1,v0,h),p(u1,v1,h),p(u0,v1,h)]
    r=[p(u1,v0,z),p(u1,v1,z),p(u1,v1,h),p(u1,v0,h)];l=[p(u0,v1,z),p(u1,v1,z),p(u1,v1,h),p(u0,v1,h)]
    sh=lambda c,k:tuple(int(x*k) for x in c)+(235,)
    poly(r,sh(col,.78),INK);poly(l,sh(col,.9),INK);poly(top,sh(col,1),INK)
    a=p(u1,v1,z);d.ellipse([a[0]-4*S,a[1]-4*S,a[0]+4*S,a[1]+4*S],fill=(200,30,30))   # âncora: canto frontal da pegada
    c=p((u0+u1)/2,(v0+v1)/2,h);label(tag or name,(c[0],c[1]-(14*S if above else 0)))
  def flat(name,u0,v0,u1,v1,col):poly([p(u0,v0),p(u1,v0),p(u1,v1),p(u0,v1)],col,INK,1);c=p((u0+u1)/2,(v0+v1)/2);label(name,c,c=(255,255,255))
  def wallrect(name,plane,a0,a1,h0,h1,col):
    pts=[p(a0,0,h0),p(a1,0,h0),p(a1,0,h1),p(a0,0,h1)] if plane=='dir' else [p(0,a0,h0),p(0,a1,h0),p(0,a1,h1),p(0,a0,h1)]
    poly(pts,col,INK,1);c=((pts[0][0]+pts[2][0])/2,(pts[0][1]+pts[2][1])/2);label(name,c,Fs)
  flat('abertura da escada 3×2',0,6,3,8,(70,55,40,230))
  flat('tapete 5×3',3,3,8,6,(55,110,115,235))
  wallrect('janela 2×1,5','esq',2,4,2.2,3.7,(150,200,220,240))
  wallrect('quadros','dir',7.4,9.6,2.4,3.4,(255,250,235,240))
  box('cama 2×4 · h1',0,1,2,5,1,(70,110,190))
  box('estante 3×1 · h1,3',2,0,5,1,1.3,(190,130,70))
  box('TV',3,0.1,4.4,0.9,2.6,(60,60,70),z=1.3)
  box('guarda-roupa 2×1 · h4',5,0,7,1,4,(190,130,70),above=True)
  box('mesa 3×2 · h1,5',7,0,10,2,1.5,(30,110,120))
  box('Kael 1×1 · h3,2',8,4,9,5,3.2,(40,50,90),above=True)
  d.text((14*S,(H-34)*S),'Grade 2:1 · célula de piso 64×32 px · 1 célula de altura = 32 px ≈ 50 cm · quarto 10×8 · paredes 5 células',font=Fs,fill=INK)
  d.text((14*S,(H-20)*S),'Ponto vermelho = âncora do objeto (canto frontal da pegada), usado para posicionar e ordenar a profundidade.',font=Fs,fill=INK)
import os;out=os.path.dirname(os.path.abspath(__file__));im.save(os.path.join(out,'chapa-guia'+('-vazia' if blank else '')+'.png'));print(im.size)

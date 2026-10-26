"""Guia técnico original para o estudo de família da PIP-82, sem arte de jogo externo."""
from pathlib import Path
from PIL import Image, ImageDraw
P=Path(__file__).resolve().parent
im=Image.new('RGB',(900,660),'#F5E9CB'); d=ImageDraw.Draw(im)
def pt(u,v,z=0):return (450+(u-v)*32,100+(u+v)*16-z)
def polygon(points,color):
    d.polygon(points,fill=color);d.line(points+[points[0]],fill='#26394D',width=2)
def floor(u,v,w,h,z,c):polygon([pt(u,v,z),pt(u+w,v,z),pt(u+w,v+h,z),pt(u,v+h,z)],c)
def block(u,v,w,h,bottom,height,top,light,dark):
    a,b,c,e=[pt(i,j,bottom) for i,j in [(u,v),(u+w,v),(u+w,v+h),(u,v+h)]]
    up=lambda p:(p[0],p[1]-height)
    polygon([up(e),up(c),c,e],dark)
    polygon([up(b),up(c),c,b],light)
    polygon([up(a),up(b),up(c),up(e)],top)
floor(0,0,12,12,0,'#C9CFAA')
for u in range(12):
    for v in range(12):floor(u,v,1,1,0,'#C9CFAA')
floor(0,7,12,3,0,'#E7DCC1');floor(4,0,3,7,0,'#E7DCC1')
floor(0,10,12,2,0,'#8194A0')
# Back terrace and a deliberate opening at the access.
block(5,0,6,4,0,64,'#A9BD88','#C0AA83','#A28A68')
floor(8,4,1,4,0,'#E7DCC1')
# Eight risers occupying four cells, upper edge aligned to terrace level 64.
for i in range(8):
    z=64-i*8;v=4+i*.5
    floor(8,v,1,.5,z,'#DDDAC5')
    polygon([pt(8,v+.5,z),pt(9,v+.5,z),pt(9,v+.5,z-8),pt(8,v+.5,z-8)],'#A9AEAA')
block(0,3,4,4,0,112,'#BC6749','#F5E9CB','#D3C09E')
# Tree volume, bench and door placeholders only, shared by all biome variants.
block(8,1,0.3,.3,64,96,'#987254','#987254','#755342')
cx,cy=pt(8,1,160)
d.ellipse((cx-70,cy-70,cx+70,cy+20),fill='#668A55',outline='#26394D',width=2)
block(9,6,2,.6,0,28,'#BC6749','#9B6044','#724C3C')
polygon([pt(1,7,0),pt(2,7,0),pt(2,7,80),pt(1,7,80)],'#637F91')
im.save(P/'GUIA-ESQUINA-2x1.png')

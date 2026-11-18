from pathlib import Path
import math,bpy,bmesh,numpy as np
from mathutils import Vector
from math import sin,cos,pi
O=Path(__file__).resolve().parent
bpy.ops.wm.read_factory_settings(use_empty=True)
s=bpy.context.scene
im=bpy.data.images.load(str(O/'Mormaco-vistas.png'));im.pack()
# Reduce the reference to console-scale texels while retaining shared UV landmarks.
im.scale(768,512);im.pack();im.name='Atlas • Mormaço'
mat=bpy.data.materials.new('Pintura da prancha');mat.use_nodes=True
nodes=mat.node_tree.nodes;links=mat.node_tree.links
tex=nodes.new('ShaderNodeTexImage');tex.image=im;tex.interpolation='Closest'
bs=nodes.get('Principled BSDF')
for slot in ('Base Color','Emission Color'):links.new(tex.outputs['Color'],bs.inputs[slot])
bs.inputs['Emission Strength'].default_value=.68;bs.inputs['Specular IOR Level'].default_value=0;bs.inputs['Roughness'].default_value=1
def world(p):
 x,y,h=p;return Vector((x/165,(y-1060)/165,(463-h)/165))
bones={'Tronco':((0,1140,330),(0,960,294),None),'Cabeça':((0,961,288),(0,820,287),'Tronco'),'Cauda':((0,1180,374),(0,1325,412),'Tronco')}
parts=[]
def obj(name,pts,faces,bind='Tronco',mode='auto',sideuv=None):
 me=bpy.data.meshes.new(name);me.from_pydata([world(p) for p in pts],[],faces);me.update()
 bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(me);bm.free()
 ob=bpy.data.objects.new(name,me);s.collection.objects.link(ob);me.materials.append(mat)
 uv=me.uv_layers.new(name='Vistas pintadas')
 for poly in me.polygons:
  n=poly.normal
  facing='side'
  if mode=='auto' and -n.y>abs(n.x)*.85 and -n.y>.24:facing='front'
  if mode=='auto' and n.y>abs(n.x)*.80 and n.y>.23:facing='back'
  for li in poly.loop_indices:
   v=me.loops[li].vertex_index;x,y,h=pts[v]
   if callable(mode):u,w=mode(v,n)
   elif facing=='side':u,w=sideuv[v] if sideuv else (y,h)
   elif facing=='front':u,w=398+x,h
   else:u,w=396-x,h+498
   uv.data[li].uv=(u/1536,1-w/1024)
 parts.append((ob,bind));return ob


# All painted landmarks use coordinates from the approved turnaround.
def mesh(name,pts,faces,uv,bind='Tronco'):
 return obj(name,pts,faces,bind,lambda i,n:uv[i])
def rings(name,sections,uvs,bind='Tronco'):
 n=len(sections[0]);faces=[(k*n+j,k*n+(j+1)%n,(k+1)*n+(j+1)%n,(k+1)*n+j) for k in range(len(sections)-1) for j in range(n)]
 faces += [tuple(range(n)),tuple(range((len(sections)-1)*n,len(sections)*n))]
 return mesh(name,sum(sections,[]),faces,sum(uvs,[]),bind)
def tube(name,a,b,r,uv):
 a,b=Vector(a),Vector(b);axis=(b-a).normalized();u=axis.cross(Vector((1,0,0))).normalized();v=axis.cross(u)
 rings(name,[[p+r*(u*cos(j*pi/3)+v*sin(j*pi/3)) for j in range(6)] for p in (a,b)],[[uv]*6]*2)
def trunk(name,rows,region,bone):
 sections=[];tex=[]
 for k,(y,h,w,r) in enumerate(rows):
  sec=[];uv=[]
  for j in range(10):
   a=math.tau*j/10;sec.append((w*cos(a),y,h+r*sin(a)))
   u,v=region(k/(len(rows)-1),cos(a),sin(a));uv.append((u,v))
  sections.append(sec);tex.append(uv)
 rings(name,sections,tex,bone)
trunk('Peito e ventre',[(884,311,50,19),(934,335,81,39),(1003,347,110,64),(1094,357,108,58),(1188,368,76,42)],lambda t,x,z:(400+x*(35-8*t),350+z*33+12*t),'Tronco')
trunk('Cauda',[(1152,368,62,33),(1208,393,55,31),(1267,417,35,19),(1320,422,17,9),(1340,415,2,2)],lambda t,x,z:(1207+t*122,413+z*(11-8*t)),'Cauda')
# The face opens toward the player. Each facial landmark has depth and its own UV.
for q in (-1,1):
 pts=[];uv=[]
 rows=[[(0,877,224),(24,889,229),(48,910,231),(62,932,245)],[(0,833,245),(19,843,247),(42,862,247),(62,893,252)],[(0,812,270),(19,822,268),(42,845,262),(68,885,263)],[(0,795,289),(18,802,284),(40,829,281),(66,876,277)],[(0,801,300),(18,807,301),(42,840,300),(61,891,292)],[(0,835,319),(20,839,317),(40,863,311),(55,911,304)]]
 texrows=[[(401,224),(423,228),(446,231),(454,243)],[(401,245),(422,247),(442,245),(455,249)],[(401,270),(421,271),(440,260),(459,257)],[(401,290),(420,284),(440,280),(465,277)],[(401,303),(422,300),(444,294),(456,289)],[(401,317),(419,314),(439,307),(453,301)]]
 for row,trow in zip(rows,texrows):
  for (x,y,h),(u,v) in zip(row,trow):pts.append((q*x,y,h));uv.append((401+q*(u-401),v))
 fs=[(i,i+1,i+5,i+4) for i in range(20) if i%4!=3]
 for k in range(6):
  x,y,h=rows[k][-1];pts.append((q*(54 if k in (0,5) else 73),952,h));uv.append((912,246+k*11))
 fs.extend((4*k+3,24+k,25+k,4*k+7) for k in range(5))
 head=mesh('Máscara esculpida',pts,fs,uv,'Cabeça')
 for poly in list(head.data.polygons)[-5:]:
  for li in poly.loop_indices:
   i=head.data.loops[li].vertex_index;x,y,h=pts[i]
   head.data.uv_layers.active.data[li].uv=((883+(y-876)*.60)/1536,1-(265+(h-264)*.48)/1024)
# Mantle arches down from the ridge, with an inked lip sampled from the brow.
sections=[];uvs=[]
for k,(y,top,w,drop,rake) in enumerate([(898,215,92,91,57),(924,199,98,96,51),(994,169,115,123,31),(1060,162,132,157,14),(1138,193,135,155,9),(1220,270,95,112,0),(1290,377,34,31,0)]):
 sec=[];uv=[]
 for j in range(9):
  a=(j-4)*pi/8;sec.append((w*sin(a),y+rake*abs(sin(a)),top+drop*(1-cos(a))))
  uv.append((401+sin(a)*(66 if k<2 else 63),[208,196,180,175,181,191,203][k]+(1-cos(a))*53))
 sections.append(sec);uvs.append(uv)
# Keep the arch open underneath.
n=9;mesh('Manto dorsal',sum(sections,[]),[(k*n+j,k*n+j+1,(k+1)*n+j+1,(k+1)*n+j) for k in range(6) for j in range(8)],sum(uvs,[]))
for q in (-1,1):
 for name,outline,width,hub in [
 ('Ombreira',[(995,188),(1024,171),(1050,178),(1075,209),(1091,242),(1092,288),(1080,340),(1050,307),(1016,268),(997,235)],[37,61,92,120,139,146,142,140,118,90],(151,1050,251)),
 ('Escama média',[(1069,185),(1100,184),(1134,202),(1156,228),(1171,263),(1160,349),(1153,357),(1115,320),(1094,283)],[42,65,102,120,132,134,123,128,111],(147,1132,256)),
 ('Escama traseira',[(1161,259),(1186,278),(1209,312),(1245,389),(1215,380),(1180,348),(1164,318)],[95,107,108,78,105,121,120],(123,1194,331))]:
  pts=[(q*w,y,h) for (y,h),w in zip(outline,width)]+[(q*hub[0],*hub[1:])]
  uv=[(hub[1]+(y-hub[1])*.91,hub[2]+(h-hub[2])*.91) for y,h in outline]+[hub[1:]]
  mesh(name,pts,[(j,(j+1)%len(outline),len(outline)) for j in range(len(outline))],uv)
 for fore in (True,False):
  end=(' frente' if fore else ' trás')+(' E' if q>0 else ' D')
  rows=([(83,978,272,37,40),(99,980,298,54,54),(111,1000,322,48,50),(117,1008,344,31,32),(130,957,366,47,49),(137,918,395,40,41),(141,895,417,56,52),(141,883,444,59,46),(140,885,463,48,35)] if fore else [(78,1158,336,37,43),(88,1136,357,47,42),(91,1120,383,34,34),(85,1167,404,23,24),(81,1167,424,24,24),(83,1135,442,36,35),(83,1131,463,34,29)])
  painted=([(310,301,10),(312,307,18),(312,323,24),(307,342,24),(291,355,31),(284,375,37),(282,385,29),(282,389,25),(282,389,19)] if fore else [(1146,357,20),(1147,367,28),(1140,382,30),(1154,395,20),(1161,410,18),(1157,424,21),(1160,439,24)])
  joints=(3,5) if fore else (2,4);ns=[p+end for p in ('Raiz','Dobra','Pata')]
  ids=[0,*joints,len(rows)-1]
  for j in range(3):
   a,b=rows[ids[j]],rows[ids[j+1]];bones[ns[j]]=((q*a[0],a[1],a[2]),(q*b[0],b[1],b[2]),'Tronco' if j==0 else ns[j-1])
  vs=[];us=[];weights=[]
  for k,((x,y,h,w,r),(u,v,tw)) in enumerate(zip(rows,painted)):
   row=[];uv=[]
   for j in range(8):
    a=j*pi/4;row.append((q*(x+w*cos(a)),y+r*sin(a),h));uv.append((u+tw*(-.82*cos(a)+.18*sin(a)),v+2*sin(a)))
    weights.append({ns[0]:.5,ns[1]:.5} if k==joints[0] else {ns[1]:.5,ns[2]:.5} if k==joints[1] else {ns[int(k>joints[0])+int(k>joints[1])]:1})
   vs.append(row);us.append(uv)
  rings('Membro'+end,vs,us,weights)
  for j in (-1,0,1):
   x=141+j*35 if fore else 83+j*20;y=856+abs(j)*7 if fore else 1104+abs(j)*3
   vs=[];us=[]
   for dy,h,w,r,vv in ([(23,431,15,14,402),(5,432,17,16,414),(-12,442,15,14,434),(-32,459,3,4,451)] if fore else [(17,448,10,10,428),(0,450,11,11,435),(-12,457,7,6,442)]):
    vs.append([(q*(x+w*cos(a*pi/3)),y+dy+r*.3*sin(a*pi/3),min(463,h+r*sin(a*pi/3))) for a in range(6)])
    us.append([((231 if fore else 1132)+(5 if fore else 4)*cos(a*pi/3)-(vv-402)*(.24 if fore else .05),vv) for a in range(6)])
   rings('Unha'+end,vs,us,ns[2])
 A=(q*93,1141,194);B=(q*174,1238,224);C=(q*148,1204,331)
 mesh('Vela',[A,B,C],[(0,1,2)],[(1159,185),(1234,226),(1207,313)])
 for a,b in [(A,B),(B,C),(C,A)]:tube('Bambu',a,b,3.7,(1210,210))
 prev=B
 for k in range(3):
  y=1258+31*k;h=254+52*k;x=q*(180+8*k)
  outline=[(-8,-18),(7,-14),(16,-4),(22,15),(10,10),(10,22),(1,17),(-4,24),(-13,7),(-14,-6)]
  pp=[(x+q*u*.35,y+u,h+v) for u,v in outline]+[(x+q*9,y,h)]
  mesh('Rabiola',pp,[(i,(i+1)%10,10) for i in range(10)],[(1277+u*.70,264+v*.73) for u,v in outline]+[(1277,264)])
  tube('Nó',prev,pp[0],3,(1271,244));prev=pp[5]
 # The spray is formed by swept, flared sections with a curling upper lip.
 cx=q*49;cy=1006 if q<0 else 1080
 for name,profile in [('Nascente',[(195,34),(171,30),(158,19)]),('Aro',[(160,23),(155,25),(143,23),(145,14)])]:
  vs=[];us=[]
  for h,r in profile:
   vs.append([(cx+r*cos(j*pi/5),cy+r*.86*sin(j*pi/5),h) for j in range(10)])
   us.append([(357+cos(j*pi/5)*r*.73,(176+(h-171)*.38 if name=='Nascente' else 149+(h-151)*.42)) for j in range(10)])
  rings(name,vs,us)
 for k,(dx,dy,height,span) in enumerate([(96,6,87,39),(85,28,103,42),(63,52,91,36)]):
  sections=[];uvs=[]
  for t,reach,up,width,thick,uu,vv in [(0,0,0,6,5,355,135),(.28,.19,.50,13,8,354,105),(.52,.45,.85,19,12,343,72),(.74,.69,1,span*.72,14,320,55),(.85,.86,.97,span*.70,14,302,50),(1,1,.80,span*.43,9,285,66)]:
   row=[];uv=[]
   for j in range(6):
    a=j*pi/3;row.append((cx+q*(reach*dx+cos(a)*width*.35),cy+reach*dy+cos(a)*width,144-up*height+sin(a)*thick))
    uv.append((uu+cos(a)*7,vv+sin(a)*(8 if t>.6 else 4)))
   sections.append(row);uvs.append(uv)
  rings('Jato termal',sections,uvs)
# Rear plates overlap like shingles.
for h,w,y in [(344,55,1275),(301,78,1245),(254,95,1204),(216,72,1168)]:
 shape=[(0,-31),(.73,-16),(1,8),(.8,28),(0,65),(-.8,28),(-1,8),(-.73,-16)]
 pts=[(x*w,y+dh*.45,h+dh) for x,dh in shape]+[(0,y+15,h)]
 mesh('Escudo das costas',pts,[(j,(j+1)%8,8) for j in range(8)],[(401+x*52, (698 if h==216 else 807)+dh*.90) for x,dh in shape]+[(401,698 if h==216 else 807)])
# Close the underside of the face and wrap the gold breast from throat to abdomen.
for q in (-1,1):
 mesh('Base da mandíbula',[(0,835,319),(q*55,911,304),(q*58,952,304),(0,952,315)],[(0,1,2,3)],[(398,314),(419,308),(423,311),(403,317)],'Cabeça')
for piece,_ in parts:
 if piece.name.startswith('Peito e ventre'):
  for face in piece.data.polygons:
   for li in face.loop_indices:
    v=piece.data.vertices[piece.data.loops[li].vertex_index].co
    x=v.x*165;h=463-v.z*165
    piece.data.uv_layers.active.data[li].uv=((401+x*.37)/1536,1-max(323,min(403,337+(h-315)*.69))/1024)
exec((O/'estudio.py').read_text(encoding='utf-8-sig'),globals())

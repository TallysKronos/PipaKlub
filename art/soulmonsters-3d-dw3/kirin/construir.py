from pathlib import Path
import math,bpy,bmesh
from mathutils import Vector,Quaternion
from math import sin,cos,pi,tau
D=Path(__file__).resolve().parent
bpy.ops.wm.read_factory_settings(use_empty=True);s=bpy.context.scene
verts=[];faces=[];uvs=[];weights=[]
def world(p):
 x,y,h=p;return Vector(((x-435)/120,y/120,(758-h)/120))
def part(points,polys,uv,bind):
 off=len(verts);verts.extend(world(p) for p in points);uvs.extend(uv);weights.extend(bind if isinstance(bind,list) else [bind]*len(points))
 faces.extend(tuple(off+j for j in f) for f in polys)
def rings(rows,tex,b):
 n=len(rows[0]);fs=[(i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j) for i in range(len(rows)-1) for j in range(n)]
 fs+=[tuple(reversed(range(n))),tuple(range((len(rows)-1)*n,len(rows)*n))]
 part(sum(rows,[]),fs,sum(tex,[]),b)
def ell(name,rows,patch,n=8):
 rr=[];tt=[]
 for k,(x,y,h,w,r) in enumerate(rows):
  rr.append([(x,y+w*cos(tau*j/n),h+r*sin(tau*j/n)) for j in range(n)])
  tt.append([patch(k,cos(tau*j/n),sin(tau*j/n)) for j in range(n)])
 rings(rr,tt,name)
def leaf(out,hub,y,relief,b,sgn=1,tex=None):
 # Thick lenticular cross-section, creased ridge and tapered inked edge.
 x,h=hub;n=len(out);rim=[(a,y,c) for a,c in out]
 p=rim+[(x,y+relief*sgn,h),(x,y-relief*.5*sgn,h)]
 part(p,[f for j in range(n) for f in ((j,(j+1)%n,n),(j,n+1,(j+1)%n))],(tex or out)+[hub,hub],b)
def rod(a,b,r,sw,bone):
 a,b=Vector(a),Vector(b);ax=(b-a).normalized();u=ax.cross(Vector((0,1,0))).normalized();v=ax.cross(u)
 rings([[p+r*(u*cos(j*tau/6)+v*sin(j*tau/6)) for j in range(6)] for p in (a,b)],[[sw]*6]*2,bone)
# Rib cage and warm underside, with a deep brisket and raised croup.
ell('breath',[(201,0,451,53,50),(265,0,465,77,85),(345,0,467,82,93),(451,0,455,72,72),(553,0,443,77,79),(633,0,439,62,67),(669,0,424,41,39)],lambda k,a,b:(268+k*38,899+84*b))
ell('neck',[(138,0,402,42,36),(194,0,402,58,63),(252,0,419,66,75),(301,0,431,71,69)],lambda k,a,b:(266+k*20,398+b*26))
# Skull shaped by transverse rings, with muzzle, orbital shelf and occipital planes.
head=[(70,0,445,13,9),(84,0,438,28,18),(108,0,431,41,22),(139,0,419,52,33),(170,0,410,60,38),(204,0,401,54,35),(234,0,395,37,24)]
ell('head',head[4:],lambda k,a,b:(187+k*7,413+b*9),10)
ell('jaw',[(78,0,462,16,7),(99,0,463,27,10),(136,0,454,34,15),(168,0,449,35,16)],lambda k,a,b:(118+k*7,458+b*4))
for side in (-1,1):
 # Cheek plates sweep backward below the eye; fangs are independent of the jaw.
 leaf([(144,437),(177,424),(212,416),(199,432),(225,440),(189,445),(199,455),(160,451)],(176,438),side*44,14,'head',side)
 for x,h in [(96,467),(121,471)]:
  rings([[(x+dx+w*cos(j*pi/3),side*27+w*.68*sin(j*pi/3),h+dh) for j in range(6)] for dx,w,dh in [(0,9,0),(-4,7,16),(-4,1,39)]], [[(115+3*cos(j*pi/3),465+dh*.55) for j in range(6)] for dh in [0,16,39]],'head')
 # Layered flame mane, built as swept asymmetrical locks surrounding the neck.
 for outline,hub,y,depth in [
 ([(156,360),(193,304),(242,247),(238,272),(277,239),(318,226),(349,229),(325,243),(371,245),(389,225),(384,261),(348,286),(280,308),(222,348),(178,384)],(260,274),15,42),
 ([(171,366),(223,306),(292,277),(354,278),(401,250),(438,240),(417,265),(462,247),(439,278),(387,310),(306,317),(240,346),(194,386)],(291,304),40,36),
 ([(187,390),(237,344),(298,313),(359,312),(404,289),(427,269),(417,302),(389,325),(445,315),(466,330),(432,338),(398,354),(323,360),(253,381)],(310,337),51,35),
 ([(184,410),(247,378),(305,352),(366,349),(403,331),(442,335),(472,351),(446,354),(422,371),(375,395),(297,398),(251,427),(204,431)],(308,376),48,43),
 ([(201,428),(260,405),(324,391),(377,389),(409,375),(395,400),(349,426),(277,439),(240,461)],(292,415),36,34)]:
  leaf(outline,hub,side*y,depth,'neck',side)
  mane_bone='mane_L' if side<0 else 'mane_R'
  for index,(vx,vh) in enumerate(outline+[hub,hub],len(weights)-len(outline)-2):
   w=min(.95,max(.03,(vx-195)/215));weights[index]={'neck':1-w,mane_bone:w}
 # Four armor masses flow from the shoulder to the hip.
 for outline,hub,y,dep,bone in [
 ([(214,534),(216,487),(248,472),(287,471),(303,453),(340,447),(372,455),(344,473),(305,494),(277,522),(248,567)],(270,497),74,18,'spine'),
 ([(246,539),(289,500),(337,482),(367,451),(411,443),(450,417),(441,463),(419,498),(391,541),(346,557),(303,580),(251,622)],(342,517),85,23,'spine'),
 ([(302,563),(344,558),(390,538),(421,510),(406,549),(384,577),(350,595),(321,614)],(357,565),75,16,'spine'),
 ([(514,450),(548,423),(601,425),(644,439),(674,466),(644,457),(657,484),(615,476),(578,462),(543,498)],(591,450),68,19,'root')]:
  leaf(outline,hub,side*y,dep,bone,side)
 for k in range(4):
  x=158+16*k;h=485+31*k
  leaf([(x-13,h-17),(x+13,h-13),(x+28,h-25),(x+22,h+9),(x+4,h+33),(x-12,h+12)],(x+3,h),side*(27+k*2),14,'neck',side)
# Front mask uses the frontal turnaround. The nasal bridge projects ahead of the eyes.
for sign in (-1,1):
 pts=[];uv=[]
 lines=[[(0,142,379,222,222),(26,155,379,239,216),(51,180,373,260,206)],
        [(0,109,404,222,245),(27,117,404,240,244),(52,145,393,253,232)],
        [(0,86,427,222,256),(29,101,422,240,253),(54,141,416,262,245)],
        [(0,66,443,222,263),(23,78,444,234,264),(47,121,441,254,255)],
        [(0,79,458,222,273),(20,87,455,235,272),(39,128,453,250,265)]]
 for row in lines:
  for lat,x,h,u,v in row:
   pts.append((x-3,sign*lat,h));uv.append((525+(222+sign*(u-222)-154)*1.5,802+(v-187)*1.5))
 part(pts,[(i,i+1,i+4,i+3) for i in range(12) if i%3<2],uv,'head')
 outer=[pts[i] for i in (2,5,8,11,14)]
 for k in range(4):
  a=outer[k];b=outer[k+1];c=(185,sign*53,b[2]);e=(185,sign*56,a[2])
  part([a,b,c,e],[(0,1,2,3)],[(178,407+k*8),(180,410+k*8),(204,410+k*8),(202,407+k*8)],'head')
 part([pts[12],pts[13],pts[14],(183,sign*42,457),(166,0,461)],[(0,1,2,3,4)],[(118,464),(125,463),(141,460),(154,461),(139,466)],'head')
 # Scales anchor the sail into the spine and continue the shoulder into the rump.
 for outline,hub,y,deep in [
 ([(397,409),(451,379),(493,379),(520,401),(510,439),(478,469),(458,492),(430,463)],(465,428),65,19),
 ([(475,399),(520,369),(567,379),(589,414),(573,447),(549,479),(522,464),(499,441)],(537,419),66,21),
 ([(543,400),(583,376),(624,386),(651,421),(651,449),(618,432),(598,455),(563,437)],(602,409),58,17)]:
  uv=[(315+(x-hub[0])*.62,521+(h-hub[1])*.62) for x,h in outline]
  n=len(outline);p=[(x,sign*y,h) for x,h in outline]+[(hub[0],sign*(y+deep),hub[1]),(hub[0],sign*(y-12),hub[1])]
  part(p,[f for i in range(n) for f in ((i,(i+1)%n,n),(i,n+1,(i+1)%n))],uv+[(315,521)]*2,'spine')
ell('spine',[(455,0,398,35,21),(493,0,377,58,28),(529,0,367,65,36),(562,0,376,56,30),(598,0,393,38,22)],lambda k,a,b:(285+k*17,545+13*b))
for k in range(4):
 x=158+17*k;h=478+29*k;w=39-3*k
 sec=[(x,-w,h),(x-9,0,h-6),(x,w,h),(x+15,w*.68,h+20),(x+15,0,h+35),(x+15,-w*.68,h+20)]
 part(sec,[(0,1,4,5),(1,2,3,4)],[(166,478),(173,473),(183,472),(186,491),(175,511),(163,499)],'neck')
# The horn sweeps back over the poll and down over the brow. Closed six-sided sections.
hp=[(63,387,5,6),(89,338,13,19),(130,288,17,25),(182,239,17,23),(249,195,12,18),(323,169,8,9),(384,158,1,1)]
rows=[];tx=[]
for i,(x,h,w,r) in enumerate(hp):
 prev=hp[max(0,i-1)];nex=hp[min(len(hp)-1,i+1)];dx,dh=nex[0]-prev[0],nex[1]-prev[1];ln=math.hypot(dx,dh);nx,nh=-dh/ln,dx/ln
 rr=[(x+nx*r*cos(j*pi/4),w*sin(j*pi/4),h+nh*r*cos(j*pi/4)) for j in range(8)]
 rows.append(rr);tx.append([(a,c) for a,_,c in rr])
rings(rows,tx,'head')
leaf([(64,390),(110,313),(159,277),(177,265),(164,312),(165,337),(187,320),(176,351),(145,366),(115,382),(106,355)],(141,331),0,21,'head')
# Hind and fore limbs: bent joints, broad fetlocks, paired weight-bearing hoof toes.
spec={'root':((555,0,445),(566,0,395),None),'spine':((555,0,445),(259,0,422),'root'),'neck':((259,0,422),(176,0,399),'spine'),'head':((176,0,399),(79,0,436),'neck'),'jaw':((164,0,445),(82,0,460),'head'),'sail':((513,0,376),(566,0,70),'spine')}
for side in (-1,1):
 tag='L' if side<0 else 'R'
 for fore in (True,False):
  rows=([(287,491,44,45),(291,544,46,48),(313,589,28,29),(299,628,32,31),(280,675,23,21),(268,710,28,27),(263,725,27,25)] if fore else [(585,469,54,51),(589,514,54,50),(559,558,37,35),(590,594,32,34),(626,627,24,24),(620,669,24,25),(604,707,27,27),(601,725,25,24)])
  labels=[p+'_'+tag for p in (('front','fore') if fore else ('back','hock','heel'))];cuts=[0,2,len(rows)-1] if fore else [0,2,4,len(rows)-1]
  lateral=side*(59 if fore else 57);offset=(14 if side>0 else -8)
  for j,name in enumerate(labels):
   aa,bb=rows[cuts[j]],rows[cuts[j+1]];spec[name]=((aa[0]+offset,lateral,aa[1]),(bb[0]+offset,lateral,bb[1]),('spine' if fore else 'root') if j==0 else labels[j-1])
  rr=[];tt=[];ww=[]
  for i,(x,h,r,w) in enumerate(rows):
   rr.append([(x+offset+r*cos(j*pi/4),lateral+w*sin(j*pi/4),h) for j in range(8)])
   samplex=(340 if fore else 652)+(x-(285 if fore else 605))*.42
   tt.append([(samplex+cos(j*pi/4)*min(r*.56,16),min(716,h+7)) for j in range(8)])
   ix=sum(i>=c for c in cuts[1:-1]);ww.extend([({labels[ix-1]:.5,labels[ix]:.5} if i in cuts[1:-1] else labels[ix])]*8)
  rings(rr,tt,ww)
  x=rows[-1][0]+offset
  toe_name=('toe_front_' if fore else 'toe_back_')+tag
  spec[toe_name]=((x,lateral,725),(x-14,lateral,757),labels[-1])
  for toe in (-1,1):
   rr=[];tt=[]
   for h,dx,w,r in [(710,4,12,18),(731,-3,17,30),(757,-11,17,32)]:
    rr.append([(x+dx+r*cos(j*pi/4),lateral+toe*14+w*sin(j*pi/4),h) for j in range(8)])
    tt.append([(329+cos(j*pi/4)*13, min(752,h+4)) for j in range(8)])
   rings(rr,tt,toe_name)
  if fore:
   leaf([(x-24,673),(x-9,652),(x+15,636),(x+29,614),(x+28,660),(x+17,696),(x+4,713),(x-23,711)],(x,683),lateral+side*18,12,labels[-1],side,[(312,695),(318,673),(349,649),(367,629),(363,664),(348,693),(335,709),(309,714)])
  else:
   leaf([(x-36,536),(x-5,504),(x+29,518),(x+55,560),(x+49,601),(x+21,582),(x-10,559)],(x+13,547),lateral+side*26,14,labels[0],side,[(570,504),(586,469),(616,496),(652,551),(662,582),(627,568),(594,543)])
# Single arched kite sail, crowned spar and sweeping gold ribs.
hub=(526,339);out=[(460,312),(477,275),(479,200),(461,158),(420,122),(386,119),(352,139),(381,112),(439,78),(503,54),(570,43),(642,53),(700,85),(753,128),(787,181),(797,219),(802,263),(790,313),(760,362),(768,323),(746,297),(712,286),(667,282),(610,297),(562,318)]
out=out+[hub];pts=[(x,y,h) for y in (-5,5) for x,h in out]
from mathutils.geometry import tessellate_polygon
n=len(out);tri=tessellate_polygon([[Vector((x,h,0)) for x,h in out]])
part(pts,[tuple(t) for t in tri]+[tuple(n+i for i in reversed(t)) for t in tri]+[(i,(i+1)%n,n+(i+1)%n,n+i) for i in range(n)],out+out,'sail')
for side in (-1,1):
 for x,h in [(576,36),(790,220),(432,373)]:
  rod((526,side*14,339),(x,side*3,h),5,(566,124),'sail')
def jewel(x,y,h,r,b,sample):
 ell(b,[(x-r,y,h,r*.35,r*.35),(x,y,h,r,r),(x+r,y,h,r*.35,r*.35)],lambda k,a,z:(sample[0]+(k-1)*3,sample[1]+z*4),8)
for x,h,r in [(576,35,19),(790,219,16),(526,340,19)]:
 jewel(x,0,h,r,'sail',(576,33) if x!=526 else (524,337))
# Tapering tail, three articulated links and four individually beveled collars.
tail=[(616,393,37),(667,380,33),(716,395,29),(764,419,26),(808,456,22),(843,496,19),(861,527,14)]
def link(x):return 'tail1' if x<721 else 'tail2' if x<804 else 'tail3'
for i,(a,b) in enumerate([(0,2),(2,4),(4,6)]):
 spec['tail'+str(i+1)]=((tail[a][0],0,tail[a][1]),(tail[b][0],0,tail[b][1]),'root' if i==0 else 'tail'+str(i))
rr=[];tt=[];ww=[]
for x,h,r in tail:
 rr.append([(x,cos(j*pi/4)*r,h+sin(j*pi/4)*r*.86) for j in range(8)])
 tt.append([(x,h+sin(j*pi/4)*r*.73) for j in range(8)]);ww.extend([link(x)]*8)
rings(rr,tt,ww)
for k in [1,2,4,5]:
 x,h,r=tail[k];dx=tail[k+1][0]-tail[k-1][0];dz=tail[k+1][1]-tail[k-1][1];ln=math.hypot(dx,dz);dx/=ln;dz/=ln;rr=[];tt=[]
 for off,m in [(-10,1.02),(-7,1.24),(7,1.24),(10,1.02)]:
  rr.append([(x+off*dx-dz*r*m*sin(j*pi/5),r*m*cos(j*pi/5),h+off*dz+dx*r*m*sin(j*pi/5)) for j in range(10)])
  tt.append([(782+off*.64,435+sin(j*pi/5)*7) for j in range(10)])
 rings(rr,tt,link(x))
leaf([(849,498),(868,514),(895,550),(914,592),(892,586),(870,612),(851,638),(835,624),(811,611),(763,643),(779,598),(804,559)],(847,567),0,11,'tail3')
leaf([(830,616),(861,636),(892,604),(910,600),(916,655),(918,721),(863,682),(816,720),(822,666)],(865,656),0,10,'tail3')
me=bpy.data.meshes.new('Kirin • malha');me.from_pydata(verts,[],faces);me.update()
bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(me);bm.free()
ob=bpy.data.objects.new('Kirin vulcânico',me);s.collection.objects.link(ob)
uv=me.uv_layers.new(name='Pintura')
for loop in me.loops:
 u,v=uvs[loop.vertex_index];uv.data[loop.index].uv=(u/1024,1-v/1024)
mat=bpy.data.materials.new('Kirin • pigmentos de magma');mat.use_nodes=True
tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(D/'Kirin-atlas.png'));tex.image.pack();tex.interpolation='Closest'
bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=1;bs.inputs['Specular IOR Level'].default_value=0
for slot in ('Base Color','Emission Color'):mat.node_tree.links.new(tex.outputs['Color'],bs.inputs[slot])
bs.inputs['Emission Strength'].default_value=.7;me.materials.append(mat)
arm=bpy.data.armatures.new('Esqueleto');rig=bpy.data.objects.new('Kirin_Rig',arm);s.collection.objects.link(rig);bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
spec['breath']=((330,0,470),(205,0,450),'spine')
for side,tag in [(-1,'L'),(1,'R')]:spec['mane_'+tag]=((200,side*35,380),(411,side*52,303),'neck')
for name,(a,b,parent) in spec.items():
 bone=arm.edit_bones.new(name);bone.head=world(a);bone.tail=world(b)
 if parent:bone.parent=arm.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT');groups={name:ob.vertex_groups.new(name=name) for name in spec}
for i,w in enumerate(weights):
 for name,value in (w if isinstance(w,dict) else {w:1}).items():groups[name].add([i],value,'REPLACE')
ob.parent=rig;ob.modifiers.new('Articulações','ARMATURE').object=rig
def rot(name,axis,angle):
 pb=rig.pose.bones[name];pb.rotation_quaternion=Quaternion(arm.bones[name].matrix_local.to_3x3().inverted()@Vector(axis),angle)
exec((D/'movimentos.py').read_text(encoding='utf-8-sig'),globals())
exec((D/'caminhada.py').read_text(encoding='utf-8-sig'),globals())
s.render.fps=30
for name,frames in [('Idle',151),('Despertar',241),('Imponencia',181),('Walk',49)]:
 rig.animation_data_create();rig.animation_data.action=None
 for f in sorted(set(range(1,frames+1,1 if name=='Walk' else 3)) | {frames}):
  s.frame_set(f);t=(f-1)/30;phase=t*pi/2
  for p in rig.pose.bones:p.rotation_quaternion=Quaternion();p.scale=(1,1,1)
  roar=sin(pi*min(1,max(0,(t-1.4)/4.2)))**2 if name=='Despertar' else 0
  dip=sin(pi*min(1,max(0,(t-.4)/1.1)))**2 if name=='Despertar' else 0
  for b,a in [('spine',.015*sin(phase)+.12*roar-.06*dip),('neck',.026*sin(phase)+.23*roar-.13*dip),('head',.02*sin(phase+.4)+.16*roar),('jaw',-.45*roar)]:rot(b,(0,1,0),a)
  rot('sail',(1,0,0),.026*sin(phase+.5)+.03*roar*sin(11*t))
  for j in range(3):rot('tail'+str(j+1),(0,0,1),(.09+.025*j)*sin(phase-.6*j)+.06*roar*sin(4*t-j))
  for side in 'LR':
   rot('front_'+side,(0,1,0),.24*roar-.07*dip);rot('fore_'+side,(0,1,0),-.39*roar)
  if name=='Walk':
   for p in rig.pose.bones:p.rotation_quaternion=Quaternion()
   walk_pose(t)
  elif name!='Despertar':pose_kirin(name,t)
  for p in rig.pose.bones:
   p.keyframe_insert(data_path='rotation_quaternion',frame=f)
   if name=='Walk' and p.name=='root':p.keyframe_insert(data_path='location',frame=f)
   if p.name=='breath':p.keyframe_insert(data_path='scale',frame=f)
 action=rig.animation_data.action;action.name=name
 track=rig.animation_data.nla_tracks.new();track.name=name;track.strips.new(name,1,action);track.mute=True;rig.animation_data.action=None
rig.pose.bones['root'].location=(0,0,0)
for tr in rig.animation_data.nla_tracks:tr.mute=False
s.frame_set(1);ob.select_set(True);bpy.ops.export_scene.gltf(filepath=str(D/'Kirin.glb'),use_selection=True,export_animation_mode='NLA_TRACKS')
for tr in rig.animation_data.nla_tracks:tr.mute=tr.name!='Idle'
s.frame_end=151;s.frame_set(1)
s.world=bpy.data.worlds.new('Estúdio');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs[0].default_value=(.31,.27,.32,1)
bpy.ops.object.light_add(type='AREA',location=(-4,-5,9));light=bpy.context.object;light.data.energy=400;light.data.size=6;light.rotation_euler=(Vector((0,0,3))-light.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();cam=bpy.context.object;s.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=8.65
def aim(x,y,z):
 target=Vector((.28,0,3.05));cam.location=target+Vector((x,y,z));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
s.render.engine='CYCLES';s.cycles.samples=8;s.render.resolution_x=760;s.render.resolution_y=650;s.render.resolution_percentage=100;s.view_settings.view_transform='Standard';s.render.film_transparent=True
for n,dir in [('Perfil',(0,-10,0)),('Frente',(-10,0,.3)),('Tres-quartos',(-7,-10,1.2))]:
 aim(*dir);s.render.filepath=str(D/(n+'.png'));bpy.ops.render.render(write_still=True)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,0));floor=bpy.context.object;floor.name='Piso de apresentação';floor.hide_select=True
ground=bpy.data.materials.new('Ardósia');ground.diffuse_color=(.18,.19,.23,1);floor.data.materials.append(ground);s.render.film_transparent=False
s.cycles.samples=20;bpy.ops.object.select_all(action='DESELECT');bpy.context.view_layer.objects.active=rig;rig.select_set(True)
for ar in bpy.context.screen.areas:
 if ar.type=='VIEW_3D':
  sp=ar.spaces.active;sp.region_3d.view_rotation=cam.rotation_euler.to_quaternion();sp.region_3d.view_distance=10;sp.region_3d.view_location=(.28,0,3.05);sp.shading.type='MATERIAL';sp.overlay.show_overlays=False
s.render.filepath='//Kirin.png';bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(D/'Kirin.blend'));bpy.ops.render.render(write_still=True)

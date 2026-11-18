from pathlib import Path
from math import sin,cos,pi,tau
import math,bpy,bmesh
from mathutils import Vector,Quaternion
D=Path(__file__).resolve().parent
bpy.ops.wm.read_factory_settings(use_empty=True);s=bpy.context.scene
points=[];polys=[];inks=[];binds=[];spec={}
def w(p):return Vector((p[0]/270,p[1]/270,(486-p[2])/270))
def add(ps,fs,uv,b):
 off=len(points);points.extend(map(w,ps));binds.extend([b]*len(ps))
 for f in fs:
  polys.append(tuple(off+j for j in f));inks.append([uv(j,f) if callable(uv) else uv[j] for j in f])
def strips(n,k):
 return [(i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j) for i in range(k-1) for j in range(n)]+[tuple(reversed(range(n))),tuple(range((k-1)*n,k*n))]
def skin(rows,b,paint,n=12):
 ps=[(x+rx*sin(j*tau/n),y-ry*cos(j*tau/n),h) for x,y,h,rx,ry in rows for j in range(n)]
 add(ps,strips(n,len(rows)),lambda i,f:paint(ps[i],i//n,jangle(i,n),sum(ps[k][1] for k in f)/len(f)),b)
def jangle(i,n):return (i%n)*tau/n
def gold(a,b,r,bone):
 a,b=Vector(a),Vector(b);d=(b-a).normalized();u=d.cross(Vector((0,1,0)))
 if u.length<.01:u=d.cross(Vector((1,0,0)))
 u.normalize();v=d.cross(u);ps=[p+r*(u*cos(j*tau/6)+v*sin(j*tau/6)) for p in (a,b) for j in range(6)]
 add(ps,strips(6,2),[(202+cos(j*tau/6)*4,26+sin(j*tau/6)*4) for j in range(6)]*2,bone)
def bead(x,y,h,r,b):
 skin([(x,y,h-r,.4*r,.4*r),(x,y,h,r,r),(x,y,h+r,.45*r,.45*r)],b,lambda p,k,a,f:(202+4*sin(a),23+4*k),8)
spec['root']=((0,0,442),(0,0,377),None);spec['peito']=((0,0,384),(0,-2,323),'root');spec['cabeça']=((0,-2,323),(0,-8,248),'peito')
skin([(0,6,447,21,25),(0,3,435,42,35),(0,0,407,49,40),(0,-3,371,42,34),(0,0,341,34,28)],'peito',lambda p,k,a,f:(299+p[0]*.46, max(373,min(450,p[2]))))
# Taper the mask into a chin. The front and back use their own painted views.
face=[(0,-5,334,7,14),(0,-3,321,45,47),(0,-2,300,71,66),(0,0,282,92,74),(0,1,261,74,65),(0,2,231,56,43),(0,3,212,24,25),(0,1,205,7,8)]
def mask(p,k,a,f):
 x,y,h=p
 if f<5:return 599+x*.975,790+h
 if f>27:return 865+x*.66,1050+(h-205)*.65
 return (1090+.42*y,1060+.65*(h-220)) if h<267 else (867+.5*y,1060+.6*(h-257))
skin(face,'cabeça',mask,16)
# Voluminous scarf made of a folded standing collar and a split short jacket.
def cloth(rows,b,paint):
 n=14;ps=[]
 for rx,ry,edge in rows:
  for j in range(n):
   a=tau*j/n;ps.append((rx*sin(a),-ry*cos(a),edge(a)))
 add(ps,strips(n,len(rows)),lambda i,f:paint(ps[i],i//n,jangle(i,n)),b)
cloth([(38,31,lambda a:327),(55,40,lambda a:346),(78,47,lambda a:373+12*abs(sin(a))+13*max(0,-cos(a))-18*max(0,cos(a))),(72,43,lambda a:372+12*abs(sin(a))+13*max(0,-cos(a))-18*max(0,cos(a)))],'peito',lambda p,k,a:(1090+sin(a)*65,1038+25*k))
cloth([(36,33,lambda a:322),(53,42,lambda a:330+4*sin(a)),(60,47,lambda a:339+22*max(0,cos(a))**5),(53,42,lambda a:340+22*max(0,cos(a))**5)],'peito',lambda p,k,a:(1110+sin(a)*70,1036+23*k+10*max(0,cos(a))**5))
for q in (-1,1):
 tag='E' if q<0 else 'D';ear='orelha_'+tag;arm='braço_'+tag;leg='coxa_'+tag;foot='pé_'+tag
 spec[ear]=((q*39,4,227),(q*99,22,28),'cabeça');spec[arm]=((q*43,-13,346),(q*43,-44,391),'peito')
 spec[leg]=((q*34,5,410),(q*46,9,459),'root');spec[foot]=((q*46,9,459),(q*47,-26,480),leg)
 skin([(q*35,7,390,18,21),(q*40,8,412,29,32),(q*43,7,435,30,31),(q*46,9,450,22,22),(q*47,8,458,13,16),(q*47,5,470,13,16)],leg,lambda p,k,a,f:(1228+69*(1+q*sin(a)*.82-cos(a)*.18),1031+([0,42,104,150,179,213][k])),10)
 skin([(q*47,-3,463,12,13),(q*48,-12,470,26,27),(q*50,-17,481,33,35),(q*50,-17,486,31,33)],foot,lambda p,k,a,f:(1382+68*(1+q*sin(a)*.57-cos(a)*.43),1030+[0,58,164,214][k]),12)
 skin([(q*43,-21,349,12,14),(q*44,-28,356,17,20),(q*43,-40,374,21,20),(q*42,-44,387,20,18),(q*41,-43,399,12,12)],arm,lambda p,k,a,f:(865+sin(a)*67,1034+23*k),10)
 # Fabric flares off the ribs, with the stitched square painted on the outside.
 rim=[(q*44,-20,342),(q*48,21,340),(q*75,45,392),(q*70,-9,386)]
 add(rim+[(q*69,12,366)],[(0,1,4),(1,2,4),(2,3,4),(3,0,4)],[(747,350),(775,350),(838,423),(786,428),(791,389)],'peito')
 # Folded kite panels with one asymmetric paper patch.
 outline=[(34,3,229),(10,2,208),(19,10,165),(38,17,98),(96,30,28),(110,29,137),(58,7,211)]
 pp=[(q*x,y,h) for x,y,h in outline]+[(q*45,-4,140),(q*47,32,140)]
 uv=[(299+q*x,h) for x,y,h in outline]+[(299+q*47,140)]*2
 fs=[f for j in range(7) for f in ((j,(j+1)%7,7),(j,8,(j+1)%7))]
 add(pp,fs,uv,ear)
 for j in [1,2,3]:gold(pp[j],pp[j+1],3.3,ear)
 for j,r in [(3,6.5),(4,7)]:bead(*pp[j],r,ear)
 # Two cords sweep apart; their bows sit at different heights.
 t1='fio_'+tag;t2='laço_'+tag
 chain=[(q*11,36,428),(q*17,58,443),(q*28,84,452),(q*43-9,120,442),(q*58-16,160,417),(q*68-20,195+q*24,365+q*18)]
 spec[t1]=(chain[0],chain[3],'root');spec[t2]=(chain[3],chain[-1],t1)
 for i in range(5):gold(chain[i],chain[i+1],3.4,t1 if i<3 else t2)
 x,y,h=chain[-1]
 for side in (-1,1):
  ps=[(x,y,h),(x+side*17,y-side*7,h-20),(x+side*21,y-side*9,h-15),(x+side*21,y-side*9,h+7),(x+side*10,y-side*4-3,h-4)]
  add(ps,[(0,1,4),(1,2,4),(2,3,4),(3,0,4) ],[(912,391),(933,385),(945,385),(934,399),(928,393)],t2)
 bead(x,y,h,5,t2)
me=bpy.data.meshes.new('Rabbito • malha');me.from_pydata(points,[],polys);me.update()
uv=me.uv_layers.new(name='Pintura')
for f,col in zip(me.polygons,inks):
 for li,(u,v) in zip(f.loop_indices,col):uv.data[li].uv=(u/1536,1-v/1280)
bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(me);bm.free()
ob=bpy.data.objects.new('Rabbito',me);s.collection.objects.link(ob)
mat=bpy.data.materials.new('Rabbito • papel, tecido e bambu');mat.use_nodes=True
tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(D/'Rabbito-atlas.png'));tex.image.pack();tex.interpolation='Closest'
bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=1;bs.inputs['Specular IOR Level'].default_value=0
for slot in ('Base Color','Emission Color'):mat.node_tree.links.new(tex.outputs['Color'],bs.inputs[slot])
bs.inputs['Emission Strength'].default_value= .53;me.materials.append(mat)
arm=bpy.data.armatures.new('Esqueleto');rig=bpy.data.objects.new('Rabbito_Rig',arm);s.collection.objects.link(rig);bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
for name,(a,b,parent) in spec.items():
 bone=arm.edit_bones.new(name);bone.head=w(a);bone.tail=w(b)
 if parent:bone.parent=arm.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT');groups={k:ob.vertex_groups.new(name=k) for k in spec}
for i,k in enumerate(binds):groups[k].add([i],1,'REPLACE')
ob.parent=rig;ob.modifiers.new('Movimento','ARMATURE').object=rig
def orient(b,ax,angle):
 pb=rig.pose.bones[b];pb.rotation_quaternion=Quaternion(arm.bones[b].matrix_local.to_3x3().inverted()@Vector(ax),angle)
s.render.fps=30
for name,end in [('Idle',121),('Alerta',91)]:
 rig.animation_data_create();rig.animation_data.action=None
 for f in range(1,end+1,3):
  s.frame_set(f);t=(f-1)/30;phase=t*tau/4
  def motion(lag):
   if name=='Idle':return sin(phase-lag)-sin(-lag)
   a=min(1,max(0,(t-.12-lag*.25)/(.58+lag*.10)));b=min(1,max(0,(t-1.85-lag*.18)/.75));return sin(pi*a/2)**2*cos(pi*b/2)**2
  for pb in rig.pose.bones:pb.rotation_quaternion=Quaternion()
  orient('peito',(1,0,0),.045*motion(0));orient('cabeça',(0,0,1),(.06 if name=='Idle' else .27)*motion(.25))
  for side,tag in [(-1,'E'),(1,'D')]:
   m=motion(.1 if side<0 else 1.2)
   orient('orelha_'+tag,(0,1,0),side*(.055 if name=='Idle' else .28)*m)
   orient('braço_'+tag,(1,0,0),.11*m);orient('fio_'+tag,(1,0,0),.095*motion(.3));orient('laço_'+tag,(0,0,1),side*.12*motion(.8))
  for pb in rig.pose.bones:pb.keyframe_insert(data_path='rotation_quaternion',frame=f)
 act=rig.animation_data.action;act.name=name;track=rig.animation_data.nla_tracks.new();track.name=name;track.strips.new(name,1,act);track.mute=True;rig.animation_data.action=None
for tr in rig.animation_data.nla_tracks:tr.mute=False
s.frame_set(1);ob.select_set(True);bpy.ops.export_scene.gltf(filepath=str(D/'Rabbito.glb'),use_selection=True,export_animation_mode='NLA_TRACKS')
for tr in rig.animation_data.nla_tracks:tr.mute=tr.name!='Idle'
s.frame_set(1);s.frame_end=121
s.world=bpy.data.worlds.new('Estúdio');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs[0].default_value=(.25,.29,.33,1)
bpy.ops.object.light_add(type='AREA',location=(-2,-4,5));light=bpy.context.object;light.data.energy=165;light.data.size=4;light.rotation_euler=(-light.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();cam=bpy.context.object;s.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=2.16
def aim(a):
 target=Vector((0,.09,.86));cam.location=target+Vector((4*sin(a),-4*cos(a),.62));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
s.render.engine='CYCLES';s.cycles.samples=8;s.view_settings.view_transform='Standard';s.render.resolution_x=540;s.render.resolution_y=560;s.render.resolution_percentage=100;s.render.film_transparent=True
for label,a in [('Frente',0),('Perfil',-pi/2),('Costas',2.85),('Tres-quartos',-.64)]:
 aim(a);s.render.filepath=str(D/(label+'.png'));bpy.ops.render.render(write_still=True)
bpy.ops.mesh.primitive_plane_add(size=200);ground=bpy.context.object;ground.name='Piso do estúdio'
m=bpy.data.materials.new('Ardósia');m.diffuse_color=(.19,.21,.24,1);ground.data.materials.append(m);ground.hide_select=True;s.cycles.samples=20;s.render.film_transparent=False;s.render.filepath='//Rabbito.png'
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
for a in bpy.context.screen.areas:
 if a.type=='VIEW_3D':
  sp=a.spaces.active;sp.region_3d.view_rotation=cam.rotation_euler.to_quaternion();sp.region_3d.view_distance=2.8;sp.region_3d.view_location=(0,.07,.86);sp.shading.type='MATERIAL';sp.overlay.show_overlays=False
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(D/'Rabbito.blend'));bpy.ops.render.render(write_still=True)

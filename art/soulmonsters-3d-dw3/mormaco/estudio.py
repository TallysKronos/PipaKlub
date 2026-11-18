arm=bpy.data.armatures.new('Esqueleto');rig=bpy.data.objects.new('Mormaço livre',arm);s.collection.objects.link(rig);bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
for name,(a,b,parent) in bones.items():
 e=arm.edit_bones.new(name);e.head=world(a);e.tail=world(b)
 if parent:e.parent=arm.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
for ob,bind in parts:
 ob.parent=rig
 if isinstance(bind,str):ob.vertex_groups.new(name=bind).add(list(range(len(ob.data.vertices))),1,'REPLACE')
 else:
  groups={n:ob.vertex_groups.new(name=n) for n in {n for row in bind for n in row}}
  for i,row in enumerate(bind):
   for n,w in row.items():groups[n].add([i],w,'REPLACE')
 ob.modifiers.new('Articulações','ARMATURE').object=rig
# A short asymmetric bracing pose for checking joint deformation.
from mathutils import Quaternion
for frame,amount in [(1,0),(10,.5),(18,1),(29,.42),(40,0)]:
 for name,turn in [('Raiz frente E',12),('Dobra frente E',-36),('Pata frente E',22),('Cabeça',4),('Cauda',-5)]:
  pb=rig.pose.bones[name];rest=pb.bone.matrix_local.to_quaternion();pb.rotation_quaternion=rest.inverted()@Quaternion((1,0,0),math.radians(turn*amount))@rest;pb.keyframe_insert(data_path='rotation_quaternion',frame=frame)
rig.animation_data.action.name='Firmar apoio';s.frame_end=40;s.frame_set(1)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=str(O/'Mormaco.glb'),use_selection=True,export_yup=True)
s.world=bpy.data.worlds.new('Estúdio');s.world.use_nodes=True;bg=s.world.node_tree.nodes['Background'];bg.inputs[0].default_value=(.235,.256,.29,1);bg.inputs[1].default_value=.82
bpy.ops.object.light_add(type='AREA',location=(1,-4,7));light=bpy.context.object;light.data.energy=210;light.data.size=5;light.rotation_euler=(-light.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();cam=bpy.context.object;s.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=4.8
s.render.engine='CYCLES';s.cycles.samples=8;s.render.resolution_x=620;s.render.resolution_y=520;s.render.resolution_percentage=100;s.view_settings.view_transform='Standard'
s.render.film_transparent=True
def aim(a):
 center=Vector((0,.025,1.30));cam.location=center+Vector((5*sin(a),-5*cos(a),.78));cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
aim(.82)
bpy.context.preferences.filepaths.save_version=0
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
for screen in bpy.data.screens:
 for area in screen.areas:
  if area.type=='VIEW_3D':
   space=area.spaces.active;space.region_3d.view_rotation=cam.rotation_euler.to_quaternion();space.region_3d.view_distance=5.4;space.region_3d.view_location=Vector((0,0,1.25));space.region_3d.view_perspective='ORTHO';space.shading.color_type='TEXTURE';space.shading.type='MATERIAL';space.overlay.show_overlays=False
bpy.ops.wm.save_as_mainfile(filepath=str(O/'Mormaco.blend'))
for name,angle in [('Tres-quartos',.82),('Frente',0),('Perfil',pi/2),('Costas',pi)]:
 aim(angle);s.render.filepath=str(O/(name+'.png'));bpy.ops.render.render(write_still=True)
aim(.82);s.frame_set(18);s.render.filepath=str(O/'Firmar-apoio.png');bpy.ops.render.render(write_still=True)
s.frame_set(1)
clay=bpy.data.materials.new('Teste da silhueta');clay.diffuse_color=(.42,.44,.46,1);clay.use_nodes=True
clay.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=clay.diffuse_color
clay.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.96
s.view_layers[0].material_override=clay
for ob,_ in parts:
 if ob.name.startswith('Jato termal'):ob.hide_render=True
for name,angle in [('Volume-frente',0),('Volume-tres-quartos',.82),('Volume-perfil',pi/2)]:
 aim(angle);s.render.filepath=str(O/(name+'.png'));bpy.ops.render.render(write_still=True)
s.view_layers[0].material_override=None
for ob,_ in parts: ob.hide_render=False
# Studio floor appears only in the presentation photograph and receives actual foot shadows.
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,.004))
ground=bpy.context.object;ground.name='Piso do estúdio'
ground_mat=bpy.data.materials.new('Piso • cinza mineral');ground_mat.use_nodes=True
floor_bs=ground_mat.node_tree.nodes['Principled BSDF']
floor_bs.inputs['Base Color'].default_value=(.37,.39,.44,1)
floor_bs.inputs['Roughness'].default_value=.98
floor_bs.inputs['Emission Color'].default_value=(.09,.097,.12,1)
floor_bs.inputs['Emission Strength'].default_value=.5
ground.data.materials.append(ground_mat)
s.render.film_transparent=False;s.cycles.samples=28
s.render.resolution_x=820;s.render.resolution_y=650;cam.data.ortho_scale=4.45
aim(.86)
studio=bpy.data.collections.new('Estúdio de apresentação');s.collection.children.link(studio)
for piece in (ground,cam,light):
 for group in list(piece.users_collection):group.objects.unlink(piece)
 studio.objects.link(piece);piece.hide_select=True
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
for screen in bpy.data.screens:
 for area in screen.areas:
  if area.type=='VIEW_3D':
   space=area.spaces.active;space.region_3d.view_rotation=cam.rotation_euler.to_quaternion()
   space.shading.use_scene_lights=True;space.shading.use_scene_world=True
s.render.filepath='//Mormaco-livre.png'
bpy.ops.wm.save_as_mainfile(filepath=str(O/'Mormaco.blend'))
bpy.ops.render.render(write_still=True)

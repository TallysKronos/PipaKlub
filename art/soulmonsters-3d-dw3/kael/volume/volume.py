"""Adjust garment ease in mesh space with an unchanged motion skeleton."""
from pathlib import Path
from math import exp, sin, pi
import bpy
from mathutils import Vector, Quaternion
D=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(D.parent/'Kael.blend'))
s=bpy.context.scene
rig=next(o for o in s.objects if o.type=='ARMATURE')
def clamp(x):return max(0,min(1,x))
def curve(z,points):
    for (a,b),(c,d) in zip(points,points[1:]):
        if z<=c:
            t=clamp((z-a)/(c-a));return b+(d-b)*t*t*(3-2*t)
    return points[-1][1]
def render(name):
    target=Vector((0,0,.85));c=s.camera;c.location=target+Vector((5,-.9,1.85))
    c.rotation_euler=(target-c.location).to_track_quat('-Z','Y').to_euler();c.data.ortho_scale=1.96
    s.render.resolution_x=380;s.render.resolution_y=460;s.render.resolution_percentage=100
    s.render.filepath=str(D/name);bpy.ops.render.render(write_still=True)
s.frame_set(12);render('Antes.png')
for o in s.objects:
    if o.type!='MESH' or o.find_armature()!=rig:continue
    label=o.name
    for v in o.data.vertices:
        x,y,z=v.co;sg=1 if x>=0 else -1
        chest=curve(z,[(.83,.32),(.94,.42),(1.08,.6),(1.22,.67),(1.27,.5),(1.32,0)])
        if label.startswith(('Jaqueta aberta','Camiseta.')):
            v.co.x*=1+chest*.78
            v.co.y=-.012+(y+.012)*(1+chest*1.15)
        elif label.startswith(('Manga ','Camiseta manga','Braço ','Mão ','Polegar ')):
            along=clamp((z-.85)/.43)
            axis=.28-.167*along
            fullness=curve(z,[(.70,.08),(.85,.12),(.92,.42),(1.07,.56),(1.19,.70),(1.27,.46),(1.30,.25)])
            v.co.x=sg*(axis+.026+.024*along)+(x-sg*axis)*(1+fullness*.67)
            v.co.y=.022+(y-.022)*(1+fullness*.98)
        elif label.startswith('Calça'):
            t=curve(z,[(.18,.08),(.27,.26),(.42,.38),(.55,.33),(.69,.48),(.82,.52),(.92,.37)])
            # Each trouser leg fills around its own centre below the crotch.
            axis=sg*(.098*(1-clamp((z-.62)/.19)))
            v.co.x=axis+(x-axis)*(1+t*.74)
            v.co.y=-.018+(y+.018)*(1+t)
        elif label.startswith(('Tênis','Sola')):
            v.co.x=sg*.13+(x-sg*.13)*1.22
            v.co.y=-.04+(y+.04)*1.09
        elif label.startswith('Tira '):
            v.co.x*=1.23;v.co.y*=1.33
        elif label.startswith('Fone'):
            v.co.y-=.043*clamp((1.31-z)/.05)
    o.data.update()
# Counterpose the arms in idle so that their outlines separate in side view.
for tr in rig.animation_data.nla_tracks:tr.mute=True
action=bpy.data.actions['Espera'];rig.animation_data.action=action
for f in range(1,80):
    s.frame_set(f)
    for sg in (-1,1):
        bone=rig.pose.bones['Braço'+str(sg)]
        axis=bone.bone.matrix_local.to_quaternion().inverted() @ Vector((1,0,0))
        bone.rotation_quaternion=Quaternion(axis,sg*.19) @ bone.rotation_quaternion
        bone.keyframe_insert(data_path='rotation_quaternion',frame=f)
rig.animation_data.action=None
for tr in rig.animation_data.nla_tracks:tr.mute=False
s.frame_set(1);bpy.ops.object.select_all(action='DESELECT')
for o in s.objects:
    if o==rig or (o.type=='MESH' and o.find_armature()==rig):o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(D/'Kael.glb'),use_selection=True,use_active_scene=True,export_animation_mode='NLA_TRACKS')
for tr in rig.animation_data.nla_tracks:tr.mute=tr.name!='Espera'
s.frame_set(12);render('Depois.png')
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(D/'Kael.blend'),compress=True)

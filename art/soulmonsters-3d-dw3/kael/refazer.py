"""Rebuild Kael's removable haircut from corresponding front and profile outlines."""
from pathlib import Path
import math
import bpy
import numpy as np
from mathutils import Vector
D=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(D/'fontes/Kael-base.blend'))
s=bpy.context.scene
rig=next(o for o in s.objects if o.type=='ARMATURE')
old=next(o for o in s.objects if o.name.startswith('Cabelo • coroa'));collection=old.users_collection[0]
old.name='Cabelo • base sobre o crânio'
# Seat the upper shell under the new locks, retaining the approved ear and nape clearance.
for v in old.data.vertices:
    y=985-v.co.z*560
    w=float(np.clip((147-y)/64,0,1))
    v.co.x*=1-.16*w
    v.co.y*=1-.10*w
    frontness=max(0,min(1,(-v.co.y-.02)/.07))
    v.co.z+=frontness*.026*float(np.clip((y-95)/33,0,1))
    v.co.z-=.052*w
    if v.co.y>.04 and y>185:
        v.co.z-=min(.019,(v.co.y-.04)*.25)*(y-185)/32
image=bpy.data.images.load(str(D/'fontes/kael-tres-vistas.png'));image.colorspace_settings.name='Non-Color'
w,h=image.size;rgba=np.empty((h,w,4),np.float32);image.pixels.foreach_get(rgba.ravel());rgba=rgba[::-1]
# x coordinates are local to the two drawings, y means distance from their top edge.
def contour(points):
    return np.array([tuple(map(float,p.split(','))) for p in points.split()])
def bounds(poly,ys):
    result=[]
    for y in np.ravel(ys):
        y=np.clip(y,poly[:,1].min()+.002,poly[:,1].max()-.002)
        hits=[]
        for (a,b),(c,d) in zip(poly,np.roll(poly,-1,axis=0)):
            if min(b,d)<=y<max(b,d):hits.append(a+(c-a)*(y-b)/(d-b))
        result.append((min(hits),max(hits)))
    return np.array(result).reshape((*np.shape(ys),2))
def pigment(name,color):
    if name=='Nuca':return np.array([.208,.215,.243])
    return np.array(color)
def textures(base,is_nape):
    views=[]
    for lo in [175,660]:
        tile=rgba[:242,lo:lo+235,:];rgb=tile[:,:,:3].copy()
        valid=(tile[:,:,3]>.80)&(rgb[:,:,0]>.12)
        if is_nape:valid &= (rgb[:,:,0]<.37)&(rgb[:,:,2]-rgb[:,:,0]>.012)&(rgb[:,:,2]-rgb[:,:,0]<.1)
        else:valid &= (rgb[:,:,2]-rgb[:,:,0]>.11)&(rgb[:,:,0]<.53)
        # Extend pigment over edge texels instead of dragging the black outline onto side faces.
        for _ in range(9):
            sums=np.zeros_like(rgb);count=np.zeros(valid.shape)
            for axis,step in ((0,1),(0,-1),(1,1),(1,-1)):
                ok=np.roll(valid,step,axis);index=[slice(None)]*2;index[axis]=0 if step==1 else -1;ok[tuple(index)]=False
                sums+=np.roll(rgb,step,axis)*ok[:,:,None];count+=ok
            new=(~valid)&(count>0);rgb[new]=sums[new]/count[new,None];valid |= new
        rgb[~valid]=base;views.append(rgb)
    return views
blue=pigment('Coroa',[.25,.32,.49]);navy=pigment('Nuca',None)
blue_views=textures(blue,False);navy_views=textures(navy,True)
# Give the supporting shell a quiet painted base; all readable upper locks are geometry.
base_mat=old.data.materials[0].copy()
base_im=next(n for n in base_mat.node_tree.nodes if n.type=='TEX_IMAGE')
bw,bh=base_im.image.size
u,v=np.meshgrid((np.arange(bw)+.5)/bw,(np.arange(bh)+.5)/bh)
a=u*np.pi*2-np.pi
line=.83-.28*(1-np.cos(a))/2-.12*np.sin(a)**2
transition=np.clip((v-line)/.025,0,1)[:,:,None]
r=np.ones((bh,bw,4),np.float32);r[:,:,:3]=(1-transition)*[.228,.291,.445]+transition*[.20,.211,.245]
im=bpy.data.images.new('Base • índigo e nuca',width=bw,height=bh,alpha=False);im.pixels.foreach_set(r[::-1].copy().ravel());im.pack();base_im.image=im;old.data.materials[0]=base_mat
# Front-projected lips on the inherited head were repeating below the nape.
# Use unmarked skin coordinates on the rear jaw polygons, preserving the eyes and ears.
face=next(o for o in s.objects if o.name.startswith('Kael • rosto'))
layer=face.data.uv_layers.active
for f in face.data.polygons:
    if f.center.y>.003:
        for i in f.loop_indices:layer.data[i].uv=(.13,.32)
models=[]
def build(name,front,side,rho,color,fringe=0):
    if name=='Nuca':return  # the connected base already supplies the nape
    front,side=contour(front),contour(side)
    fy=front[:,1];sy=side[:,1];low=fy.min();high=fy.max()
    def sample(v,a):
        Y=low+(high-low)*v
        xf=bounds(front,Y);yf=bounds(side,sy.min()+(sy.max()-sy.min())*v)
        u=np.sin(a);q=rho*u-np.sqrt(1-rho*rho)*np.cos(a)
        return xf.mean(axis=-1)+np.diff(xf)[...,0]*.5*u,Y,yf.mean(axis=-1)+np.diff(yf)[...,0]*.5*q
    # One geometry ring at each change of direction, including the narrow ends.
    levels=sorted(set(round(float(v),4) for v in [0,.99,1,*np.linspace(0,1,11),*((fy-low)/(high-low)),*((sy-sy.min())/(sy.max()-sy.min()))]))
    levels=[v for i,v in enumerate(levels) if i==0 or v==1 or (v-levels[i-1])>.008]
    N=24;ps=[];uv=[];fs=[];weights=[]
    for v in levels:
        a=np.linspace(-np.pi,np.pi,N+1);x,y,z=sample(np.full_like(a,v),a)
        for j in range(N+1):
            fore=max(0,math.cos(a[j]))**.55
            push={'Franja • sobre a testa':16,'Mecha • têmpora':9,'Mecha • varrida':8}.get(name,2)
            ps.append(((x[j]+175-302+push*.42*math.sin(a[j]))/560,(z[j]+660-760-fore*push*(.42+.58*max(0,math.sin(a[j]))))/560,(985-y[j])/560))
            uv.append((j/N,1-v));weights.append(fringe*max(0,math.cos(a[j]))*(.2+.8*v))
    for i in range(len(levels)-1):
        for j in range(N):
            k=i*(N+1)+j;fs.append((k,k+N+1,k+N+2,k+1))
    fs.extend([tuple(reversed(range(N))),tuple((len(levels)-1)*(N+1)+j for j in range(N))])
    me=bpy.data.meshes.new(name);me.from_pydata(ps,[],fs);me.update();ob=bpy.data.objects.new(name,me);collection.objects.link(ob)
    layer=me.uv_layers.new(name='Pintura');ob.parent=rig;ob.modifiers.new('Armação','ARMATURE').object=rig
    crown=ob.vertex_groups.new(name='Cabeça');tip=ob.vertex_groups.new(name='Franja') if fringe else None
    for i,weight in enumerate(weights):
        crown.add([i],1-weight,'REPLACE')
        if weight:tip.add([i],weight,'REPLACE')
    for f in me.polygons:
        f.use_smooth=True
        for l in f.loop_indices:layer.data[l].uv=uv[me.loops[l].vertex_index]
    W,H=256,128
    a,v=np.meshgrid((np.arange(W)+.5)/W*2*np.pi-np.pi,(np.arange(H)+.5)/H)
    x,y,z=sample(v[:,0,None],a)
    x=np.clip(np.rint(x).astype(int),0,234);z=np.clip(np.rint(z).astype(int),0,234);y=np.rint(y).astype(int)
    source=navy_views if name=='Nuca' else blue_views
    wf=np.maximum(np.cos(a),0)**3;ws=np.abs(np.sin(a))**3;wb=np.maximum(-np.cos(a),0)**3
    rgb=(source[0][y,x]*wf[:,:,None]+source[1][y,z]*ws[:,:,None]+color*wb[:,:,None])/(wf+ws+wb)[:,:,None]
    tone={'Coroa • redemoinho':.97,'Coroa • ponta alta':1.13,'Mecha • varrida':1.08,'Mecha • têmpora':1.04,'Franja • sobre a testa':1.10}.get(name,1)
    rgb=(.54*rgb+.46*color)*tone
    # Restrained painted underside and a broad light plane, following each individual lock.
    rgb*= (1-.29*v**4+.047*np.maximum(np.cos(a+.75),0)*(1-v))[:,:,None]
    models.append((ob,rgba_image(rgb),len(models)))
def rgba_image(rgb):
    rgba=np.ones((*rgb.shape[:2],4),np.float32);rgba[:,:,:3]=rgb;return rgba
# Nape arches behind the ear. The hairline above the brow is supplied by the separate fringe.
build('Nuca',
'86,65 146,49 190,64 205,80 204,126 198,151 185,174 178,181 174,162 162,140 136,127 100,126 80,146 74,171 66,184 57,163 50,142 50,113 58,86',
'75,62 138,55 178,71 193,64 189,95 201,87 195,117 184,139 196,128 185,154 169,179 149,199 125,219 119,229 108,209 103,201 116,192 121,174 114,164 103,165 91,180 88,184 90,157 84,136 56,112',.18,navy)
build('Coroa • redemoinho',
'49,93 49,77 58,62 66,55 62,72 70,56 85,39 101,29 119,22 106,37 98,56 114,73 128,96 127,115 107,127 85,129 68,118 55,107',
'18,96 20,78 29,62 48,44 69,31 96,22 82,33 70,46 88,55 110,76 117,97 100,115 73,129 51,132 31,121',
.42,blue)
build('Coroa • ponta alta',
'60,92 65,66 79,48 99,35 126,25 158,21 183,16 179,32 169,48 152,62 138,78 125,101 101,118 78,119 65,108',
'24,94 34,69 55,48 85,34 112,26 145,23 174,17 171,34 158,50 145,63 131,82 112,102 84,119 56,122 36,114',
.62,blue,.16)
build('Mecha • varrida',
'53,94 60,75 78,63 105,56 141,54 173,49 198,41 196,59 187,75 168,87 148,96 124,110 96,122 75,122 61,114',
'18,99 27,81 49,68 70,59 108,54 144,54 168,50 188,41 186,61 174,76 149,89 128,103 102,115 72,128 42,126 24,115',
.55,blue,.20)
build('Mecha • têmpora',
'52,98 64,84 86,77 108,78 132,84 157,88 182,89 207,85 198,98 182,108 160,114 133,115 115,122 88,132 70,126 56,114',
'12,104 23,91 45,84 71,80 99,74 125,76 150,79 172,78 163,89 150,99 130,103 109,104 90,111 69,125 45,135 26,127 15,117',
.55,blue,.27)
build('Franja • sobre a testa',
'51,95 59,81 77,79 92,89 110,102 136,111 160,119 186,122 174,130 153,136 133,136 117,133 132,140 114,139 94,132 80,123 85,134 71,127 59,114',
'10,114 13,102 23,88 37,82 52,86 70,99 90,112 117,122 142,121 129,128 107,133 79,134 60,129 42,121 37,119 43,144 28,140 16,129',.45,blue,.64)
# Pack all six pieces on a single atlas with a two-texel gutter.
W,H=1024,512;atlas=np.ones((H,W,4),np.float32)
for ob,tile,i in models:
    x=2+(i%3)*260;y=2+(i//3)*132
    atlas[y-2:y+130,x-2:x+258]=np.pad(tile,((2,2),(2,2),(0,0)),mode='edge')
    for l in ob.data.uv_layers.active.data:
        u,v=l.uv;l.uv=((x+.5+u*255)/W,1-(y+.5+(1-v)*127)/H)
im=bpy.data.images.new('Kael • índigo',width=W,height=H,alpha=False);im.pixels.foreach_set(atlas[::-1].copy().ravel());im.pack()
mat=bpy.data.materials.new('Cabelo • índigo pintado');mat.use_nodes=True
n=mat.node_tree.nodes;t=n.new('ShaderNodeTexImage');t.image=im
bs=n.get('Principled BSDF');bs.inputs['Roughness'].default_value=1;bs.inputs['Specular IOR Level'].default_value=0
for key in ('Base Color','Emission Color'):mat.node_tree.links.new(t.outputs[0],bs.inputs[key])
bs.inputs['Emission Strength'].default_value=.60
for ob,_,_ in models:
    ob.data.materials.append(mat)
    bpy.context.view_layer.objects.active=ob
    dec=ob.modifiers.new('Simplificar superfícies internas','DECIMATE');dec.ratio=.53
    bpy.ops.object.modifier_move_to_index(modifier=dec.name,index=0)
    bpy.ops.object.modifier_apply(modifier=dec.name)
bpy.data.images.remove(image)
for tr in rig.animation_data.nla_tracks:tr.mute=False
s.frame_set(1);bpy.ops.object.select_all(action='DESELECT')
for o in s.objects:
    if o==rig or o.type=='MESH' and o.find_armature()==rig:o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(D/'Kael.glb'),use_selection=True,use_active_scene=True,export_animation_mode='NLA_TRACKS')
for tr in rig.animation_data.nla_tracks:tr.mute=tr.name!='Espera'
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(D/'Kael.blend'),compress=True)
for name,angle in [('Frente',0),('Tres-quartos',38),('Perfil',87),('Costas',169),('Outro lado',-55)]:
    c=s.camera;target=Vector((0,0,1.525));a=math.radians(angle);c.location=target+Vector((5*math.sin(a),-5*math.cos(a),.08));c.rotation_euler=(target-c.location).to_track_quat('-Z','Y').to_euler();c.data.ortho_scale=.51
    s.render.filepath=str(D/(name+'.png'));bpy.ops.render.render(write_still=True)

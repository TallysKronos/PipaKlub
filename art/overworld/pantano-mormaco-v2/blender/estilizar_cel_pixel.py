"""Derive a cel-shaded, discrete-pixel variant without changing the approved scene."""
from pathlib import Path
import bpy
import bmesh
import json
import numpy as np

OUT=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/"mormaco-referencia.blend"))
scene=bpy.context.scene
changed=[]
for mat in bpy.data.materials:
    if not mat.use_nodes: continue
    old=mat.node_tree.nodes.get("Principled BSDF")
    if old is None: continue
    base=tuple(mat.diffuse_color)[:3]
    nodes=mat.node_tree.nodes
    links=mat.node_tree.links
    nodes.clear()
    diffuse=nodes.new("ShaderNodeBsdfDiffuse")
    diffuse.name="Luz · difusa branca"
    diffuse.inputs["Color"].default_value=(1,1,1,1)
    diffuse.inputs["Roughness"].default_value=0
    rgb=nodes.new("ShaderNodeShaderToRGB")
    rgb.location=(180,0)
    ramp=nodes.new("ShaderNodeValToRGB")
    ramp.name="Cel shading · três faixas"
    ramp.location=(360,0)
    ramp.color_ramp.interpolation="CONSTANT"
    dark,mid=ramp.color_ramp.elements
    dark.position=.0
    dark.color=(*(base[i]*[.43,.54,.71][i] for i in range(3)),1)
    mid.position=.39
    mid.color=(*(base[i]*[.78,.85,.94][i] for i in range(3)),1)
    bright=ramp.color_ramp.elements.new(.83)
    bright.color=(*(min(1,base[i]*[1.15,1.12,1.03][i]) for i in range(3)),1)
    emission=nodes.new("ShaderNodeEmission")
    emission.location=(620,0)
    output=nodes.new("ShaderNodeOutputMaterial")
    output.location=(820,0)
    links.new(diffuse.outputs[0],rgb.inputs[0])
    links.new(rgb.outputs["Color"],ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"],emission.inputs["Color"])
    links.new(emission.outputs[0],output.inputs["Surface"])
    mat["Cel shading"]="Três faixas constantes; sombra fria, meio-tom e luz quente"
    changed.append(mat.name)

# Inverted closed hulls outline major silhouettes only, avoiding noisy leaf contours.
contours=bpy.data.collections.new("08 · Contornos de silhueta")
scene.collection.children.link(contours)
outline=bpy.data.materials.new("Contorno · azul petróleo")
outline.use_nodes=True
outline.use_backface_culling=True
nodes=outline.node_tree.nodes
nodes.clear()
emission=nodes.new("ShaderNodeEmission")
emission.inputs["Color"].default_value=(.012,.026,.047,1)
out=nodes.new("ShaderNodeOutputMaterial")
outline.node_tree.links.new(emission.outputs[0],out.inputs[0])
outlined=0
for obj in list(scene.objects):
    if obj.type!="MESH" or obj.hide_render: continue
    if not obj.name.startswith(("Escarpa ·","Contraforte","Pedra de composição","Tronco ·","Gabinete do mirante")): continue
    data=obj.data.copy()
    bm=bmesh.new()
    bm.from_mesh(data)
    if any(not edge.is_manifold for edge in bm.edges):
        bm.free()
        bpy.data.meshes.remove(data)
        continue
    bm.normal_update()
    for vertex in bm.verts: vertex.co+=vertex.normal*.023
    bmesh.ops.reverse_faces(bm,faces=list(bm.faces))
    bm.to_mesh(data)
    bm.free()
    data.materials.clear()
    data.materials.append(outline)
    for face in data.polygons: face.material_index=0
    hull=bpy.data.objects.new("Silhueta · "+obj.name,data)
    contours.objects.link(hull)
    hull.matrix_world=obj.matrix_world.copy()
    outlined+=1

sun=bpy.data.lights.get("Sol filtrado")
if sun:
    sun.angle=.025
scene.render.engine="BLENDER_EEVEE"
scene.eevee.taa_render_samples=1
scene.render.filter_size=.01
scene.render.resolution_x=836
scene.render.resolution_y=471
scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"
scene.render.image_settings.color_mode="RGBA"
scene.render.filepath=str(OUT/"mormaco-cel-pixel-nativo.png")
scene["Estilo"]="Cel shading + render discreto em pixels"
scene["Grade de pixels"]="836 × 471; apresentação com ampliação inteira 2× por nearest neighbour"
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"mormaco-cel-pixel.blend"))
bpy.ops.render.render(write_still=True)

# Preserve PNG code values while repeating every pixel exactly, with no interpolation.
source=bpy.data.images.load(str(OUT/"mormaco-cel-pixel-nativo.png"),check_existing=False)
source.colorspace_settings.name="Non-Color"
w,h=source.size[:]
values=np.empty(w*h*4,dtype=np.float32)
source.pixels.foreach_get(values)
enlarged=np.repeat(np.repeat(values.reshape(h,w,4),2,axis=0),2,axis=1)
preview=bpy.data.images.new("Prévia · ampliação inteira 2×",width=w*2,height=h*2,alpha=True)
preview.colorspace_settings.name="Non-Color"
preview.pixels.foreach_set(enlarged.ravel())
preview.filepath_raw=str(OUT/"mormaco-cel-pixel.png")
preview.file_format="PNG"
preview.save()
report={"native_resolution":[w,h],"preview_resolution":[w*2,h*2],"integer_scale":2,"resampling":"nearest; exact pixel repetition","cel_materials":len(changed),"outlined_objects":outlined,"original_scene_preserved":True,"game_integration":False}
(OUT/"validacao-cel-pixel.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
print(json.dumps(report))

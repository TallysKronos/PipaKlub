"""Export discrete-pixel layers and navigation from the same Blender geometry."""
from pathlib import Path
import bpy,json,math
import numpy as np
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/"godot/project.godot").exists())
OUT=ROOT/"godot/assets/overworld/kits/mormaco-cel-pixel-pilot"
OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(HERE/"mormaco-cel-pixel.blend"))
scene=bpy.context.scene
W,H=3344,1882
scene.render.resolution_x=W
scene.render.resolution_y=H
scene.render.resolution_percentage=100
scene.eevee.taa_render_samples=8
scene.render.filter_size=.01
scene.render.image_settings.file_format="PNG"
scene.render.image_settings.color_mode="RGBA"

def project(p):
    uv=world_to_camera_view(scene,scene.camera,Vector(p))
    return [round(uv.x*W,3),round((1-uv.y)*H,3)]

trees=[o for o in scene.objects if "game_foot" in o and o.type=="EMPTY"]
for obj in scene.objects:
    if obj.name.startswith("Silhueta · "):
        original=bpy.data.objects.get(obj.name[len("Silhueta · "):])
        if original and original.parent in trees:obj.parent=original.parent
tree_parts={o for t in trees for o in t.children_recursive}
fall_parts={o for o in scene.objects if o.type=="MESH" and o.name.startswith(("Cachoeira","Espuma da cachoeira","Arco de espuma"))}
cast_parts={o for o in scene.objects if o.name in ("Mormaço · referência","Capanga no mirante")}
prop_groups=[]
for i,(a,b) in enumerate([([586,774],[766,718]),([846,1078],[984,1150]),([1778,1444],[1962,1370])]):
    prop_groups.append({"name":"fence-%02d"%i,"parts":[],"foot":a if a[1]>b[1] else b,"segment":[a,b]})
def segment_distance(p,a,b):
    p,a,b=Vector(p),Vector(a),Vector(b)
    d=b-a
    return (p-(a+d*max(0,min(1,(p-a).dot(d)/d.length_squared)))).length
for obj in scene.objects:
    if obj.type!="MESH":continue
    if obj.name.startswith("Cerca ·"):
        points=[obj.matrix_world@Vector(p) for p in obj.bound_box]
        if max(p.z for p in points)>.7:continue
        center=sum(points,Vector())/8
        center.z=0
        foot=project(center)
        chosen=min((group for group in prop_groups if "segment" in group),key=lambda group:segment_distance(foot,*group["segment"]))
        chosen["parts"].append(obj)
    if "game_foot" in obj and abs(float(obj["game_foot"][2]))<.045 and float(obj["game_radius"])*104>=12:
        parts=[obj]
        hull=bpy.data.objects.get("Silhueta · "+obj.name)
        if hull:parts.append(hull)
        prop_groups.append({"name":"rock-%02d"%len(prop_groups),"parts":parts,"foot":project(obj["game_foot"])})
prop_parts={o for group in prop_groups for o in group["parts"]}
base_visibility={o:o.hide_render for o in scene.objects}
for obj in tree_parts|fall_parts|cast_parts|prop_parts:obj.hide_render=True
scene.render.film_transparent=False
scene.render.use_border=False
scene.render.filepath=str(OUT/"terrain.png")
bpy.ops.render.render(write_still=True)
print("EXPORT terrain.png",flush=True)

base_nav=json.loads(scene["runtime_navigation"])
nav={k:([[round(x*2,3),round(y*2,3)] for x,y in v] if k in ("ground","water","water_surface","targets") else [[[round(x*2,3),round(y*2,3)] for x,y in p] for p in v] if k=="raised" else [v[0]*2,v[1]*2] if k=="spawn" else v) for k,v in base_nav.items()}
manifest={"size":[W,H],"terrain":"terrain.png","trees":[],"props":[],"colliders":[],"navigation":nav,"pixel_scale":1,"kael_visible_height":70,"pilot":True}
all_meshes=[o for o in scene.objects if o.type=="MESH"]
for obj in all_meshes:obj.hide_render=True
scene.render.film_transparent=True

def layer(name,parts,foot):
    parts=[o for o in parts if o.type=="MESH" and not base_visibility.get(o,False)]
    if not parts:return None
    points=[world_to_camera_view(scene,scene.camera,o.matrix_world@Vector(p)) for o in parts for p in o.bound_box]
    left=max(0,math.floor(min(p.x for p in points)*W)-5)
    right=min(W,math.ceil(max(p.x for p in points)*W)+5)
    top=max(0,math.floor((1-max(p.y for p in points))*H)-5)
    bottom=min(H,math.ceil((1-min(p.y for p in points))*H)+5)
    if right<=left or bottom<=top:return None
    scene.render.use_border=True
    scene.render.use_crop_to_border=True
    scene.render.border_min_x=left/W
    scene.render.border_max_x=right/W
    scene.render.border_min_y=1-bottom/H
    scene.render.border_max_y=1-top/H
    for obj in parts:obj.hide_render=False
    scene.render.filepath=str(OUT/(name+".png"))
    bpy.ops.render.render(write_still=True)
    for obj in parts:obj.hide_render=True
    return {"file":name+".png","foot":foot,"origin":[left,top],"size":[right-left,bottom-top]}

for i,tree in enumerate(trees):
    foot=project(tree["game_foot"])
    item=layer("tree-%02d"%i,tree.children_recursive,foot)
    if item:
        item["elevation"]=float(tree["game_foot"][2])
        manifest["trees"].append(item)
        if abs(item["elevation"])<.03:manifest["colliders"].append({"at":foot,"radius":22,"kind":"tree"})
    print("EXPORT tree",i+1,"/",len(trees),flush=True)

for group in prop_groups:
    item=layer(group["name"],group["parts"],group["foot"])
    if item:manifest["props"].append(item)
    if "segment" in group:manifest["colliders"].append({"kind":"fence","segment":group["segment"]})
manifest["waterfall"]=layer("waterfall",fall_parts,[1812,650])
for obj in scene.objects:
    if obj.type!="MESH" or "game_foot" not in obj:continue
    p=list(obj["game_foot"])
    if abs(p[2])>.045:continue
    radius=float(obj["game_radius"])*104
    if radius>=12:manifest["colliders"].append({"at":project(p),"radius":round(radius,2),"kind":"rock"})

# Conservative mask: keep animation inside the water and away from the banks.
mw,mh=836,471
yy,xx=np.mgrid[0:mh,0:mw]
xx=(xx+.5)*W/mw
yy=(yy+.5)*H/mh
mask=np.zeros((mh,mw),dtype=bool)
poly=nav["water_surface"]
for a,b in zip(poly,poly[1:]+poly[:1]):
    mask^=((a[1]>yy)!=(b[1]>yy)) & (xx < (b[0]-a[0])*(yy-a[1])/(b[1]-a[1]+1e-9)+a[0])
for i in range(5):
    mask=mask & np.roll(mask,1,0) & np.roll(mask,-1,0) & np.roll(mask,1,1) & np.roll(mask,-1,1)
rgba=np.zeros((mh,mw,4),dtype=np.float32)
rgba[:,:,:3]=mask[:,:,None]
rgba[:,:,3]=1
image=bpy.data.images.new("Water animation mask",width=mw,height=mh,alpha=True)
image.colorspace_settings.name="Non-Color"
image.pixels.foreach_set(rgba[::-1].copy().ravel())
image.filepath_raw=str(OUT/"water-mask.png")
image.file_format="PNG"
image.save()
(OUT/"kit.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding="utf-8")
print("EXPORT COMPLETE",len(manifest["trees"]),"trees",len(manifest["colliders"]),"colliders",flush=True)

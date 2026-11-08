extends RefCounted
## Estruturas da floresta. Um contorno medido serve ao recorte e ao volume do poço.
const FALL=preload("res://scripts/overworld/cave_waterfall.gd")
const BASE="res://assets/overworld/kits/"
static func geometry() -> bool:return OS.get_environment("KRONASTA_GEOMETRIA")=="1"

static func harbor_deck_at(model,u:int,v:int)->bool:
 for dock:Dictionary in model.data.get("forest",{}).get("docks",[]):
  if Rect2i(dock.u,dock.v,dock.w,dock.h).has_point(Vector2i(u,v)):return true
 return false
static func iso(p:Vector2,h:float=0) -> Vector2:return Vector2((p.x-p.y)*32,(p.x+p.y)*16-h)
static func uv_points(values:Array) -> PackedVector2Array:
 var result:=PackedVector2Array()
 for p in values:result.append(Vector2(p[0],p[1]))
 return result
static func shapes(model) -> Array:
 var w:Dictionary=model.data.get("forest",{}).get("water",{}) if model.data.get("forest",{}).get("water")!=null else {}
 return [uv_points(w.contour),uv_points(w.channel)] if not w.is_empty() else []
static func is_water(model,p:Vector2) -> bool:
 if model.data.get("forest",{}).get("harbor",false):return model.cell_at(Vector2i(p.floor())).get("material","")=="agua"
 for shape:PackedVector2Array in shapes(model):
  if shape.is_empty():continue
  if Geometry2D.is_point_in_polygon(p,shape):return true
 return false
static func mine_cut_height(model,u:int,v:int) -> float:
 if not model.data.get("forest",{}).get("mine",false):return -999.0
 var c:Dictionary=model.cell_at(Vector2i(u,v))
 if c.get("material")!="rocha":return -999.0
 var height:float=-999.0
 for k in range(1,6):
  for p:Vector2i in [Vector2i(u-k,v-k),Vector2i(u-k,v),Vector2i(u,v-k)]:
   if model.walkable(p):height=maxf(height,model.height_at(Vector2(p)+Vector2(.5,.5))+14.0/64.0)
 return height
static func mine_cutaway(model,u:int,v:int) -> bool:return mine_cut_height(model,u,v)>-999.0
static func floor_cut(model,node:Node2D,poly:Polygon2D,corners:Array,u:int,v:int,coastal_tiles:Dictionary={}) -> void:
 var c:Dictionary=model.cell_at(Vector2i(u,v))
 if c.is_empty():c={"material":"grama","level":0}
 if model.data.get("forest",{}).get("mountain",false) and (u<0 or v<0 or u>=int(model.data.w) or v>=int(model.data.h)):
  c=model.cell_at(Vector2i(clampi(u,0,int(model.data.w)-1),clampi(v,0,int(model.data.h)-1)))
 if (model.data.get("forest",{}).get("mountain",false) or model.data.get("forest",{}).get("ice",false) or model.data.get("forest",{}).get("submerged",false)) and int(c.level)<0:poly.free();return
 if model.data.get("forest",{}).get("mine",false) and c.get("material")=="rocha":
  var near:=false
  for y in range(v-3,v+4):
   for x in range(u-3,u+4):
    if model.walkable(Vector2i(x,y)):near=true
  if not near:poly.free();return
 for stairs:Dictionary in model.data.get("forest",{}).get("stairs",[]):
  if u>=int(stairs.u) and u<int(stairs.u+stairs.width) and v>=int(stairs.v) and v<int(stairs.v+2):poly.free();return
 var fragments:Array=[PackedVector2Array(corners)]
 if c.get("material","")!="ponte":
  for shape:PackedVector2Array in shapes(model):
   if shape.is_empty():continue
   var next:Array=[]
   for f:PackedVector2Array in fragments:next.append_array(Geometry2D.clip_polygons(f,shape))
   fragments=next
 if fragments.is_empty():poly.free();return
 for index in fragments.size():
  var fragment:PackedVector2Array=fragments[index]
  var target:Polygon2D=poly if index==0 else poly.duplicate()
  var points:=PackedVector2Array()
  for p in fragment:
   var height:float=mine_cut_height(model,u,v)
   if height<=-999.0:height=model.surface_height(c,p-Vector2(u,v))
   points.append(iso(p,height*64)-node.position)
  target.polygon=points
  target.uv=fragment
  var shade:Color=poly.vertex_colors[0] if poly.vertex_colors.size()>0 else Color.WHITE
  target.vertex_colors=PackedColorArray()
  target.color=shade
  if bool(model.data.get("forest",{}).get("industrial",false)) and not geometry():
   target.uv=fragment
   target.color=shade
  if c.get("material","")=="piso" and model.data.get("forest",{}).get("gallery",false) and not geometry():
   target.material=null
   target.texture=load(BASE+"cavernas-v3/surfaces/rocha-cinza.png")
   target.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
   target.color=Color("#918ca7") if u in range(22,26) else Color("#6e6884")
   var stone_uv:=PackedVector2Array()
   for p in fragment:stone_uv.append(p*48.0)
   target.uv=stone_uv
  if c.get("material","")=="piso" and (geometry() or not str(model.data.id).begins_with("kronasta-mirante-")) and model.data.get("id")!="kronasta-estadio-a" and not model.data.get("forest",{}).get("chamber",false) and not model.data.get("forest",{}).get("ice",false) and not model.data.get("forest",{}).get("submerged",false):
   target.material=null
   target.texture=null if geometry() else load(BASE+"terrenos-v1/superficies/bloquete.png")
   target.color=Color("c5b88b") if geometry() else Color.WHITE
   target.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
   var paving_uv:=PackedVector2Array()
   for p in points:paving_uv.append((p+node.position)*2.8)
   target.uv=paving_uv
  if c.get("material","")=="ponte":
   target.material=null
   target.texture=null
   target.color=Color("a8b9b9") if model.data.get("forest",{}).get("industrial",false) else Color("b08a52")
  if model.data.get("forest",{}).get("harbor",false) and c.get("material","")=="agua":
   target.material=null;target.texture=null if geometry() else load(BASE+"aguas-v1/surfaces/rio-claro.png")
   target.vertex_colors=PackedColorArray();target.color=Color("2a7490") if geometry() else Color("5f9bac")
   target.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
   var water_uv:=PackedVector2Array()
   for p in points:water_uv.append((p+node.position)*.7)
   target.uv=water_uv
  if not coastal_tiles.is_empty():
   var tile:Texture2D=coastal_tiles.get(c.material,coastal_tiles.piso)
   var tile_uv:=PackedVector2Array()
   for p in fragment:
    var local:Vector2=p-Vector2(u,v)
    tile_uv.append(Vector2(.5+.36*(local.x-local.y),.13+.32*(local.x+local.y))*tile.get_size())
   target.material=null
   target.texture=tile
   target.color=Color.WHITE
   target.uv=tile_uv
   if not coastal_tiles.has("path_surface"):
    node.add_child(target)
    continue
   if c.material == "agua":
    var near_shore := false
    for side in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
     var adjacent: Dictionary = model.cell_at(Vector2i(u,v)+side)
     near_shore = near_shore or (not adjacent.is_empty() and adjacent.material != "agua")
    if not near_shore or (u*7+v*11)%5 != 0:
     target.texture=null
     target.color=Color("237c87").lightened(float((u*7+v*11)%5)*.008)
   elif c.material == "piso" and (u+v)%4 != 0:
    target.texture=null
    target.color=Color("e7bc82").lightened(float((u*7+v*11)%7)*.016)
   elif c.material == "terra" and (u+v)%3 != 0:
    target.texture=null
    target.color=Color("9ba44d").lightened(float((u*7+v*11)%7)*.014)
   if coastal_tiles.has("path_surface") and c.material in ["piso","terra"] and c.get("ramp")==null:
    target.material=coastal_tiles.terrace_surface if int(c.level)>1 else coastal_tiles.path_surface
    target.texture=null
    target.uv=fragment
  node.add_child(target)
  if not coastal_tiles.is_empty() and str(model.data.id).begins_with("kronasta-aracati-") and points.size()==4 and (not coastal_tiles.has("path_surface") or target.material!=coastal_tiles.path_surface and target.material!=coastal_tiles.terrace_surface):
   coastal_edges(model,node,points,Vector2i(u,v),c.material)
static func coastal_edges(model,node:Node2D,points:PackedVector2Array,cell:Vector2i,material:String) -> void:
 var directions := [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
 for i in 4:
  var adjacent:Dictionary=model.cell_at(cell+directions[i])
  var neighbor:=str(adjacent.get("material",""))
  var a:=points[i]
  var b:=points[(i+1)%4]
  var inward:=((points[(i+2)%4]+points[(i+3)%4])-a-b)*.5
  var variation:=float(posmod(cell.x*7+cell.y*11+i*3,7))/7.0
  if material=="agua" and neighbor in ["piso","terra"] and variation>.28:
   line(node,PackedVector2Array([a.lerp(b,.13)+inward*.22,a.lerp(b,.4)+inward*.15,a.lerp(b,.7)+inward*.23,a.lerp(b,.92)+inward*.19]),2,Color("8ecdd0"))
  elif material=="piso" and neighbor=="ponte":
   quad(node,PackedVector2Array([a,b,b+inward*.27,a+inward*.27]),Color("b18554"))
  elif material=="piso" and neighbor=="terra":
   var mid:=a.lerp(b,.3+variation*.4)
   quad(node,PackedVector2Array([a,b,b+inward*.10,mid+inward*(.27+variation*.15),a+inward*.1]),Color("c3ad66"))
   quad(node,PackedVector2Array([a,b,b+inward*.04,mid+inward*.16,a+inward*.04]),Color("9ba44d"))

static func line(parent:Node2D,points:PackedVector2Array,width:float,color:Color) -> void:
 var node:=Line2D.new();node.points=points;node.width=width;node.default_color=color;parent.add_child(node)
static func quad(parent:Node2D,points:PackedVector2Array,color:Color,texture:Texture2D=null) -> Polygon2D:
 var node:=Polygon2D.new();node.polygon=points;node.color=color;node.texture=texture;parent.add_child(node);return node
static func build(view) -> void:
 var model=view.model
 var f:Dictionary=model.data.get("forest",{})
 if f.is_empty():return
 var w:Dictionary=f.get("water",{}) if f.get("water")!=null else {}
 if not w.is_empty():
  var contours:=shapes(model)
  for index in contours.size():
   var contour:PackedVector2Array=contours[index]
   if contour.is_empty():continue
   if index==0 and not f.get("canal",false):
    contour.insert(1,Vector2(35,9))
    contour.insert(2,Vector2(36,9))
   var depth:float=float(w.depth if index==0 else w.channelDepth)
   var surface:=Node2D.new();surface.z_index=-2;view.actors.add_child(surface)
   var bottom:=PackedVector2Array()
   for p in contour:bottom.append(iso(p)+Vector2(0,depth))
   var swamp:bool=f.get("swamp",false)
   var water:=quad(surface,bottom,Color("2a7490") if geometry() else Color("20483b") if swamp else Color(.65,.87,.93),null if geometry() or swamp else load(BASE+"aguas-v1/surfaces/rio-claro.png"))
   if f.get("canal",false) and not geometry():
    var player:Variant=view.get("saved_player")
    if not player is Dictionary or not player.get("flags",{}).get("comportaVeredasAberta",false):water.modulate=Color(.58,.67,.36)
   if swamp and not geometry():
    var shader:=ShaderMaterial.new();shader.shader=preload("res://shaders/swamp_water.gdshader");water.material=shader
    if f.has("arena"):
     shader.set_shader_parameter("arena",true)
     shader.set_shader_parameter("arena_center",iso(Vector2(f.arena.center[0],f.arena.center[1]))+Vector2(0,depth))
     shader.set_shader_parameter("arena_radii",Vector2(32,16)*sqrt(2.0)*float(f.arena.radius))
   if not geometry():
    water.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
    var uv:=PackedVector2Array();for p in bottom:uv.append(p*.8)
    water.uv=uv
   for i in contour.size():
    var uv_a:Vector2=contour[i];var uv_b:Vector2=contour[(i+1)%contour.size()]
    if index==0 and uv_a==Vector2(35,9) and uv_b==Vector2(36,9):continue
    var bridge:Dictionary=w.get("bridge",{"u":23,"v":19,"w":3,"h":6})
    if index==1 and not w.get("noBridge",false) and maxf(uv_a.x,uv_b.x)>=float(bridge.u) and minf(uv_a.x,uv_b.x)<=float(bridge.u+bridge.w):
     # Split long banks at the actual deck; do not discard an entire channel side.
     if not f.get("industrial",false):continue
    var a:Vector2=iso(uv_a);var b:Vector2=iso(uv_b)
    var bank:=Node2D.new();bank.position=Vector2(0,maxf(a.y,b.y)+3);view.actors.add_child(bank)
    var pts:=PackedVector2Array([a-bank.position,b-bank.position,b+Vector2(0,depth)-bank.position,a+Vector2(0,depth)-bank.position])
    var aperture:=PackedVector2Array()
    for p in contour:aperture.append(iso(p)-bank.position)
    # The same upper aperture clips the bank faces. The near bank is occluded by
    # the uncut upper floor, so its translated bottom cannot leak outside the hole.
    for fragment:PackedVector2Array in Geometry2D.intersect_polygons(pts,aperture):
     var face:=quad(bank,fragment,Color("907049") if geometry() else Color(.65,.67,.58),null if geometry() else load(BASE+"terrenos-v1/superficies/terra-barranco.png"))
     if not geometry():
      face.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
      var face_uv:=PackedVector2Array()
      for p in fragment:face_uv.append((p+bank.position)*2)
      face.uv=face_uv
    line(bank,PackedVector2Array([a-bank.position,b-bank.position]),3,Color("a4aaa0") if f.get("industrial",false) else Color("84a54a"))
    if Geometry2D.is_point_in_polygon((a+b)*.5+Vector2(0,depth)-bank.position,aperture):line(bank,PackedVector2Array([a+Vector2(0,depth)-bank.position,b+Vector2(0,depth)-bank.position]),3,Color(.05,.12,.13,.6))
  if w.get("fall")!=null:
   var fall_root:=Node2D.new();fall_root.position=iso(Vector2(w.fall[0],w.fall[1]));view.actors.add_child(fall_root)
   var fall:=Node2D.new();fall.set_script(FALL);fall.width_cells=1;fall.drop_levels=1;fall.drop_pixels_override=float(w.lipHeight)+float(w.depth);fall.position=Vector2(0,-float(w.lipHeight));fall.preview_time=.4;fall_root.add_child(fall)
   if geometry():
    fall.hide();var plane:=Node2D.new();plane.position=fall_root.position;view.actors.add_child(plane)
    var lip:float=float(w.lipHeight);var water_height:float=float(w.depth)
    quad(plane,PackedVector2Array([Vector2(0,-lip),Vector2(32,16-lip),Vector2(32,16+water_height),Vector2(0,water_height)]),Color("8ed3e0"))
 # Bridge timbers laid in the same cell footprint, head posts only at the two banks.
 for v in int(model.data.h):
  for u in int(model.data.w):
   if f.get("swamp",false) and not geometry():continue
   if model.cell_at(Vector2i(u,v)).material!="ponte":continue
   var plank:=Node2D.new();plank.position=iso(Vector2(u,v))+Vector2(0,3);view.actors.add_child(plank)
   var deck_height:float=float(model.cell_at(Vector2i(u,v)).level)*64 if f.get("harbor",false) else 0.0
   for t in [0.0,.33,.66]:line(plank,PackedVector2Array([iso(Vector2(u,v+t),deck_height)-plank.position,iso(Vector2(u+1,v+t),deck_height)-plank.position]),1.4,Color("667b80") if f.get("industrial",false) else Color("735333"))
 if not w.is_empty() and not w.get("noBridge",false) and (not f.get("swamp",false) or geometry()):
  var bridge:Dictionary=w.get("bridge",{"u":23,"v":19,"w":3,"h":6})
  for at in [Vector2(bridge.u,bridge.v),Vector2(bridge.u+bridge.w,bridge.v),Vector2(bridge.u,bridge.v+bridge.h),Vector2(bridge.u+bridge.w,bridge.v+bridge.h)]:
   var post:=Node2D.new();post.position=iso(at)+Vector2(0,4);view.actors.add_child(post)
   line(post,PackedVector2Array([Vector2(0,-4),Vector2(0,-30)]),7,Color("687e83") if f.get("industrial",false) else Color("79542f"))
   line(post,PackedVector2Array([Vector2(-3,-30),Vector2(3,-30)]),3,Color("dbba78"))
 for guard:Dictionary in f.get("guards",[]):_guard(view,guard)
 if str(model.data.id).begins_with("kronasta-mirante-"):_mirante_guards(view)
 for stairs:Dictionary in f.get("stairs",[]):_stairs(view,stairs)
 if f.get("landmark")!=null and not f.get("bamboo",false):_landmark(view,f.landmark)
 if not geometry():
  for track:Array in f.get("footprints",[]):
   var point:=Vector2(track[0],track[1])
   var node:=Node2D.new();node.position=view.model.project(point,false)+Vector2(0,2);view.actors.add_child(node)
   var base:Vector2=view.model.project(point)-node.position
   # Flat impressions in the earth, three joined toes and a heel. These are
   # surface geometry, with the same height/depth as the measured ground.
   var shape:=PackedVector2Array([Vector2(-5,2),Vector2(-8,-1),Vector2(-5,-4),Vector2(-1,-1),Vector2(0,-5),Vector2(3,-4),Vector2(3,0),Vector2(7,-2),Vector2(8,1),Vector2(2,5),Vector2(-2,5)])
   for i in shape.size():shape[i]=shape[i]*Vector2(1,.6)+base
   quad(node,shape,Color("785734",.85))
  if not f.get("footprints",[]).is_empty():
   var strand:=Node2D.new();var point:=Vector2(23.7,34.5);strand.position=view.model.project(point,false)+Vector2(0,2);view.actors.add_child(strand)
   var base:Vector2=view.model.project(point)-strand.position
   line(strand,PackedVector2Array([base+Vector2(-14,0),base+Vector2(-6,-3),base+Vector2(2,0),base+Vector2(9,-4),base+Vector2(18,-2)]),1.4,Color("514c42"))
static func _mirante_guards(view) -> void:
 var model=view.model
 var part:=str(model.data.id).right(1)
 var front_row:=21 if part=="c" else 7
 var segments:Array=[Vector3i(19,front_row,22),Vector3i(27,front_row,30)]
 if part=="c":segments=[Vector3i(17,front_row,21),Vector3i(28,front_row,33)]
 for segment:Vector3i in segments:
  for u in range(segment.x,segment.z+1):
   var edge:=Vector2i(u,segment.y)
   var cell:Dictionary=model.cell_at(edge)
   var lower:Dictionary=model.cell_at(edge+Vector2i(0,1))
   if cell.is_empty() or lower.is_empty() or not model.walkable(edge):continue
   if cell.get("ramp")!=null or lower.get("ramp")!=null:continue
   if int(cell.level)>int(lower.level):_guard(view,{"u":u,"v":segment.y,"side":"v"})

static func _guard(view,g:Dictionary) -> void:
 var model=view.model
 var a:=Vector2(g.u+1,g.v) if g.side=="u" else Vector2(g.u,g.v+1)
 var b:=Vector2(g.u+1,g.v+1)
 var height:float=model.height_at(Vector2(g.u+.5,g.v+.5))*64
 var base_a:=iso(a,height);var base_b:=iso(b,height)
 var node:=Node2D.new();node.position=iso((a+b)*.5)+Vector2(0,3);view.actors.add_child(node)
 quad(node,PackedVector2Array([base_a-node.position,base_b-node.position,base_b-Vector2(0,20)-node.position,base_a-Vector2(0,20)-node.position]),Color("7e8272") if geometry() else Color("7a8176"))
 line(node,PackedVector2Array([base_a-Vector2(0,20)-node.position,base_b-Vector2(0,20)-node.position]),4,Color("d5c69d"))
 # End caps are explicit vertical strips, also close adjacent corner faces.
 for p in [base_a,base_b]:line(node,PackedVector2Array([p-node.position,p-Vector2(0,20)-node.position]),3,Color("716449"))
static func _stairs(view,s:Dictionary) -> void:
 var u:float=s.u;var v:float=s.v;var width:float=s.width
 var base:float=float(view.model.cell_at(Vector2i(int(u),int(v))).get("level",0))*64
 var chamber: bool = view.model.data.get("forest",{}).get("chamber",false)
 var district: String = str(view.model.data.id).get_slice("-",1)
 var closed: bool = view.model.data.get("forest",{}).get("closedStairs",false) or district in ["centro","lajes","porto","palafitas"]
 var tread := Color("#636077") if chamber else Color("d1c69e")
 var riser := Color("#38364c") if chamber else Color("807c67")
 for k in 8:
  var low:float=float(k)/8;var high:float=float(k+1)/8;var height:float=base+high*64
  var a:=Vector2(u,v+2-high*2);var b:=Vector2(u+width,v+2-high*2)
  var c:=Vector2(u+width,v+2-low*2);var d:=Vector2(u,v+2-low*2)
  var node:=Node2D.new();node.position=iso((a+c)*.5)+Vector2(0,4);view.actors.add_child(node)
  quad(node,PackedVector2Array([iso(a,height)-node.position,iso(b,height)-node.position,iso(c,height)-node.position,iso(d,height)-node.position]),tread)
  quad(node,PackedVector2Array([iso(d,height)-node.position,iso(c,height)-node.position,iso(c,height-8)-node.position,iso(d,height-8)-node.position]),riser)
  if closed:
   # The sloped collision surface cannot seal the triangular void under each tread.
   # Close the actual stepped prism, inside its measured footprint, per depth slice.
   for edge in [[a,d],[b,c]]:
    var first:Vector2=edge[0];var last:Vector2=edge[1]
    var side:=Node2D.new();side.position=iso((first+last)*.5)+Vector2(0,4);view.actors.add_child(side)
    quad(side,PackedVector2Array([iso(first,height)-side.position,iso(last,height)-side.position,iso(last,base)-side.position,iso(first,base)-side.position]),riser)
static func _landmark(view,p:Dictionary) -> void:
 var point:=Vector2(p.u,p.v);var pos:Vector2=view.model.project(point);var node:=Node2D.new();node.position=view.model.project(point,false);view.actors.add_child(node)
 node.z_index=1
 node.set_meta("scenery",true)
 var base:Vector2=pos-node.position
 line(node,PackedVector2Array([base,base-Vector2(0,205)]),12,Color("7a5231"))
 line(node,PackedVector2Array([base+Vector2(-64,-170),base+Vector2(64,-170)]),7,Color("a67b43"))
 for k in 5:
  var x:float=-54+k*26;var color:Color=[Color("edb849"),Color("dc7462"),Color("61afae"),Color("6b93b4"),Color("d6b978")][k]
  quad(node,PackedVector2Array([base+Vector2(x,-169),base+Vector2(x+14,-169),base+Vector2(x+30,-88-k%2*18),base+Vector2(x+16,-93-k%2*18)]),color)


extends Node2D
## A real recessed river: shared contour, two upper banks, lower animated surface.
@export_range(16.0,28.0) var depth_px := 24.0
@export var reduced_motion := false
@export var show_geometry := false
@export var show_props := true
const BASE := "res://assets/overworld/kits/lava-v1/"
@export var playable := true
var preview_time := -1.0
var elapsed := 0.0
var lava_material: ShaderMaterial
var ground_material: ShaderMaterial
var props: Node2D
var floor_piece_count := 0
var contour := PackedVector2Array()
var side_points := 25

static func iso(x: float,y: float) -> Vector2:
 return Vector2((x-y)*32.0,(x+y)*16.0)

func _ready() -> void:
 var left := PackedVector2Array()
 var right := PackedVector2Array()
 for i in range(side_points):
  # Extend the cutter a fraction beyond the room to avoid coincident Boolean edges.
  var v := -0.52+float(i)*12.04/float(side_points-1)
  var center := 7.7+sin(v*0.55)*1.15
  var width := 1.55+sin(v*1.2)*0.18
  left.append(iso(center-width,v))
  right.append(iso(center+width,v))
 contour.append_array(left)
 right.reverse()
 contour.append_array(right)
 var bottom := PackedVector2Array()
 for point in contour:bottom.append(point+Vector2(0,depth_px))
 lava_material = ShaderMaterial.new()
 lava_material.shader = load("res://shaders/overworld/lava_surface.gdshader")
 lava_material.set_shader_parameter("lava_texture",load(BASE+"surfaces/lava.png"))
 var liquid := polygon(bottom,null if show_geometry else lava_material,Color("E86D2A") if show_geometry else Color.WHITE)
 liquid.name = "LavaNaCotaInferior"
 for i in range(contour.size()):
  # The two cross-river edges are open map outlets, not retaining walls.
  if i == side_points-1 or i == contour.size()-1:continue
  var a := contour[i]
  var b := contour[(i+1)%contour.size()]
  var face := polygon(PackedVector2Array([a,b,b+Vector2(0,depth_px),a+Vector2(0,depth_px)]),null,Color("A76849") if show_geometry else Color(0.75,0.57,0.54))
  face.name = "FaceDaMargem"
  if not show_geometry:
   face.texture = load(BASE+"surfaces/basalto.png")
   face.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
   var distance_value := float(i)*48.0
   face.uv = PackedVector2Array([Vector2(distance_value,0),Vector2(distance_value+48,0),Vector2(distance_value+48,80),Vector2(distance_value,80)])
 ground_material = ShaderMaterial.new()
 ground_material.shader = load("res://shaders/overworld/lava_ground.gdshader")
 ground_material.set_shader_parameter("basalt_texture",load(BASE+"surfaces/basalto.png"))
 var room := PackedVector2Array([iso(-.5,-.5),iso(13.5,-.5),iso(13.5,11.5),iso(-.5,11.5)])
 var pieces := Geometry2D.clip_polygons(room,contour)
 floor_piece_count = pieces.size()
 if not show_geometry:
  for piece in pieces:
   for i in range(piece.size()):
    var a: Vector2 = piece[i]
    var b: Vector2 = piece[(i+1)%piece.size()]
    var mid := (a+b)*.5
    var gx := mid.x/64.+mid.y/32.
    var gy := mid.y/32.-mid.x/64.
    if absf(gx-13.5)<.015 or absf(gy-11.5)<.015:
     var blocks := maxi(1,roundi(a.distance_to(b)/30.))
     for j in blocks:
      var p := a.lerp(b,float(j)/blocks)
      var q := a.lerp(b,float(j+1)/blocks)
      var footp := p+Vector2(1,25+4*sin(p.x*.05))
      var footq := q+Vector2(1,25+4*sin(q.x*.05))
      var tone := Color("504150") if gx>13.4 else Color("423946")
      polygon(PackedVector2Array([p,q,footq,footp]),null,tone.darkened(.12*absf(sin(p.x))))
      polygon(PackedVector2Array([p,q,q+Vector2.DOWN*3,p+Vector2.DOWN*2]),null,Color("79636a"))
 for piece in pieces:
  var bank := polygon(piece,null if show_geometry else ground_material,Color("536875") if show_geometry else Color.WHITE)
  bank.name = "SoloSuperiorRecortado"
 for shore in [left,right]:
  var rim := Line2D.new()
  rim.points = shore
  rim.width = 2.5
  rim.default_color = Color("211F2F")
  add_child(rim)
 props = Node2D.new()
 props.name = "RochasPorProfundidade"
 props.y_sort_enabled = true
 props.visible = show_props and not show_geometry
 add_child(props)
 for at in [Vector2(2.8,2.2),Vector2(3.8,8.4),Vector2(12.1,5.4)]:
  var rock: Node2D = load("res://scenes/overworld/caves-v3/props/rocha-solta.tscn").instantiate()
  rock.position = iso(at.x,at.y)
  rock.scale = Vector2(0.85,0.85)
  var visual := rock.get_node("Visual") as Sprite2D
  visual.material = visual.material.duplicate()
  visual.material.set_shader_parameter("body_tint",Color(0.57,0.43,0.53))
  props.add_child(rock)
 _apply(0.0)
 if playable:
  var exploration := Node2D.new()
  exploration.set_script(load("res://scripts/overworld/lava_exploration.gd"))
  exploration.name = "Exploracao"
  add_child(exploration)

func polygon(points: PackedVector2Array,material_value: Material,color_value: Color) -> Polygon2D:
 var node := Polygon2D.new()
 node.polygon = points
 node.material = material_value
 node.color = color_value
 add_child(node)
 return node

func _process(delta: float) -> void:
 elapsed += delta
 _apply(elapsed if preview_time < 0.0 else preview_time)

func _apply(value: float) -> void:
 if lava_material:lava_material.set_shader_parameter("animation_time",0.0 if reduced_motion else fposmod(value,8.0))

func set_animation_time(value: float) -> void:
 preview_time = value
 _apply(elapsed if value < 0.0 else value)

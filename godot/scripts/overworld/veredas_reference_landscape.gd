extends Node2D
## Approved 2D painted scenery, authored support/occlusion and legacy save adapter.
const ROOT := "res://assets/overworld/kits/veredas-reference-v4/"
const Warp = preload("res://scripts/overworld/legacy_map_warp.gd")
var warp := Warp.new()
var layout: Dictionary
var prop_nodes: Array[Node2D]=[]
var geometry_only := false
var show_props := true
var water_material: ShaderMaterial

func project(p: Vector2) -> Vector2:return warp.transform(p)
func unproject(p: Vector2) -> Vector2:return warp.transform(p,true)
func depth(p: Vector2) -> int:return clampi(roundi(project(p).y),-4000,4000)

func build(_id: String,_source: Dictionary) -> void:
	layout=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"layout.json"))
	warp.setup(layout.anchors)
	var backdrop := CanvasLayer.new();backdrop.layer=-100
	var color := ColorRect.new();color.color=Color("152630")
	color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);color.mouse_filter=Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(color);add_child(backdrop)
	var plate := Sprite2D.new();plate.name="ApprovedPaintedTerrain"
	plate.texture=load(ROOT+"mapa.png");plate.centered=false;plate.z_index=-4090
	plate.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;add_child(plate)
	var water := Polygon2D.new();water.name="CreekAnimation"
	water.polygon=polygon(layout.water);water.uv=water.polygon
	water.texture=plate.texture;water.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;water.z_index=-4080
	water_material=ShaderMaterial.new();water_material.shader=load("res://shaders/overworld/painted_creek.gdshader")
	var preferences=preload("res://scripts/campaign/preferences.gd").new();preferences.load_settings()
	water_material.set_shader_parameter("motion",0.0 if preferences.reduced_motion else 1.0)
	water.material=water_material;add_child(water)
	for mask: Dictionary in layout.foreground:
		var node := Polygon2D.new();node.name=mask.name
		node.polygon=polygon(mask.points);node.uv=node.polygon
		node.texture=plate.texture;node.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		node.z_index=int(mask.baseline);add_child(node);prop_nodes.append(node)

func legacy_layout(original: Dictionary) -> Dictionary:
	var data := original.duplicate(true)
	data.floors=[];data.obstacles=[];data.separated_trees=[];data.foreground=[]
	for floor_data: Dictionary in layout.floors:
		for p in warp.legacy_polygons(polygon(floor_data.points)):
			data.floors.append({"name":floor_data.name,"points":as_array(p),"height":floor_data.height})
	for obstacle: Dictionary in layout.obstacles:
		var p: PackedVector2Array
		if obstacle.has("points"):p=polygon(obstacle.points)
		else:
			p=PackedVector2Array()
			for i in 24:p.append(Vector2(obstacle.center[0],obstacle.center[1])+Vector2(cos(TAU*i/24)*obstacle.radius[0],sin(TAU*i/24)*obstacle.radius[1]))
		for piece in warp.legacy_polygons(p):data.obstacles.append({"name":obstacle.name,"points":as_array(piece)})
	return data

func polygon(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in points:result.append(Vector2(p[0],p[1]))
	return result

func as_array(points: PackedVector2Array) -> Array:
	var result := []
	for p in points:result.append([p.x,p.y])
	return result

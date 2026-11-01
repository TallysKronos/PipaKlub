extends Node2D
## One ground root, one directional saddle socket, independent reusable rider.
var definition:Dictionary={}
var facing:="se"
var body:Sprite2D
var seat:Marker2D
var rider:Sprite2D
var far_leg:Sprite2D
var foreground:Sprite2D
@export_file("*.json") var definition_path:="res://assets/mounts/doberman-c-v1/mount.json"

func _ready() -> void:
	definition=JSON.parse_string(FileAccess.get_file_as_string(definition_path))
	use_parent_material=true
	body=Sprite2D.new();body.name="MountBody";body.region_enabled=true;body.centered=false;add_child(body)
	body.texture=load(definition.texture)
	body.use_parent_material=true
	seat=Marker2D.new();seat.name="RiderSocket";add_child(seat)
	rider=Sprite2D.new();rider.name="Rider";rider.region_enabled=true;rider.centered=false;seat.add_child(rider)
	rider.texture=load(definition.riderTexture)
	seat.use_parent_material=true;rider.use_parent_material=true
	far_leg=rider.duplicate();far_leg.name="FarLeg";seat.add_child(far_leg)
	for layer in [rider,far_leg]:
		layer.use_parent_material=false
		var shader_material:=ShaderMaterial.new()
		shader_material.shader=load("res://shaders/rider_layer.gdshader")
		shader_material.set_shader_parameter("far_layer",layer==far_leg)
		layer.material=shader_material
	foreground=Sprite2D.new();foreground.name="NeckForeground";foreground.centered=false;foreground.region_enabled=true
	foreground.texture=body.texture;foreground.use_parent_material=true;add_child(foreground);foreground.z_index=2
	set_facing(facing)

func set_facing(value:String) -> void:
	facing=value
	if not is_instance_valid(body):return
	var frame:Dictionary=definition.directions.get(value,definition.directions.se)
	body.region_rect=Rect2(frame.rect[0],frame.rect[1],frame.rect[2],frame.rect[3])
	body.scale=Vector2.ONE*definition.scale
	body.position=-Vector2(frame.ground[0],frame.ground[1])*definition.scale
	seat.position=(Vector2(frame.seat[0],frame.seat[1])-Vector2(frame.ground[0],frame.ground[1]))*definition.scale
	rider.region_rect=Rect2(frame.riderRect[0],frame.riderRect[1],frame.riderRect[2],frame.riderRect[3])
	rider.scale=Vector2.ONE*definition.riderScale
	rider.position=-Vector2(frame.hip[0],frame.hip[1])*definition.riderScale
	seat.z_index=0;rider.z_index=1;far_leg.z_index=-1
	far_leg.region_rect=rider.region_rect;far_leg.scale=rider.scale;far_leg.position=rider.position
	for layer in [rider,far_leg]:
		layer.material.set_shader_parameter("region_origin",rider.region_rect.position)
		layer.material.set_shader_parameter("atlas_size",rider.texture.get_size())
		var polygon:=PackedVector2Array()
		for point in frame.get("farLeg",[]):polygon.append(Vector2(point[0],point[1]))
		layer.material.set_shader_parameter("leg_count",polygon.size())
		while polygon.size()<12:polygon.append(Vector2.ZERO)
		layer.material.set_shader_parameter("leg_polygon",polygon)
		var parent_material:ShaderMaterial=get_parent().material as ShaderMaterial
		var has_depth:bool=parent_material!=null and parent_material.get_shader_parameter("depth_map")!=null
		layer.material.set_shader_parameter("depth_enabled",has_depth)
		if has_depth:
			for key in ["depth_map","roofless_depth_map","depth_bounds","ray_constant","reveal_under_deck","roof_cutaway"]:
				layer.material.set_shader_parameter(key,parent_material.get_shader_parameter(key))
	foreground.visible=frame.has("neck")
	if foreground.visible:
		var clip:Array=frame.neck
		foreground.region_rect=Rect2(body.region_rect.position+Vector2(clip[0],clip[1]),Vector2(clip[2],clip[3]))
		foreground.position=body.position+Vector2(clip[0],clip[1])*definition.scale
		foreground.scale=body.scale

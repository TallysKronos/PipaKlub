extends Node2D
## One ground root, one directional saddle socket, independent reusable rider.
var definition:Dictionary={}
var facing:="se"
var body:Sprite2D
var seat:Marker2D
var rider:Sprite2D
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
	# Rear views see the rider in front of the rump; front view neck hides far legs.
	seat.z_index=-1 if value=="s" else 1

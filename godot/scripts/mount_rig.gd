extends Node2D
const LiveSprites=preload("res://scripts/pixelgen_sprites.gd")
## One ground root, one directional saddle socket, independent reusable rider.
var definition:Dictionary={}
var facing:="se"
var body:Sprite2D
var seat:Marker2D
var rider:Sprite2D
var far_leg:Sprite2D
var foreground:Sprite2D
var animated:Sprite2D
var animations:Dictionary={}
var animation_textures:Dictionary={}
var animation_key:=""
var animation_clock:=0.0
var layout_revision:=""
var layout_poll:=0.0
@export_file("*.json") var definition_path:="res://assets/mounts/doberman-c-v1/mount.json"

func _ready() -> void:
	definition=JSON.parse_string(FileAccess.get_file_as_string(definition_path))
	layout_revision=FileAccess.get_file_as_string(definition_path).sha256_text()
	use_parent_material=true
	body=Sprite2D.new();body.name="MountBody";body.region_enabled=true;body.centered=false;add_child(body)
	body.texture=LiveSprites.load_texture(definition.texture)
	body.use_parent_material=true
	seat=Marker2D.new();seat.name="RiderSocket";add_child(seat)
	rider=Sprite2D.new();rider.name="Rider";rider.region_enabled=true;rider.centered=false;seat.add_child(rider)
	rider.texture=LiveSprites.load_texture(definition.riderTexture)
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
	animated=Sprite2D.new();animated.name="MountedAnimation";animated.centered=false;animated.region_enabled=true;animated.use_parent_material=true;animated.z_index=1;add_child(animated)
	var manifest_path: String = definition.get("animationManifest", "res://assets/mounts/doberman-animated-v1/animations.json")
	var manifest=JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if manifest is Dictionary:animations=manifest.get("animations",{})
	set_facing(facing)

func _process(delta:float) -> void:
	if not is_visible_in_tree():return
	animation_clock+=delta
	_update_animation()
	if not OS.has_feature("editor") or not is_visible_in_tree():return
	layout_poll+=delta
	if layout_poll<1:return
	layout_poll=0
	var text:=FileAccess.get_file_as_string(definition_path)
	if text.sha256_text()==layout_revision:return
	var next=JSON.parse_string(text)
	if not next is Dictionary or not next.has("directions"):return
	definition=next;layout_revision=text.sha256_text();set_facing(facing)

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
	# Rotate only the distant limb around the shared hip, never around the sheet.
	far_leg.rotation=deg_to_rad(float(frame.get("farLegAngle",0)))
	far_leg.position=rider.position.rotated(far_leg.rotation)
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
	_update_animation()

func _update_animation() -> void:
	if not is_instance_valid(animated):return
	var actor=get_parent()
	# Any parent works: a still preview (no avatar fields) shows the static pose.
	var moving:bool=bool(actor.get("moving")) if actor!=null and actor.get("moving")!=null else false
	var running:bool=bool(actor.get("running")) if actor!=null and actor.get("running")!=null else false
	var key:String=("run-" if running else "walk-")+facing if moving else ""
	if key!=animation_key:animation_key=key;animation_clock=0
	animated.visible=animations.has(key)
	body.visible=not animated.visible;rider.visible=not animated.visible;far_leg.visible=not animated.visible
	foreground.visible=not animated.visible and definition.directions.get(facing,{}).has("neck")
	if not animated.visible:return
	var clip:Dictionary=animations[key]
	if not animation_textures.has(key):animation_textures[key]=LiveSprites.load_texture(clip.texture)
	animated.texture=animation_textures[key]
	var index:=int(animation_clock*1000/float(clip.durationMs))%int(clip.frames)
	animated.region_rect=Rect2((index%int(clip.columns))*int(clip.cell[0]),(index/int(clip.columns))*int(clip.cell[1]),clip.cell[0],clip.cell[1])
	animated.scale=Vector2.ONE*float(clip.scale)
	animated.position=-Vector2(clip.pivot[0],clip.pivot[1])*float(clip.scale)

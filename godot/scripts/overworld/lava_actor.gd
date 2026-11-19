extends Node2D
## A depth-sorted, foot-anchored view of an animated 3D character on the isometric floor.
var model: Node3D
var player: AnimationPlayer
var heading_offset := 0.0
var heading := 0.0

func setup(asset: PackedScene, height: float, pixels_per_unit: float, canvas_size: Vector2i, footprint: Vector2, forward_offset: float) -> void:
	heading_offset = forward_offset
	var shadow := Polygon2D.new()
	for i in 24:
		var angle := TAU * i / 24
		shadow.polygon = shadow.polygon + PackedVector2Array([Vector2(cos(angle), sin(angle)) * footprint])
	shadow.color = Color(0.07, 0.04, 0.08, 0.45)
	add_child(shadow)
	var view := SubViewport.new()
	view.size = canvas_size * 2
	view.msaa_3d = Viewport.MSAA_2X
	view.transparent_bg = true
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("ffecdf")
	world.environment.ambient_light_energy = 0.54
	view.add_child(world)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45,-30,0)
	key.light_energy = 0.48
	view.add_child(key)
	model = asset.instantiate()
	view.add_child(model)
	player = model.find_children("*","AnimationPlayer",true,false)[0]
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = canvas_size.y / pixels_per_unit
	view.add_child(cam)
	var target := Vector3.UP * height
	var pitch := deg_to_rad(30)
	cam.position = target + Vector3(0,sin(pitch),cos(pitch)) * 18
	cam.look_at(target)
	var sprite := Sprite2D.new()
	sprite.texture = view.get_texture()
	sprite.position.y = -height * cos(pitch) * pixels_per_unit
	sprite.scale = Vector2.ONE * 0.5
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)

func play(clip: StringName, repeat: bool = true) -> void:
	if player.current_animation == clip:
		return
	player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR if repeat else Animation.LOOP_NONE
	player.play(clip,0.16)

func face(direction: Vector2, delta: float) -> void:
	if direction.length_squared() > 0.001:
		heading = atan2(direction.x, direction.y * 2.0) + heading_offset
	model.rotation.y = lerp_angle(model.rotation.y, heading, 1.0-exp(-14.0*delta))

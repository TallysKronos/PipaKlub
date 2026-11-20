extends Node
## Mergulho no Abismo de Kronasta (cenas "abismo-*"): o Kael nada montado na montaria
## aquática (a Capiboia, mount_passives.gd) e o mapa ganha a camada de fundo do mar.
const SWIM := "res://assets/campaign/marisol-row-v1/capivara-d-swim.png"
const LIFT := 26.0
var view: Node2D
var ride: Sprite2D
var depth_layer: ColorRect
var frames: Array = []
var clock := 0.0

static func applies(scene: String) -> bool:
	return scene.begins_with("abismo-")

func _ready() -> void:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/marisol-row-v1/swim.json"))
	frames = meta.frames
	ride = Sprite2D.new()
	ride.name = "BoiaRide"
	ride.texture = load(SWIM)
	ride.region_enabled = true
	ride.centered = true
	ride.scale = Vector2.ONE * .2
	view.player_root.add_child(ride)
	view.player_root.move_child(ride, 0)
	depth_layer = ColorRect.new()
	depth_layer.name = "AbismoDepth"
	depth_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	depth_layer.z_index = 3000
	depth_layer.z_as_relative = false
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/overworld/abismo_depth.gdshader")
	material.set_shader_parameter("depth", float(view.model.data.get("forest", {}).get("depth", 0)))
	material.set_shader_parameter("still", 1.0 if view.get("reduced_motion") == true or OS.get_environment("SUBMERSO_CAPTURE") == "1" else 0.0)
	depth_layer.material = material
	view.camera.add_child(depth_layer)
	_update(0.0)

func _process(delta: float) -> void:
	clock += delta
	_update(delta)

func _update(_delta: float) -> void:
	if not is_instance_valid(view) or not is_instance_valid(view.avatar): return
	# Kael sobe no dorso da Boia; a Boia nada no lugar dos pés dele.
	var frame: Dictionary = frames[int(clock * 6.0) % frames.size()]
	ride.region_rect = Rect2(frame.x, frame.y, frame.w, frame.h)
	var facing: String = str(view.avatar.get("facing"))
	ride.flip_h = facing in ["w", "nw", "sw", "n"]
	# O pivô do quadro é o meio da base (pés da Boia); centralizado, só desce meio quadro.
	ride.offset = Vector2(0, float(frame.h) * .5 - float(frame.pivot[1]))
	ride.position = view.avatar.position + Vector2(0, LIFT + 4.0)
	var size: Vector2 = view.get_viewport_rect().size / view.camera.zoom
	depth_layer.size = size
	depth_layer.position = -size * .5

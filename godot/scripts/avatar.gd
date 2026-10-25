extends Node2D
## Avatar composed from the existing, anchored paper-doll frames.
var manifest: Dictionary
var textures: Dictionary = {}
var facing: String = "se"
var moving: bool = false
var clock: float = 0.0

func _ready() -> void:
	manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/kael/manifest.json"))
	for action in ["parado", "andar"]:
		for direction in ["se", "ne"]:
			for frame in manifest.actions[action].directions[direction]:
				_cache(frame.image)
	for layer in manifest.layers.values():
		for path in layer.images.values():
			_cache(path)
	scale = Vector2(0.85, 0.85)

func _cache(path: String) -> void:
	if not textures.has(path):
		textures[path] = load("res://assets/kael/" + path)

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	if manifest.is_empty():
		return
	var action: String = "andar" if moving else "parado"
	var direction: String = "ne" if facing in ["ne", "nw"] else "se"
	var frames: Array = manifest.actions[action].directions[direction]
	var index: int = int(clock * (10.0 if moving else 5.5)) % frames.size()
	var frame: Dictionary = frames[index]
	var mirror: bool = facing in ["sw", "nw"]
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1 if mirror else 1, 1))
	var pivot := Vector2(64,112)
	_draw_layer("mochila-pipa", frame, direction, pivot)
	draw_texture(textures[frame.image], -pivot)
	_draw_layer("alcas-mochila", frame, direction, pivot)
	_draw_layer("cabelo-kael", frame, direction, pivot)

func _draw_layer(id: String, frame: Dictionary, direction: String, pivot: Vector2) -> void:
	var layer: Dictionary = manifest.layers[id]
	var anchor: Array = layer.anchor[direction]
	var mount: Array = frame.head if layer.kind == "head" else frame.torso
	draw_texture(textures[layer.images[direction]], Vector2(mount[0]-anchor[0],mount[1]-anchor[1])-pivot)

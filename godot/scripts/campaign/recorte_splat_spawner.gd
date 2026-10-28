extends Control
## Event-only presentation. No physics, game RNG, saves or input capture.
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Ink = preload("res://scripts/campaign/recorte_ink.gd")
const Sequence = preload("res://scripts/campaign/recorte_splat_sequence.gd")
@export var event_seed := 64
var reduced_motion := false
var _sequence: RefCounted
var _bursts: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	add_to_group("recorte_motion")
	_sequence = Sequence.new(event_seed)

func spawn(point: Vector2, token: String = "ceu", family: String = "medium") -> Sprite2D:
	if _sequence == null: _sequence = Sequence.new(event_seed)
	_bursts = _bursts.filter(func(entry: Dictionary): return is_instance_valid(entry.sprite))
	if _bursts.size() >= 12:
		var oldest: Dictionary = _bursts.pop_front()
		oldest.tween.kill()
		oldest.sprite.hide()
		oldest.sprite.queue_free()
	var choice: Dictionary = _sequence.next(family)
	if choice.is_empty(): return null
	var sprite := Sprite2D.new()
	sprite.texture = Ink.texture(choice.id)
	sprite.position = point
	sprite.modulate = Tokens.COLORS.get(token,Tokens.CEU)
	sprite.flip_h = choice.flip_h
	sprite.flip_v = choice.flip_v
	sprite.rotation = 0 if reduced_motion else choice.rotation
	sprite.set_meta("source_id",choice.source_id)
	add_child(sprite)
	var tween := create_tween()
	if reduced_motion:
		sprite.modulate.a = 0
		tween.tween_property(sprite,"modulate:a",1.0,.08)
		tween.tween_interval(.44)
		tween.tween_property(sprite,"modulate:a",0.0,.08)
	else:
		tween.tween_interval(.44)
		tween.tween_property(sprite,"modulate:a",0.0,.16)
	tween.tween_callback(sprite.queue_free)
	_bursts.append({"sprite":sprite,"tween":tween})
	return sprite

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if not value: return
	for entry in _bursts:
		if not is_instance_valid(entry.sprite): continue
		entry.tween.kill()
		entry.sprite.rotation = 0
		entry.tween = create_tween()
		entry.tween.tween_property(entry.sprite,"modulate:a",0.0,.08)
		entry.tween.tween_callback(entry.sprite.queue_free)

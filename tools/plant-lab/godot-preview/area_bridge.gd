extends Node2D
## Mount the generated top-down area without modifying campaign save ownership.
signal interaction_requested(event: Dictionary)
var generated: Node2D
func _ready() -> void:
	generated=load("res://main.tscn").instantiate()
	add_child(generated)
	generated.load_layout("res://layout.json")
	generated.runtime_only=true
	generated.testing=true
	for child: Node in generated.get_children():
		if child is CanvasLayer:
			child.visible=false
	generated.interaction_requested.connect(func(event: Dictionary): interaction_requested.emit(event))
func get_player_position() -> Vector2:
	return generated.player.position
func set_player_position(point: Vector2) -> void:
	generated.player.position=point
func get_area_events() -> Array:
	return generated.layout.get("events",[])

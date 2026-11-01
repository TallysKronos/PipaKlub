extends Node
signal received(event: InputEvent)
func _input(event: InputEvent) -> void:
	received.emit(event)

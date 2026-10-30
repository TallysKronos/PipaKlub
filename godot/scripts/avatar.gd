extends "res://scripts/kael_video_avatar.gd"
## Shared campaign/prototype entry point. Coordinates and foot anchors stay with each scene.
func _ready() -> void:
	super()
	scale=Vector2.ONE*.85*BODY_SCALE

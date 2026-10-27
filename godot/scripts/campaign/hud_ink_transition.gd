extends "res://scripts/campaign/recorte_ink_wipe.gd"
## Campaign adapter: owns only its temporary CanvasLayer, never the next scene.
func _ready() -> void:
	super._ready()
	finished.connect(get_parent().queue_free,CONNECT_ONE_SHOT)
	play(Tokens.TINTA,reduced_motion,false)

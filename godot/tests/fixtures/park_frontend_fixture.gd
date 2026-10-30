extends "res://scripts/campaign/front_end.gd"
## Test-only bootstrap. The caller installs an isolated Store before adding this node.
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(session)
	add_child(sound)
	AudioServer.set_bus_mute(0,true)
	Controls.install()
	content=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	journey=Journey.new(session)
	exploration=Exploration.new(session)
	encounters=Encounters.new(session)
	morro=Morro.new(session)
	Hud.Recorte.install(self,true)
	preferences.reduced_motion=true

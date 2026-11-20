extends Control
## Decorative broadcast framing. Dialogue retains focus and all input.
const Hud=preload("res://scripts/campaign/hud.gd")
var reduced_motion := false

func _ready() -> void:
	name="ChampionshipBroadcast"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var crt := ColorRect.new()
	crt.mouse_filter=Control.MOUSE_FILTER_IGNORE
	crt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var screen := ShaderMaterial.new()
	screen.shader=preload("res://shaders/campaign_crt.gdshader")
	crt.material=screen
	add_child(crt)
	var station := PanelContainer.new()
	station.add_theme_stylebox_override("panel",Hud.panel("dark"))
	station.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	station.position=Vector2(36,30)
	station.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(station)
	var label := Label.new()
	label.text="PIPA TV    ● AO VIVO"
	label.add_theme_font_override("font",Hud.display())
	label.add_theme_font_size_override("font_size",26)
	label.add_theme_color_override("font_color",Hud.PAPER)
	station.add_child(label)
	var lower := PanelContainer.new()
	lower.add_theme_stylebox_override("panel",Hud.panel("dark"))
	lower.anchor_left=.36
	lower.anchor_right=.95
	lower.anchor_top=.04
	lower.anchor_bottom=.18
	lower.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(lower)
	var lines := VBoxContainer.new()
	lines.mouse_filter=Control.MOUSE_FILTER_IGNORE
	lower.add_child(lines)
	var headline := Label.new()
	headline.text="KAEL · CAMPEÃO DE KRONASTA"
	headline.add_theme_font_override("font",Hud.display())
	headline.add_theme_font_size_override("font_size",30)
	headline.add_theme_color_override("font_color",Hud.GOLD)
	headline.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	lines.add_child(headline)
	var subtitle := Label.new()
	subtitle.text="Final da Liga · Estádio de Kronasta"
	subtitle.add_theme_font_size_override("font_size",20)
	lines.add_child(subtitle)
	if not reduced_motion:
		modulate.a=0.0
		create_tween().tween_property(self,"modulate:a",1.0,.4)

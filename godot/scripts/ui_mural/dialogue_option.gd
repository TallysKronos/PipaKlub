extends Button
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
const T=preload("res://scripts/campaign/ui_tokens.gd")
var text_scale:=1.0
var backing:Control
func _ready() -> void:
	for state in ["normal","hover","pressed","disabled","focus"]:
		var empty:=StyleBoxEmpty.new()
		empty.content_margin_left=32;empty.content_margin_right=32;empty.content_margin_top=29;empty.content_margin_bottom=29
		add_theme_stylebox_override(state,empty)
	for key in ["font_color","font_focus_color","font_hover_color","font_pressed_color"]:add_theme_color_override(key,T.MURAL_INK)
	add_theme_font_override("font",T.label());add_theme_font_size_override("font_size",roundi(22*text_scale))
	autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	backing=Control.new();backing.show_behind_parent=true;backing.mouse_filter=MOUSE_FILTER_IGNORE;add_child(backing)
	backing.draw.connect(func():Paper.frame(backing,Rect2(Vector2.ZERO,size),"MuralSunPanel" if has_focus() else "MuralPaperPanel",.35))
	for event in [focus_entered,focus_exited,mouse_entered,mouse_exited,resized]:event.connect(backing.queue_redraw)

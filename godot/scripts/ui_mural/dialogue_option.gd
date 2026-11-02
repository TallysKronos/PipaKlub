extends Button
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
const T=preload("res://scripts/campaign/ui_tokens.gd")
var text_scale:=1.0
var selected:=false
var density:=.35
var font_base:=22
var backing:Control
func _ready() -> void:
	for state in ["normal","hover","pressed","disabled","focus"]:
		var empty:=StyleBoxEmpty.new()
		var padding:=Paper.inset(density)
		empty.content_margin_left=padding+3;empty.content_margin_right=padding+3;empty.content_margin_top=padding;empty.content_margin_bottom=padding
		add_theme_stylebox_override(state,empty)
	for key in ["font_color","font_focus_color","font_hover_color","font_pressed_color"]:add_theme_color_override(key,T.MURAL_INK)
	add_theme_font_override("font",T.label());add_theme_font_size_override("font_size",roundi(font_base*text_scale))
	autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	backing=Control.new();backing.show_behind_parent=true;backing.mouse_filter=MOUSE_FILTER_IGNORE;add_child(backing)
	backing.draw.connect(_paint)
	for event in [focus_entered,focus_exited,mouse_entered,mouse_exited,resized]:event.connect(backing.queue_redraw)
func _paint() -> void:Paper.frame(backing,Rect2(Vector2.ZERO,size),"MuralSunPanel" if has_focus() or selected else "MuralPaperPanel",density)

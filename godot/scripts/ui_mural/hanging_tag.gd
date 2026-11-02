extends "res://scripts/ui_mural/dialogue_option.gd"
const Art=preload("res://scripts/ui_mural/menu_art.gd")
func _ready() -> void:
	font_base=20;super._ready()
	for state in ["normal","hover","pressed","disabled","focus"]:
		var empty:=StyleBoxEmpty.new()
		for index in 4:empty.set_content_margin([SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM][index],Art.padding("tag")[index])
		add_theme_stylebox_override(state,empty)
func _paint() -> void:
	Art.frame(backing,Rect2(Vector2.ZERO,size),"tag")
	if has_focus() or selected:
		var center:=Vector2(24,size.y*.6)
		backing.draw_colored_polygon(PackedVector2Array([center+Vector2(-7,-10),center+Vector2(7,0),center+Vector2(-7,10)]),T.MURAL_INK)

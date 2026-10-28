extends Node2D
## At most one two-second ambient balloon; never pauses or changes story flags.
var age:=0.0
static func spawn(owner:Node2D,point:Vector2,text:String) -> Node2D:
	for old in owner.get_tree().get_nodes_in_group("world_manga_speech"):old.hide();old.queue_free()
	var bubble=load("res://scripts/campaign/hud_world_speech.gd").new()
	bubble.position=point+Vector2(-130,-170)
	owner.add_child(bubble)
	bubble.add_to_group("world_manga_speech")
	var panel=load("res://scripts/campaign/hud_dialogue_surface.gd").new()
	panel.custom_minimum_size.x=260
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bubble.add_child(panel)
	var label:=Label.new()
	label.custom_minimum_size.x=204
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",16)
	label.text=text
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	bubble.z_index=4000
	return bubble
func _process(delta:float) -> void:
	age+=delta
	if age>=2:queue_free()

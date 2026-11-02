extends Control
## Short Mural reveal, separate from the loading gate used by heavy world scenes.
const Travel=preload("res://scripts/ui_mural/travel_surface.gd")
var reduced_motion:=false
func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var surface:=Travel.new()
	surface.loading=false
	surface.reduced_motion=reduced_motion
	add_child(surface)
	var director:=get_tree().get_first_node_in_group("soul_sound")
	if director!=null:director.transition()
	var tween:=create_tween()
	if reduced_motion:tween.tween_property(surface,"opacity",0.0,.10)
	else:tween.tween_property(surface,"slide",1.0,.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(get_parent().queue_free)
func _process(_delta:float)->void:
	for child in get_children():child.queue_redraw()

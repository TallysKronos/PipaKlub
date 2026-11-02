extends CanvasLayer
## Covers before scene construction; the owner releases it after the first rendered frame.
const Travel=preload("res://scripts/ui_mural/travel_surface.gd")
const Mural=preload("res://scripts/ui_mural/mural_theme.gd")
var reduced_motion:=false
var phase:="covering"
var opacity:=0.0
var slide:=0.0
var age:=0.0
var surface:Control
var previous_focus:WeakRef

func _ready()->void:
	layer=120
	process_mode=Node.PROCESS_MODE_ALWAYS
	previous_focus=weakref(get_viewport().gui_get_focus_owner())
	surface=Travel.new()
	surface.text_scale=Mural.text_scale_for(self)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter=Control.MOUSE_FILTER_STOP
	surface.focus_mode=Control.FOCUS_ALL
	add_child(surface)
	surface.grab_focus()

func _exit_tree()->void:
	var previous:Control=previous_focus.get_ref() if previous_focus!=null else null
	if is_instance_valid(previous) and previous.is_inside_tree() and previous.is_visible_in_tree():previous.grab_focus.call_deferred()

func _input(_event:InputEvent)->void:
	get_viewport().set_input_as_handled()

func _process(delta:float)->void:
	age+=delta
	surface.age=age
	surface.opacity=opacity
	surface.slide=slide
	surface.reduced_motion=reduced_motion
	surface.queue_redraw()

func cover()->void:
	var director:=get_tree().get_first_node_in_group("soul_sound")
	if director!=null:director.transition()
	var tween:=create_tween()
	tween.tween_property(self,"opacity",1.0,.08 if reduced_motion else .14)
	await tween.finished
	phase="loading"
	# Explicitly present the cover/icon before any synchronous scene work.
	if DisplayServer.get_name()!="headless":await RenderingServer.frame_post_draw

func reveal()->void:
	phase="revealing"
	var tween:=create_tween()
	if reduced_motion:
		tween.tween_property(self,"opacity",0.0,.10)
	else:
		tween.tween_property(self,"slide",1.0,.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	phase="complete"

extends CanvasLayer
## Covers before scene construction; the owner releases it after the first rendered frame.
const Hud=preload("res://scripts/campaign/hud.gd")
var reduced_motion:=false
var phase:="covering"
var opacity:=0.0
var slide:=0.0
var age:=0.0
var surface:Control

func _ready()->void:
	layer=120
	process_mode=Node.PROCESS_MODE_ALWAYS
	surface=Control.new()
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter=Control.MOUSE_FILTER_STOP
	surface.focus_mode=Control.FOCUS_ALL
	add_child(surface)
	surface.draw.connect(_paint)
	surface.resized.connect(surface.queue_redraw)
	surface.grab_focus()

func _input(_event:InputEvent)->void:
	get_viewport().set_input_as_handled()

func _process(delta:float)->void:
	age+=delta
	surface.queue_redraw()

func _paint()->void:
	var extent:=surface.size
	surface.draw_rect(Rect2(Vector2(-slide*extent.x,0),extent),Color(Hud.INK,opacity))
	# Safe inset follows the viewport, not the scene's camera or text scale.
	var point:=extent-Vector2(42,38)
	var alpha:=opacity*(1.0-slide)
	var angle:=0.0 if reduced_motion else age*3.4
	surface.draw_arc(point,15,angle,angle+TAU*.72,28,Color(Hud.GOLD,alpha),2.5,true)
	surface.draw_colored_polygon(PackedVector2Array([point+Vector2(0,-7),point+Vector2(5,0),point+Vector2(0,7),point+Vector2(-5,0)]),Color(Hud.CYAN,alpha))
	surface.draw_line(point+Vector2(0,7),point+Vector2(-3,12),Color(Hud.GOLD,alpha),1.5,true)

func cover()->void:
	var tween:=create_tween()
	tween.tween_property(self,"opacity",1.0,.08 if reduced_motion else .14)
	await tween.finished
	phase="loading"
	# Explicitly present the cover/icon before any synchronous scene work.
	await RenderingServer.frame_post_draw

func reveal()->void:
	phase="revealing"
	var tween:=create_tween()
	if reduced_motion:
		tween.tween_property(self,"opacity",0.0,.10)
	else:
		tween.tween_property(self,"slide",1.0,.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	phase="complete"

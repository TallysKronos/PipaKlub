extends CanvasLayer
## Presentation only: the care service remains the sole owner of kit consumption.
const Hud=preload("res://scripts/campaign/hud.gd")
var avatar:Node2D
var companion:Node2D
var companion_position:=Vector2.ZERO
var companion_tint:=Color.WHITE
var reduced_motion:=false
var elapsed:=0.0
var blackout:=0.0
var tent:Node2D
var surface:Control
var old_facing:="se"

class Tent extends Node2D:
	var elapsed:=0.0
	var reduced_motion:=false
	func polygon(points:Array,color:Color) -> void:
		var p:=PackedVector2Array(points);draw_colored_polygon(p,color);p.append(p[0]);draw_polyline(p,Color("172936"),2,true)
	func _draw() -> void:
		if elapsed<.38:return
		var toss:=clampf((elapsed-.38)/.62,0,1)
		if elapsed<1.1:
			var point:=Vector2(-7,-49).lerp(Vector2(16,13),toss)
			if not reduced_motion:point.y-=sin(toss*PI)*36
			var kit:Texture2D=preload("res://assets/ui/kit-remendo.svg")
			draw_texture_rect(kit,Rect2(point-Vector2(10,10),Vector2(20,20)),false)
		if elapsed<1:return
		var rise:=smoothstep(0,1,clampf((elapsed-1)/.8,0,1))
		var peak:=Vector2(0,22-132*rise)
		var rear:=peak+Vector2(36,-14*rise)
		var left:=Vector2(-76,22);var right:=Vector2(64,22);var back:=Vector2(100,-2)
		draw_ellipse_shadow()
		polygon([peak,rear,back,right],Color("267082"))
		var door_peak:=Vector2(0,22-93*rise)
		var door_left:=Vector2(-35,22);var door_right:=Vector2(34,22)
		# The doorway is a real hole between canvas panels until the flaps close.
		polygon([left,peak,door_peak,door_left],Color("e9bc72"))
		polygon([peak,right,door_right,door_peak],Color("f9d897"))
		var closure:=smoothstep(0,1,clampf((elapsed-1.95)/.5,0,1))
		if closure>0:
			polygon([door_left,door_peak,door_left.lerp(door_right,closure*.5)],Color("e1ab61"))
			polygon([door_right,door_right.lerp(door_left,closure*.5),door_peak],Color("efc47a"))
		if closure>.97:
			draw_line(door_peak+Vector2(0,5),Vector2(0,20),Color("7f5d39"),2)
			draw_circle(Vector2(2,7),2,Hud.GOLD)
		draw_line(left,peak,Color("fff0c6"),3,true);draw_line(peak,rear,Color("a6dfdb"),3,true)
		if rise>.75:
			# Seams, reinforcement patches and tie-downs keep the canvas readable
			# at overworld scale without painting a noisy texture over it.
			draw_line(left+Vector2(5,-2),door_left+Vector2(0,-2),Color("8f6d42"),2)
			draw_line(door_right+Vector2(0,-2),right+Vector2(-3,-2),Color("8f6d42"),2)
			draw_line(rear.lerp(back,.12),right.lerp(back,.8),Color("92bdba"),1.5,true)
			for peg in [left,right,back]:
				var end:Vector2=peg+Vector2(-12 if peg.x<0 else 12,7)
				draw_line(peg+Vector2(0,-12),end,Color("e1d4ae"),1.5,true)
				draw_line(end+Vector2(-2,-3),end+Vector2(3,3),Color("183e48"),3)
			polygon([left+Vector2(0,-2),left+Vector2(6,-12),left+Vector2(13,-2)],Color("376d73"))
			var c:=rear.lerp(back,.43)+Vector2(-7,3)
			var kite:=PackedVector2Array([c+Vector2(0,-10),c+Vector2(8,0),c+Vector2(0,11),c+Vector2(-8,0),c+Vector2(0,-10)])
			draw_colored_polygon(kite,Hud.PAPER);draw_polyline(kite,Color("173744"),2,true)
			draw_line(c-Vector2(7,0),c+Vector2(7,0),Color("267082"),1)
	func draw_ellipse_shadow() -> void:
		draw_set_transform(Vector2(12,18),0,Vector2(1,.28))
		draw_circle(Vector2.ZERO,85,Color(0,0,0,.2))
		draw_set_transform(Vector2.ZERO)

func _ready() -> void:
	layer=125
	set_meta("care_camp",true)
	surface=Control.new();surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);surface.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(surface)
	surface.draw.connect(func():surface.draw_rect(Rect2(Vector2.ZERO,surface.size),Color(0,0,0,blackout)))
	if is_instance_valid(avatar):
		old_facing=avatar.facing
		avatar.moving=false;avatar.running=false
		tent=Tent.new();tent.reduced_motion=reduced_motion
		avatar.get_parent().add_child(tent)
		tent.position=avatar.position;tent.scale=Vector2.ONE*absf(avatar.scale.y)
		tent.z_index=mini(4095,avatar.z_index+1)
	if is_instance_valid(companion):companion_position=companion.global_position;companion_tint=companion.modulate

func _input(_event:InputEvent) -> void:get_viewport().set_input_as_handled()
func _process(_delta:float) -> void:
	if is_instance_valid(tent):tent.elapsed=elapsed;tent.queue_redraw()
	if is_instance_valid(avatar):
		if elapsed<.65 and not reduced_motion:avatar.item_pose(clampf(elapsed/.65,0,1),old_facing)
		else:
			avatar.stop_item();avatar.facing="s"
		if is_instance_valid(companion):
			var front:=avatar.global_position+Vector2(0,38)*absf(avatar.scale.y)
			var inside:=avatar.global_position+Vector2(0,9)*absf(avatar.scale.y)
			var approach:=smoothstep(0,1,clampf((elapsed-.4)/.6,0,1))
			var enter:=smoothstep(0,1,clampf((elapsed-1)/.55,0,1))
			companion.global_position=companion_position.lerp(front,approach).lerp(inside,enter)
			companion.modulate=Color(companion_tint,companion_tint.a*(1-clampf((elapsed-1.55)/.25,0,1)))
	blackout=smoothstep(0,1,clampf((elapsed-2.6)/.4,0,1))
	surface.queue_redraw()
func play() -> void:
	var tween:=create_tween();tween.tween_property(self,"elapsed",3.05,.85 if reduced_motion else 3.05)
	await tween.finished
	blackout=1;surface.queue_redraw()
func reveal() -> void:
	set_process(false)
	var tween:=create_tween();tween.tween_property(self,"blackout",0,.12 if reduced_motion else .35)
	tween.parallel().tween_method(func(_value:float):surface.queue_redraw(),0.0,1.0,.12 if reduced_motion else .35)
	await tween.finished
func _exit_tree() -> void:
	if is_instance_valid(tent):tent.queue_free()
	if is_instance_valid(avatar):avatar.stop_item();avatar.facing=old_facing
	if is_instance_valid(companion):companion.global_position=companion_position;companion.modulate=companion_tint

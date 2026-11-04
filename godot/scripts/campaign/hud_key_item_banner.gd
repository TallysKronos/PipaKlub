extends Control
## Acquisition presentation only. Rewards must already be committed by the caller.
const Tokens=preload("res://scripts/campaign/ui_tokens.gd")
signal finished
const Hud = preload("res://scripts/campaign/hud.gd")
const DURATION := 2.5
var item_name := ""
var item_texture: Texture2D
var reduced_motion := false
var elapsed := 0.0
var done := false
var band: GradientTexture2D

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	z_index = 220
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0,.18,.82,1])
	gradient.colors = PackedColorArray([Tokens.alpha(Tokens.NANQUIM,0.0),Color(Hud.INK,.88),Color(Hud.INK,.88),Tokens.alpha(Tokens.NANQUIM,0.0)])
	band = GradientTexture2D.new()
	band.gradient = gradient
	band.width = 512; band.height = 1
	band.fill_from = Vector2.ZERO; band.fill_to = Vector2.RIGHT
	set_meta("key_item_banner",true)
	queue_redraw()

func _input(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if done: return
	elapsed = minf(DURATION,elapsed + maxf(delta,0))
	queue_redraw()
	if elapsed >= DURATION:
		done = true
		set_process(false)
		finished.emit()

func opacity_at(time: float) -> float:
	return smoothstep(0,.22,time) * (1.0-smoothstep(2.05,DURATION,time))

func item_scale_at(time: float) -> float:
	if reduced_motion: return 1.0
	if time < .16: return 0.0
	if time < .32: return lerpf(.8,1.08,smoothstep(.16,.32,time))
	return lerpf(1.08,1.0,smoothstep(.32,.48,time))

func _draw() -> void:
	if band == null: return
	var alpha := opacity_at(elapsed)
	if alpha <= 0: return
	var center := Vector2(size.x*.5,size.y*.48)
	draw_texture_rect(band,Rect2(0,center.y-112,size.x,240),false,Tokens.alpha(Tokens.UNTINTED,alpha))
	# Quiet halftone and ink, confined to the sides so the item keeps the focus.
	for side in [-1,1]:
		for x in range(80,int(size.x*.34),12):
			var fade := sin(float(x)/(size.x*.34)*PI)
			for y in range(-88,94,12):
				if absi(y)%24==0: continue
				draw_circle(center+Vector2(side*(size.x*.5-x),y),1.1,Color(Hud.MUTED,alpha*fade*.18))
		for index in 7:
			var y := -94.0+index*30.0
			var outer := center+Vector2(side*size.x*.37,y)
			var inner := center+Vector2(side*(180+index%3*20),y*.55)
			draw_line(outer,inner,Color(Hud.PAPER,alpha*.14),1.2,true)
			draw_line(outer+Vector2(0,4),inner+Vector2(side*24,2),Color(Hud.CYAN,alpha*.12),2,true)
	var icon_center := center-Vector2(0,15)
	for ring in range(6,0,-1):
		draw_circle(icon_center,20+ring*11,Color(Hud.CYAN,alpha*.018))
	var scale := item_scale_at(elapsed)
	if scale > 0 and item_texture != null:
		var extent := Vector2(128,128)*scale
		draw_texture_rect(item_texture,Rect2(icon_center-extent/2,extent),false,Tokens.alpha(Tokens.UNTINTED,alpha))
	if not reduced_motion:
		var impact := (1.0-smoothstep(.32,.65,elapsed))*smoothstep(.16,.22,elapsed)
		for index in 4:
			var direction := Vector2.from_angle(PI*.25+index*PI*.5)
			draw_line(icon_center+direction*70,icon_center+direction*84,Color(Hud.CYAN,alpha*impact*.6),2,true)
	var font := Hud.display()
	var font_size := 28
	while font_size>18 and font.get_string_size(item_name,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>size.x-152: font_size-=1
	var display_name: String = preload("res://scripts/campaign/battle_ink.gd").ellipsis(item_name,font,font_size,size.x-152)
	var text_width := font.get_string_size(display_name,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	var width := minf(size.x-80,maxf(330,text_width+72))
	var rect := Rect2(center.x-width/2,center.y+70,width,50)
	var shape := PackedVector2Array([rect.position+Vector2(15,0),Vector2(rect.end.x,rect.position.y),rect.end-Vector2(15,0),Vector2(rect.position.x,rect.end.y)])
	draw_colored_polygon(shape,Color(Hud.INK,alpha))
	shape.append(shape[0])
	draw_polyline(shape,Color(Hud.CYAN,alpha),2,true)
	draw_string(font,Vector2(center.x-text_width/2,rect.position.y+35),display_name,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(Hud.PAPER,alpha))

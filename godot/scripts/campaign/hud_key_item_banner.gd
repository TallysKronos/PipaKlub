extends Control
## Acquisition presentation only. Rewards must already be committed by the caller.
signal finished
const Hud = preload("res://scripts/campaign/hud.gd")
const T=preload("res://scripts/campaign/ui_tokens.gd")
const Mural=preload("res://scripts/ui_mural/mural_theme.gd")
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
var text_scale:=1.0
var moment:="item"
var duration:=DURATION
const DURATION := 2.5
var item_name := ""
var item_texture: Texture2D
var reduced_motion := false
var elapsed := 0.0
var done := false
var band: GradientTexture2D

func _ready() -> void:
	text_scale=maxf(text_scale,Mural.text_scale_for(self))
	if moment=="emblem":duration=3.0
	elif moment=="level":duration=1.7
	tooltip_text=item_name
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	z_index = 220
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0,.18,.82,1])
	gradient.colors = PackedColorArray([Color(0,0,0,0),Color(Hud.INK,.88),Color(Hud.INK,.88),Color(0,0,0,0)])
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
	elapsed = minf(duration,elapsed + maxf(delta,0))
	queue_redraw()
	if elapsed >= duration:
		done = true
		set_process(false)
		finished.emit()

func opacity_at(time: float) -> float:
	return smoothstep(0,.22,time) * (1.0-smoothstep(duration-.45,duration,time))

func item_scale_at(time: float) -> float:
	if reduced_motion: return 1.0
	if time < .16: return 0.0
	if time < .32: return lerpf(.8,1.08,smoothstep(.16,.32,time))
	return lerpf(1.08,1.0,smoothstep(.32,.48,time))

func _draw() -> void:
	if band == null: return
	var opacity:=opacity_at(elapsed)
	self_modulate=Color(1,1,1,opacity)
	if opacity<=0:return
	var alpha:=1.0
	var accent:=T.MURAL_SUN if moment in ["emblem","level"] else T.MURAL_MINT
	Paper.begin(self)
	var center := Vector2(size.x*.5,size.y*.48)
	draw_texture_rect(band,Rect2(0,center.y-112,size.x,240),false,Color(1,1,1,alpha))
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
	if moment=="level":
		for index in 4:
			var direction:=Vector2.from_angle(PI*.25+index*PI*.5)
			var point:=icon_center+direction*96
			draw_colored_polygon(PackedVector2Array([point,point+direction*24+direction.orthogonal()*7,point+direction*48,point+direction*24-direction.orthogonal()*7]),T.MURAL_SUN)
	if moment=="emblem":
		preload("res://scripts/ui_mural/menu_art.gd").frame(self,Rect2(center-Vector2(180,140),Vector2(360,250)),"case")
	for ring in range(6,0,-1):
		draw_circle(icon_center,20+ring*11,Color(accent,alpha*.018))
	var scale := item_scale_at(elapsed)
	if scale > 0 and item_texture != null:
		var extent := Vector2(128,128)*scale
		draw_texture_rect(item_texture,Rect2(icon_center-extent/2,extent),false,Color(1,1,1,alpha))
	if not reduced_motion:
		var impact := (1.0-smoothstep(.32,.65,elapsed))*smoothstep(.16,.22,elapsed)
		for index in 4:
			var direction := Vector2.from_angle(PI*.25+index*PI*.5)
			draw_line(icon_center+direction*70,icon_center+direction*84,Color(Hud.CYAN,alpha*impact*.6),2,true)
	var font_size:=roundi(26*text_scale)
	var width:=minf(size.x-96,1000)
	var lines:=preload("res://scripts/campaign/hud_dialogue_surface.gd").wrapped_lines(item_name,T.label(),font_size,width-64)
	if lines.size()>2:lines=lines.slice(0,2);lines[1]=preload("res://scripts/campaign/battle_ink.gd").ellipsis(lines[1]+"…",T.label(),font_size,width-64)
	var content_width:=0.0
	for line in lines:content_width=maxf(content_width,T.label().get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x)
	width=minf(width,maxf(330,content_width+64))
	var height:=T.label().get_height(font_size)
	var rect:=Rect2(center.x-width/2,center.y+(130 if moment=="emblem" else 70),width,height*lines.size()+58)
	Paper.frame(self,rect,"MuralInkPanel",.35)
	var safe:=Paper.content(rect,.35)
	for index in lines.size():Paper.label(self,Rect2(safe.position+Vector2(0,height*index),Vector2(safe.size.x,height)),lines[index],font_size,T.MURAL_PAPER,true,safe)

extends Control
## Live lettering and approved creature portrait; no baked names or combat state.
signal skip_requested
var skip:Button
const Mural=preload("res://scripts/ui_mural/mural_theme.gd")
const T=preload("res://scripts/campaign/ui_tokens.gd")
const Hud=preload("res://scripts/campaign/hud.gd")
const Ink=preload("res://scripts/campaign/battle_ink.gd")

const INTRO_SECONDS:=3.2
var remaining:=INTRO_SECONDS
var title:="Lacertubo"
var face:Texture2D
var reduced_motion:=false

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_IGNORE
	z_index=20
	skip=Button.new();skip.text="Pular apresentação";skip.custom_minimum_size=Vector2(240,56)
	skip.add_theme_font_size_override("font_size",20);add_child(skip)
	skip.pressed.connect(func():skip_requested.emit())
	resized.connect(_layout);_layout()
func _layout() -> void:
	if skip!=null:skip.position=Vector2(size.x-284,size.y-88);skip.size=Vector2(260,64)


static func meter_rect(viewport:Vector2) -> Rect2:
	return Rect2(344,18,maxf(400,viewport.x-368),102)

static func text(c:Control,at:Vector2,value:String,font_size:int=16,color:Color=T.PAPEL) -> void:
	c.draw_string(Hud.font(true),at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

static func bar(c:Control,rect:Rect2,fraction:float,color:Color) -> void:
	c.draw_colored_polygon(Ink.shape(rect,3),T.TINTA_3)
	if rect.size.x*clampf(fraction,0,1)>.5:c.draw_colored_polygon(Ink.shape(Rect2(rect.position,Vector2(rect.size.x*clampf(fraction,0,1),rect.size.y)),3),color)

static func draw_meter(c:Control,actor:Dictionary,portrait:Texture2D,seconds:float,level:int) -> void:
	var box:=meter_rect(c.size)
	Ink.plate(c,box,T.TINTA,T.RABIOLA,16)
	c.draw_texture_rect(Ink.brush(1),Rect2(box.position+Vector2(-10,-8),Vector2(112,114)),false)
	if portrait!=null:c.draw_texture_rect(portrait,Hud.fit_texture(portrait,Rect2(box.position+Vector2(4,0),Vector2(90,98))),false)
	var x:=box.position.x+104
	var width:=box.size.x-126
	text(c,Vector2(x,box.position.y+23),"BOSS  /  "+("FASE 2" if actor.get("phase",1)==2 else "FASE 1"),15,T.SOL)
	var name:=str(actor.get("bossTitle","Lacertubo"))
	text(c,Vector2(x,box.position.y+48),Ink.ellipsis(name.to_upper(),Hud.lettering(),26,width-120),26)
	text(c,Vector2(box.end.x-126,box.position.y+25),"Nv. %d  ·  %ds"%[level,ceili(seconds)],16,T.PAPEL_2)
	var track:=Rect2(x,box.position.y+57,width-56,18)
	bar(c,track,actor.hp/actor.stats.line,T.RABIOLA)
	for part in range(1,10):c.draw_line(track.position+Vector2(track.size.x*part/10,0),track.position+Vector2(track.size.x*part/10,18),T.TINTA,2)
	text(c,Vector2(track.end.x+8,track.end.y),"%d%%"%roundi(actor.hp/actor.stats.line*100),16)
	text(c,Vector2(x,box.position.y+94),"ARMAÇÃO",12,T.PAPEL_2)
	bar(c,Rect2(x+74,box.position.y+85,width-130,6),actor.hull/actor.stats.line,T.PAPEL_2)
	text(c,Vector2(box.end.x-48,box.position.y+96),"%d%%"%roundi(actor.hull/actor.stats.line*100),12,T.PAPEL_2)

func _draw() -> void:
	if remaining<=0:return
	draw_rect(Rect2(Vector2.ZERO,size),T.alpha(T.MURAL_GROUND,.85))
	var factor:=minf(size.x/1280,size.y/720)
	draw_set_transform(size/2,0,Vector2.ONE*factor)
	draw_style_box(Mural.shared().get_stylebox("panel","MuralSunPanel"),Rect2(-580,-154,1160,328))
	if face!=null:draw_texture_rect(face,Hud.fit_texture(face,Rect2(-540,-174,300,350)),false)
	draw_string(T.lettering(),Vector2(-196,-25),"BOSS À VISTA!",HORIZONTAL_ALIGNMENT_LEFT,-1,66,T.MURAL_INK)
	draw_string(T.label(),Vector2(-196,36),title,HORIZONTAL_ALIGNMENT_LEFT,700,42,T.MURAL_INK)
	draw_string(T.label(),Vector2(-196,88),"Guardião dos Canos",HORIZONTAL_ALIGNMENT_LEFT,700,26,T.MURAL_INK)
	draw_set_transform(Vector2.ZERO)

extends Control
## Live lettering and approved creature portrait; no baked names or combat state.
signal skip_requested
var skip:Button
const Mural=preload("res://scripts/ui_mural/mural_theme.gd")
const EventArt=preload("res://scripts/ui_mural/event_art.gd")
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
const T=preload("res://scripts/campaign/ui_tokens.gd")
const Hud=preload("res://scripts/campaign/hud.gd")
const Ink=preload("res://scripts/campaign/battle_ink.gd")

const INTRO_SECONDS:=3.2
var remaining:=INTRO_SECONDS
var title:="Lacertubo"
var face:Texture2D
var reduced_motion:=false
var text_scale:=1.0
func _init()->void:set_meta("owns_ui_theme",true)

func _ready() -> void:
	text_scale=maxf(text_scale,Mural.text_scale_for(self))
	Mural.install(self)
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_IGNORE
	z_index=20
	skip=preload("res://scripts/ui_mural/dialogue_option.gd").new();skip.text="Pular apresentação";skip.text_scale=text_scale;skip.font_base=20;skip.density=.2;skip.custom_minimum_size=Vector2(240,56)
	add_child(skip)
	skip.pressed.connect(func():skip_requested.emit())
	skip.minimum_size_changed.connect(_layout)
	resized.connect(_layout);_layout()
func _layout() -> void:
	if skip!=null:
		var width:=maxf(260,skip.get_combined_minimum_size().x)
		var height:=maxf(64,skip.get_combined_minimum_size().y)
		skip.position=Vector2(size.x-width-24,size.y-height-24);skip.size=Vector2(width,height)


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
	Paper.begin(self)
	draw_rect(Rect2(Vector2.ZERO,size),T.alpha(T.MURAL_GROUND,.8))
	var height:=minf(380+(text_scale-1)*160,size.y*.68)
	var band:=Rect2(24,size.y/2-height/2,size.x-48,height)
	EventArt.draw(self,band,"boss-warning")
	var safe:=EventArt.content(band,"boss-warning")
	var portrait_width:=minf(300,size.x*.26)
	if face!=null:draw_texture_rect(face,Hud.fit_texture(face,Rect2(band.position+Vector2(24,-20),Vector2(portrait_width,height+40))),false)
	safe.position.x=band.position.x+portrait_width+50
	safe.size.x=band.end.x-safe.position.x-210
	var extra:=minf(24,maxf(0,safe.size.y-160))
	safe.position.y+=extra;safe.size.y-=extra
	# The red warning is ornament; smaller names need a quiet, high-contrast field.
	draw_colored_polygon(Ink.shape(safe.grow(24),18),T.NANQUIM)
	var title_size:=roundi(clampf(size.x/22,40,64)*text_scale)
	var h:=Paper.height(title_size)
	Paper.label(self,Rect2(safe.position,Vector2(safe.size.x,h)),"BOSS À VISTA!",title_size,T.MURAL_PAPER,false,safe)
	var name_font:=roundi(32*text_scale);var subtitle_font:=roundi(22*text_scale)
	var name_h:=Paper.height(name_font)
	Paper.label(self,Rect2(safe.position+Vector2(0,h+8),Vector2(safe.size.x,name_h)),title,name_font,T.MURAL_PAPER,false,safe)
	Paper.label(self,Rect2(safe.position+Vector2(0,h+name_h+16),Vector2(safe.size.x,Paper.height(subtitle_font))),"Guardião dos Canos",subtitle_font,T.MURAL_PAPER,false,safe)

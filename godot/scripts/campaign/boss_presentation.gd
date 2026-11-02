extends Control
## Live lettering and approved creature portrait; no baked names or combat state.
const T=preload("res://scripts/campaign/ui_tokens.gd")
const Hud=preload("res://scripts/campaign/hud.gd")
const Ink=preload("res://scripts/campaign/battle_ink.gd")

const INTRO_SECONDS:=3.2
var remaining:=INTRO_SECONDS
var title:="Lacertubo"
var subtitle:="Guardião dos Canos"
var face:Texture2D
var reduced_motion:=false

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_IGNORE
	z_index=20

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
	var elapsed:=INTRO_SECONDS-minf(remaining,INTRO_SECONDS)
	var opacity:=minf(1,remaining/.35) if reduced_motion else 1.0
	draw_rect(Rect2(Vector2.ZERO,size),T.alpha(T.NANQUIM,.7*opacity))
	var scale_factor:=minf(size.x/1280.0,size.y/720.0)
	var origin:=size/2
	var slide:=0.0 if reduced_motion else -1400*pow(maxf(0,1-elapsed/.32),3)+1400*pow(maxf(0,1-remaining/.3),3)
	draw_set_transform(origin+Vector2(slide,0),0,Vector2.ONE*scale_factor)
	var edge:=T.alpha(T.SOL,opacity)
	var points:=PackedVector2Array([Vector2(-720,-58),Vector2(720,-154),Vector2(720,70),Vector2(-720,162)])
	draw_colored_polygon(points,T.NANQUIM)
	var band:=PackedVector2Array([Vector2(-720,-42),Vector2(720,-138),Vector2(720,54),Vector2(-720,146)])
	draw_colored_polygon(band,T.alpha(T.RABIOLA,opacity))
	points.append(points[0]);draw_polyline(points,edge,5,true)
	for i in 16:
		var x:float=-720+i*100
		var y:float=-62-(x+720)/15
		draw_line(Vector2(x,y),Vector2(x+45,y-3),edge,6,true)
		for j in 3:draw_circle(Vector2(x+12,j*17+y+32),2,T.alpha(T.NANQUIM,.25*opacity))
	for i in 7:
		draw_line(Vector2(-620+i*23,-178+i*6),Vector2(-240+i*23,-152+i*6),T.alpha(T.PAPEL,.3*opacity),2,true)
	var portrait_box:=Rect2(-490,-137,234,265)
	draw_texture_rect(Ink.brush(1),portrait_box.grow(25),false,T.alpha(T.PAPEL,opacity))
	if face!=null:draw_texture_rect(face,Hud.fit_texture(face,portrait_box),false,T.alpha(T.UNTINTED,opacity))
	var font:=Hud.lettering()
	draw_string_outline(font,Vector2(-215,3),"BOSS À VISTA!",HORIZONTAL_ALIGNMENT_LEFT,-1,82,14,T.alpha(T.NANQUIM,opacity))
	draw_string(font,Vector2(-215,3),"BOSS À VISTA!",HORIZONTAL_ALIGNMENT_LEFT,-1,82,T.alpha(T.PAPEL,opacity))
	Ink.plate(self,Rect2(-180,25,550,56),T.TINTA,T.SOL,14)
	draw_string(Hud.font(true),Vector2(-156,62),title+" · "+subtitle,HORIZONTAL_ALIGNMENT_LEFT,500,25,T.alpha(T.PAPEL,opacity))
	draw_set_transform(Vector2.ZERO)


extends Control
signal skip_requested
const T=preload("res://scripts/campaign/ui_tokens.gd")
const Mural=preload("res://scripts/ui_mural/mural_theme.gd")
const Hud=preload("res://scripts/campaign/hud.gd")
const Ink=preload("res://scripts/campaign/battle_ink.gd")
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
var remaining:=3.0
var rival_name:="Mikka"
var player_name:="Kael"
var subtitle:="Campeã do Morro do Sol"
var partner_name:="Azulão"
var face:Texture2D
var reduced_motion:=false
var text_scale:=1.0
var skip:Button
func _init()->void:set_meta("owns_ui_theme",true)
func _ready() -> void:
	text_scale=maxf(text_scale,Mural.text_scale_for(self));Mural.install(self)
	set_anchors_and_offsets_preset(PRESET_FULL_RECT);mouse_filter=MOUSE_FILTER_IGNORE;z_index=21
	skip=preload("res://scripts/ui_mural/dialogue_option.gd").new();skip.text="Pular apresentação";skip.text_scale=text_scale;skip.font_base=20;skip.density=.2;skip.custom_minimum_size=Vector2(240,48)
	add_child(skip)
	skip.pressed.connect(func():skip_requested.emit())
	skip.minimum_size_changed.connect(_layout)
	resized.connect(_layout);_layout()
func _layout() -> void:
	if skip!=null:
		var width:=maxf(260,skip.get_combined_minimum_size().x)
		var height:=maxf(64,skip.get_combined_minimum_size().y)
		skip.position=Vector2(size.x-width-24,size.y-height-24);skip.size=Vector2(width,height)
func rects() -> Dictionary:
	return {"left":Rect2(size.x*.045,size.y*.20,size.x*.42,size.y*.56),"right":Rect2(size.x*.535,size.y*.20,size.x*.42,size.y*.56)}
func _draw() -> void:
	if remaining<=0:return
	draw_rect(Rect2(Vector2.ZERO,size),T.alpha(T.MURAL_GROUND,.92))
	var boxes:=rects()
	var left:Rect2=boxes.left;var right:Rect2=boxes.right
	Paper.begin(self)
	Paper.frame(self,left,"MuralPaperPanel",.5)
	Paper.frame(self,right,"MuralInkPanel",.5)
	var ls:=Paper.content(left,.5);var rs:=Paper.content(right,.5)
	var font_size:=roundi(clampf(size.x/25,36,58)*text_scale)
	Paper.label(self,Rect2(ls.position,Vector2(ls.size.x,Paper.height(font_size))),player_name,font_size,T.MURAL_INK,false,ls)
	Paper.label(self,Rect2(rs.position,Vector2(rs.size.x,Paper.height(font_size))),rival_name,font_size,T.MURAL_PAPER,false,rs)
	var portrait:Texture2D=preload("res://assets/campaign/portrait-kael-manga-v4.png")
	var art_top:=Paper.height(font_size)+12
	draw_texture_rect(portrait,Hud.fit_texture(portrait,Rect2(ls.position+Vector2(0,art_top),ls.size-Vector2(0,art_top))),false)
	var partner_font:=roundi(24*text_scale);var partner_height:=Paper.height(partner_font)
	if face!=null:draw_texture_rect(face,Hud.fit_texture(face,Rect2(rs.position+Vector2(0,art_top),rs.size-Vector2(0,art_top+partner_height+8))),false)
	Paper.label(self,Rect2(Vector2(rs.position.x,rs.end.y-partner_height),Vector2(rs.size.x,partner_height)),partner_name,partner_font,T.MURAL_PAPER,false,rs)
	var center_size:=Vector2(172+(text_scale-1)*90,132+(text_scale-1)*100)
	var center:=Rect2(Vector2(size.x/2-center_size.x/2,size.y*.43),center_size)
	Paper.frame(self,center,"MuralSunPanel",.35)
	var safe:=Paper.content(center,.35)
	Paper.label(self,safe,"VS",roundi(48*text_scale),T.MURAL_INK,true,safe)
	var caption:=subtitle.to_upper()
	var caption_font:=roundi(24*text_scale)
	Paper.label(self,Rect2(24,size.y*.07,size.x-48,Paper.height(caption_font)),caption,caption_font,T.MURAL_PAPER,true,Rect2(Vector2(24,24),size-Vector2(48,48)))

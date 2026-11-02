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
var skip:Button
func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT);mouse_filter=MOUSE_FILTER_IGNORE;z_index=21
	skip=Button.new();skip.text="Pular apresentação";skip.custom_minimum_size=Vector2(240,48)
	skip.add_theme_font_size_override("font_size",20);add_child(skip)
	skip.pressed.connect(func():skip_requested.emit())
	resized.connect(_layout);_layout()
func _layout() -> void:
	if skip!=null:skip.position=Vector2(size.x-284,size.y-88);skip.size=Vector2(260,64)
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
	var font_size:=roundi(clampf(size.x/25,36,58))
	Paper.label(self,Rect2(ls.position,Vector2(ls.size.x,Paper.height(font_size))),player_name,font_size,T.MURAL_INK,false,ls)
	Paper.label(self,Rect2(rs.position,Vector2(rs.size.x,Paper.height(font_size))),rival_name,font_size,T.MURAL_PAPER,false,rs)
	var portrait:Texture2D=preload("res://assets/campaign/portrait-kael-manga-v4.png")
	var art_top:=Paper.height(font_size)+12
	draw_texture_rect(portrait,Hud.fit_texture(portrait,Rect2(ls.position+Vector2(0,art_top),ls.size-Vector2(0,art_top))),false)
	if face!=null:draw_texture_rect(face,Hud.fit_texture(face,Rect2(rs.position+Vector2(0,art_top),rs.size-Vector2(0,art_top+44))),false)
	Paper.label(self,Rect2(Vector2(rs.position.x,rs.end.y-32),Vector2(rs.size.x,32)),partner_name,24,T.MURAL_PAPER,false,rs)
	var center:=Rect2(size.x/2-86,size.y*.43,172,132)
	Paper.frame(self,center,"MuralSunPanel",.35)
	var safe:=Paper.content(center,.35)
	Paper.label(self,safe,"VS",48,T.MURAL_INK,true,safe)
	var caption:=subtitle.to_upper()
	var width:=T.label().get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,24).x
	draw_string(T.label(),Vector2((size.x-width)/2,size.y*.14),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,24,T.MURAL_PAPER)

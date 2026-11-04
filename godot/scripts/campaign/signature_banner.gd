extends Control
## Port of web signature-banner: same approved art, copy and 820 ms duration.
const ROOT:="res://assets/ui/signatures-v1/"
const T=preload("res://scripts/campaign/ui_tokens.gd")
const Hud=preload("res://scripts/campaign/hud.gd")
const Ink=preload("res://scripts/campaign/battle_ink.gd")
const DURATION:=.82
var entries:Dictionary={}
var images:Dictionary={}
var active_id:=""
var enemy:=false
var age:=0.0
var reduced_motion:=false

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_IGNORE;z_index=15;hide()
	entries=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"manifest.json")).images
	for id in entries:images[id]=load(ROOT+entries[id].image)

func announce(id:String,rival:bool=false) -> void:
	if not entries.has(id):return
	# A player's simultaneous activation must never replace an enemy warning.
	if visible and enemy and not rival:return
	active_id=id;enemy=rival;age=0;show();queue_redraw()

func advance(delta:float,suspended:bool=false,finished:bool=false) -> void:
	if active_id.is_empty():return
	if finished:active_id="";hide();return
	if suspended:hide();return
	age+=delta
	if age>=DURATION:active_id="";hide()
	else:show();queue_redraw()

func banner_rect() -> Rect2:
	return Rect2(0,size.y*.23,size.x,clampf(size.y*.26,155,285))

func _draw() -> void:
	if active_id.is_empty():return
	var rect:=banner_rect()
	var phase:=age/DURATION
	var opacity:=minf(1,minf(phase/.17,(1-phase)/.15))
	var slide:=0.0 if reduced_motion else -size.x*pow(maxf(0,1-phase/.17),3)+size.x*.12*pow(maxf(0,(phase-.85)/.15),2)
	draw_set_transform(Vector2(slide,0))
	var accent:=T.SOL if entries[active_id].tone=="amber" else T.CEU
	var outline:=PackedVector2Array([rect.position+Vector2(0,16),rect.position+Vector2(size.x*.2,4),rect.position+Vector2(size.x*.48,10),Vector2(rect.end.x,rect.position.y),rect.end-Vector2(0,12),rect.end-Vector2(size.x*.4,0),Vector2(0,rect.end.y-8)])
	draw_colored_polygon(outline,T.alpha(T.TINTA,opacity))
	outline.append(outline[0]);draw_polyline(outline,T.alpha(accent,opacity),4,true)
	var texture:Texture2D=images[active_id]
	var picture:=Rect2(rect.position+Vector2(0,17),Vector2(size.x*.55,rect.size.y-30))
	var focus:=Vector2(.5,.45)
	if active_id=="rabbito":focus=Vector2(.38,.54)
	elif active_id=="lacertubo":focus=Vector2(.42,.5)
	var scale_factor:=maxf(picture.size.x/texture.get_width(),picture.size.y/texture.get_height())
	var uv_size:=picture.size/(texture.get_size()*scale_factor)
	var uv_start:Vector2=(Vector2.ONE-uv_size)*focus
	for i in 24:
		var left:=i/24.0;var right:=(i+1)/24.0
		var x0:=picture.position.x+left*picture.size.x;var x1:=picture.position.x+right*picture.size.x
		var alpha0:=opacity*clampf((1-left)/.38,0,1);var alpha1:=opacity*clampf((1-right)/.38,0,1)
		var points:=PackedVector2Array([Vector2(x0,picture.position.y),Vector2(x1,picture.position.y),Vector2(x1,picture.end.y),Vector2(x0,picture.end.y)])
		var uv:=PackedVector2Array([uv_start+uv_size*Vector2(left,0),uv_start+uv_size*Vector2(right,0),uv_start+uv_size*Vector2(right,1),uv_start+uv_size*Vector2(left,1)])
		draw_polygon(points,PackedColorArray([T.alpha(T.UNTINTED,alpha0),T.alpha(T.UNTINTED,alpha1),T.alpha(T.UNTINTED,alpha1),T.alpha(T.UNTINTED,alpha0)]),uv,texture)
	var x:=size.x*.52
	var unit:=clampf(size.x/1280.0,.72,1.5)
	var y:=rect.position.y+rect.size.y*.22
	draw_string(Hud.font(true),Vector2(x,y),"GOLPE DE ASSINATURA",HORIZONTAL_ALIGNMENT_LEFT,-1,roundi(13*unit),T.alpha(accent,opacity))
	draw_string(Hud.font(true),Vector2(x,y+28*unit),str(entries[active_id].name).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,roundi(19*unit),T.alpha(T.PAPEL,opacity))
	var move:=str(entries[active_id].move).to_upper()
	var font_size:=roundi(48*unit)
	while Hud.lettering().get_string_size(move,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>size.x*.44 and font_size>20:font_size-=1
	draw_string(Hud.lettering(),Vector2(x,y+77*unit),move,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,T.alpha(T.PAPEL,opacity))
	draw_string(Hud.font(true),Vector2(x,y+106*unit),"Impacto chegando · prepare a guarda!" if enemy else "Seu elo ganha força!",HORIZONTAL_ALIGNMENT_LEFT,-1,roundi(16*unit),T.alpha(T.PAPEL_2,opacity))
	draw_set_transform(Vector2.ZERO)

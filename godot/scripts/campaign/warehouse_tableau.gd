extends Control
## Read-only manga insert. Static approved poses, no claim of rigged animation.
var beat:=0
var reduced_motion:=false
var age:=0.0
var dragon:Texture2D
var retalho:Texture2D
var tyler:Texture2D
func _ready()->void:
 set_anchors_and_offsets_preset(PRESET_FULL_RECT);mouse_filter=MOUSE_FILTER_IGNORE;z_index=79
 dragon=load("res://assets/campaign/warehouse-v1/dragon.png")
 retalho=load("res://assets/campaign/retalho-v1/battle.png")
 tyler=load("res://assets/campaign/tyler-clareira-v1/tyler.png")
func _process(dt:float)->void:
 age+=dt;queue_redraw()
func _draw()->void:
 draw_rect(Rect2(Vector2.ZERO,size),Color(.025,.04,.06,.78))
 var focus:=Vector2(size.x*.58,size.y*.31)
 var extent:=Vector2(410,310) if beat<3 else Vector2(290,220)
 if not reduced_motion:focus.y+=sin(age*1.5)*2
 if dragon!=null:draw_texture_rect(dragon,preload("res://scripts/campaign/hud.gd").fit_texture(dragon,Rect2(focus-extent*.5,extent)),false)
 if beat<3:
  for i in 2:
   var knot:=focus+Vector2(-25+i*55,12+i*14)
   var rope:=PackedVector2Array([knot+Vector2(-60,-35),knot,knot+Vector2(50,30)])
   draw_polyline(rope,Color("493a32"),5);draw_polyline(rope,Color("d6b477"),3)
   draw_arc(knot+Vector2(-5,0),8,-1.4,1.4,12,Color("d6b477"),3)
   draw_arc(knot+Vector2(5,0),8,1.7,4.5,12,Color("d6b477"),3)
 if beat>=1 and retalho!=null:
  draw_texture_rect(retalho,preload("res://scripts/campaign/hud.gd").fit_texture(retalho,Rect2(size.x*.24,size.y*.28,130,180)),false,Color(1,1,1,.8) if beat>=2 else Color.WHITE)
 if beat>=2 and tyler!=null:draw_texture_rect(tyler,preload("res://scripts/campaign/hud.gd").fit_texture(tyler,Rect2(size.x*.13,size.y*.16,150,240)),false)
 # Symbolic soul lights remain separate from the creature's permanent hoses/tail.
 if beat>=3:
  for i in 2:
   var rise:=.5 if reduced_motion else fmod(age*.22+i*.4,1.0)
   var p:=focus+Vector2(-70+i*140,-40-rise*130)
   draw_circle(p,6,Color(.83,.95,1,.8));draw_arc(p,11,0,TAU,24,Color(.6,.85,1,.3),2)

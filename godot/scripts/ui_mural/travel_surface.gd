extends Control
## One cut-paper curtain for loading and short scene reveals. No progress fiction.
const T=preload("res://scripts/campaign/ui_tokens.gd")
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
var opacity:=1.0
var slide:=0.0
var age:=0.0
var reduced_motion:=false
var loading:=true
var text_scale:=1.0

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func label_rect()->Rect2:
	var width:=300.0+100.0*(text_scale-1.0)
	var height:=100.0+40.0*(text_scale-1.0)
	return Rect2(size-Vector2(width+24,height+24),Vector2(width,height))

func _draw()->void:
	Paper.begin(self)
	modulate.a=opacity
	var offset:=-slide*(size.x+48)
	draw_set_transform(Vector2(offset,0))
	draw_rect(Rect2(Vector2.ZERO,size),T.MURAL_GROUND)
	# Torn poster edge; the cut moves as one piece, never stretches its artwork.
	var edge:=PackedVector2Array([Vector2(size.x,0),Vector2(size.x+14,0)])
	for i in 17: edge.append(Vector2(size.x+(12 if i%2==0 else 30),size.y*float(i)/16))
	edge.append(Vector2(size.x,size.y))
	draw_colored_polygon(edge,T.MURAL_PAPER)
	var center:=Vector2(size.x*.21,size.y*.44)
	var r:=minf(size.x,size.y)*.26
	var kite:=PackedVector2Array([center+Vector2(0,-r),center+Vector2(r*.65,0),center+Vector2(0,r),center-Vector2(r*.65,0),center-Vector2(0,r)])
	draw_polyline(kite,Color(T.MURAL_MINT,.11),4,true)
	draw_line(center-Vector2(0,r),center+Vector2(0,r),Color(T.MURAL_MINT,.11),3,true)
	draw_line(center-Vector2(r*.65,0),center+Vector2(r*.65,0),Color(T.MURAL_MINT,.11),3,true)
	draw_polyline(PackedVector2Array([center+Vector2(0,r),center+Vector2(-30,r+30),center+Vector2(20,r+55)]),Color(T.MURAL_MINT,.11),3,true)
	draw_set_transform(Vector2.ZERO)
	if not loading:return
	# Bottom-right information stays inside the safe viewport while the curtain exits.
	var rect:=label_rect()
	rect.position.x+=offset
	Paper.frame(self,rect,"MuralPaperPanel",.3)
	var safe:=Paper.content(rect,.3)
	var point:=safe.position+Vector2(26,safe.size.y/2)
	var angle:=0.0 if reduced_motion else age*3.4
	draw_arc(point,21,angle,angle+TAU*.74,32,T.MURAL_TEAL,3,true)
	draw_colored_polygon(PackedVector2Array([point+Vector2(0,-14),point+Vector2(10,0),point+Vector2(0,14),point+Vector2(-10,0)]),T.MURAL_SUN)
	draw_line(point+Vector2(0,-14),point+Vector2(0,14),T.MURAL_INK,1.5,true)
	draw_line(point-Vector2(10,0),point+Vector2(10,0),T.MURAL_INK,1.5,true)
	var slot:=Rect2(safe.position+Vector2(66,0),safe.size-Vector2(66,0))
	Paper.label(self,slot,"Carregando…",roundi(26*text_scale),T.MURAL_INK,false,safe)

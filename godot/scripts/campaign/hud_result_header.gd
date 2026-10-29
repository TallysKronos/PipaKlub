extends Control
const Hud=preload("res://scripts/campaign/hud.gd")
const Ink=preload("res://scripts/campaign/battle_ink.gd")
var outcome:="won"
var left:=60.0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	z_index=5
# Approved board: Bangers lettering in paper with a thick ink outline and solid shadow, tilted,
# over a brush stroke (sol for victory, rabiola for defeat). Defeat keeps a short consolation line.
func _draw() -> void:
	var title:="VITÓRIA!" if outcome=="won" else "DERROTA" if outcome=="lost" else "VOCÊ RECUOU"
	var font:=Hud.lettering()
	var font_size:=96
	var width:=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	_brush(Rect2(left+width*.3,34,width*1.1,62),Hud.GOLD if outcome=="won" else Hud.CORAL if outcome=="lost" else Hud.MUTED)
	draw_set_transform(Vector2(left,100),deg_to_rad(-5),Vector2.ONE)
	draw_string_outline(font,Vector2(6,7),title,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,14,Ink.BLACK)
	draw_string(font,Vector2(6,7),title,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Ink.BLACK)
	draw_string_outline(font,Vector2.ZERO,title,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,12,Ink.BLACK)
	draw_string(font,Vector2.ZERO,title,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Ink.WHITE)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	if outcome=="won":return
	var subtitle:="Seu parceiro está com você. Vamos de novo!" if outcome=="lost" else "Você escolheu voltar em segurança."
	Ink.plate(self,Rect2(left+4,124,470,34),Hud.INK,Hud.INK,8)
	draw_string(Hud.font(),Vector2(left+16,148),subtitle,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Hud.PAPER)

# Dry brush stroke in a flat colour: tapered body with ragged edges and a few loose streaks.
func _brush(r:Rect2,color:Color) -> void:
	var top:=PackedVector2Array()
	var bottom:=PackedVector2Array()
	for i in 25:
		var t:=i/24.0
		var x:=r.position.x+r.size.x*t
		var taper:=sin(PI*minf(1,t*1.4))*.5+.5 if t<.7 else 1.0-(t-.7)/.3*.85
		var jag:=(float((i*37)%7)/7.0-.5)*8
		top.append(Vector2(x,r.position.y+r.size.y*.5-r.size.y*.5*taper+jag*.5))
		bottom.append(Vector2(x,r.position.y+r.size.y*.5+r.size.y*.5*taper+jag))
	bottom.reverse()
	draw_colored_polygon(top+bottom,color)
	for k in 4:
		var y:=r.position.y+r.size.y*(.2+k*.2)
		draw_line(Vector2(r.end.x-r.size.x*.18,y),Vector2(r.end.x+18+k*9,y-4+k*3),color,3-k*.5,true)

extends PanelContainer
## Moldura do visor de exploração. As mesmas bordas acompanham fichas e avisos.
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
var accent := Tokens.CEU

func _ready() -> void:
	set_meta("recorte_decorated",true)
	var inset:=StyleBoxEmpty.new()
	inset.set_content_margin(SIDE_LEFT,16)
	inset.set_content_margin(SIDE_RIGHT,16)
	inset.set_content_margin(SIDE_TOP,6)
	inset.set_content_margin(SIDE_BOTTOM,6)
	add_theme_stylebox_override("panel",inset)
	resized.connect(queue_redraw)

static func outline(rect:Rect2,cut:float) -> PackedVector2Array:
	var p:=rect.position
	var end:=rect.end
	return PackedVector2Array([p+Vector2(cut,0),Vector2(end.x,p.y),end-Vector2(0,cut),end-Vector2(cut,0),Vector2(p.x,end.y),p+Vector2(0,cut)])

static func frame(canvas:Control,rect:Rect2,tone:Color) -> void:
	var path:=outline(rect.grow(-1),8)
	canvas.draw_colored_polygon(path,Tokens.LOBBY_TILE)
	path.append(path[0])
	canvas.draw_polyline(path,Tokens.LOBBY_INSET_EDGE,1.5,true)
	canvas.draw_line(path[5],path[0],tone,2,true)
	canvas.draw_line(path[0],path[0]+Vector2(minf(rect.size.x*.30,48),0),tone,2,true)

func _draw() -> void:
	frame(self,Rect2(Vector2.ZERO,size),accent)

static func action(button:Button) -> void:
	for state in ["normal","hover","pressed","hover_pressed","focus","disabled"]:
		var box:=StyleBoxFlat.new()
		box.bg_color=Tokens.LOBBY_TILE_ACTIVE if state in ["hover","pressed","hover_pressed"] else Tokens.LOBBY_TILE
		box.border_color=Tokens.CEU if state in ["focus","hover","hover_pressed","pressed"] else Tokens.LOBBY_INSET_EDGE
		box.set_border_width_all(1)
		box.set_corner_radius_all(4)
		box.set_content_margin(SIDE_LEFT,10)
		box.set_content_margin(SIDE_RIGHT,10)
		if state=="focus":box.draw_center=false
		button.add_theme_stylebox_override(state,box)

extends PanelContainer
## Quiet cut-paper inset. Decoration remains independent of container measurements.
const Ink=preload("res://scripts/campaign/battle_ink.gd")
var accent:Color=Color("24c8ed")
func _ready() -> void:
	set_meta("recorte_decorated",true)
	theme_type_variation="RecorteEmptyPanel"
	var spacing:=StyleBoxEmpty.new()
	for side in [SIDE_LEFT,SIDE_RIGHT]:spacing.set_content_margin(side,12)
	for side in [SIDE_TOP,SIDE_BOTTOM]:spacing.set_content_margin(side,8)
	add_theme_stylebox_override("panel",spacing)
	resized.connect(queue_redraw)
func _draw() -> void:
	var rect:=Rect2(Vector2.ZERO,size)
	Ink.plate(self,rect,Color("102536"),Color("07151e"),12)
	var edge:=Ink.shape(rect,12)
	draw_line(edge[0]+Vector2(3,2),edge[1]-Vector2(4,-2),accent,3,true)
	draw_line(edge[2]-Vector2(2,2),edge[2]-Vector2(28,2),accent,3,true)

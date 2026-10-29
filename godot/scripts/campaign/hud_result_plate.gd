extends PanelContainer
## Recorte card from the approved unified HUD board. Decoration stays independent of measurements.
const Ink=preload("res://scripts/campaign/battle_ink.gd")
var accent:Color=Ink.Hud.CYAN
## Paper plates (place names, prompts, name stickers) carry dark text.
var paper:=false
func _ready() -> void:
	set_meta("recorte_decorated",true)
	theme_type_variation="RecorteEmptyPanel"
	var spacing:=StyleBoxEmpty.new()
	for side in [SIDE_LEFT,SIDE_RIGHT]:spacing.set_content_margin(side,12)
	for side in [SIDE_TOP,SIDE_BOTTOM]:spacing.set_content_margin(side,8)
	add_theme_stylebox_override("panel",spacing)
	resized.connect(queue_redraw)
func _draw() -> void:
	# Recorte card: ink (or paper) body, cut corner, solid shadow and a short accent tab.
	var rect:=Rect2(Vector2.ZERO,size)
	Ink.plate(self,rect,Ink.Hud.Tokens.PAPEL if paper else Ink.Hud.Tokens.TINTA,Ink.BLACK if accent==Ink.Hud.MUTED else accent,14)

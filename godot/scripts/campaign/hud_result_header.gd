extends Control
const Hud=preload("res://scripts/campaign/hud.gd")
const Ink=preload("res://scripts/campaign/battle_ink.gd")
var outcome:="won"
var left:=60.0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	z_index=5
func _draw() -> void:
	var title:="VITÓRIA!" if outcome=="won" else "DERROTA" if outcome=="lost" else "VOCÊ RECUOU"
	draw_texture_rect(Ink.brush(0),Rect2(left-30,0,650,108),false,Hud.CYAN if outcome=="won" else Hud.MUTED)
	draw_string_outline(Hud.display(),Vector2(left,86),title,HORIZONTAL_ALIGNMENT_LEFT,-1,76,5,Ink.BLACK)
	draw_string(Hud.display(),Vector2(left,86),title,HORIZONTAL_ALIGNMENT_LEFT,-1,76,Ink.WHITE)
	var subtitle:="RECOMPENSAS DO ENCONTRO" if outcome=="won" else "Seu parceiro está com você. Vamos de novo!" if outcome=="lost" else "Você escolheu voltar em segurança."
	Ink.plate(self,Rect2(left+4,102,470,34),Hud.INK,Hud.INK,8)
	draw_string(Hud.font(),Vector2(left+16,126),subtitle,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Hud.GOLD if outcome=="won" else Hud.PAPER)

extends Control
const Art=preload("res://scripts/ui_mural/result_art.gd")
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
const T=preload("res://scripts/campaign/ui_tokens.gd")
var outcome:="won"
var left:=60.0
var text_scale:=1.0
var blocked:=false
var context:="RECOMPENSAS DO ENCONTRO"
func _ready() -> void:mouse_filter=MOUSE_FILTER_IGNORE;z_index=5
func _draw() -> void:
	var extent:Vector2=get_parent().size
	var variant:="fled" if blocked else outcome
	var layout:=Art.layout(extent,text_scale,variant)
	Paper.begin(self);Art.draw(self,layout,variant)
	Paper.label(self,layout.safe,"NÃO SALVO" if blocked else "VITÓRIA!" if outcome=="won" else "DERROTA" if outcome=="lost" else "RECUO",layout.font,T.MURAL_INK,true,layout.safe)
	var subtitle:="Sua jornada aguarda uma nova tentativa de gravação." if blocked else context if outcome=="won" else "A linha rompeu. O Elo continua." if outcome=="lost" else "Você escolheu voltar em segurança."
	var slot:=Rect2(32,layout.rect.end.y+8,extent.x-64,T.label().get_height(roundi(18*text_scale)))
	Paper.label(self,slot,subtitle,roundi(18*text_scale),T.MURAL_PAPER,true,slot)

extends VBoxContainer
signal retry_requested
const Hud=preload("res://scripts/campaign/hud.gd")
var state:="loading"
var reduced_motion:=false
var message:=""
var caption:Label
var age:=0.0
func _ready() -> void:
	add_theme_constant_override("separation",18)
	caption=Label.new()
	caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_size_override("font_size",22)
	add_child(caption)
	caption.text=message if not message.is_empty() else "◆ ◇ ◇  Carregando…" if state=="loading" else "Não foi possível ler esta lista."
	if state!="loading":
		var retry:=Button.new()
		retry.text="Tentar de novo" if state=="error" else "Voltar"
		Hud.navigation_button(retry,true)
		retry.custom_minimum_size=Vector2(220,52)
		add_child(retry)
		retry.pressed.connect(func():retry_requested.emit())
func _process(delta:float) -> void:
	if state!="loading":return
	if reduced_motion:return
	age+=delta
	caption.text=["◆ ◇ ◇","◇ ◆ ◇","◇ ◇ ◆"][int(age*3)%3]+"  Carregando…"

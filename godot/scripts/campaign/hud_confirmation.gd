extends Control
## Centered system confirmation; narrative conversations retain their own layout.
signal confirmed
signal canceled
const Hud=preload("res://scripts/campaign/hud.gd")
var title:="Confirmar"
var dialog_text:=""
var ok_button_text:="Confirmar"
var cancel_button_text:="Cancelar"
var decline:Button
var accept:Button
var closed:=false
func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	z_index=90
	add_to_group("manga_dialogue")
	var previous:=get_viewport().gui_get_focus_owner()
	if previous!=null:
		var reference:WeakRef=weakref(previous)
		tree_exiting.connect(func():
			var target=reference.get_ref()
			if is_instance_valid(target) and target.is_inside_tree():Hud.focus_later(target))
	var shade:=ColorRect.new()
	shade.color=Color(Hud.INK,.86)
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(shade)
	var center:=CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	var card=load("res://scripts/campaign/hud_result_plate.gd").new()
	card.custom_minimum_size=Vector2(660,0)
	card.accent=Hud.GOLD
	center.add_child(card)
	var margin:=MarginContainer.new()
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,24)
	card.add_child(margin)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",22)
	margin.add_child(column)
	var heading:=Label.new()
	heading.text=title
	heading.add_theme_font_override("font",Hud.display())
	heading.add_theme_font_size_override("font_size",30)
	column.add_child(heading)
	var body:=Label.new()
	body.text=dialog_text
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x=580
	body.add_theme_font_size_override("font_size",20)
	column.add_child(body)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",32)
	column.add_child(row)
	decline=_button(cancel_button_text,row,func():_finish(false))
	accept=_button(ok_button_text,row,func():_finish(true))
	for button in [decline,accept]:
		var other:Button=accept if button==decline else decline
		for direction in ["focus_neighbor_left","focus_neighbor_right","focus_neighbor_top","focus_neighbor_bottom","focus_next","focus_previous"]:
			button.set(direction,button.get_path_to(other))
	Hud.focus_later(decline)
func _button(text:String,parent:Node,callback:Callable) -> Button:
	var space:=Hud.focus_space(parent)
	var button:=Button.new()
	button.text=text
	button.custom_minimum_size=Vector2(244,54)
	Hud.navigation_button(button,true)
	button.pressed.connect(callback)
	space.add_child(button)
	return button
func _finish(value:bool) -> void:
	if closed:return
	closed=true
	if value:confirmed.emit()
	else:canceled.emit()
func _unhandled_input(event:InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish(false)
func popup_centered(_extent:Vector2i=Vector2i.ZERO) -> void:
	show()
	Hud.focus_later(decline)

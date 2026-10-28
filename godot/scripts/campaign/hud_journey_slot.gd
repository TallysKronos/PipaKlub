extends "res://scripts/campaign/hud_result_plate.gd"
const Hud=preload("res://scripts/campaign/hud.gd")
signal selected
signal erase_requested
var inspection:Dictionary={}
var slot_id:="slot-1"
var available_for_new:=false
var action:Button
var erase:Button
var detail:Label
var timestamp:Label
var area_name:=""
var thumbnail:Texture2D
var partner_portrait:Texture2D
func caption(text:String,parent:Node,font_size:int=16) -> Label:
	var label:=Label.new()
	label.text=text
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	parent.add_child(label)
	return label
func _ready() -> void:
	super._ready()
	custom_minimum_size.y=150
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",20)
	add_child(row)
	var art:=TextureRect.new()
	art.texture=partner_portrait if partner_portrait!=null else Hud.icon("pipa",true)
	art.modulate=Color.WHITE if partner_portrait!=null else Hud.Tokens.TINTA_3
	art.custom_minimum_size=Vector2(112,112)
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(art)
	var text:=VBoxContainer.new()
	text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation",4)
	row.add_child(text)
	caption("JORNADA "+slot_id.trim_prefix("slot-").pad_zeros(2),text,14).theme_type_variation="RecorteAccentText"
	var valid:bool=inspection.status=="ok"
	var empty:bool=inspection.status=="missing"
	var snapshot:Dictionary=inspection.get("data",{})
	var player:Dictionary=snapshot.get("player",{})
	detail=caption(player.get("name","Uma nova história" if empty else "Jornada indisponível"),text,22)
	var partner_name:="Sem parceiro ainda"
	for partner in player.get("partners",[]):
		if partner.id==player.get("equippedPartnerId",""):partner_name=partner.get("personalName",partner.modelId)
	if valid:
		caption(area_name,text,17).add_theme_color_override("font_color",Hud.PAPER)
		var line:=HBoxContainer.new()
		line.add_theme_constant_override("separation",12)
		text.add_child(line)
		var partner_label:=caption("Parceiro · "+partner_name,line,15)
		partner_label.autowrap_mode=TextServer.AUTOWRAP_OFF
		var badge:=caption(" AUTO ",line,14)
		badge.autowrap_mode=TextServer.AUTOWRAP_OFF
		badge.add_theme_color_override("font_color",Hud.INK)
		var style:=StyleBoxFlat.new()
		style.bg_color=Hud.CYAN
		badge.add_theme_stylebox_override("normal",style)
		var played:="Tempo sem registro"
		if snapshot.has("playSeconds"):
			var minutes:=int(float(snapshot.playSeconds)/60)
			played="%dh %02dmin"%[minutes/60,minutes%60]+(" + histórico anterior" if snapshot.get("playTimePartial",false) else "")
		var seconds:int=snapshot.get("savedAt",inspection.get("modifiedAt",0))
		var date:Dictionary=Time.get_datetime_dict_from_unix_time(seconds)
		timestamp=caption("%s   /   %02d/%02d/%04d · %02d:%02d UTC"%[played,date.day,date.month,date.year,date.hour,date.minute],text,14)
		timestamp.add_theme_color_override("font_color",Hud.MUTED)
	else:caption("Espaço livre para sua próxima aventura." if empty else "Os arquivos foram preservados para recuperação.",text,16)
	if valid and thumbnail!=null:
		var place:=VBoxContainer.new()
		place.custom_minimum_size.x=144
		place.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		row.add_child(place)
		var scene_art:=TextureRect.new()
		scene_art.texture=thumbnail
		scene_art.custom_minimum_size=Vector2(144,78)
		scene_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		scene_art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		scene_art.mouse_filter=Control.MOUSE_FILTER_IGNORE
		place.add_child(scene_art)
		var place_caption:=caption("LOCAL ATUAL",place,12)
		place_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		place_caption.add_theme_color_override("font_color",Hud.MUTED)
	var commands:=VBoxContainer.new()
	commands.add_theme_constant_override("separation",8)
	commands.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	row.add_child(commands)
	action=Button.new()
	action.text="Começar" if empty else "Continuar" if valid else "Indisponível"
	action.tooltip_text="Jornada %s · Novo jogo"%slot_id.trim_prefix("slot-") if empty else "Jornada %s · Continuar — %s"%[slot_id.trim_prefix("slot-"),player.get("name","Kael")]
	Hud.navigation_button(action,true)
	action.custom_minimum_size=Vector2(168,52)
	action.disabled=not empty if available_for_new else not valid
	action.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	action.pressed.connect(func():selected.emit())
	var action_space:=Hud.focus_space(commands)
	action_space.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	action_space.add_child(action)
	if valid:
		erase=Button.new()
		erase.text="Excluir"
		Hud.navigation_button(erase,true)
		erase.custom_minimum_size=Vector2(112,36)
		erase.add_theme_font_size_override("font_size",16)
		erase.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		erase.pressed.connect(func():erase_requested.emit())
		var erase_space:=Hud.focus_space(commands)
		erase_space.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
		erase_space.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		erase_space.add_child(erase)

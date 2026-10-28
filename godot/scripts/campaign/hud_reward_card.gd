extends PanelContainer
const Hud = preload("res://scripts/campaign/hud.gd")
const ResultPlate=preload("res://scripts/campaign/hud_result_plate.gd")
const Model = preload("res://scripts/campaign/encounter_model.gd")
var summary: Dictionary = {}
var portrait_texture: AtlasTexture
var reduced_motion := false
var elapsed := 0.0
var shown := -1
var earned: Label
var levels: Label
var progress: ProgressBar
var progress_caption: Label
var level_sticker:Label
var loot_cards:Array[Control]=[]
var tamer_progress:ProgressBar
var tamer_start:=0
var tamer_before:=0
var tamer_after:=0

func caption(text:String,parent:Node,font_size:int=18,role:String="Label") -> Label:
	var label:=Label.new()
	label.text=text
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	label.theme_type_variation=role
	label.add_theme_color_override("font_outline_color",Hud.INK)
	label.add_theme_constant_override("outline_size",3)
	parent.add_child(label)
	return label

func portrait(texture:Texture2D,parent:Node,extent:Vector2) -> void:
	var art:=TextureRect.new()
	art.texture=texture
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size=extent
	art.size_flags_vertical=Control.SIZE_EXPAND_FILL
	parent.add_child(art)

func section_heading(text:String,parent:Node,gold:bool=false) -> void:
	var plate:=ResultPlate.new()
	plate.accent=Hud.GOLD if gold else Hud.CYAN
	parent.add_child(plate)
	caption(text,plate,18,"RecorteGoldText" if gold else "RecorteAccentText")

func meter(parent:Node,value:float,maximum:float) -> ProgressBar:
	var bar:=ProgressBar.new()
	bar.theme_type_variation="RecorteXPBar"
	bar.show_percentage=false
	bar.custom_minimum_size.y=10
	bar.max_value=maxf(1,maximum)
	bar.value=value
	parent.add_child(bar)
	return bar

func _ready() -> void:
	set_meta("recorte_decorated",true)
	theme_type_variation="RecorteEmptyPanel"
	theme=Hud.make_theme()
	add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	var art_layer:=Control.new()
	art_layer.show_behind_parent=true
	art_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(art_layer)
	var backing:=NinePatchRect.new()
	backing.name="IllustratedBacking"
	backing.texture=load("res://assets/campaign/battle-ink/result-frame-v1.png")
	backing.draw_center=true
	backing.patch_margin_left=380
	backing.patch_margin_right=380
	backing.patch_margin_top=180
	backing.patch_margin_bottom=170
	backing.mouse_filter=Control.MOUSE_FILTER_IGNORE
	art_layer.add_child(backing)
	backing.visible=summary.get("outcome","won")=="won"
	if not backing.visible:
		art_layer.draw.connect(func():
			var ink=preload("res://scripts/campaign/battle_ink.gd")
			ink.plate(art_layer,Rect2(Vector2.ZERO,size),Hud.INK,Hud.MUTED,20))
		resized.connect(art_layer.queue_redraw)
	# Fixed illustrated corners at half source scale; only the quiet middle grows.
	backing.scale=Vector2.ONE*.32
	var layout_backing:=func():
		backing.position=Vector2(-16,-45)
		backing.size=(size+Vector2(32,90))/.32
	resized.connect(layout_backing)
	layout_backing.call_deferred()
	var margins:=MarginContainer.new()
	for side in ["left","right","top","bottom"]:margins.add_theme_constant_override("margin_"+side,32)
	margins.add_theme_constant_override("margin_right",52)
	margins.add_theme_constant_override("margin_top",44)
	add_child(margins)
	var layout:=HBoxContainer.new()
	layout.add_theme_constant_override("separation",24)
	margins.add_child(layout)
	var tamer:=VBoxContainer.new()
	tamer.custom_minimum_size.x=210
	tamer.add_theme_constant_override("separation",6)
	layout.add_child(tamer)
	portrait(load("res://assets/campaign/portrait-kael.png"),tamer,Vector2(210,185))
	var trainer:Dictionary=summary.get("tamer",{})
	var total:int=trainer.get("after",0)
	var tamer_level:=1
	while tamer_level<100 and total>=20*tamer_level+3*tamer_level*tamer_level:tamer_level+=1
	var start:=20*(tamer_level-1)+3*(tamer_level-1)*(tamer_level-1)
	var next:=20*tamer_level+3*tamer_level*tamer_level
	var nameplate:=ResultPlate.new()
	nameplate.accent=Hud.GOLD
	tamer.add_child(nameplate)
	var info:=VBoxContainer.new()
	info.add_theme_constant_override("separation",4)
	nameplate.add_child(info)
	caption("TAMER · NV. %d"%tamer_level,info,14,"RecorteAccentText")
	caption(trainer.get("name","Kael"),info,22)
	caption("+%d XP"%trainer.get("xp",0),info,22,"RecorteGoldText")
	tamer_progress=meter(info,total-start,next-start)
	tamer_start=start
	tamer_before=int(trainer.get("before",total))
	tamer_after=total
	caption("%d / %d XP"%[total-start,next-start],info,14,"RecorteMutedText")
	var middle:=VBoxContainer.new()
	middle.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation",12)
	layout.add_child(middle)
	section_heading("SOULMONSTERS DO TIME",middle)
	var team:=HBoxContainer.new()
	team.add_theme_constant_override("separation",12)
	team.size_flags_vertical=Control.SIZE_EXPAND_FILL
	middle.add_child(team)
	var participants:Array=summary.get("team",[])
	for index in 3:
		var panel:=ResultPlate.new()
		panel.accent=[Hud.CYAN,Hud.CORAL,Hud.LINE][index] if summary.get("outcome","won")=="won" else Hud.MUTED
		panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		panel.rotation=[-.012,.014,-.012][index]
		team.add_child(panel)
		var slot:=VBoxContainer.new()
		slot.add_theme_constant_override("separation",8)
		panel.add_child(slot)
		if index>=participants.size() and index>0:
			caption("—",slot,40,"RecorteMutedText").size_flags_vertical=Control.SIZE_EXPAND_FILL
			caption("Espaço livre",slot,16,"RecorteMutedText")
			continue
		var entry:Dictionary=participants[index] if index<participants.size() else {}
		var picture:Texture2D=portrait_texture
		if index>0:
			var id:String={"basica":"basic-carcara","mata":"basic-mata-verde","azulao":"basic-azulao","raio":"basic-raio-de-sol"}.get(entry.get("modelId",""),entry.get("modelId","rabbito"))
			var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
			var art:Dictionary=data.combat.get(id,{})
			if not art.is_empty():
				var atlas:=AtlasTexture.new()
				atlas.atlas=load("res://assets/campaign/"+art.image)
				var frame:Dictionary=art.animations.idle[0]
				atlas.region=Rect2(frame.x,frame.y,frame.w,frame.h)
				picture=atlas
		if picture!=null:portrait(picture,slot,Vector2(130,180))
		else:caption("◇",slot,44,"RecorteAccentText").size_flags_vertical=Control.SIZE_EXPAND_FILL
		if index==0:
			levels=caption("",slot,20)
			earned=caption("",slot,22,"RecorteGoldText")
			progress=meter(slot,0,50)
			progress_caption=caption("",slot,14,"RecorteMutedText")
			level_sticker=caption("SUBIU DE NÍVEL",slot,14,"RecorteGoldText")
			level_sticker.visible=false
		else:
			caption(entry.get("personalName",entry.get("modelId","Parceiro")),slot,20)
			var xp:int=entry.get("xp",0)
			var level:int=Model.level_for_xp(xp)
			caption("Nv. %d"%level,slot,16,"RecorteMutedText")
			var base:=40*(level-1)+10*(level-1)*(level-1)
			var threshold:=40*level+10*level*level
			meter(slot,xp-base,threshold-base)
			caption("Sem participação",slot,14,"RecorteMutedText")
	caption(summary.get("notice","Seu progresso será guardado ao continuar."),middle,14,"RecorteMutedText")
	layout.add_child(VSeparator.new())
	var loot:=VBoxContainer.new()
	loot.custom_minimum_size.x=220
	loot.add_theme_constant_override("separation",16)
	layout.add_child(loot)
	section_heading("RECOMPENSAS",loot,true)
	caption("MOEDAS",loot,14,"RecorteMutedText")
	caption("+%d"%summary.get("coins",0),loot,32,"RecorteGoldText")
	if summary.get("stars",0)>0:caption("★".repeat(int(summary.stars))+" · %d estrelas"%summary.stars,loot,18,"RecorteGoldText")
	if summary.has("unlock"):caption(summary.unlock,loot,16,"RecorteAccentText")
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	loot.add_child(scroll)
	var items:=VBoxContainer.new()
	items.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	items.add_theme_constant_override("separation",12)
	scroll.add_child(items)
	for item in summary.get("items",[]):
		var card:=ResultPlate.new()
		card.accent=Hud.GOLD if item in summary.get("new_items",[]) else Hud.MUTED
		items.add_child(card)
		loot_cards.append(card)
		var column:=VBoxContainer.new()
		card.add_child(column)
		if item in summary.get("new_items",[]):caption("NOVO!",column,14,"RecorteGoldText")
		var row:=HBoxContainer.new()
		column.add_child(row)
		var item_id:String={"Rabiola de Mata verde":"rabiola-mata","Rabiola de Lacertubo":"rabiola-lacertubo","Rabiola de Carcará":"rabiola-basica","Rabiola de Raio de sol":"rabiola-raio"}.get(str(item),"")
		if not item_id.is_empty():portrait(Hud.item_art(item_id),row,Vector2(40,48))
		caption(str(item),row,16).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if summary.get("items",[]).is_empty():caption("Nenhum item obtido.",items,16,"RecorteMutedText")
	advance(0)

func advance(delta: float) -> void:
	elapsed += delta
	for index in loot_cards.size():
		loot_cards[index].modulate.a=clampf(elapsed/.08,0,1) if reduced_motion else clampf((elapsed-index*.09)/.18,0,1)
	var fraction := 1.0 if reduced_motion else 1.0 - pow(1.0 - clampf(elapsed / 1.1, 0, 1), 3)
	if is_instance_valid(tamer_progress):tamer_progress.value=maxi(0,roundi(lerpf(tamer_before,tamer_after,fraction))-tamer_start)
	var amount := roundi(summary.get("xp", 0) * fraction)
	if amount == shown: return
	shown = amount
	var total: int = summary.get("before", 0) + amount
	var level := Model.level_for_xp(total)
	var before_level := Model.level_for_xp(summary.get("before", 0))
	level_sticker.visible=level>before_level
	levels.text = "%s\nNv. %d" % [summary.get("name", "Seu parceiro"), before_level] + (" → %d" % level if level > before_level else "")
	earned.text = "+%d XP" % amount if summary.get("xp", 0) > 0 else "Sem XP"
	earned.theme_type_variation = "RecorteGoldText" if summary.get("xp", 0) > 0 else "RecorteMutedText"
	var base := 40 * (level - 1) + 10 * (level - 1) * (level - 1)
	var threshold := 40 * level + 10 * level * level
	progress.max_value = threshold - base
	progress.value = total - base if level < 50 else progress.max_value
	progress_caption.text = "%d / %d XP" % [total - base, threshold - base] if level < 50 else "Nível máximo"

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

const ITEM_IDS:={"Rabiola de Mata verde":"rabiola-mata","Rabiola de Lacertubo":"rabiola-lacertubo","Rabiola de Carcará":"rabiola-basica","Rabiola de Raio de sol":"rabiola-raio"}

# "NOVO!" / "NÍVEL!" ink splash sticker from the approved board.
func splash(parent:Node,text:String,at:Vector2) -> Control:
	var sticker:=Control.new()
	sticker.mouse_filter=Control.MOUSE_FILTER_IGNORE
	sticker.position=at
	sticker.size=Vector2(104,60)
	sticker.z_index=2
	sticker.draw.connect(func():
		sticker.draw_texture_rect(Hud.artwork("splat"),Rect2(Vector2(-4,-6),sticker.size+Vector2(8,12)),false,Hud.PAPER)
		sticker.draw_texture_rect(Hud.artwork("splat"),Rect2(Vector2.ZERO,sticker.size),false,Hud.INK)
		var font:=Hud.lettering()
		var width:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,26).x
		sticker.draw_string(font,Vector2((sticker.size.x-width)/2,39),text,HORIZONTAL_ALIGNMENT_LEFT,-1,26,Hud.PAPER))
	parent.add_child(sticker)
	return sticker

func card(parent:Node,accent:Color,heading:String,heading_role:String,expand:bool) -> VBoxContainer:
	var panel:=ResultPlate.new()
	panel.accent=accent
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL if expand else Control.SIZE_FILL
	panel.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	parent.add_child(panel)
	var margins:=MarginContainer.new()
	for side in ["left","right","top","bottom"]:margins.add_theme_constant_override("margin_"+side,10)
	panel.add_child(margins)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	margins.add_child(column)
	var title:=caption(heading,column,16,"Label" if heading_role=="RecorteCoralText" else heading_role)
	title.add_theme_font_override("font",Hud.font(true))
	if heading_role=="RecorteCoralText":title.add_theme_color_override("font_color",Hud.CORAL)
	return column

func _ready() -> void:
	# Approved unified board: no frame around the result. Kael stands on the arena with his
	# tamer card, a large card for what was earned, a compact team card and CONTINUAR.
	set_meta("recorte_decorated",true)
	theme_type_variation="RecorteEmptyPanel"
	theme=Hud.make_theme()
	add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	var won:bool=summary.get("outcome","won")=="won"
	var layout:=HBoxContainer.new()
	layout.add_theme_constant_override("separation",28)
	add_child(layout)
	var tamer:=Control.new()
	tamer.custom_minimum_size=Vector2(300,0)
	tamer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layout.add_child(tamer)
	var hero:=TextureRect.new()
	hero.texture=load("res://assets/campaign/portrait-kael.png")
	hero.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hero.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hero.offset_top=-40
	hero.mouse_filter=Control.MOUSE_FILTER_IGNORE
	tamer.add_child(hero)
	var trainer:Dictionary=summary.get("tamer",{})
	var total:int=trainer.get("after",0)
	var tamer_level:=1
	while tamer_level<100 and total>=20*tamer_level+3*tamer_level*tamer_level:tamer_level+=1
	var start:=20*(tamer_level-1)+3*(tamer_level-1)*(tamer_level-1)
	var next:=20*tamer_level+3*tamer_level*tamer_level
	var nameplate:=ResultPlate.new()
	nameplate.accent=Hud.GOLD
	nameplate.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	nameplate.offset_top=-118
	nameplate.offset_right=-20
	tamer.add_child(nameplate)
	var info:=VBoxContainer.new()
	info.add_theme_constant_override("separation",4)
	nameplate.add_child(info)
	caption("TAMER · NV. %d"%tamer_level,info,15,"RecorteAccentText").add_theme_font_override("font",Hud.font(true))
	caption(trainer.get("name","Kael"),info,24).add_theme_font_override("font",Hud.display())
	var tamer_row:=HBoxContainer.new()
	info.add_child(tamer_row)
	caption("+%d XP"%trainer.get("xp",0),tamer_row,20,"RecorteGoldText").size_flags_horizontal=Control.SIZE_EXPAND_FILL
	caption("%d / %d"%[total-start,next-start],tamer_row,15,"RecorteMutedText").autowrap_mode=TextServer.AUTOWRAP_OFF
	tamer_progress=meter(info,total-start,next-start)
	tamer_start=start
	tamer_before=int(trainer.get("before",total))
	tamer_after=total
	var items:Array=summary.get("items",[])
	var center:=card(layout,Hud.CORAL if won else Hud.MUTED,("NOVA RABIOLA" if items.size()==1 and "Rabiola" in str(items[0]) else "RECOMPENSAS") if not items.is_empty() else ("TIME" if won else "NÃO FOI DESSA VEZ"),"RecorteCoralText" if won else "RecorteMutedText",true)
	if not items.is_empty():
		var first:=HBoxContainer.new()
		first.add_theme_constant_override("separation",18)
		center.add_child(first)
		loot_cards.append(first)
		var item_id:String=ITEM_IDS.get(str(items[0]),"")
		portrait(Hud.item_art(item_id) if not item_id.is_empty() else Hud.icon("bag"),first,Vector2(170,170))
		var words:=VBoxContainer.new()
		words.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		words.alignment=BoxContainer.ALIGNMENT_CENTER
		first.add_child(words)
		caption(str(items[0]),words,30).add_theme_font_override("font",Hud.display())
		caption("Leve ao ateliê do Sr. Assis para montar um novo parceiro." if "Rabiola" in str(items[0]) else "Guardado na mochila.",words,17,"RecorteMutedText")
		if items[0] in summary.get("new_items",[]):
			# A Node2D holder keeps the sticker out of the PanelContainer's layout.
			var plate:Control=center.get_parent().get_parent()
			var holder:=Node2D.new()
			plate.add_child(holder)
			splash(holder,"NOVO!",Vector2.ZERO)
			var place:=func():holder.position=Vector2(plate.size.x-92,-30)
			plate.resized.connect(place)
			place.call_deferred()
		for item in items.slice(1):
			var row:=HBoxContainer.new()
			center.add_child(row)
			loot_cards.append(row)
			var other_id:String=ITEM_IDS.get(str(item),"")
			if not other_id.is_empty():portrait(Hud.item_art(other_id),row,Vector2(40,48))
			caption(str(item)+("  · NOVO!" if item in summary.get("new_items",[]) else ""),row,17).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var coins:int=summary.get("coins",0)
	var extras:=center if not items.is_empty() else null
	var team_parent:Node=layout if not items.is_empty() else null
	var team:VBoxContainer=card(team_parent,Hud.CYAN,"TIME","RecorteAccentText",false) if team_parent!=null else center
	if team_parent!=null:team.get_parent().get_parent().custom_minimum_size.x=320
	else:extras=team
	var participants:Array=summary.get("team",[])
	for index in clampi(participants.size(),1,3):
		var entry:Dictionary=participants[index] if index<participants.size() else {}
		var row:=HBoxContainer.new()
		row.add_theme_constant_override("separation",14)
		team.add_child(row)
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
		if picture!=null:portrait(picture,row,Vector2(72,72) if team_parent!=null else Vector2(150,150))
		var stats:=VBoxContainer.new()
		stats.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		stats.alignment=BoxContainer.ALIGNMENT_CENTER
		row.add_child(stats)
		if index==0:
			levels=caption("",stats,22)
			levels.add_theme_font_override("font",Hud.display())
			earned=caption("",stats,20,"RecorteGoldText")
			progress=meter(stats,0,50)
			progress_caption=caption("",stats,14,"RecorteMutedText")
			level_sticker=caption("NÍVEL!",stats,15,"RecorteGoldText")
			level_sticker.visible=false
		else:
			caption(entry.get("personalName",entry.get("modelId","Parceiro")),stats,20).add_theme_font_override("font",Hud.display())
			var xp:int=entry.get("xp",0)
			var level:int=Model.level_for_xp(xp)
			var base:=40*(level-1)+10*(level-1)*(level-1)
			var threshold:=40*level+10*level*level
			meter(stats,xp-base,threshold-base)
			caption("NV. %d · sem participação"%level,stats,14,"RecorteMutedText")
	# Free slots become small dashed tags instead of empty cards.
	var free:=3-clampi(participants.size(),1,3)
	if free>0 and team_parent!=null:
		var tags:=HBoxContainer.new()
		tags.add_theme_constant_override("separation",10)
		team.add_child(tags)
		for slot in free:
			var tag:=Label.new()
			tag.text="VAGA LIVRE"
			tag.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			tag.custom_minimum_size=Vector2(128,40)
			tag.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			tag.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
			tag.theme_type_variation="RecorteMutedText"
			tag.add_theme_font_override("font",Hud.font(true))
			tag.add_theme_font_size_override("font_size",14)
			tag.draw.connect(func():
				var r:=Rect2(Vector2.ZERO,tag.size)
				for side in [[r.position,Vector2(r.end.x,r.position.y)],[Vector2(r.position.x,r.end.y),r.end],[r.position,Vector2(r.position.x,r.end.y)],[Vector2(r.end.x,r.position.y),r.end]]:tag.draw_dashed_line(side[0],side[1],Hud.Tokens.TINTA_3,2,6))
			tags.add_child(tag)
	if coins>0:caption("+%d MOEDAS"%coins,extras,20,"RecorteGoldText").add_theme_font_override("font",Hud.font(true))
	if summary.get("stars",0)>0:caption("★".repeat(int(summary.stars))+" · %d estrelas"%summary.stars,extras,18,"RecorteGoldText")
	if summary.has("unlock"):caption(summary.unlock,extras,16,"RecorteAccentText")
	var notice:String=summary.get("notice","")
	if not notice.is_empty():caption(notice,extras,15,"RecorteMutedText")
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
	levels.text = "%s · Nv. %d" % [summary.get("name", "Seu parceiro"), before_level] + (" → %d" % level if level > before_level else "")
	earned.text = "+%d XP" % amount if summary.get("xp", 0) > 0 else "Sem XP"
	earned.theme_type_variation = "RecorteGoldText" if summary.get("xp", 0) > 0 else "RecorteMutedText"
	var base := 40 * (level - 1) + 10 * (level - 1) * (level - 1)
	var threshold := 40 * level + 10 * level * level
	progress.max_value = threshold - base
	progress.value = total - base if level < 50 else progress.max_value
	progress_caption.text = "%d / %d XP" % [total - base, threshold - base] if level < 50 else "Nível máximo"

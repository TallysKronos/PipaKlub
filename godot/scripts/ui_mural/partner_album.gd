extends Control
## Read-only presentation. Equipping and care remain existing campaign operations.
signal closed
signal equip_requested(id:String)
signal care_requested(id:String)
signal emblems_requested
signal retry_requested
const T=preload("res://scripts/campaign/ui_tokens.gd")
const Mural=preload("res://scripts/ui_mural/mural_theme.gd")
const Surface=preload("res://scripts/ui_mural/menu_surface.gd")
const Option=preload("res://scripts/ui_mural/dialogue_option.gd")
const Tag=preload("res://scripts/ui_mural/hanging_tag.gd")
const Levels=preload("res://scripts/campaign/partner_levels.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
const Hud=preload("res://scripts/campaign/hud.gd")
var player:Dictionary={}
var content:Dictionary={}
var can_care:=false
var text_scale:=1.0
var mode:="varal"
var selected:=0
var entries:Array=[]
var entry_buttons:Array[Button]=[]
var tabs:Array[Button]=[]
var list:VBoxContainer
var detail:VBoxContainer
var description:Label
var body:HBoxContainer
var list_scroll:ScrollContainer
var detail_scroll:ScrollContainer
var back:Button
var actions:Array[Button]=[]
var catalog:Array=[]
var page_title:Label
var header_icon:TextureRect
var detail_surface:PanelContainer
var action_bar:HBoxContainer
var hero_art:TextureRect
var load_state:="ready"
func _init() -> void:set_meta("owns_ui_theme",true)
func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT);mouse_filter=MOUSE_FILTER_STOP
	text_scale=maxf(text_scale,Mural.text_scale_for(self));Mural.install(self)
	catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/mural-catalog.json"))
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,24)
	add_child(margin)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);margin.add_child(column)
	var heading:=HBoxContainer.new();column.add_child(heading)
	var icon:=TextureRect.new();icon.texture=Mural.icon("varal");icon.custom_minimum_size=Vector2(72,72);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;heading.add_child(icon)
	header_icon=icon;page_title=copy("Laços de papel",heading,32,T.MURAL_PAPER);page_title.size_flags_horizontal=SIZE_EXPAND_FILL
	var nav:=HBoxContainer.new();nav.add_theme_constant_override("separation",12);column.add_child(nav)
	for pair in [["Varal","varal"],["Pipa Dex","dex"],["Evolução","evolution"],["Emblemas","emblems"]]:
		var tab:=button(pair[0],nav,func():
			if pair[1]=="emblems":emblems_requested.emit()
			else:set_mode(pair[1]))
		tab.size_flags_horizontal=SIZE_EXPAND_FILL;tabs.append(tab)
		tab.disabled=pair[1]=="emblems" and not preload("res://scripts/campaign/pipeiro_identity.gd").issued(player)
	description=copy("",column,18,T.MURAL_PAPER)
	body=HBoxContainer.new();body.size_flags_vertical=SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",20);column.add_child(body)
	list_scroll=ScrollContainer.new();list_scroll.follow_focus=true;list_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;body.add_child(list_scroll)
	list=VBoxContainer.new();list.size_flags_horizontal=SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",12);list_scroll.add_child(list)
	var paper:=Surface.new();paper.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_child(paper);detail_surface=paper
	detail_scroll=ScrollContainer.new();detail_scroll.follow_focus=true;detail_scroll.focus_mode=FOCUS_ALL;detail_scroll.gui_input.connect(_detail_input);detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;paper.add_child(detail_scroll)
	detail_scroll.resized.connect(_fit_hero)
	detail=VBoxContainer.new();detail.size_flags_horizontal=SIZE_EXPAND_FILL;detail.add_theme_constant_override("separation",14);detail_scroll.add_child(detail)
	action_bar=HBoxContainer.new();action_bar.add_theme_constant_override("separation",12);column.add_child(action_bar)
	var footer:=HBoxContainer.new();column.add_child(footer)
	back=button("Voltar ao lobby",footer,func():closed.emit());back.custom_minimum_size.x=260
	copy("Tab / ombros · mudar seção",footer,17,T.MURAL_MINT).size_flags_horizontal=SIZE_EXPAND_FILL
	resized.connect(_layout);_layout();set_mode(mode)
	Hud.focus_later(entry_buttons[0] if not entry_buttons.is_empty() else tabs[0])
func _layout() -> void:
	if is_instance_valid(list_scroll):list_scroll.custom_minimum_size.x=minf(320*text_scale,size.x*.34)
func _fit_hero() -> void:
	if mode=="varal" and is_instance_valid(hero_art) and is_instance_valid(detail_scroll):hero_art.custom_minimum_size=Vector2(minf(180,detail_scroll.size.x*.4),clampf(detail_scroll.size.y-4,80,180))
func copy(value:String,parent:Node,font:int,color:Color=T.MURAL_INK) -> Label:
	var label:=Label.new();label.text=value;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_override("font",T.label() if font>=24 else T.text());label.add_theme_font_size_override("font_size",roundi(font*text_scale))
	if mode=="varal" and is_instance_valid(detail) and (parent==detail or detail.is_ancestor_of(parent)):
		if color==T.MURAL_INK:color=T.MURAL_PAPER
		elif color==T.MURAL_TEAL:color=T.MURAL_MINT
	label.add_theme_color_override("font_color",color);parent.add_child(label);return label
func button(value:String,parent:Node,callback:Callable) -> Button:
	var result:=Option.new();result.text=value;result.text_scale=text_scale;result.density=.2;result.font_base=20;result.pressed.connect(callback);parent.add_child(result);return result
func set_mode(value:String) -> void:
	mode=value;selected=0;entries.clear();entry_buttons.clear()
	detail_surface.family={"varal":"cloth","dex":"dex","evolution":"evolution"}[mode]
	page_title.text={"varal":"Varal dos seus Elos","dex":"Pipa Dex","evolution":"Evolução do Elo"}.get(mode,"")
	header_icon.texture=Mural.icon(mode)
	for child in list.get_children():child.free()
	for tab in tabs:
		tab.selected=tab.text=={"varal":"Varal","dex":"Pipa Dex","evolution":"Evolução"}.get(mode,"")
		if is_instance_valid(tab.backing):tab.backing.queue_redraw()
	if mode=="dex":
		entries=catalog.duplicate(true)
		description.text="Registros da jornada · %d / %d espécies conhecidas"%[catalog.filter(func(entry):return known(entry.model)).size(),catalog.size()]
	else:
		entries=player.get("partners",[]).duplicate(true)
		description.text="Escolha um parceiro para acompanhar seu progresso." if mode=="evolution" else "Seu Varal · %d parceiros · escolha quem voa ao seu lado"%entries.size()
	for index in entries.size():
		var entry:Dictionary=entries[index]
		var name:String=entry.get("name","") if mode=="dex" else str(entry.get("personalName",display_name(entry.modelId)))
		if mode=="dex" and not known(entry.model):name="??? · registro %02d"%(index+1)
		elif mode!="dex":name+=" · Nv. %d"%Levels.level_for_xp(entry.get("xp",0))
		var option:Button
		if mode=="varal":option=Tag.new();option.text=name;option.text_scale=text_scale;option.pressed.connect(select_entry.bind(index));list.add_child(option)
		else:option=button(name,list,select_entry.bind(index))
		entry_buttons.append(option)
		option.focus_entered.connect(select_entry.bind(index));option.tooltip_text=name
	if entries.is_empty():
		clear_detail();copy("O primeiro Elo ainda está por vir.",detail,28);copy("Continue sua jornada com o professor para encontrar seu primeiro parceiro.",detail,20)
	else:select_entry(0)
	if load_state!="ready" and mode=="varal":
		for child in list.get_children():child.free()
		entry_buttons.clear();clear_detail()
		copy("Consultando seu Varal…" if load_state=="loading" else "Não foi possível ler seu Varal.",detail,26)
		if load_state!="loading":actions.append(button("Tentar novamente",detail,func():retry_requested.emit()))
func known(model:String) -> bool:
	return model in player.get("sightings",[]) or acquired(model)
func acquired(model:String) -> bool:
	return model in player.get("acquiredModels",[]) or player.get("partners",[]).any(func(partner):return partner.modelId==model)
func display_name(model:String) -> String:
	for entry in catalog:
		if entry.model==model:return entry.name
	return model
func clear_detail() -> void:
	actions.clear()
	hero_art=null
	if is_instance_valid(action_bar):
		for child in action_bar.get_children():child.free()
		action_bar.hide()
	for child in detail.get_children():child.free()
	detail_scroll.scroll_vertical=0
func select_entry(index:int) -> void:
	selected=index;clear_detail()
	for i in entry_buttons.size():
		entry_buttons[i].selected=i==index
		if is_instance_valid(entry_buttons[i].backing):entry_buttons[i].backing.queue_redraw()
	var entry:Dictionary=entries[index]
	var model:String=entry.model if mode=="dex" else entry.modelId
	if mode=="dex" and not known(model):
		copy("Registro %02d"%(index+1),detail,30);copy("Uma história por descobrir",detail,24)
		copy("Explore Kronasta. As espécies que encontrar serão registradas aqui.",detail,20);return
	var partner_name:String=entry.get("name",display_name(model)) if mode=="dex" else entry.get("personalName",display_name(model))
	if mode!="varal":copy(partner_name,detail,30)
	var hero:=HBoxContainer.new();hero.add_theme_constant_override("separation",16);detail.add_child(hero)
	var art_id:String={"basica":"basic-carcara","mata":"basic-mata-verde","azulao":"basic-azulao","raio":"basic-raio-de-sol"}.get(model,model)
	if content.get("combat",{}).has(art_id):
		var art:=TextureRect.new();art.texture=preload("res://scripts/campaign/battle_ink.gd").portrait(load("res://assets/campaign/"+content.combat[art_id].image),art_id);art.custom_minimum_size=Vector2(180,180) if mode=="varal" else Vector2(112,128);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;hero.add_child(art)
		if mode=="varal":hero_art=art;art.size_flags_vertical=SIZE_SHRINK_BEGIN;_fit_hero.call_deferred()
		if mode=="varal" and preload("res://scripts/campaign/mount_quest.gd").capable(entry):
			var badge:=TextureRect.new();badge.name="MountCapability";badge.texture=load("res://assets/ui/mount-capability.svg");badge.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;badge.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;badge.size=Vector2(32,32);badge.tooltip_text="Pode ser montado · requer ao menos 1 HP e Armação intacta" if preload("res://scripts/campaign/mount_quest.gd").healthy(entry) else "Montaria derrotada · repare antes de montar";art.add_child(badge)
			if not preload("res://scripts/campaign/mount_quest.gd").healthy(entry):badge.modulate=Color(.45,.45,.45)
	var summary:=VBoxContainer.new();summary.size_flags_horizontal=SIZE_EXPAND_FILL;summary.add_theme_constant_override("separation",6);hero.add_child(summary)
	if mode=="varal":copy(partner_name,summary,28)
	if mode=="dex":
		copy("Elo formado" if acquired(model) else "Avistado",summary,20,T.MURAL_TEAL)
		if not str(entry.get("habitat","")).is_empty():copy(entry.habitat,detail,22)
		for paragraph in entry.get("story",[]):copy(paragraph,detail,20)
		if not str(entry.get("note","")).is_empty():copy(entry.note,detail,18)
		return
	var xp:int=entry.get("xp",0)
	var level:=Levels.level_for_xp(xp)
	copy("Nv. %d · %s"%[level,"Parceiro ativo" if entry.id==player.get("equippedPartnerId","") else "No seu Varal"],summary,18,T.MURAL_TEAL)
	var before:=Levels.xp_for_level(level)
	var threshold:=Levels.xp_for_level(level+1) if level<Levels.MAX_LEVEL else before
	if mode=="evolution":
		if level<Levels.MAX_LEVEL:meter("XP do nível",xp-before,threshold-before,summary)
		else:copy("Nível máximo · 50",summary,20,T.MURAL_TEAL)
		var track:=preload("res://scripts/ui_mural/elo_track.gd").new();track.level=level;track.text_scale=text_scale;detail.add_child(track)
		copy("Nível máximo alcançado" if level==Levels.MAX_LEVEL else "Próximo marco · Nv. %d\nFaltam %d XP"%[level+1,threshold-xp],detail,24)
		copy("Este parceiro mantém sua forma ao ganhar níveis. Linha, força e resistência acompanham seu progresso.",detail,20)
		var stats:Dictionary=preload("res://scripts/campaign/encounter_model.gd").stats(level,entry.get("craftBonus",0))
		copy("Linha base · %d\nPotência · %.0f%%\nResistência · %.0f%%"%[stats.line,stats.attack*100,stats.defense*100],detail,20)
		return
	var condition:Dictionary=entry.get("condition",{"line":100,"structure":100})
	meter("Linha",condition.line,100,summary);meter("Armação",condition.structure,100,summary)
	if preload("res://scripts/campaign/mount_quest.gd").capable(entry):copy("Montaria · pronta para montar" if preload("res://scripts/campaign/mount_quest.gd").healthy(entry) else "Montaria · precisa de cuidados",detail,20,T.MURAL_TEAL)
	action_bar.show()
	var spacer:=Control.new();spacer.size_flags_horizontal=SIZE_EXPAND_FILL;action_bar.add_child(spacer)
	var equip:=Tag.new();equip.text="Em voo" if entry.id==player.get("equippedPartnerId","") else "Voar juntos";equip.text_scale=text_scale;equip.custom_minimum_size.x=260;equip.pressed.connect(func():equip_requested.emit(entry.id));action_bar.add_child(equip);equip.disabled=entry.id==player.get("equippedPartnerId","");actions.append(equip)
	var care:=Tag.new();care.text="Cuidar";care.text_scale=text_scale;care.custom_minimum_size.x=240;care.pressed.connect(func():care_requested.emit(entry.id));action_bar.add_child(care);care.disabled=not can_care;actions.append(care)
	if not can_care:copy("Os cuidados ficam disponíveis durante a exploração.",detail,18)
func meter(title:String,value:float,maximum:float,parent:Node) -> void:
	copy("%s · %d / %d"%[title,value,maximum],parent,16 if mode=="varal" else 18)
	if mode=="varal":
		var thread:=preload("res://scripts/ui_mural/thread_meter.gd").new();thread.value=value;thread.maximum=maximum;thread.color=T.MURAL_SUN if title=="Armação" else T.MURAL_MINT;parent.add_child(thread);return
	var bar:=ProgressBar.new();bar.max_value=maximum;bar.value=value;bar.show_percentage=false;bar.custom_minimum_size.y=12
	var fill:=StyleBoxFlat.new();fill.bg_color=T.MURAL_MINT if mode=="varal" else T.MURAL_TEAL;bar.add_theme_stylebox_override("fill",fill)
	var track:=StyleBoxFlat.new();track.bg_color=T.alpha(T.MURAL_PAPER if mode=="varal" else T.MURAL_INK,.2);bar.add_theme_stylebox_override("background",track);parent.add_child(bar)
func _input(event:InputEvent) -> void:
	Controls.observe(event)
	if Controls.cancel(event) or event.is_action_pressed("ui_cancel"):get_viewport().set_input_as_handled();closed.emit()
	elif (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_TAB) or (event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER]):
		var direction:=(-1 if event.shift_pressed else 1) if event is InputEventKey else (1 if event.button_index==JOY_BUTTON_RIGHT_SHOULDER else -1)
		var modes:=["varal","dex","evolution"];set_mode(modes[posmod(modes.find(mode)+direction,3)]);tabs[modes.find(mode)].grab_focus();get_viewport().set_input_as_handled()
func _detail_input(event:InputEvent) -> void:
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
		detail_scroll.scroll_vertical+=roundi(64*text_scale)*(1 if event.is_action_pressed("ui_down") else -1);detail_scroll.accept_event()
	elif event.is_action_pressed("ui_left") and not entry_buttons.is_empty():entry_buttons[selected].grab_focus();detail_scroll.accept_event()
func _unhandled_input(_event:InputEvent) -> void:get_viewport().set_input_as_handled()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),T.MURAL_GROUND)
	for y in range(24,int(size.y),36):draw_line(Vector2(0,y),Vector2(size.x,y),T.alpha(T.MURAL_MINT,.04),1)

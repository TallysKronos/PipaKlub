extends Control
## One quiet, discovery-safe overlay for all campaign exploration scenes.
signal chosen(action:String)
const Hud=preload("res://scripts/campaign/hud.gd")
const T=preload("res://scripts/campaign/ui_tokens.gd")
const Mural=preload("res://scripts/ui_mural/mural_theme.gd")
const Ink=preload("res://scripts/campaign/battle_ink.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
const Locomotion = preload("res://scripts/campaign/locomotion.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
var text_scale:=1.0
var map_button:Button
var interaction_key:Label
func _init() -> void:set_meta("owns_ui_theme",true)
var subject:Node2D
var area_name:=""
var player_data:Dictionary={}
var area_age:=0.0
var objective_age:=0.0
var idle_age:=0.0
var coin_age:=10.0
var pointer_mode:=false
var objective:Label
var prompt:Label
var area:Label
var coins:Label
var area_panel:PanelContainer
var objective_panel:PanelContainer
var prompt_panel:PanelContainer
var partner_panel:Control
var tools:HBoxContainer
var run_button:Button
var mount_button:Button
var map:Control
var notices:Array[Dictionary]=[]
var notice_stack:VBoxContainer
var partner:Dictionary={}
var portrait:Texture2D
var _objective_text:=""
var _prompt_text:=""
var _portrait_id:=""
var _sample:=0.0
func plate(parent:Node,_accent:Color=Hud.MUTED) -> PanelContainer:
	var panel:=PanelContainer.new()
	panel.theme_type_variation="MuralHudPanel"
	panel.mouse_filter=MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel
func label(parent:Node,font_size:int=16) -> Label:
	var text:=Label.new()
	text.add_theme_font_size_override("font_size",roundi(font_size*text_scale))
	text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	text.mouse_filter=MOUSE_FILTER_IGNORE
	parent.add_child(text)
	return text
func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_IGNORE
	text_scale=maxf(text_scale,Mural.text_scale_for(self))
	Mural.install(self)
	add_to_group("exploration_hud")
	area_panel=plate(self)
	area_panel.theme_type_variation="MuralHudSunPanel"
	area=label(area_panel,24)
	area.text=area_name
	area.add_theme_font_override("font",T.lettering())
	objective_panel=plate(self,Hud.CORAL)
	objective=label(objective_panel)
	objective.max_lines_visible=2
	objective_panel.hide()
	partner_panel=Control.new()
	partner_panel.mouse_filter=MOUSE_FILTER_IGNORE
	add_child(partner_panel)
	partner_panel.draw.connect(_draw_partner)
	coins=label(self)
	coins.add_theme_color_override("font_color",T.MURAL_PAPER)
	coins.add_theme_color_override("font_outline_color",T.MURAL_INK)
	coins.add_theme_constant_override("outline_size",4)
	prompt_panel=plate(self,Hud.CYAN)
	var row:=HBoxContainer.new()
	row.mouse_filter=MOUSE_FILTER_IGNORE
	prompt_panel.add_child(row)
	interaction_key=label(row,18);interaction_key.text=Controls.prompt("interact")
	interaction_key.size_flags_vertical=SIZE_EXPAND_FILL
	prompt=label(row)
	prompt.size_flags_vertical=SIZE_EXPAND_FILL
	prompt.max_lines_visible=2
	prompt.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	prompt.size_flags_horizontal=SIZE_EXPAND_FILL
	prompt_panel.hide()
	notice_stack=VBoxContainer.new()
	notice_stack.mouse_filter=MOUSE_FILTER_IGNORE
	add_child(notice_stack)
	notice_stack.minimum_size_changed.connect(func():notice_stack.size.y=notice_stack.get_combined_minimum_size().y)
	tools=HBoxContainer.new()
	add_child(tools)
	for option in [["Equipe","collection","team"],["Bolsa","bag","bag"],["Menu","menu","settings"]]:
		var button:=Button.new()
		button.text=option[0]
		button.icon=Mural.icon(option[2]);button.expand_icon=true
		button.add_theme_constant_override("icon_max_width",32)
		button.add_theme_font_size_override("font_size",roundi(18*text_scale))
		button.custom_minimum_size=Vector2(104,48)
		button.pressed.connect(func():chosen.emit(option[1]))
		tools.add_child(button)
	resized.connect(_layout)
	run_button=Button.new()
	run_button.name="RunToggle"
	run_button.toggle_mode=true
	run_button.focus_mode=Control.FOCUS_NONE
	run_button.custom_minimum_size=Vector2(144,44)
	run_button.add_theme_font_size_override("font_size",roundi(18*text_scale))
	run_button.tooltip_text="Segure Shift para correr ou clique para alternar. No controle: L3."
	run_button.pressed.connect(func():
		if is_instance_valid(subject) and subject.has_method("toggle_run"):subject.toggle_run())
	add_child(run_button)
	mount_button=Button.new();mount_button.name="MountToggle";mount_button.focus_mode=Control.FOCUS_NONE
	mount_button.custom_minimum_size=Vector2(144,44);mount_button.add_theme_font_size_override("font_size",roundi(18*text_scale))
	mount_button.tooltip_text="Apito de Elo · B no teclado / direcional para cima no controle."
	mount_button.pressed.connect(func():
		if is_instance_valid(subject) and subject.has_method("toggle_mount"):subject.toggle_mount())
	add_child(mount_button)
	map_button=Button.new();map_button.text=Controls.prompt("map")+" · Kronasta"
	map_button.custom_minimum_size=Vector2(190,44);map_button.add_theme_font_size_override("font_size",roundi(18*text_scale))
	map_button.pressed.connect(func():chosen.emit("map"));add_child(map_button)
	refresh(player_data)
	_layout()
func refresh(value:Dictionary) -> void:
	if int(value.get("coins",0))!=int(player_data.get("coins",0)):coin_age=0
	player_data=value.duplicate(true)
	partner={}
	for entry in player_data.get("partners",[]):
		if entry.id==player_data.get("equippedPartnerId",""):partner=entry
	var id:String=partner.get("modelId","")
	if id!=_portrait_id:
		portrait=null
		_portrait_id=id
	if not id.is_empty() and portrait==null:
		_portrait_id=id
		var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
		var art:Dictionary=data.combat.get({"basica":"basic-carcara","mata":"basic-mata-verde","azulao":"basic-azulao","raio":"basic-raio-de-sol"}.get(id,id),{})
		if not art.is_empty():
			var texture:=AtlasTexture.new()
			texture.atlas=load("res://assets/campaign/"+art.image)
			var frame:Dictionary=art.animations.idle[0]
			texture.region=Rect2(frame.x,frame.y,frame.w,frame.h)
			portrait=texture
	partner_panel.queue_redraw()
func reveal_objective() -> void:
	objective_age=0
	coin_age=0
func push_notice(message:String,kind:String="saved") -> void:
	var panel:=plate(notice_stack,{"saved":Hud.LINE,"item":Hud.GOLD,"error":Hud.CORAL}.get(kind,Hud.MUTED))
	var note:=label(panel);note.text=message
	note.theme_type_variation="MuralErrorText" if kind=="error" else "MuralSuccessText" if kind=="saved" else "MuralBody"
	if kind=="error":note.text="! "+message
	notices.append({"panel":panel,"age":0.0})
	while notices.size()>3:notices.pop_front().panel.queue_free()
	_layout()
func _input(event:InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventScreenTouch:
		pointer_mode=true
		idle_age=0
	elif event is InputEventKey or event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value)>.3):
		pointer_mode=false
		idle_age=0
func _process(delta:float) -> void:
	area_age+=delta
	objective_age+=delta
	idle_age+=delta
	coin_age+=delta
	if objective.text!=_objective_text:
		_objective_text=objective.text
		objective_age=0
	if prompt.text!=_prompt_text:
		_prompt_text=prompt.text
	for entry in notices:entry.age+=delta
	for index in range(notices.size()-1,-1,-1):
		if notices[index].age>=3:
			notices[index].panel.queue_free()
			notices.remove_at(index)
	_sample+=delta
	if _sample>=.1:
		_sample=0
		_layout()
func _layout() -> void:
	if not is_instance_valid(area):return
	var compact:=area_age>=3
	var margin:=24.0
	var font_size:=roundi((16 if compact else 24)*text_scale)
	area.add_theme_font_size_override("font_size",font_size)
	var needed:=T.lettering().get_string_size(area.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x+52
	area_panel.position=Vector2(margin,margin)
	area_panel.size=Vector2(clampf(needed,240 if compact else 280,minf(560,size.x*.55)),64)
	area_panel.size.y=maxf(64,area_panel.get_combined_minimum_size().y)
	if is_instance_valid(map):
		map.offset_left=-144;map.offset_right=-24;map.offset_top=24;map.offset_bottom=144
	map_button.text=Controls.prompt("map")+" · Mapa"
	map_button.visible=pointer_mode and not Controls.gamepad and idle_age<4
	map_button.size=Vector2(maxf(190,190*text_scale),48)
	map_button.position=Vector2(size.x-map_button.size.x-margin,180)
	tools.visible=pointer_mode and not Controls.gamepad and idle_age<4
	tools.position=Vector2(size.x-tools.get_combined_minimum_size().x-margin,244)
	tools.size=tools.get_combined_minimum_size()
	run_button.visible=is_instance_valid(subject) and subject.has_method("toggle_run")
	run_button.set_pressed_no_signal(Locomotion.toggled)
	run_button.text="Corrida ligada" if Locomotion.toggled else Controls.prompt("run")+" · Correr"
	run_button.size=Vector2(144*text_scale,48)
	run_button.position=Vector2(size.x-run_button.size.x-margin,tools.position.y+(tools.size.y+12 if tools.visible else 0))
	mount_button.visible=is_instance_valid(subject) and subject.has_method("toggle_mount") and (not subject.has_method("can_mount") or subject.can_mount())
	if mount_button.visible:
		var riding:bool=is_instance_valid(subject.get("avatar")) and subject.avatar.mounted
		mount_button.text=("↑" if Controls.gamepad else "B")+(" · Desmontar" if riding else " · Montar")
		mount_button.size=run_button.size
		mount_button.position=run_button.position+Vector2(0,run_button.size.y+12)
	objective_panel.position=Vector2(margin,area_panel.get_rect().end.y+8)
	objective_panel.size=Vector2(minf(480*text_scale,size.x*.55),72)
	objective_panel.visible=not objective.text.is_empty() and objective_age<4
	partner_panel.size=Vector2(260 if compact else 300,104)*text_scale
	partner_panel.position=Vector2(margin,size.y-partner_panel.size.y-margin)
	partner_panel.visible=not partner.is_empty()
	coins.text="%d moedas"%int(player_data.get("coins",0))
	coins.position=partner_panel.position-Vector2(0,30*text_scale);coins.visible=coin_age<3
	prompt.custom_minimum_size.x=0
	prompt_panel.size=Vector2(minf(300*text_scale,size.x*.4),64)
	prompt_panel.position=Vector2(size.x-prompt_panel.size.x-margin,size.y-prompt_panel.size.y-margin)
	prompt_panel.visible=not prompt.text.is_empty()
	interaction_key.text=Controls.prompt("interact")
	notice_stack.size=Vector2(minf(390*text_scale,size.x*.43),0)
	notice_stack.position=Vector2(margin,(objective_panel.get_rect().end.y if objective_panel.visible else area_panel.get_rect().end.y)+12)
	objective_panel.tooltip_text=objective.text
	prompt_panel.tooltip_text=prompt.text
	partner_panel.queue_redraw()
func _draw_partner() -> void:
	if partner.is_empty():return
	var scale:=text_scale
	var extent:=partner_panel.size
	partner_panel.draw_style_box(Mural.shared().get_stylebox("panel","MuralHudPanel"),Rect2(Vector2.ZERO,extent))
	var left:=90.0*scale
	if portrait!=null:
		partner_panel.draw_texture_rect(portrait,Hud.fit_texture(portrait,Rect2(-10*scale,-20*scale,98*scale,120*scale)),false)
	var width:=extent.x-left-22*scale
	var name:String=partner.get("personalName",partner.get("modelId","Parceiro"))
	var title:=name+" · Nv. %d"%Model.level_for_xp(partner.get("xp",0))
	partner_panel.draw_string(T.label(),Vector2(left,40*scale),Ink.ellipsis(title,T.label(),roundi(20*scale),width),HORIZONTAL_ALIGNMENT_LEFT,-1,roundi(20*scale),T.MURAL_INK)
	var health:=clampf(float(partner.get("condition",{}).get("line",100)),0,100)
	var structure:=clampf(float(partner.get("condition",{}).get("structure",100)),0,100)
	var color:=T.MURAL_TEAL if health>=25 else T.MURAL_RED
	partner_panel.draw_rect(Rect2(left,49*scale,width,5*scale),T.alpha(T.MURAL_INK,.18))
	partner_panel.draw_rect(Rect2(left,49*scale,width*health/100,5*scale),color)
	partner_panel.draw_string(T.label(),Vector2(left,74*scale),"Linha %d%% · Armação %d%%"%[health,structure],HORIZONTAL_ALIGNMENT_LEFT,width,roundi(15*scale),T.MURAL_INK)
	var level:=Model.level_for_xp(partner.get("xp",0))
	var start:=Model.xp_for_level(level)
	var next:=Model.xp_for_level(mini(50,level+1))
	var progress:=1.0 if level>=50 else clampf(float(partner.get("xp",0)-start)/maxi(1,next-start),0,1)
	partner_panel.draw_string(T.label(),Vector2(left,92*scale),"XP",HORIZONTAL_ALIGNMENT_LEFT,-1,roundi(13*scale),T.MURAL_INK)
	partner_panel.draw_rect(Rect2(left+22*scale,85*scale,width-22*scale,4*scale),T.alpha(T.MURAL_INK,.18))
	partner_panel.draw_rect(Rect2(left+22*scale,85*scale,(width-22*scale)*progress,4*scale),T.MURAL_TEAL)
	partner_panel.tooltip_text=title+" · Linha %d%% · Armação %d%%"%[health,structure]
func occupied_fraction() -> float:
	var total:=0.0
	for widget in [area_panel,objective_panel,partner_panel,prompt_panel,tools,coins,notice_stack,map,map_button,run_button,mount_button]:
		if is_instance_valid(widget) and widget.is_visible_in_tree():
			if widget==notice_stack and notices.is_empty():continue
			total+=widget.size.x*widget.size.y
	return total/maxf(1,size.x*size.y)

extends Control
## One quiet, discovery-safe overlay for all campaign exploration scenes.
signal chosen(action:String)
const Hud=preload("res://scripts/campaign/hud.gd")
const Ink=preload("res://scripts/campaign/battle_ink.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
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
var map:Control
var notices:Array[Dictionary]=[]
var notice_stack:VBoxContainer
var partner:Dictionary={}
var portrait:Texture2D
var _objective_text:=""
var _prompt_text:=""
var _portrait_id:=""
var _sample:=0.0
func plate(parent:Node,accent:Color=Hud.MUTED) -> PanelContainer:
	var panel=preload("res://scripts/campaign/hud_result_plate.gd").new()
	panel.accent=accent
	panel.mouse_filter=MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel
func label(parent:Node,font_size:int=16) -> Label:
	var text:=Label.new()
	text.add_theme_font_size_override("font_size",font_size)
	text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text.mouse_filter=MOUSE_FILTER_IGNORE
	parent.add_child(text)
	return text
func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_IGNORE
	theme=Hud.make_theme()
	add_to_group("exploration_hud")
	area_panel=plate(self)
	area=label(area_panel,24)
	area.text=area_name
	area.add_theme_font_override("font",Hud.display())
	area_panel.modulate.a=0
	area_panel.create_tween().tween_property(area_panel,"modulate:a",1,.14)
	objective_panel=plate(self,Hud.CORAL)
	objective=label(objective_panel)
	objective.max_lines_visible=2
	objective_panel.hide()
	partner_panel=Control.new()
	partner_panel.mouse_filter=MOUSE_FILTER_IGNORE
	add_child(partner_panel)
	partner_panel.draw.connect(_draw_partner)
	coins=label(self)
	coins.theme_type_variation="RecorteGoldText"
	prompt_panel=plate(self,Hud.CYAN)
	var row:=HBoxContainer.new()
	row.mouse_filter=MOUSE_FILTER_IGNORE
	prompt_panel.add_child(row)
	Hud.input_hint(row,"interact")
	prompt=label(row)
	prompt.max_lines_visible=2
	prompt.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	prompt.size_flags_horizontal=SIZE_EXPAND_FILL
	prompt_panel.hide()
	notice_stack=VBoxContainer.new()
	notice_stack.mouse_filter=MOUSE_FILTER_IGNORE
	add_child(notice_stack)
	tools=HBoxContainer.new()
	add_child(tools)
	for option in [["Equipe","collection","team"],["Bolsa","bag","bag"],["Menu","menu","settings"]]:
		var button:=Button.new()
		button.text=option[0]
		Hud.navigation_button(button,true,option[2])
		button.add_theme_font_size_override("font_size",16)
		button.custom_minimum_size=Vector2(104,48)
		button.pressed.connect(func():chosen.emit(option[1]))
		tools.add_child(button)
	resized.connect(_layout)
	refresh(player_data)
	_layout()
func refresh(value:Dictionary) -> void:
	if int(value.get("coins",0))!=int(player_data.get("coins",0)):coin_age=0
	player_data=value.duplicate(true)
	partner={}
	for entry in player_data.get("partners",[]):
		if entry.id==player_data.get("equippedPartnerId",""):partner=entry
	var id:String=partner.get("modelId","")
	if id!=_portrait_id and not id.is_empty():
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
	label(panel).text=message
	if kind=="item":panel.draw.connect(func():panel.draw_texture_rect(Ink.brush(1),Rect2(-8,-6,28,20),false,Hud.GOLD))
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
		if not prompt.text.is_empty():
			prompt_panel.modulate.a=0
			prompt_panel.create_tween().tween_property(prompt_panel,"modulate:a",1,.14)
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
	var factor:=size.y/1080.0
	var compact:=area_age>=3
	area_panel.position=Vector2(20,20)
	area_panel.size=Vector2(maxf(240,280*factor) if compact else 560*factor,44*factor if compact else 88*factor)
	area.add_theme_font_size_override("font_size",16 if compact else maxi(22,roundi(34*factor)))
	if is_instance_valid(map):
		var edge:=220*factor
		map.offset_left=-edge-20
		map.offset_right=-20
		map.offset_top=20
		map.offset_bottom=edge+20
	objective_panel.position=Vector2(20,area_panel.position.y+area_panel.size.y+12)
	objective_panel.size=Vector2(520*factor,72*factor)
	objective_panel.visible=not objective.text.is_empty() and objective_age<4
	partner_panel.position=Vector2(20,size.y-120*factor-20)
	partner_panel.size=Vector2(360,120)*factor
	partner_panel.visible=not partner.is_empty()
	coins.text="%d moedas"%int(player_data.get("coins",0))
	coins.position=partner_panel.position-Vector2(0,32)
	coins.visible=coin_age<3
	prompt.custom_minimum_size.x=maxf(120,440*factor-76)
	prompt_panel.size=Vector2(440*factor,72*factor)
	prompt_panel.position=Vector2(size.x-prompt_panel.size.x-20,size.y-prompt_panel.size.y-20)
	prompt_panel.visible=not prompt.text.is_empty()
	notice_stack.size=Vector2(420,200)*factor
	notice_stack.position=Vector2(size.x-notice_stack.size.x-20,prompt_panel.position.y-notice_stack.size.y-12)
	tools.position=Vector2(size.x-tools.get_combined_minimum_size().x-20,220*factor+32)
	tools.visible=pointer_mode and not Controls.gamepad and idle_age<4
	partner_panel.queue_redraw()
func _draw_partner() -> void:
	if partner.is_empty():return
	var extent:=partner_panel.size
	Ink.plate(partner_panel,Rect2(Vector2.ZERO,extent),Hud.INK,Hud.CYAN,12)
	var center:=Vector2(extent.y*.48,extent.y*.5)
	var radius:=extent.y*.4
	var diamond:=PackedVector2Array([center+Vector2(0,-radius),center+Vector2(radius,0),center+Vector2(0,radius),center+Vector2(-radius,0),center+Vector2(0,-radius)])
	partner_panel.draw_colored_polygon(diamond,Hud.SURFACE)
	partner_panel.draw_polyline(diamond,Hud.CYAN,2,true)
	if portrait!=null:partner_panel.draw_texture_rect(portrait,Hud.fit_texture(portrait,Rect2(center-Vector2.ONE*radius*.8,Vector2.ONE*radius*1.6)),false)
	var left:=extent.y
	var width:=extent.x-left-12
	var title:String=partner.get("personalName",partner.get("modelId","Parceiro"))+" · Nv. %d"%Model.level_for_xp(partner.get("xp",0))
	partner_panel.draw_string(Hud.font(true),Vector2(left,24),Ink.ellipsis(title,Hud.font(true),16,width),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Hud.PAPER)
	var health:float=partner.get("condition",{}).get("line",100)
	var color:=Hud.LINE if health>=50 else Hud.GOLD if health>=25 else Hud.CORAL
	partner_panel.draw_rect(Rect2(left,extent.y*.48,width,6),Hud.TRACK)
	partner_panel.draw_rect(Rect2(left,extent.y*.48,width*health/100,6),color)
	partner_panel.draw_string(Hud.font(),Vector2(left,extent.y-12),"Linha %d%%"%health,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Hud.PAPER)
	partner_panel.draw_line(Vector2(left,extent.y-5),Vector2(extent.x-12,extent.y-5),Hud.CYAN,2,true)
	partner_panel.draw_line(center+Vector2(radius,0),Vector2(left-4,extent.y*.5),Hud.CYAN,2,true)
func occupied_fraction() -> float:
	var total:=0.0
	for widget in [area_panel,objective_panel,partner_panel,prompt_panel,tools,coins,notice_stack,map]:
		if is_instance_valid(widget) and widget.is_visible_in_tree():
			if widget==notice_stack and notices.is_empty():continue
			total+=widget.size.x*widget.size.y
	return total/maxf(1,size.x*size.y)

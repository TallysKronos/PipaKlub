extends Control
## One quiet, discovery-safe overlay for all campaign exploration scenes.
signal chosen(action:String)
const Hud=preload("res://scripts/campaign/hud.gd")
const Ink=preload("res://scripts/campaign/battle_ink.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
const Locomotion = preload("res://scripts/campaign/locomotion.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
const Layout=preload("res://scripts/campaign/hud_layout.gd")
var subject:Node2D
var area_name:=""
var player_data:Dictionary={}
var area_age:=0.0
var objective_age:=0.0
var idle_age:=0.0
var coin_age:=10.0
var pointer_mode:=false
var show_partner:=true
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
	objective_panel.hide()
	partner_panel=Control.new()
	partner_panel.mouse_filter=MOUSE_FILTER_IGNORE
	add_child(partner_panel)
	partner_panel.draw.connect(_draw_partner)
	coins=label(self)
	coins.autowrap_mode=TextServer.AUTOWRAP_OFF
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
		button.custom_minimum_size=Vector2(144,48)
		button.pressed.connect(func():chosen.emit(option[1]))
		tools.add_child(button)
	resized.connect(_layout)
	run_button=Button.new()
	run_button.name="RunToggle"
	run_button.toggle_mode=true
	run_button.focus_mode=Control.FOCUS_NONE
	run_button.custom_minimum_size=Vector2(184,44)
	Hud.navigation_button(run_button,true)
	run_button.tooltip_text="Segure Shift para correr ou clique para alternar. No controle: L3."
	run_button.pressed.connect(func():
		if is_instance_valid(subject) and subject.has_method("toggle_run"):subject.toggle_run())
	add_child(run_button)
	mount_button=Button.new();mount_button.name="MountToggle";mount_button.focus_mode=Control.FOCUS_NONE
	mount_button.custom_minimum_size=Vector2(184,44);Hud.navigation_button(mount_button,true)
	mount_button.tooltip_text="Apito de Elo · B no teclado / direcional para cima no controle."
	mount_button.pressed.connect(func():
		if is_instance_valid(subject) and subject.has_method("toggle_mount"):subject.toggle_mount())
	add_child(mount_button)
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
	# Every corner sits on one safe rectangle (hud_layout.gd): Switch handheld, Steam
	# Deck 16:10 and ultrawide share the same placement rules.
	var safe:=Layout.safe_rect(size)
	var gap:=Layout.space("m")
	var compact:=area_age>=3
	# Top left: area plate, then the objective under it.
	var area_font:=Layout.type("small") if compact else Layout.type("title")
	area.add_theme_font_size_override("font_size",area_font)
	# Long area names widen the plate (up to 55% of the safe width) instead of wrapping
	# against its bottom stripe; beyond that the plate grows in height.
	var area_margins:=area_panel.get_theme_stylebox("panel").get_minimum_size().x+24
	var area_need:=Hud.display().get_string_size(area.text,HORIZONTAL_ALIGNMENT_LEFT,-1,area_font).x+area_margins
	area_panel.size=Layout.snap_v(Vector2(clampf(area_need,200 if compact else 320,safe.size.x*.55),40 if compact else 56))
	area_panel.position=safe.position
	objective.add_theme_font_size_override("font_size",Layout.type("body"))
	objective_panel.size=Vector2(minf(460,safe.size.x*.42),0)
	objective_panel.size=Layout.snap_v(Vector2(objective_panel.size.x,maxf(56,objective_panel.get_combined_minimum_size().y)))
	objective_panel.position=Vector2(safe.position.x,area_panel.position.y+area_panel.size.y+gap)
	objective_panel.visible=not objective.text.is_empty() and objective_age<4
	# Top right: minimap, then the pointer tools under it.
	var edge:=128.0
	if is_instance_valid(map):
		map.offset_left=-(size.x-safe.end.x)-edge
		map.offset_right=-(size.x-safe.end.x)
		map.offset_top=safe.position.y
		map.offset_bottom=safe.position.y+edge
	for button in tools.get_children():button.add_theme_font_size_override("font_size",Layout.type("small"))
	tools.add_theme_constant_override("separation",int(Layout.space("s")))
	tools.position=Vector2(safe.end.x-tools.get_combined_minimum_size().x,safe.position.y+edge+gap)
	tools.visible=pointer_mode and not Controls.gamepad and idle_age<4
	# Bottom left: partner card, coins above it.
	partner_panel.size=Vector2(328,100)
	partner_panel.position=Vector2(safe.position.x,safe.end.y-partner_panel.size.y)
	partner_panel.visible=show_partner and not partner.is_empty()
	coins.add_theme_font_size_override("font_size",Layout.type("small"))
	coins.text="%d moedas"%int(player_data.get("coins",0))
	coins.position=Vector2(safe.position.x+Layout.space("s"),partner_panel.position.y-Layout.space("s")-coins.get_combined_minimum_size().y)
	coins.visible=coin_age<3
	# Bottom right: interaction prompt, notices stacked above it.
	prompt.add_theme_font_size_override("font_size",Layout.type("body"))
	prompt_panel.size=Vector2(minf(360,safe.size.x*.32),0)
	# The text gets what the plate leaves after its insets and the button glyph.
	var prompt_row:Container=prompt.get_parent()
	var used:=prompt_panel.get_theme_stylebox("panel").get_minimum_size().x+prompt_row.get_theme_constant("separation")
	for child in prompt_row.get_children():
		if child!=prompt:used+=child.get_combined_minimum_size().x
	prompt.custom_minimum_size.x=maxf(120,prompt_panel.size.x-used)
	prompt_panel.size=Layout.snap_v(Vector2(prompt_panel.size.x,maxf(52,prompt_panel.get_combined_minimum_size().y)))
	prompt_panel.position=safe.end-prompt_panel.size
	prompt_panel.visible=not prompt.text.is_empty()
	for panel in notice_stack.get_children():
		for text in panel.get_children():
			if text is Label:text.add_theme_font_size_override("font_size",Layout.type("body"))
	notice_stack.add_theme_constant_override("separation",int(Layout.space("s")))
	notice_stack.size=Vector2(minf(400,safe.size.x*.36),0)
	notice_stack.size=Vector2(notice_stack.size.x,notice_stack.get_combined_minimum_size().y)
	notice_stack.position=Vector2(safe.end.x-notice_stack.size.x,prompt_panel.position.y-notice_stack.size.y-gap)
	# Bottom centre: run toggle (mouse), labelled with the active device's button.
	run_button.visible=is_instance_valid(subject) and subject.has_method("toggle_run") and (not subject.has_method("can_run") or subject.can_run())
	run_button.set_pressed_no_signal(Locomotion.toggled)
	run_button.text="Corrida ligada" if Locomotion.toggled else "Correr"
	run_button.icon=Controls.glyph("run")
	run_button.expand_icon=true
	run_button.add_theme_constant_override("icon_max_width",28)
	run_button.add_theme_font_size_override("font_size",Layout.type("small"))
	run_button.tooltip_text=("Pressione %s ou clique para alternar a corrida." if Controls.gamepad else "Segure %s para correr ou clique para alternar.")%Controls.prompt("run")
	run_button.custom_minimum_size=Vector2(168,44)
	run_button.size=run_button.get_combined_minimum_size()
	run_button.position=Vector2(safe.position.x+(safe.size.x-run_button.size.x)/2,safe.end.y-run_button.size.y)
	run_button.modulate.a=1.0 if idle_age<4 or Locomotion.toggled else .55
	# Mount toggle (when the area offers one) stacks above the run toggle.
	mount_button.visible=is_instance_valid(subject) and subject.has_method("toggle_mount") and (not subject.has_method("can_mount") or subject.can_mount())
	if mount_button.visible:
		var riding:bool=is_instance_valid(subject.get("avatar")) and subject.avatar.mounted
		mount_button.text=("↑" if Controls.gamepad else "B")+(" · Desmontar" if riding else " · Montar")
		mount_button.add_theme_font_size_override("font_size",Layout.type("small"))
		mount_button.size=mount_button.get_combined_minimum_size()
		mount_button.position=Vector2(safe.position.x+(safe.size.x-mount_button.size.x)/2,run_button.position.y-mount_button.size.y-Layout.space("s"))
	partner_panel.queue_redraw()
func _draw_partner() -> void:
	if partner.is_empty():return
	var extent:=partner_panel.size
	Ink.plate(partner_panel,Rect2(Vector2.ZERO,extent),Hud.INK,Hud.CYAN,12)
	# Kite diamond with the partner, tied to the bars by the elo line.
	var center:=Vector2(extent.y*.5,extent.y*.5)
	var radius:=extent.y*.4
	var diamond:=PackedVector2Array([center+Vector2(0,-radius),center+Vector2(radius,0),center+Vector2(0,radius),center+Vector2(-radius,0),center+Vector2(0,-radius)])
	partner_panel.draw_colored_polygon(diamond,Hud.SURFACE)
	partner_panel.draw_polyline(diamond,Hud.CYAN,2,true)
	if portrait!=null:partner_panel.draw_texture_rect(portrait,Hud.fit_texture(portrait,Rect2(center-Vector2.ONE*radius*.8,Vector2.ONE*radius*1.6)),false)
	partner_panel.draw_line(center+Vector2(radius,0),Vector2(extent.y+4,extent.y*.5),Hud.CYAN,2,true)
	# Rows on a 4-unit grid, 16 from the right stroke and 12 from the bottom one.
	var left:=extent.y+8
	var width:=extent.x-left-20
	var name_size:=Layout.type("label")
	var small:=Layout.type("micro")
	var level:=Model.level_for_xp(partner.get("xp",0))
	var title:String=partner.get("personalName",partner.get("modelId","Parceiro"))
	var level_text:="Nv. %d"%level
	var level_width:=Hud.font(true).get_string_size(level_text,HORIZONTAL_ALIGNMENT_LEFT,-1,small).x
	partner_panel.draw_string(Hud.font(true),Vector2(left,28),Ink.ellipsis(title,Hud.font(true),name_size,width-level_width-8),HORIZONTAL_ALIGNMENT_LEFT,-1,name_size,Hud.PAPER)
	partner_panel.draw_string(Hud.font(true),Vector2(left+width-level_width,28),level_text,HORIZONTAL_ALIGNMENT_LEFT,-1,small,Hud.CYAN)
	var health:float=partner.get("condition",{}).get("line",100)
	var structure: float=partner.get("condition",{}).get("structure",100)
	var color:=Hud.LINE if health>=50 else Hud.GOLD if health>=25 else Hud.CORAL
	partner_panel.draw_rect(Rect2(left,40,width,8),Hud.TRACK)
	partner_panel.draw_rect(Rect2(left,40,width*health/100,8),color)
	# Two values, one per side, so neither truncates at the handheld text size.
	var structure_text:="Estr. %d%%"%structure
	var structure_width:=Hud.font().get_string_size(structure_text,HORIZONTAL_ALIGNMENT_LEFT,-1,small).x
	var line_text:="Linha %d%%"%health
	# Falls back to the short label if a larger text scale would make the two meet.
	if Hud.font().get_string_size(line_text,HORIZONTAL_ALIGNMENT_LEFT,-1,small).x+structure_width+12>width:line_text="%d%%"%health
	partner_panel.draw_string(Hud.font(),Vector2(left,68),line_text,HORIZONTAL_ALIGNMENT_LEFT,-1,small,Hud.PAPER)
	partner_panel.draw_string(Hud.font(),Vector2(left+width-structure_width,68),structure_text,HORIZONTAL_ALIGNMENT_LEFT,-1,small,Hud.MUTED)
	var start:=Model.xp_for_level(level)
	var next:=Model.xp_for_level(mini(50,level+1))
	var progress:=1.0 if level>=50 else clampf(float(partner.get("xp",0)-start)/maxi(1,next-start),0,1)
	var xp_width:=Hud.font(true).get_string_size("XP",HORIZONTAL_ALIGNMENT_LEFT,-1,small).x+6
	partner_panel.draw_string(Hud.font(true),Vector2(left,extent.y-12),"XP",HORIZONTAL_ALIGNMENT_LEFT,-1,small,Hud.GOLD)
	partner_panel.draw_rect(Rect2(left+xp_width,extent.y-21,width-xp_width,6),Hud.TRACK)
	partner_panel.draw_rect(Rect2(left+xp_width,extent.y-21,(width-xp_width)*progress,6),Hud.GOLD)
	partner_panel.tooltip_text="Experiência %d / %d para o Nv. %d"%[int(partner.get("xp",0))-start,next-start,mini(50,level+1)] if level<50 else "Nível máximo"
func occupied_fraction() -> float:
	var total:=0.0
	for widget in [area_panel,objective_panel,partner_panel,prompt_panel,tools,coins,notice_stack,map]:
		if is_instance_valid(widget) and widget.is_visible_in_tree():
			if widget==notice_stack and notices.is_empty():continue
			total+=widget.size.x*widget.size.y
	return total/maxf(1,size.x*size.y)

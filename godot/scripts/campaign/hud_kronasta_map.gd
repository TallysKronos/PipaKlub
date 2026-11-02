extends Control
signal travel_requested(scene:String)
signal local_requested
signal closed
const Hud=preload("res://scripts/campaign/hud.gd")
const Atlas=preload("res://scripts/campaign/kronasta_atlas.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
const Checkpoint=preload("res://scripts/campaign/park_checkpoint.gd")
const Story=preload("res://scripts/campaign/kronasta_story.gd")
var current_scene:="quintal"
var saved_player:Dictionary={}
var selected:=0
var map_rect:=Rect2()
var art:Texture2D
var markers:Array[Button]=[]
var heading:Label
var detail:Label
var state_label:Label
var parts:VBoxContainer
var side:PanelContainer
var top:Label
var objective_label:Label
var footer:HBoxContainer
var back:Button
var area_button:Button

class Marker extends Button:
	var title:=""
	var lit:=true
	var current:=false
	var selected:=false
	func _draw() -> void:
		var at:=Vector2(18,18)
		var active:bool=is_hovered() or has_focus() or selected
		var color:=Color("ffc23d") if current else Color("2ec8e3") if lit else Color("697478")
		draw_circle(at,14,Color("141e29"))
		if active:draw_arc(at,18,0,TAU,32,Color("f4e9d2"),2,true)
		draw_arc(at,12,0,TAU,32,color,2,true)
		draw_circle(at,7 if lit else 4,color)
		if current:draw_colored_polygon(PackedVector2Array([at+Vector2(-5,-24),at+Vector2(5,-24),at+Vector2(0,-17)]),color)
		var width:=minf(190,Hud.font(true).get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+16)
		var rect:=Rect2(12,34,width,24)
		draw_style_box(Hud.panel("dark"),rect)
		draw_string(Hud.font(true),Vector2(20,51),title,HORIZONTAL_ALIGNMENT_LEFT,width-16,14,Color("f4e9d2") if lit else Color("b3b4ae"))

func label(parent:Node,text:String,font_size:int=18) -> Label:
	var result:=Label.new();result.text=text
	result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size",font_size)
	parent.add_child(result);return result
func action(parent:Node,text:String,callback:Callable) -> Button:
	var button:=Button.new();button.text=text
	button.custom_minimum_size=Vector2(0,48)
	button.add_theme_font_size_override("font_size",18)
	Hud.navigation_button(button,true)
	parent.add_child(button);button.pressed.connect(callback);return button
func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	theme=Hud.make_theme();mouse_filter=MOUSE_FILTER_STOP
	if ResourceLoader.exists("res://assets/campaign/maps/kronasta-atlas-v1.png"):
		art=load("res://assets/campaign/maps/kronasta-atlas-v1.png")
	top=label(self,"KRONASTA  /  CARTA DOS CAMINHOS",30)
	top.add_theme_font_override("font",Hud.display())
	objective_label=label(self,Story.objective(saved_player),16)
	objective_label.autowrap_mode=TextServer.AUTOWRAP_OFF
	objective_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	objective_label.tooltip_text=objective_label.text
	side=PanelContainer.new();side.add_theme_stylebox_override("panel",Hud.panel("dark"));add_child(side)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",14);side.add_child(column)
	state_label=label(column,"",14)
	heading=label(column,"",26);heading.add_theme_font_override("font",Hud.display())
	detail=label(column,"",17)
	var gap:=Control.new();gap.size_flags_vertical=SIZE_EXPAND_FILL;column.add_child(gap)
	parts=VBoxContainer.new();parts.add_theme_constant_override("separation",10);column.add_child(parts)
	for i in Atlas.REGIONS.size():
		var region:Dictionary=Atlas.REGIONS[i]
		var marker:=Marker.new();marker.title=region.name;marker.lit=not region.scenes.is_empty()
		marker.current=region.id==Atlas.region_for(current_scene)
		marker.flat=true;marker.mouse_default_cursor_shape=CURSOR_POINTING_HAND
		for style in ["normal","hover","pressed","focus","disabled"]:marker.add_theme_stylebox_override(style,StyleBoxEmpty.new())
		marker.tooltip_text=region.name+(" · Em breve" if not marker.lit else " · Escolher destino")
		marker.focus_mode=FOCUS_ALL;marker.custom_minimum_size=Vector2(42,42)
		marker.set_meta("recorte_decorated",true)
		add_child(marker);markers.append(marker)
		if not Story.qa() and ((region.get("preview",false) and not (region.id=="pantano" and load("res://scripts/campaign/retalho_trust.gd").swamp_open(saved_player))) or region.scenes.is_empty()):marker.hide();marker.focus_mode=FOCUS_NONE
		marker.pressed.connect(func():select(i))
		marker.focus_entered.connect(func():select(i))
	footer=HBoxContainer.new();footer.add_theme_constant_override("separation",14);add_child(footer)
	back=action(footer,"Voltar ao jogo",func():closed.emit())
	back.custom_minimum_size.x=190
	area_button=action(footer,"Mapa da área",func():local_requested.emit())
	area_button.custom_minimum_size.x=190
	var legend:=label(footer,"● Acesso aberto     ○ Em breve     ◆ Você está aqui",14)
	legend.autowrap_mode=TextServer.AUTOWRAP_OFF
	footer.minimum_size_changed.connect(_layout)
	selected=0
	for i in Atlas.REGIONS.size():
		if Atlas.REGIONS[i].id==Atlas.region_for(current_scene):selected=i
	if not markers[selected].visible:selected=0
	resized.connect(_layout);_layout();select(selected)
	_layout.call_deferred()
	Hud.focus_later(markers[selected])
func _layout() -> void:
	top.position=Vector2(32,24);top.size=Vector2(size.x-64,50)
	objective_label.position=Vector2(32,74);objective_label.size=Vector2(size.x-64,22)
	side.position=Vector2(size.x-324,104);side.size=Vector2(292,size.y-200)
	var available:=Rect2(24,98,size.x-372,size.y-194)
	var factor:=minf(available.size.x/1536,available.size.y/1024)
	map_rect=Rect2(available.get_center()-Vector2(1536,1024)*factor/2,Vector2(1536,1024)*factor)
	for i in markers.size():
		markers[i].position=map_rect.position+Atlas.REGIONS[i].at*map_rect.size-Vector2(18,18)
		markers[i].size=Vector2(42,42)
	footer.position=Vector2(32,size.y-72);footer.size=Vector2(size.x-64,48)
	queue_redraw()
func select(index:int) -> void:
	selected=index
	var region:Dictionary=Atlas.REGIONS[index]
	heading.text=region.name
	detail.text=region.description
	state_label.text="EM BREVE · ACESSO APAGADO" if region.scenes.is_empty() else "EXPLORAÇÃO DISPONÍVEL" if region.get("preview",false) else "CAMINHO ABERTO"
	state_label.modulate=Hud.MUTED if region.scenes.is_empty() else Hud.CYAN
	var story_region:bool=region.id in Checkpoint.REGIONS
	if story_region:state_label.text=Story.requirement(saved_player,region.id)
	detail.tooltip_text=Story.objective(saved_player)
	for child in parts.get_children():parts.remove_child(child);child.queue_free()
	if region.get("preview",false) and not Story.qa() and not (region.id=="pantano" and load("res://scripts/campaign/retalho_trust.gd").swamp_open(saved_player)):
		var disabled:=action(parts,"Ainda não disponível",func():pass);disabled.disabled=true
	elif story_region and not Story.can_travel(saved_player,region.id):
		var disabled:=action(parts,"Caminho ainda fechado",func():pass);disabled.disabled=true
	elif story_region:
		# Regional travel enters part A; B/C are reached by walking the authored exits.
		action(parts,region.parts[0],func():travel_requested.emit(region.scenes[0]))
	elif region.scenes.is_empty():
		var disabled:=action(parts,"Ainda não disponível",func():pass);disabled.disabled=true
	else:
		for i in region.scenes.size():
			var scene:String=region.scenes[i]
			var destination_button:=action(parts,region.parts[i],func():travel_requested.emit(scene))
			if scene in ["park-clearing","park-veredas"] and not Story.park_access(saved_player,scene):
				destination_button.disabled=true;destination_button.text="Vença o Lohan · "+region.parts[i]
			if scene=="parque-patio-liga" and not load("res://scripts/campaign/blue_exam_preparation.gd").eligible(saved_player):
				destination_button.disabled=true;destination_button.text="Após bairros 5 e 6 · Pátio da Liga"
	for i in markers.size():markers[i].selected=i==index;markers[i].queue_redraw()
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Hud.INK)
	if art!=null:draw_texture_rect(art,map_rect,false)
	for link in Atlas.LINKS:
		if not markers[link[0]].visible or not markers[link[1]].visible:continue
		var a:Dictionary=Atlas.REGIONS[link[0]];var b:Dictionary=Atlas.REGIONS[link[1]]
		var start:Vector2=map_rect.position+a.at*map_rect.size
		var end:Vector2=map_rect.position+b.at*map_rect.size
		var active:bool=not a.scenes.is_empty() and not b.scenes.is_empty()
		draw_line(start,end,Color("141e29",.65),5,true)
		draw_dashed_line(start,end,Color("f4e9d2",.85) if active else Color("697478",.7),2,7,true)
	draw_rect(map_rect.grow(2),Hud.MUTED,false,2)

func _unhandled_input(event:InputEvent) -> void:
	if Controls.pressed(event,"map"):
		get_viewport().set_input_as_handled()
		closed.emit()

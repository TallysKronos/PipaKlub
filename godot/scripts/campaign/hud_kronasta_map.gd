extends Control
signal travel_requested(scene:String)
signal local_requested
signal closed
const T=preload("res://scripts/campaign/ui_tokens.gd")
const Mural=preload("res://scripts/ui_mural/mural_theme.gd")
const Hud=preload("res://scripts/campaign/hud.gd")
const Atlas=preload("res://scripts/campaign/kronasta_atlas.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
var text_scale:=1.0
var header:PanelContainer
var scroll:ScrollContainer
func _init() -> void:set_meta("owns_ui_theme",true)
var current_scene:="quintal"
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
var footer:HFlowContainer
var back:Button
var area_button:Button

class Marker extends Button:
	var title:=""
	var lit:=true
	var current:=false
	var selected:=false
	var number:=0
	func _draw() -> void:
		var at:=Vector2(21,21)
		var active:bool=is_hovered() or has_focus() or selected
		var paper:=T.MURAL_SUN if current or active else T.MURAL_PAPER if lit else T.MURAL_MUTED
		var shape:=PackedVector2Array([at+Vector2(0,-17),at+Vector2(16,0),at+Vector2(0,18),at+Vector2(-16,0),at+Vector2(0,-17)])
		draw_colored_polygon(shape,paper)
		draw_polyline(shape,T.MURAL_INK,3,true)
		if active:draw_arc(at,21,0,TAU,32,T.MURAL_PAPER,2,true)
		if lit:
			var value:=str(number+1)
			var width:=T.label().get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x
			draw_string(T.label(),at+Vector2(-width/2,6),value,HORIZONTAL_ALIGNMENT_LEFT,-1,18,T.MURAL_INK)
		else:
			draw_line(at+Vector2(-5,-5),at+Vector2(5,5),T.MURAL_INK,3,true)
			draw_line(at+Vector2(5,-5),at+Vector2(-5,5),T.MURAL_INK,3,true)
		if current:draw_colored_polygon(PackedVector2Array([at+Vector2(-5,-29),at+Vector2(5,-29),at+Vector2(0,-22)]),T.MURAL_SUN)

func label(parent:Node,text:String,font_size:int=18) -> Label:
	var result:=Label.new();result.text=text
	result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size",roundi(font_size*text_scale))
	parent.add_child(result);return result
func action(parent:Node,text:String,callback:Callable) -> Button:
	var button:=Button.new();button.text=text
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.tooltip_text=text
	button.custom_minimum_size=Vector2(0,48)
	button.add_theme_font_size_override("font_size",roundi(20*text_scale))
	parent.add_child(button);button.pressed.connect(callback);return button
func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	text_scale=maxf(text_scale,Mural.text_scale_for(self))
	Mural.install(self);mouse_filter=MOUSE_FILTER_STOP
	if ResourceLoader.exists("res://assets/campaign/maps/kronasta-atlas-v1.png"):
		art=load("res://assets/campaign/maps/kronasta-atlas-v1.png")
	header=PanelContainer.new();header.theme_type_variation="MuralTitlePanel";add_child(header)
	top=label(header,"KRONASTA · CARTA DOS CAMINHOS",30)
	top.add_theme_font_override("font",T.lettering())
	side=PanelContainer.new();side.theme_type_variation="MuralPaperPanel";add_child(side)
	scroll=ScrollContainer.new();scroll.follow_focus=true;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;side.add_child(scroll)
	scroll.get_v_scroll_bar().custom_minimum_size.x=12
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",14);column.size_flags_horizontal=SIZE_EXPAND_FILL;scroll.add_child(column)
	state_label=label(column,"",14)
	heading=label(column,"",26);heading.add_theme_font_override("font",T.lettering())
	detail=label(column,"",17)
	var gap:=Control.new();gap.size_flags_vertical=SIZE_EXPAND_FILL;column.add_child(gap)
	parts=VBoxContainer.new();parts.add_theme_constant_override("separation",10);column.add_child(parts)
	for i in Atlas.REGIONS.size():
		var region:Dictionary=Atlas.REGIONS[i]
		var marker:=Marker.new();marker.title=region.name;marker.number=i;marker.lit=not region.scenes.is_empty()
		marker.current=region.id==Atlas.region_for(current_scene)
		marker.flat=true;marker.mouse_default_cursor_shape=CURSOR_POINTING_HAND
		for style in ["normal","hover","pressed","focus","disabled"]:marker.add_theme_stylebox_override(style,StyleBoxEmpty.new())
		marker.tooltip_text=str(i+1)+" · "+region.name+(" · Em breve" if not marker.lit else " · Escolher destino")
		marker.focus_mode=FOCUS_ALL;marker.custom_minimum_size=Vector2(42,42)
		marker.set_meta("recorte_decorated",true)
		add_child(marker);markers.append(marker)
		marker.pressed.connect(func():select(i))
		marker.focus_entered.connect(func():select(i))
	footer=HFlowContainer.new();footer.add_theme_constant_override("separation",14);add_child(footer)
	back=action(footer,"Voltar ao jogo",func():closed.emit())
	back.custom_minimum_size.x=190
	area_button=action(footer,"Mapa da área",func():local_requested.emit())
	area_button.custom_minimum_size.x=190
	var legend:=label(footer,"Nº: acesso aberto · ×: em breve · seta: você está aqui",14)
	legend.add_theme_color_override("font_color",T.MURAL_PAPER)
	legend.custom_minimum_size.x=300
	legend.size_flags_horizontal=SIZE_EXPAND_FILL
	footer.minimum_size_changed.connect(_layout)
	selected=0
	for i in Atlas.REGIONS.size():
		if Atlas.REGIONS[i].id==Atlas.region_for(current_scene):selected=i
	resized.connect(_layout);_layout();select(selected)
	_layout.call_deferred()
	Hud.focus_later(markers[selected])
func _layout() -> void:
	header.position=Vector2(24,24);header.size=Vector2(size.x-48,maxf(130,header.get_combined_minimum_size().y))
	var body_top:=header.get_rect().end.y+18
	var side_width:=minf(380,maxf(300,size.x*.28))
	side.position=Vector2(size.x-side_width-24,body_top);side.size=Vector2(side_width,size.y-body_top-152)
	var available:=Rect2(36,body_top+12,side.position.x-60,size.y-body_top-176)
	var factor:=minf(available.size.x/1536,available.size.y/1024)
	map_rect=Rect2(available.get_center()-Vector2(1536,1024)*factor/2,Vector2(1536,1024)*factor)
	for i in markers.size():
		markers[i].position=map_rect.position+Atlas.REGIONS[i].at*map_rect.size-Vector2(21,21)
		markers[i].size=Vector2(42,42)
	footer.position=Vector2(24,size.y-136);footer.size=Vector2(size.x-48,112)
	queue_redraw()
func select(index:int) -> void:
	selected=index
	var region:Dictionary=Atlas.REGIONS[index]
	heading.text="%02d · "%(index+1)+region.name
	detail.text=region.description
	state_label.text="EM BREVE · ACESSO APAGADO" if region.scenes.is_empty() else "EXPLORAÇÃO DISPONÍVEL" if region.get("preview",false) else "CAMINHO ABERTO"
	state_label.add_theme_color_override("font_color",T.MURAL_MUTED if region.scenes.is_empty() else T.MURAL_TEAL)
	for child in parts.get_children():parts.remove_child(child);child.queue_free()
	if region.scenes.is_empty():
		var disabled:=action(parts,"Ainda não disponível",func():pass);disabled.disabled=true
	else:
		for i in region.scenes.size():
			var scene:String=region.scenes[i]
			action(parts,region.parts[i],func():travel_requested.emit(scene))
	for i in markers.size():markers[i].selected=i==index;markers[i].queue_redraw()
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),T.MURAL_GROUND)
	var board:=map_rect.grow(16)
	draw_style_box(Mural.shared().get_stylebox("panel","MuralPaperPanel"),board)
	if art!=null:draw_texture_rect(art,map_rect,false)
	for link in Atlas.LINKS:
		var a:Dictionary=Atlas.REGIONS[link[0]];var b:Dictionary=Atlas.REGIONS[link[1]]
		var start:Vector2=map_rect.position+a.at*map_rect.size
		var end:Vector2=map_rect.position+b.at*map_rect.size
		var active:bool=not a.scenes.is_empty() and not b.scenes.is_empty()
		draw_line(start,end,T.alpha(T.MURAL_INK,.85),5,true)
		draw_dashed_line(start,end,T.MURAL_PAPER if active else T.MURAL_MUTED,2,7,true)

func _unhandled_input(event:InputEvent) -> void:
	if Controls.pressed(event,"map") or Controls.cancel(event) or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()

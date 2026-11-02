extends Control
## UI-only runner. A confirmation emits once, after all speaker pages are read.
signal confirmed
signal canceled
signal choice_selected(id:String)
const T=preload("res://scripts/campaign/ui_tokens.gd")
const Mural=preload("res://scripts/ui_mural/mural_theme.gd")
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
const Option=preload("res://scripts/ui_mural/dialogue_option.gd")
var text_scale:=1.0
var choice_scroll:ScrollContainer
func _init() -> void:set_meta("owns_ui_theme",true)
const Hud=preload("res://scripts/campaign/hud.gd")
const Surface=preload("res://scripts/campaign/hud_dialogue_surface.gd")
const Portrait=preload("res://scripts/campaign/hud_dialogue_portrait.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
var title:="Aviso"
var dialog_text:="":
	set(value):
		dialog_text=value
		if is_node_ready():_rebuild()
var ok_button_text:="Entendi"
var cancel_button_text:=""
var options:Array=[]
var option_buttons:Array[Button]=[]
var reduced_motion:=false
var allow_cancel:=true
var body:Label
var box:PanelContainer
var nameplate:PanelContainer
var name_label:Label
var portrait:TextureRect
var other_portrait:TextureRect
var choices:VBoxContainer
var accept:Button
var decline:Button
var advance:Button
var pages:Array[Dictionary]=[]
var page_index:=0
var elapsed:=0.0
var reaction_age:=10.0
var _closed:=false
var _portraits:Dictionary={}
var _indicator:=Vector2.ZERO
func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_STOP
	z_index=80
	add_to_group("manga_dialogue")
	add_to_group("recorte_motion")
	text_scale=maxf(text_scale,Mural.text_scale_for(self))
	Mural.install(self)
	var previous_focus:Control=get_viewport().gui_get_focus_owner()
	if previous_focus!=null:
		var previous_reference:WeakRef=weakref(previous_focus)
		tree_exiting.connect(func():
			var target:Control=previous_reference.get_ref()
			if target!=null and target.is_inside_tree() and target.is_visible_in_tree():Hud.focus_later(target))
	for hud:Control in get_tree().get_nodes_in_group("exploration_hud"):
		var reference:WeakRef=weakref(hud)
		var depth:int=hud.get_meta("dialogue_depth",0)
		hud.set_meta("dialogue_depth",depth+1)
		hud.hide()
		if is_instance_valid(hud.map):hud.map.hide()
		tree_exiting.connect(func():
			var target:Control=reference.get_ref()
			if target==null:return
			var remaining:int=maxi(0,int(target.get_meta("dialogue_depth",1))-1)
			target.set_meta("dialogue_depth",remaining)
			if remaining==0:
				target.show()
				if is_instance_valid(target.map):target.map.show())
	portrait=Portrait.new();add_child(portrait)
	other_portrait=Portrait.new();other_portrait.modulate=Hud.Tokens.alpha(Hud.Tokens.UNTINTED,.65);add_child(other_portrait)
	move_child(other_portrait,0)
	box=Surface.new();box.mural=true;add_child(box)
	body=Label.new()
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical=Control.SIZE_FILL
	body.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	body.add_theme_font_override("font",T.text())
	box.add_child(body)
	nameplate=PanelContainer.new();nameplate.theme_type_variation="MuralInkPanel";add_child(nameplate)
	name_label=Label.new();name_label.add_theme_font_override("font",T.label());name_label.add_theme_color_override("font_color",T.MURAL_PAPER)
	name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	nameplate.add_child(name_label)
	nameplate.resized.connect(func():
		nameplate.position.y=box.position.y-nameplate.size.y-12
		_align_choices.call_deferred())
	choice_scroll=ScrollContainer.new();choice_scroll.follow_focus=true;choice_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(choice_scroll)
	choice_scroll.get_v_scroll_bar().custom_minimum_size.x=12
	choices=VBoxContainer.new();choices.size_flags_horizontal=SIZE_EXPAND_FILL;choices.add_theme_constant_override("separation",10);choice_scroll.add_child(choices)
	choices.minimum_size_changed.connect(_align_choices.call_deferred)
	advance=_button("Continuar",func():next_page())
	decline=_button(cancel_button_text,func():_finish(false))
	accept=_button(ok_button_text,func():_finish(true))
	for option in options.slice(0,4):
		var id:String=option.get("id","")
		var button:=_button(option.get("text",id),func():
			if not _closed:_closed=true;choice_selected.emit(id))
		button.set_meta("safe",option.get("safe",false))
		option_buttons.append(button)
	resized.connect(_rebuild)
	_rebuild()
	_sync_glyphs()
func _sync_glyphs() -> void:
	for button in [advance,accept,decline]+option_buttons:
		button.icon=Controls.glyph("back" if button==decline else "accept")
		button.expand_icon=true;button.add_theme_constant_override("icon_max_width",24)
func _button(text:String,callback:Callable) -> Button:
	var button:=Option.new();button.text_scale=text_scale
	button.text=text
	button.pressed.connect(callback)
	choices.add_child(button)
	return button
func _portrait_for(speaker:String) -> Texture2D:
	if _portraits.has(speaker):return _portraits[speaker]
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	var texture:Texture2D
	if data.portraits.has(speaker):texture=load("res://assets/campaign/"+data.portraits[speaker])
	else:
		var maps:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/morro/maps.json"))
		for area in maps.values():
			for npc in area.npcs:
				if npc.name!=speaker:continue
				var atlas:=AtlasTexture.new()
				atlas.atlas=load("res://assets/campaign/morro/"+npc.image)
				atlas.region=Rect2(npc.bounds.x,npc.bounds.y,npc.bounds.w,npc.bounds.h*.68)
				texture=atlas
	_portraits[speaker]=texture
	return texture
func _rebuild() -> void:
	if not is_instance_valid(body):return
	var font_size:=roundi(24*text_scale)
	body.add_theme_font_size_override("font_size",font_size)
	var padding:=Paper.inset(.45)
	var height:=maxf(200,ceilf(T.text().get_height(font_size)*3+body.get_theme_constant("line_spacing")*2+padding*2+12))
	var portrait_width:=clampf(size.x*.23,180,300)
	box.position=Vector2(portrait_width+40,size.y-height-24)
	box.size=Vector2(size.x-box.position.x-24,height)
	var name_height:=maxf(76,T.label().get_height(roundi(26*text_scale))+58)
	nameplate.position=Vector2(box.position.x,box.position.y-name_height-12)
	nameplate.size=Vector2(minf(380*text_scale,box.size.x),name_height)
	var name_space:=StyleBoxEmpty.new()
	for edge in [SIDE_LEFT,SIDE_RIGHT]:name_space.set_content_margin(edge,32)
	for edge in [SIDE_TOP,SIDE_BOTTOM]:name_space.set_content_margin(edge,29)
	nameplate.add_theme_stylebox_override("panel",name_space)
	nameplate.draw.connect(_draw_nameplate) if not nameplate.draw.is_connected(_draw_nameplate) else null
	name_label.add_theme_font_size_override("font_size",roundi(26*text_scale))
	portrait.position=Vector2(24,maxf(40,box.position.y-270))
	portrait.size=Vector2(portrait_width,size.y-portrait.position.y-24)
	other_portrait.position=portrait.position+Vector2(30,-30)
	other_portrait.size=portrait.size*Vector2(.78,.85)
	_indicator=Vector2(box.get_rect().end.x-18,box.get_rect().end.y-18)
	pages.clear()
	var speaker:=title if title!="Aviso" else "Jornada"
	for paragraph in dialog_text.split("\n\n",false):
		var colon:=paragraph.find(": ")
		if colon>0 and colon<36:
			speaker=paragraph.left(colon)
			paragraph=paragraph.substr(colon+2)
		var parsed:=Surface.parse_tags(paragraph)
		var width:=maxf(180,box.size.x-padding*2-4)
		var lines:=Surface.wrapped_lines(str(parsed.text),T.text(),font_size,width)
		for start in range(0,lines.size(),3):pages.append({"speaker":speaker,"text":"\n".join(lines.slice(start,mini(start+3,lines.size()))),"emotion":parsed.emotion,"reaction":parsed.reaction,"shout":parsed.shout})
	if pages.is_empty():pages.append({"speaker":speaker,"text":"","emotion":"","reaction":"","shout":false})
	page_index=clampi(page_index,0,pages.size()-1)
	_show_page()
func _show_page() -> void:
	preload("res://scripts/campaign/sound_director.gd").cue(self, "dialogue.blip")
	var page:Dictionary=pages[page_index]
	body.text=page.text
	name_label.text=page.speaker
	name_label.tooltip_text=page.speaker
	nameplate.size.x=minf(box.size.x,maxf(180,T.label().get_string_size(page.speaker,HORIZONTAL_ALIGNMENT_LEFT,-1,roundi(26*text_scale)).x+64))
	portrait.texture=_portrait_for(page.speaker)
	portrait.visible=portrait.texture!=null
	portrait.emotion=page.emotion;portrait.reaction=page.reaction;portrait.queue_redraw()
	other_portrait.hide()
	for earlier in pages.slice(0,page_index):
		if earlier.speaker!=page.speaker:
			other_portrait.texture=_portrait_for(earlier.speaker)
			other_portrait.visible=other_portrait.texture!=null
	box.shouted=page.shout;box.queue_redraw()
	reaction_age=0
	var last:=page_index==pages.size()-1
	advance.visible=not last
	accept.visible=last and option_buttons.is_empty()
	decline.visible=last and not cancel_button_text.is_empty() and option_buttons.is_empty()
	for button in option_buttons:button.visible=last
	accept.text=ok_button_text;decline.text=cancel_button_text
	var target:Button=decline if decline.visible else accept if last else advance
	if last and not option_buttons.is_empty():
		target=option_buttons[0]
		for button in option_buttons:
			if button.get_meta("safe",false):target=button;break
	Hud.focus_later(target)
	call_deferred("_align_choices")
func _align_choices() -> void:
	if not is_instance_valid(choices):return
	choice_scroll.size.x=minf(500*text_scale,size.x*.52)
	choice_scroll.position.x=size.x-choice_scroll.size.x-24
	var limit:=box.position.y-12 if choice_scroll.position.x>nameplate.get_rect().end.x+12 else nameplate.position.y-12
	choice_scroll.size.y=minf(maxf(76,choices.get_combined_minimum_size().y),maxf(76,limit-24))
	choice_scroll.position.y=limit-choice_scroll.size.y
	choices.custom_minimum_size.x=choice_scroll.size.x-16
func _draw_nameplate() -> void:
	Paper.frame(nameplate,Rect2(Vector2.ZERO,nameplate.size),"MuralInkPanel",.35)
func next_page() -> void:
	preload("res://scripts/campaign/sound_director.gd").cue(self, "dialogue.advance")
	if page_index<pages.size()-1:page_index+=1;_show_page()
func _finish(accepted:bool) -> void:
	if _closed:return
	preload("res://scripts/campaign/sound_director.gd").cue(self, "dialogue.choice" if accepted else "dialogue.end")
	_closed=true
	if accepted:confirmed.emit()
	else:canceled.emit()
func popup_centered(_requested:Vector2i=Vector2i.ZERO) -> void:
	show()
	_rebuild()
func get_label() -> Label:return body
func get_ok_button() -> Button:return accept
func get_cancel_button() -> Button:return decline
func set_reduced_motion(value:bool) -> void:reduced_motion=value
func _process(delta:float) -> void:
	elapsed+=delta;reaction_age+=delta;queue_redraw()
func _input(event:InputEvent) -> void:
	Controls.observe(event)
	if is_instance_valid(accept):_sync_glyphs()
	if Controls.cancel(event) or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if not allow_cancel:return
		if not cancel_button_text.is_empty():_finish(false)
		elif not option_buttons.is_empty():return
		elif page_index<pages.size()-1:next_page()
		else:_finish(true)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),T.alpha(T.MURAL_GROUND,.3))
	if not is_instance_valid(box):return
	if box.shouted and reaction_age<.25 and not reduced_motion:
		for index in 12:
			var angle:=TAU*index/12
			var vector:=Vector2.from_angle(angle)
			draw_line(size*.5+vector*size.y*.42,size*.5+vector*size.y*.5,Hud.PAPER,2)
	var offset:=0.0 if reduced_motion else 2*(1-cos(elapsed*PI/.6))
	var center:=_indicator+Vector2(0,offset)
	draw_colored_polygon(PackedVector2Array([center+Vector2(0,-7),center+Vector2(6,0),center+Vector2(0,7),center+Vector2(-6,0)]),T.MURAL_TEAL)

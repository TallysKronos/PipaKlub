extends Control
## UI-only runner. A confirmation emits once, after all speaker pages are read.
signal confirmed
signal canceled
signal choice_selected(id:String)
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
	theme=Hud.make_theme()
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
	other_portrait=Portrait.new();other_portrait.modulate=Color(.65,.65,.65);add_child(other_portrait)
	move_child(other_portrait,0)
	box=Surface.new();add_child(box)
	body=Label.new()
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font",Hud.font())
	box.add_child(body)
	nameplate=load("res://scripts/campaign/hud_result_plate.gd").new()
	nameplate.accent=Hud.CORAL
	add_child(nameplate)
	name_label=Label.new();name_label.add_theme_font_override("font",Hud.display());nameplate.add_child(name_label)
	choices=VBoxContainer.new();choices.add_theme_constant_override("separation",8);add_child(choices)
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
func _button(text:String,callback:Callable) -> Button:
	var button:=Button.new()
	button.text=text
	Hud.navigation_button(button,true)
	button.add_theme_font_size_override("font_size",20)
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
	var factor:=size.y/1080.0
	var height:=maxf(180,240*factor)
	box.position=Vector2(maxf(24,size.x*.16),size.y-height-24)
	box.size=Vector2(size.x-box.position.x-32,height)
	var font_size:=maxi(20,roundi(30*factor))
	body.add_theme_font_size_override("font_size",font_size)
	nameplate.position=box.position-Vector2(-20,40)
	nameplate.size=Vector2(360*factor,48)
	name_label.add_theme_font_size_override("font_size",maxi(22,roundi(32*factor)))
	portrait.position=Vector2(16,box.position.y-340*factor)
	portrait.size=Vector2(400,520)*factor
	other_portrait.position=portrait.position+Vector2(290*factor,25*factor)
	other_portrait.size=Vector2(340,470)*factor
	choices.size=Vector2(minf(640*factor,size.x*.45),0)
	choices.position=Vector2(size.x-choices.size.x-32,box.position.y-choices.get_combined_minimum_size().y-60)
	_indicator=Vector2(size.x-54,size.y-46)
	pages.clear()
	var speaker:=title if title!="Aviso" else "Jornada"
	for paragraph in dialog_text.split("\n\n",false):
		var colon:=paragraph.find(": ")
		if colon>0 and colon<36:
			speaker=paragraph.left(colon)
			paragraph=paragraph.substr(colon+2)
		var parsed:=Surface.parse_tags(paragraph)
		var lines:Array[String]=[]
		var line:=""
		var width:=maxf(180,box.size.x-64)
		for word in str(parsed.text).replace("\n"," ").split(" ",false):
			var candidate:=word if line.is_empty() else line+" "+word
			if Hud.font().get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>width and not line.is_empty():lines.append(line);line=word
			else:line=candidate
		if not line.is_empty():lines.append(line)
		if lines.is_empty():lines.append("")
		for start in range(0,lines.size(),3):pages.append({"speaker":speaker,"text":"\n".join(lines.slice(start,mini(start+3,lines.size()))),"emotion":parsed.emotion,"reaction":parsed.reaction,"shout":parsed.shout})
	if pages.is_empty():pages.append({"speaker":speaker,"text":"","emotion":"","reaction":"","shout":false})
	page_index=clampi(page_index,0,pages.size()-1)
	_show_page()
func _show_page() -> void:
	var page:Dictionary=pages[page_index]
	body.text=page.text
	name_label.text=page.speaker
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
	choices.position.y=box.position.y-choices.get_combined_minimum_size().y-60
func next_page() -> void:
	if page_index<pages.size()-1:page_index+=1;_show_page()
func _finish(accepted:bool) -> void:
	if _closed:return
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
	if Controls.cancel(event) or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish(cancel_button_text.is_empty())
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(Hud.BLACK,.38))
	if not is_instance_valid(box):return
	if box.shouted and reaction_age<.25 and not reduced_motion:
		for index in 12:
			var angle:=TAU*index/12
			var vector:=Vector2.from_angle(angle)
			draw_line(size*.5+vector*size.y*.42,size*.5+vector*size.y*.5,Hud.PAPER,2)
	var offset:=0.0 if reduced_motion else 2*(1-cos(elapsed*PI/.6))
	var center:=_indicator+Vector2(0,offset)
	draw_colored_polygon(PackedVector2Array([center+Vector2(0,-7),center+Vector2(6,0),center+Vector2(0,7),center+Vector2(-6,0)]),Hud.CORAL)

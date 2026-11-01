extends Control
## A small, walkable room for care; only the care service commits inventory changes.
signal completed(steps:Array)
signal supplies_requested
signal back_requested
const Hud=preload("res://scripts/campaign/hud.gd")
const Care=preload("res://scripts/campaign/partner_care.gd")
const Animal=preload("res://scripts/campaign/care_creature.gd")
const IDS=["clean","frame","line"]
const ACTIONS=["Paninho","Papel e cola","Carretel"]
var partner:Dictionary={}
var kits:=0
var coins:=0
var welcome:=true
var reduced_motion:=false
var steps:Array=[]
var saved:=false
var busy:=false
var clock:=0.0
var reaction:=0.0
var state:="wander"
var tool:="hand"
var foot:=Vector2(.52,.76)
var target:=Vector2(.66,.72)
var rug:=Vector2(.52,.76)
var idle_time:=2.0
var hand:=Vector2(.68,.56)
var pointer_inside:=false
var holding:=false
var progress:=0.0
var bond:=0.0
var room_rect:=Rect2()
var pet_height:=150.0
var stage:Control
var hand_layer:Control
var creature:Node2D
var message:Label
var stock:Label
var condition:Label
var action:Button
var pet:Button
var supply:Button
var back:Button
var call_button:Button
var roam_button:Button
var meters:Array[ProgressBar]=[]
var tool_buttons:Array[Button]=[]
var images:Dictionary={}
var marks:Array=[]
var rng:=RandomNumberGenerator.new()
var _cursor_hidden:=false
var dock:PanelContainer
var bottom:MarginContainer
var inspection:PanelContainer
func copy(text:String,parent:Node,font_size:int=18) -> Label:
	var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size);parent.add_child(label);return label
func panel() -> PanelContainer:
	var result:=PanelContainer.new();var style:=StyleBoxFlat.new()
	style.bg_color=Color("253844ed");style.border_color=Color("d6b887");style.set_border_width_all(1);style.set_corner_radius_all(12)
	style.content_margin_left=16;style.content_margin_right=16;style.content_margin_top=10;style.content_margin_bottom=10
	result.add_theme_stylebox_override("panel",style);return result
func button(text:String,parent:Node,callback:Callable,icon_name:String="") -> Button:
	var result:=Button.new();result.text=text;result.custom_minimum_size=Vector2(150,46)
	Hud.navigation_button(result,true);parent.add_child(result);result.pressed.connect(callback)
	result.add_theme_font_size_override("font_size",18)
	if not icon_name.is_empty():result.icon=images[icon_name];result.expand_icon=true;result.add_theme_constant_override("icon_max_width",30)
	return result
func _ready() -> void:
	size_flags_vertical=Control.SIZE_EXPAND_FILL;size_flags_horizontal=Control.SIZE_EXPAND_FILL
	rng.seed=hash(partner.get("id","care"))
	for name in ["hand-open","hand-pet","hand-point","cloth","patch","spool","heart","basket"]:images[name]=load("res://assets/care-room-v1/"+name+".svg")
	images.room=load("res://assets/care-room-v1/quarto-atelie.png")
	stage=Control.new();add_child(stage);stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.focus_mode=Control.FOCUS_ALL;stage.clip_contents=true
	stage.draw.connect(_draw_stage);stage.gui_input.connect(_stage_input)
	stage.mouse_entered.connect(func():pointer_inside=true)
	stage.mouse_exited.connect(func():pointer_inside=false;holding=false;_restore_cursor())
	creature=Animal.new();creature.configure(str(partner.get("modelId","rabbito")));creature.reduced_motion=reduced_motion;stage.add_child(creature)
	hand_layer=Control.new();stage.add_child(hand_layer);hand_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hand_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;hand_layer.draw.connect(_draw_hand)
	var top:=MarginContainer.new();add_child(top);top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left=22;top.offset_right=-22;top.offset_top=16;top.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var row:=HBoxContainer.new();top.add_child(row)
	var title:=panel();title.custom_minimum_size.x=460;row.add_child(title);var heading:=VBoxContainer.new();title.add_child(heading)
	copy("Cantinho do "+str(partner.get("personalName",partner.get("modelId","parceiro"))),heading,24)
	stock=copy("",heading,15)
	copy("Setas: mão · Enter: usar · Tab: ferramentas · Esc: voltar",heading,13)
	var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;spacer.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(spacer)
	back=button("Voltar",row,func():back_requested.emit());back.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	inspection=panel();add_child(inspection);inspection.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	inspection.offset_left=-290;inspection.offset_right=-22;inspection.offset_top=84;inspection.offset_bottom=172
	var detail:=VBoxContainer.new();inspection.add_child(detail);condition=copy("",detail,15)
	for color in [Hud.LINE,Hud.GOLD]:
		var bar:=ProgressBar.new();bar.custom_minimum_size.y=8;bar.show_percentage=false
		var fill:=StyleBoxFlat.new();fill.bg_color=color;bar.add_theme_stylebox_override("fill",fill);detail.add_child(bar);meters.append(bar)
	bottom=MarginContainer.new();add_child(bottom);bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left=22;bottom.offset_right=-22;bottom.offset_top=-126;bottom.offset_bottom=-14
	dock=panel();bottom.add_child(dock);var column:=VBoxContainer.new();dock.add_child(column)
	message=copy("",column,17);message.custom_minimum_size.y=28
	var tools:=HFlowContainer.new();tools.add_theme_constant_override("h_separation",8);tools.add_theme_constant_override("v_separation",8);column.add_child(tools)
	tools.add_theme_font_size_override("font_size",18)
	pet=button("Carinho",tools,func():select_tool("hand"),"hand-open")
	call_button=button("Chamar",tools,func():select_tool("call"),"hand-point")
	for index in 3:
		var id:String=IDS[index]
		tool_buttons.append(button(ACTIONS[index],tools,func():select_tool(id),["cloth","patch","spool"][index]))
	action=tool_buttons[0]
	tool_buttons[1].custom_minimum_size.x=178
	roam_button=button("Passear",tools,release_pet)
	supply=button("",tools,func():supplies_requested.emit(),"basket");supply.custom_minimum_size.x=210
	stage.focus_next=pet.get_path();stage.focus_previous=back.get_path()
	refresh_stock(kits,coins,welcome);resized.connect(_layout);_layout();stage.grab_focus()
func _layout() -> void:
	if not is_instance_valid(stage):return
	var ratio:=minf(size.x/1672.0,size.y/941.0)
	room_rect=Rect2((size-Vector2(1672,941)*ratio)*.5,Vector2(1672,941)*ratio)
func position_for(point:Vector2) -> Vector2:return room_rect.position+point*room_rect.size
func floor_point(point:Vector2) -> Vector2:return point.clamp(Vector2(.28,.58),Vector2(.77,.82))
func _near_pet(point:Vector2) -> bool:
	return position_for(point).distance_to(position_for(foot)-Vector2(0,pet_height*.48))<pet_height*.72
func _restore_cursor() -> void:
	if _cursor_hidden:Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);_cursor_hidden=false
func _exit_tree() -> void:_restore_cursor()
func _notification(what:int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:holding=false;pointer_inside=false;_restore_cursor()
func _stage_input(event:InputEvent) -> void:
	if event is InputEventMouseMotion:
		pointer_inside=true
		hand=(event.position-room_rect.position)/room_rect.size
		if holding:_touch(event.relative.length())
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		hand=(event.position-room_rect.position)/room_rect.size;holding=event.pressed
		if event.pressed:stage.grab_focus();interact_at(hand)
	if event.is_action("ui_accept") and not event is InputEventMouseButton:
		holding=event.is_pressed()
		if event.is_pressed() and not event.is_echo():interact_at(hand)
		stage.accept_event()
	for direction in ["ui_left","ui_right","ui_up","ui_down"]:
		if event.is_action(direction):stage.accept_event()
func select_tool(value:String) -> void:
	if IDS.has(value) and (not can_treat() or value!=IDS[mini(steps.size(),2)]):return
	tool=value;holding=false;progress=0
	if IDS.has(value):
		state="approach";target=rug;message.text="Ele vem até o tapete. Espere chegar para cuidar dele."
	elif value=="call":message.text="Toque no chão livre para chamá-lo até lá."
	else:
		state="rest";idle_time=2;message.text="Passe a mão ou toque no seu parceiro para fazer carinho."
	stage.grab_focus();_update()
func can_treat() -> bool:
	var data:Dictionary=partner.get("condition",{"line":100,"structure":100})
	return not busy and not saved and kits>0 and steps.size()<3 and (float(data.line)<100 or float(data.structure)<100)
func interact_at(point:Vector2) -> void:
	if busy:return
	if tool=="call":
		target=floor_point(point);state="called";message.text="Vem cá!";return
	if tool=="hand":
		if _near_pet(point):_pet()
		else:target=floor_point(point);state="called";message.text="Ele vem investigar a sua mão."
	elif state=="care" and _near_pet(point) and can_treat():
		if tool=="frame":progress=minf(1,progress+.36);reaction=.4;_finish_touch()
func _touch(distance:float) -> void:
	if not _near_pet(hand) or busy:return
	if tool=="hand":
		bond+=distance
		if bond>45:bond=0;_pet()
	elif tool=="clean" and state=="care" and can_treat():
		progress=minf(1,progress+minf(distance,35)/240);reaction=.4;_finish_touch()
func _finish_touch() -> void:
	if progress>=1:_care()
func release_pet() -> void:
	tool="hand";holding=false;progress=0;state="wander"
	target=Vector2(rng.randf_range(.31,.74),rng.randf_range(.61,.80));idle_time=rng.randf_range(2,4)
	message.text="Pode passear. Estou aqui com você.";stage.grab_focus()
func _care() -> void:
	if not can_treat():return
	steps.append(IDS[steps.size()]);progress=0;holding=false;reaction=1.0
	if steps.size()==3:busy=true;_update();completed.emit(steps.duplicate())
	else:tool=IDS[steps.size()];state="care";_instruction();_update()
func _instruction() -> void:
	message.text={"clean":"Segure e passe o paninho no papel. No controle: segure confirmar.","frame":"Papel limpinho! Toque três vezes no parceiro para firmar o remendo.","line":"Armação firme! Segure o carretel sobre ele para ajustar a linha."}.get(tool,"")
func _pet() -> void:
	reaction=1.5;state="pet";idle_time=2.2
	marks.append({"at":foot,"age":0.0});message.text="Um carinho e um tempinho juntos. Ele parece gostar!"
func finish_result(ok:bool,text:String="") -> void:
	busy=false;saved=ok
	if ok:
		tool="hand";state="pet";idle_time=3;reaction=1.5;marks.append({"at":foot,"age":0.0})
		message.text="Prontinho! Linha e armação recuperadas. Agora, um tempinho para brincar."
	else:
		steps=IDS.slice(0,2);tool="line";state="care";progress=0;message.text=text
	_update();stage.grab_focus()
func refresh_stock(count:int,money:int,first:bool) -> void:
	kits=count;coins=money;welcome=first
	stock.text="Kit de Remendo × %d   ·   %d moedas"%[kits,coins]
	supply.text="Pegar primeiro kit" if welcome else "Kit · %d moedas"%Care.PRICE
	supply.disabled=busy or saved or (not welcome and coins<Care.PRICE)
	_update()
func _update() -> void:
	var data:Dictionary=partner.get("condition",{"line":100,"structure":100})
	meters[0].value=100 if saved else float(data.line);meters[1].value=100 if saved else float(data.structure)
	condition.text="Linha %d%%   ·   Armação %d%%"%[meters[0].value,meters[1].value]
	for i in 3:
		tool_buttons[i].disabled=not can_treat() or steps.size()!=i
		tool_buttons[i].text=ACTIONS[i]
		tool_buttons[i].tooltip_text="Concluído" if i<steps.size() else ACTIONS[i]
	if clock==0 or (steps.is_empty() and state=="wander"):
		message.text="Um cantinho para passear e receber carinho." if meters[0].value==100 and meters[1].value==100 else "Escolha o paninho e ele virá até o tapete. O kit só é gasto ao terminar." if kits>0 else "Pegue um kit e escolha o paninho. O reparo só gasta o kit ao terminar."
func _process(delta:float) -> void:
	clock+=delta;reaction=maxf(0,reaction-delta)
	if room_rect.size.x<=0:return
	# Flow height grows at narrower windows instead of clipping the second row.
	bottom.offset_top=-maxf(116,dock.get_combined_minimum_size().y+14)
	var keys:=Input.get_vector("ui_left","ui_right","ui_up","ui_down") if stage.has_focus() else Vector2.ZERO
	if keys!=Vector2.ZERO:hand=(hand+keys*delta*.4).clamp(Vector2(.12,.22),Vector2(.88,.87));pointer_inside=false;_restore_cursor()
	if pointer_inside and Input.get_mouse_mode()==Input.MOUSE_MODE_VISIBLE:Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN);_cursor_hidden=true
	if stage.has_focus() and holding and Input.is_action_pressed("ui_accept"):_touch(delta*120)
	if holding and tool=="line" and state=="care" and _near_pet(hand) and can_treat():progress=minf(1,progress+delta*.6);_finish_touch()
	var moving:=false
	if state in ["wander","called","approach"]:
		var previous:=foot
		foot=foot.move_toward(target,delta*(.13 if state=="approach" else .075))
		moving=foot.distance_to(previous)>.00001
		if moving:creature.left=target.x<previous.x
		if foot.distance_to(target)<.001:
			if state=="approach":state="care";_instruction()
			else:state="rest";idle_time=rng.randf_range(2,4)
	elif state in ["rest","pet"]:
		idle_time-=delta
		if idle_time<=0:release_pet()
	creature.pose="walk" if moving else "pet" if reaction>0 else "rest" if state=="rest" else "idle"
	pet_height=clampf(room_rect.size.y*.24,90,190)*lerpf(.88,1.04,(foot.y-.58)/.24)
	creature.scale=Vector2.ONE*pet_height/creature.native_height;creature.position=position_for(foot);creature.animate(delta)
	for mark in marks:mark.age+=delta
	marks=marks.filter(func(mark):return mark.age<1.5)
	inspection.visible=state=="care" or ((pointer_inside or stage.has_focus()) and _near_pet(hand))
	stage.queue_redraw();hand_layer.queue_redraw()
func _draw_stage() -> void:
	stage.draw_rect(Rect2(Vector2.ZERO,stage.size),Color("202d36"))
	stage.draw_texture_rect(images.room,room_rect,false)
	var center:=position_for(foot)
	stage.draw_set_transform(center,0,Vector2(1,.27));stage.draw_circle(Vector2.ZERO,pet_height*.27,Color(0.1,.2,.2,.22));stage.draw_set_transform(Vector2.ZERO)
	if state=="care" and progress>0:stage.draw_arc(center+Vector2(0,10),30,-PI/2,-PI/2+TAU*progress,40,Color("f6d48c"),4,true)
	for mark in marks:
		var at:=position_for(mark.at)-Vector2(-30,pet_height+mark.age*30)
		stage.draw_texture_rect(images.heart,Rect2(at,Vector2(28,28)),false,Color(1,1,1,1-mark.age/1.5))
func _draw_hand() -> void:
	if not pointer_inside and not stage.has_focus():return
	var at:=position_for(hand)
	var name:="hand-point" if tool=="call" else "hand-pet" if holding and tool=="hand" else "hand-open"
	hand_layer.draw_texture_rect(images[name],Rect2(at-Vector2(22,18),Vector2(58,58)),false)
	if IDS.has(tool):
		var icon:String={"clean":"cloth","frame":"patch","line":"spool"}[tool]
		hand_layer.draw_texture_rect(images[icon],Rect2(at-Vector2(42,4),Vector2(38,38)),false)

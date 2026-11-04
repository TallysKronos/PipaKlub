extends "res://scripts/overworld/pier_play.gd"
## Starter neighborhood uses the dock's real actor, trail, depth and input system.
var conversation: Array[String] = []
var conversation_name := ""
var conversation_index := 0
var dialogue_panel: PanelContainer
var dialogue_name: Label
var dialogue_text: Label
var greeted: Dictionary = {}
var near_person: Dictionary = {}
var near_house: Dictionary = {}

func _ready() -> void:
	DisplayServer.window_set_title("PipaKlub · Vila do Primeiro Vento")
	world_scene_path = "res://scenes/overworld/neighborhood/bairro-inicial.tscn"
	cell = Vector2(4.4,17.4)
	surface = "4:17"
	elevation = 8
	follower = Vector2(4.5,17.9)
	follower_height = 8
	follower_surface = "4:17"
	visited = {surface:true}
	super._ready()
	camera.zoom = Vector2.ONE*1.45
	for label in hud_root.find_children("*","Label",true,false):
		if label.text=="CAIS DOS ELOS":label.text="VILA DO PRIMEIRO VENTO"
	for button in pause_panel.find_children("*","Button",true,false):
		if button.text=="Recomeçar a travessia":button.text="Recomeçar o passeio"
		if button.text=="Fechar prévia":button.text="Fechar bairro"
	for label in pause_panel.find_children("*","Label",true,false):
		if label.text=="Uma pausa no cais":label.text="Uma pausa no bairro"
	_build_dialogue()
	_update_hint()

func _obstructed(p: Vector2,_id: String) -> bool:
	for blocker in world.blockers:
		var b: Array = blocker.bounds
		if p.x>b[0]-RADIUS and p.x<b[2]+RADIUS and p.y>b[1]-RADIUS and p.y<b[3]+RADIUS:return true
	for person in world.people:
		if p.distance_to(person.p)<.3:return true
	return false

func _physics_process(delta: float) -> void:
	if not conversation.is_empty():
		avatar.moving = false
		avatar.running = false
		return
	super._physics_process(delta)

func _goal() -> Dictionary:
	var p := Vector2(6.8,-.65) if not greeted.has("assis") else Vector2(25.8,-.6) if not greeted.has("lia") else Vector2(22,18.5)
	return {"p":p,"h":world.support(p)}

func _update_hint() -> void:
	near_person = {};near_house = {}
	var distance := 1.55
	for person in world.people:
		var d: float = cell.distance_to(person.p)
		if d<distance:near_person=person;distance=d
	if near_person.is_empty():
		for house in world.houses:
			if cell.distance_to(house.door)<1.0:near_house=house;break
	objective.text = "O bairro onde tudo começa"
	progress_label.text = "Conheça o professor · suba a ladeira pela calçada." if not greeted.has("assis") else "Visite a Lia · a lojinha fica na rua alta." if not greeted.has("lia") else "Você já conhece o caminho. Explore os quintais e a pracinha."
	var action := Controls.prompt("interact")
	context.text = action+" · Conversar com "+str(near_person.name) if not near_person.is_empty() else action+" · "+("Casa do Kael" if near_house.get("id")=="casa-kael" else "Examinar a entrada") if not near_house.is_empty() else "WASD / setas · caminhar     "+Controls.prompt("map")+" · ver o bairro     Esc · pausa"
	if overview:context.text = Controls.prompt("map")+" · voltar ao passeio"

func interact() -> void:
	if paused or overview:return
	if not conversation.is_empty():
		conversation_index += 1
		if conversation_index>=conversation.size():
			conversation.clear()
			dialogue_panel.hide()
			context.show()
			_update_hint()
		else:dialogue_text.text = conversation[conversation_index]+"\n\n"+Controls.prompt("interact")+" · continuar"
		return
	_update_hint()
	if not near_person.is_empty():
		greeted[near_person.id]=true
		_say(near_person.name,[near_person.line])
	elif not near_house.is_empty():
		var message := "Minha casa. Um quintal, uma pipa e um mundo inteiro lá fora." if near_house.id=="casa-kael" else "O professor prefere conversar no jardim, de olho na direção do vento." if near_house.id=="professor" else "A Lia está na frente da loja. Ela conhece cada papel e cada linha destas prateleiras." if near_house.id=="loja" else "Dá para ouvir uma conversa e o rádio baixinho. O bairro já acordou."
		_say("Kael",[message])

func _say(speaker: String,lines: Array) -> void:
	conversation.assign(lines)
	conversation_name=speaker;conversation_index=0
	dialogue_name.text=speaker
	dialogue_text.text=conversation[0]+"\n\n"+Controls.prompt("interact")+" · continuar"
	dialogue_panel.show();context.hide();avatar.moving=false

func _unhandled_input(event: InputEvent) -> void:
	Controls.observe(event)
	if not conversation.is_empty():
		if Controls.cancel(event):
			conversation.clear();dialogue_panel.hide();context.show();_update_hint()
		elif Controls.pressed(event,"interact"):interact()
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)
	if Controls.pressed(event,"map") and not paused:
		camera.zoom=Vector2.ONE*(.44 if overview else 1.45)
		_update_hint()

func _build_dialogue() -> void:
	dialogue_panel=PanelContainer.new()
	hud_root.add_child(dialogue_panel)
	dialogue_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_panel.offset_left=90;dialogue_panel.offset_right=-90;dialogue_panel.offset_top=-195;dialogue_panel.offset_bottom=-20
	dialogue_panel.add_theme_stylebox_override("panel",Hud.panel("paper"))
	var text := VBoxContainer.new()
	dialogue_panel.add_child(text)
	dialogue_name=Label.new();dialogue_name.add_theme_color_override("font_color",Hud.INK)
	dialogue_name.add_theme_font_override("font",Hud.font(true));dialogue_name.add_theme_font_size_override("font_size",24)
	text.add_child(dialogue_name)
	dialogue_text=Label.new();dialogue_text.add_theme_color_override("font_color",Hud.INK)
	dialogue_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text.add_child(dialogue_text)
	dialogue_panel.hide()

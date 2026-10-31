extends "res://scripts/overworld/neighborhood_play.gd"
## Campaign adapter: native city geometry, existing campaign save/menu contracts.
signal action_requested(id: String)
signal menu_requested
const Checkpoint = preload("res://scripts/campaign/neighborhood_checkpoint.gd")
var saved_player: Dictionary = {}
var checkpoint_position := Checkpoint.HOME
var exploration_hud: Control
var data := {"walkable":[[0,-7,32,35]]}
var player: Vector2:
	get:return cell
var autosave_age := 0.0
var last_saved_cell := Vector2.ZERO
var exit_id := ""
var active_dialogue: Control

# Merge identical row spans before projection: streets stay legible without a tile grid.
func _map_spans(kind: String) -> Array[Rect2]:
	var spans: Array[Rect2] = []
	for v in range(-7,28):
		var start := -1
		for u in range(33):
			var matches: bool = u<32 and world.find_surface(world.cell_id(u,v)).get("kind","")==kind
			if matches and start<0:start=u
			if matches or start<0:continue
			var merged := false
			for i in spans.size():
				if spans[i].position.x==start and spans[i].size.x==u-start and spans[i].end.y==v:
					spans[i].size.y+=1;merged=true;break
			if not merged:spans.append(Rect2(start,v,u-start,1))
			start=-1
	return spans

func _map_rect(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)])

func map_polygons() -> Array[PackedVector2Array]:
	var paths: Array[PackedVector2Array] = []
	for kind in ["paving","asphalt"]:
		for span in _map_spans(kind):paths.append(_map_rect(span))
	return paths

func map_regions() -> Array[Dictionary]:
	var regions: Array[Dictionary] = [{"polygon":_map_rect(Rect2(0,-7,32,35)),"color":Color("647B58")}]
	for kind in ["paving","asphalt"]:
		for span in _map_spans(kind):
			regions.append({"polygon":_map_rect(span),"color":Color("D8CDAF") if kind=="paving" else Color("405766")})
	return regions

func map_landmarks() -> Array[Dictionary]:
	var markers: Array[Dictionary] = []
	for house in world.houses:
		var title: String={"casa-kael":"Casa do Kael","professor":"Ateliê do professor","loja":"Loja da Lia"}.get(house.id,"")
		if not title.is_empty():markers.append({"point":house.door,"text":title})
	return markers

func _ready() -> void:
	super._ready()
	cell=Checkpoint.resolve(checkpoint_position,saved_player)
	surface=world.cell_id(floori(cell.x),floori(cell.y))
	# A saved point can become obstructed after an art/layout update.
	if _obstructed(cell,surface):
		cell=Checkpoint.HOME
		surface=world.cell_id(floori(cell.x),floori(cell.y))
	elevation=world.surface_height(world.find_surface(surface),cell,true)
	follower=cell;follower_height=elevation;follower_surface=surface
	trail=[{"p":cell,"h":elevation,"surface":surface,"distance":0.0}]
	distance_walked=0
	last_saved_cell=cell
	for child in hud_root.get_children():
		if child is CanvasItem and child!=dialogue_panel:child.hide()
	exploration_hud=load("res://scripts/campaign/hud_exploration.gd").new()
	exploration_hud.area_name="Vila do Primeiro Vento"
	exploration_hud.player_data=saved_player
	exploration_hud.subject=self
	hud_root.add_child(exploration_hud)
	exploration_hud.map=Hud.map_for(self,exploration_hud)
	exploration_hud.chosen.connect(func(id: String):action_requested.emit(id))
	_equip_partner()
	_refresh_visuals();_update_hint()
	camera.position=player_root.position-Vector2(0,45)
	camera.reset_smoothing()

func _equip_partner() -> void:
	for equipped: Dictionary in saved_player.get("partners",[]):
		if equipped.id!=saved_player.get("equippedPartnerId",""):continue
		var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
		var model: String={"basica":"basic-carcara","mata":"basic-mata-verde","azulao":"basic-azulao","raio":"basic-raio-de-sol"}.get(equipped.modelId,equipped.modelId)
		var art: Dictionary=catalog.combat.get(model,{})
		if art.is_empty():return
		partner.texture=load("res://assets/campaign/"+str(art.image))
		partner_frames=art.animations.idle.duplicate(true)
		var frame: Dictionary=partner_frames[0]
		var bounds: Rect2i=partner.texture.get_image().get_region(Rect2i(frame.x,frame.y,frame.w,frame.h)).get_used_rect()
		if bounds.size.y>0:
			partner.scale=Vector2.ONE*30.0/float(bounds.size.y)
			partner.offset=Vector2(float(frame.w)*.5-bounds.get_center().x,float(frame.h)*.5-bounds.end.y)
		return

func project(point: Vector2) -> Vector2:
	return world.iso(point,world.support(point))

func _process(delta: float) -> void:
	if paused or not conversation.is_empty():return
	autosave_age+=delta
	if autosave_age>=5 and last_saved_cell.distance_to(cell)>.15:
		autosave_age=0
		last_saved_cell=cell
		action_requested.emit("autosave")

func _goal() -> Dictionary:
	var p: Vector2=Checkpoint.PARK if saved_player.get("journey",{}).get("phase")=="complete" else Checkpoint.PROFESSOR
	return {"p":p,"h":world.support(p)} if is_instance_valid(world) else {"p":p,"h":8}

func _update_hint() -> void:
	super._update_hint()
	context.hide();objective.hide();progress_label.hide()
	if not is_instance_valid(exploration_hud):return
	exit_id="morro" if cell.distance_to(Checkpoint.MORRO)<1.6 else "park" if cell.distance_to(Checkpoint.PARK)<1.6 else ""
	var hint := ""
	if not exit_id.is_empty():hint="Seguir para o Morro do Sol" if exit_id=="morro" else "Seguir para o parque"
	elif not near_person.is_empty():hint="Entrar no ateliê do professor" if near_person.id=="assis" else "Conversar com "+str(near_person.name)
	elif not near_house.is_empty():hint="Entrar no ateliê" if near_house.id=="professor" else "Examinar a entrada"
	exploration_hud.prompt.text=hint
	exploration_hud.objective.text="Explore o parque ou siga para o Morro do Sol." if saved_player.get("journey",{}).get("phase")=="complete" else "Suba a ladeira e entre no ateliê do professor."

func interact() -> void:
	if paused:return
	if is_instance_valid(active_dialogue):
		if active_dialogue.page_index<active_dialogue.pages.size()-1:active_dialogue.next_page()
		else:active_dialogue._finish(true)
		return
	if not conversation.is_empty():
		super.interact();return
	_update_hint()
	if not exit_id.is_empty():
		if saved_player.get("journey",{}).get("phase")!="complete":
			_say("Kael",["Primeiro vou concluir meu treino e montar minha pipa com o professor."])
		else:action_requested.emit(exit_id)
	elif near_person.get("id")=="assis" or near_house.get("id")=="professor":action_requested.emit("professor-home")
	else:super.interact()

func _say(speaker: String,lines: Array) -> void:
	if is_instance_valid(active_dialogue):return
	conversation.assign(lines)
	dialogue_panel.hide()
	avatar.moving=false;avatar.running=false
	active_dialogue=load("res://scripts/campaign/hud_dialogue.gd").new()
	active_dialogue.title=speaker
	active_dialogue.dialog_text="\n\n".join(lines)
	active_dialogue.ok_button_text="Continuar"
	active_dialogue.confirmed.connect(_close_dialogue)
	active_dialogue.canceled.connect(_close_dialogue)
	hud_root.add_child(active_dialogue)

func _close_dialogue() -> void:
	conversation.clear()
	if is_instance_valid(active_dialogue):
		hud_root.remove_child(active_dialogue)
		active_dialogue.queue_free()
	active_dialogue=null
	_update_hint()

func _unhandled_input(event: InputEvent) -> void:
	Controls.observe(event)
	if paused:return
	if is_instance_valid(active_dialogue):
		if Controls.pressed(event,"interact"):
			if active_dialogue.page_index<active_dialogue.pages.size()-1:active_dialogue.next_page()
			else:active_dialogue._finish(true)
		get_viewport().set_input_as_handled()
		return
	if not conversation.is_empty():
		super._unhandled_input(event);return
	if Controls.cancel(event):
		menu_requested.emit();get_viewport().set_input_as_handled()
	elif Controls.pressed(event,"map"):
		action_requested.emit("map");get_viewport().set_input_as_handled()
	elif Controls.pressed(event,"interact"):
		interact();get_viewport().set_input_as_handled()

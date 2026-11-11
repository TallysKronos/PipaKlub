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
	var quest=preload("res://scripts/campaign/mount_quest.gd")
	if quest.available(saved_player) and not quest.owned(saved_player):
		markers.append({"point":quest.LIA if quest.stage(saved_player)==1 else quest.ZECA,"text":"Lia · fecho da guia" if quest.stage(saved_player)==1 else "Zeca · montaria"})
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
	for offset in [Vector2(-.49,.49),Vector2(.49,-.49)]:
		var behind := state()
		for step in range(1, 9):
			behind = resolve_step(behind, cell + offset * (float(step) / 8.0))
		if behind.p.distance_to(cell + offset) < .01 and absf(behind.h - elevation) < 1:
			follower = behind.p
			follower_height = behind.h
			follower_surface = behind.surface
			trail.push_front({"p":follower,"h":follower_height,"surface":follower_surface,"distance":-.7})
			break
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
	var model_id := CompanionFollow.equipped_model(saved_player)
	partner_root.visible = not model_id.is_empty()
	if not partner_root.visible: return
	if CompanionFollow.setup_overworld_art(partner, model_id, avatar.scale.y):
		partner_frames.clear()
		return
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	var art: Dictionary = catalog.combat.get(CompanionFollow.combat_art_id(model_id), {})
	if art.is_empty(): return
	partner.texture = load("res://assets/campaign/" + str(art.image))
	partner_frames = art.animations.idle.duplicate(true)
	var frame: Dictionary = partner_frames[0]
	var bounds: Rect2i = partner.texture.get_image().get_region(Rect2i(frame.x,frame.y,frame.w,frame.h)).get_used_rect()
	if bounds.size.y > 0:
		partner.scale = Vector2.ONE * 30.0 / float(bounds.size.y)
		partner.offset = Vector2(float(frame.w)*.5-bounds.get_center().x,float(frame.h)*.5-bounds.end.y)

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
	var quest=preload("res://scripts/campaign/mount_quest.gd")
	if quest.available(saved_player) and quest.stage(saved_player) in [1,2]:
		var target:Vector2=quest.LIA if quest.stage(saved_player)==1 else quest.ZECA
		return {"p":target,"h":world.support(target)}
	var p: Vector2=Checkpoint.PARK if saved_player.get("journey",{}).get("phase")=="complete" else Checkpoint.PROFESSOR
	return {"p":p,"h":world.support(p)} if is_instance_valid(world) else {"p":p,"h":8}

func _update_hint() -> void:
	super._update_hint()
	# At the shop threshold, entering wins; Lia can still be greeted a step away.
	for house in world.houses:
		if house.id=="loja" and cell.distance_to(house.door)<.65:
			near_house=house;near_person={};break
	context.hide();objective.hide();progress_label.hide()
	if not is_instance_valid(exploration_hud):return
	exit_id="morro" if cell.distance_to(Checkpoint.MORRO)<1.6 else "park" if cell.distance_to(Checkpoint.PARK)<1.6 else ""
	var hint := ""
	if not exit_id.is_empty():hint="Seguir para o Morro do Sol" if exit_id=="morro" else "Seguir para o parque"
	elif not near_person.is_empty():hint="Entrar no ateliê do professor" if near_person.id=="assis" else "Conversar com "+str(near_person.name)
	elif not near_house.is_empty():hint="Entrar na Linha & Papel" if near_house.id=="loja" else "Entrar no ateliê" if near_house.id=="professor" else "Examinar a entrada"
	var quest=preload("res://scripts/campaign/mount_quest.gd")
	if quest.available(saved_player) and quest.stage(saved_player)<3:
		if near_person.get("id")=="zeca":hint+=" · Missão de montaria"
		elif near_person.get("id")=="lia" and quest.stage(saved_player)==1:hint+=" · Fecho da guia"
	exploration_hud.prompt.text=hint
	exploration_hud.objective.text=preload("res://scripts/campaign/kronasta_story.gd").objective(saved_player) if saved_player.get("journey",{}).get("phase")=="complete" else "Suba a ladeira e entre no ateliê do professor."
	if quest.available(saved_player) and quest.stage(saved_player) in [1,2]:exploration_hud.objective.text=quest.objective(saved_player)

func can_mount() -> bool:
	return preload("res://scripts/campaign/mount_quest.gd").eligible(saved_player)

func toggle_mount() -> void:
	if not can_mount() or not conversation.is_empty() or is_instance_valid(active_dialogue):return
	super.toggle_mount()

func interact() -> void:
	if has_node("HeleanaReunionMother") and cell.distance_to(Checkpoint.HOME)<=2.0:
		action_requested.emit("heleana-confession");return
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
	elif near_house.get("id")=="loja":action_requested.emit("kite-shop")
	elif near_house.get("id")=="casa-kael":action_requested.emit("kael-home")
	elif near_person.get("id") in ["zeca","lia"]:action_requested.emit("mount-quest:"+str(near_person.id))
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

# Same directional mother art as the house, staged at its real exterior entrance.
func build_heleana_reunion()->void:
	var mother:=Sprite2D.new()
	mother.name="HeleanaReunionMother"
	preload("res://scripts/npc_pixel_sprite.gd").setup(mother,"mae",48.0,"se")
	mother.position=project(Checkpoint.HOME+Vector2(1.0,1.0))
	add_child(mother)
	var retalho:=Sprite2D.new()
	retalho.name="HeleanaReunionRetalho"
	retalho.texture=load("res://assets/campaign/retalho-v1/overworld-idle-eight.png")
	retalho.region_enabled=true
	retalho.region_rect=Rect2(64,0,64,96)
	retalho.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	retalho.scale=Vector2.ONE*48.0/82.0
	retalho.offset=Vector2(0,-44)
	retalho.position=project(Checkpoint.HOME+Vector2(2.0,.4))
	add_child(retalho)

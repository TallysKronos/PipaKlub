extends "res://scripts/overworld/view.gd"
## Campaign adapter over the reviewed renderer/controller, with no preview grants or warps.
const Checkpoint = preload("res://scripts/campaign/park_checkpoint.gd")
const Park = preload("res://scripts/campaign/park_data.gd")
const Training=preload("res://scripts/campaign/park_training.gd")
const Pacing = preload("res://scripts/campaign/park_pacing.gd")
const Bosque = preload("res://scripts/campaign/bosque_campaign.gd")
signal action_requested(id: String)
signal menu_requested
signal exit_requested(event: Dictionary)
var checkpoint_space := Checkpoint.SPACE
var saved_checkpoint: Dictionary = {}
var saved_player: Dictionary = {}
var content: Dictionary = {}
var paused := false
var ui_theme: Theme
var exploration_hud: Control
var markers: Array = []
var save_distance := 0.0
var save_age := 0.0
var encounter_threshold := 3.5
var encounter_walk_time := 0.0
var encounter_grace := 0.0
var companion_frames: Array = []
var item_receipt: Dictionary = {}
var _map_floors: Array[PackedVector2Array] = []
var collected_pieces: Dictionary = {}
var reduced_motion := false
var guardian_focus := false
var guardian_art: Sprite2D
var guardian_frames: Array = []
var presentation_age := 0.0

func _process(delta: float) -> void:
	presentation_age+=delta
	if is_instance_valid(guardian_art) and not guardian_frames.is_empty() and (not paused or guardian_focus):
		var frame: Dictionary=guardian_frames[int(presentation_age*8)%guardian_frames.size()]
		guardian_art.region_rect=Rect2(frame.x,frame.y,frame.w,frame.h)

func focus_guardian() -> void:
	guardian_focus=true
	paused=true
	path.clear()
	avatar.moving=false
	var destination: Vector2=model.project(Checkpoint.target("park-veredas","boss"))
	if reduced_motion: camera.position=destination
	else: await create_tween().tween_property(camera,"position",destination,.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished

func restore_guardian_focus() -> void:
	if not guardian_focus: return
	if reduced_motion: camera.position=model.project(player)
	else: await create_tween().tween_property(camera,"position",model.project(player),.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished
	guardian_focus=false
	paused=false
	encounter_grace=maxf(encounter_grace,6.0)

func _ready() -> void:
	campaign_mode = true
	art_preview = true
	area_id = Checkpoint.MAPS[saved_checkpoint.scene]
	super()
	interface.hide()
	player = Checkpoint.resolve(saved_checkpoint)
	follower = player
	camera.zoom = Vector2.ONE*(1.0 if Checkpoint.is_bosque(saved_checkpoint.scene) else 1.15)
	_refresh_positions()
	camera.reset_smoothing()
	var partner_id := "rabbito"
	for partner in saved_player.get("partners",[]):
		if partner.id==saved_player.get("equippedPartnerId",""): partner_id=partner.modelId
	var atlas_id: String = {"basica":"basic-carcara","mata":"basic-mata-verde","azulao":"basic-azulao","raio":"basic-raio-de-sol"}.get(partner_id,partner_id)
	var atlas: Dictionary = content.combat.get(atlas_id,content.combat.rabbito)
	companion.texture = load("res://assets/campaign/"+atlas.image)
	companion_frames = atlas.animations.idle
	var ui := CanvasLayer.new()
	add_child(ui)
	exploration_hud = load("res://scripts/campaign/hud_exploration.gd").new()
	exploration_hud.subject = self
	exploration_hud.area_name = model.data.name
	exploration_hud.player_data = saved_player
	ui.add_child(exploration_hud)
	hint = exploration_hud.prompt
	exploration_hud.map = Hud.map_for(self,ui)
	exploration_hud.chosen.connect(func(id: String):
		if id=="menu": menu_requested.emit()
		else: action_requested.emit(id))
	_build_markers()
	refresh(saved_player)
	for actor in npc_nodes:
		if actor.root.get_meta("event",{}).get("props",{}).get("acao","")=="parkBoss" and actor.visual.get_child_count()>0:
			guardian_art=actor.visual.get_child(0)
			guardian_frames=content.combat.lacertubo.animations.idle
	_roll_encounter_distance()
	encounter_grace=Pacing.walking_grace(saved_player)

func _build_events() -> void:
	# Dito has no approved overworld sprite in the delivery. Do not duplicate another
	# character or leave an invisible person as an interaction target.
	if Checkpoint.is_bosque(area_id):
		interaction_events=interaction_events.filter(func(event: Dictionary): return event.type!="npc" or event.props.has("npcIdentity"))
	interaction_events.append_array(Training.events(area_id,model))
	interaction_events.append_array(Bosque.rest_events(area_id,model))
	super()

func _roll_encounter_distance() -> void:
	var bounds:=Pacing.distance_range(saved_checkpoint.scene)
	encounter_threshold=randf_range(bounds.x,bounds.y)

func project(point: Vector2) -> Vector2:
	return model.project(point)

func map_polygons() -> Array[PackedVector2Array]:
	if not _map_floors.is_empty(): return _map_floors
	# Row runs avoid thousands of tiny polygons in the HUD.
	for v in int(model.data.h):
		var start := -1
		for u in range(int(model.data.w)+1):
			var walk: bool = u<int(model.data.w) and model.walkable(Vector2i(u,v))
			if walk and start<0: start=u
			if not walk and start>=0:
				_map_floors.append(PackedVector2Array([Vector2(start,v),Vector2(u,v),Vector2(u,v+1),Vector2(start,v+1)]))
				start=-1
	return _map_floors

func _build_markers() -> void:
	for event in model.data.events:
		var tail: bool = event.props.get("acao","")=="veredasTail"
		if not tail and (event.type!="item" or event.props.get("visibilidade","")=="escondido"): continue
		var marker := Node2D.new()
		var point := Vector2(event.u+.5,event.v+.5)
		marker.position = model.project(point,false)
		var art := Sprite2D.new()
		art.texture = load("res://assets/campaign/nina-tail.png") if tail else Hud.item_art(str(event.props.get("item","folha")))
		if art.texture==null: marker.free(); continue
		art.scale = Vector2.ONE*(48.0 if tail else 18.0)/maxf(art.texture.get_width(),art.texture.get_height())
		art.position = Vector2(0,-model.height_at(point)*64-12)
		marker.add_child(art)
		if tail:
			var ring:=Line2D.new()
			ring.width=2.0
			ring.default_color=Color(1.0,.8,.3,.8)
			ring.position=Vector2(0,-model.height_at(point)*64)
			for i in 33:
				var angle: float=TAU*i/32
				ring.add_point(Vector2(cos(angle)*18,sin(angle)*8))
			marker.add_child(ring)
		actors.add_child(marker)
		markers.append({"node":marker,"event":event})

func refresh(value: Dictionary) -> void:
	saved_player = value.duplicate(true)
	collected_pieces.clear()
	for actor in npc_nodes:
		for event in model.data.events:
			if event.type=="npc" and actor.point==Vector2(event.u+.5,event.v+.5): actor.root.visible=Checkpoint.allowed(event,saved_player,area_id)
	for marker in markers: marker.node.visible=Checkpoint.allowed(marker.event,saved_player,area_id)
	for piece in model.data.pieces:
		if piece.asset!="bau": continue
		var id: String = piece.props.get("bau","parque:"+area_id+":"+str(int(piece.id)))
		if id not in saved_player.get("openedChests",[]): continue
		collected_pieces[str(int(piece.id))]=true
		var node: Node2D = piece_nodes.get(str(piece.id))
		if node!=null and node.has_node("Art"):
			var art: Sprite2D = node.get_node("Art")
			var entry: Dictionary = kits[0].pieces.bau.variants.aberto
			art.texture = load(kits[0].root+entry.file)
			art.position=node.get_meta("center_offset",Vector2.ZERO)-Vector2(entry.anchor[0],entry.anchor[1])-Vector2(0,model.height_at(Vector2(piece.u+.5,piece.v+.5))*64)
	if is_instance_valid(exploration_hud):
		exploration_hud.refresh(saved_player)
		var scene: String=saved_checkpoint.get("scene","park-trail")
		exploration_hud.objective.text = Bosque.objective(saved_player,scene) if Checkpoint.is_bosque(scene) else Training.objective(saved_player,scene)

func _physics_process(delta: float) -> void:
	if paused: avatar.moving=false; return
	if not item_receipt.is_empty():
		item_receipt.time+=delta
		avatar.item_pose(minf(1.0,item_receipt.time/item_receipt.duration),item_receipt.facing)
		if item_receipt.time>=item_receipt.duration: avatar.stop_item(); item_receipt.clear()
		return
	var before := player
	super(delta)
	if not companion_frames.is_empty():
		var frame: Dictionary = companion_frames[int(clock*12)%companion_frames.size()]
		companion.region_rect=Rect2(frame.x,frame.y,frame.w,frame.h)
	nearby = {}
	var nearest := 1.8
	for event in interaction_events:
		if event.type=="entrada" or not Checkpoint.allowed(event,saved_player,area_id): continue
		if event.type=="piece" and collected_pieces.has(str(int(str(event.get("piece_id","0")).to_float()))): continue
		var at := Vector2(event.u+.5,event.v+.5)
		var gap := player.distance_to(at)
		if gap<nearest and absf(model.height_at(player)-model.height_at(at))<.25:
			nearby=event; nearest=gap
	hint.text = "" if nearby.is_empty() else nearby.name
	var moved := player.distance_to(before)
	if saved_checkpoint.scene=="park-veredas" and saved_player.get("flags",{}).get("ninaAccepted",false) and not saved_player.flags.get("guardianDefeated",false):
		var boss_gap: float=player.distance_to(Checkpoint.target("park-veredas","boss"))
		if boss_gap<8.0:
			exploration_hud.objective.text="Lacertubo guarda a rabiola. Aproxime-se para enfrentá-lo ou recue para se preparar."
			if not saved_player.flags.get("lacertuboIntroduced",false):
				paused=true
				action_requested.emit("guardian-approach")
				return
		else: exploration_hud.objective.text=Training.objective(saved_player,saved_checkpoint.scene)
	save_distance+=moved
	save_age+=delta
	if moved>0:
		var weight: float=0.0 if Training.needs_rest(saved_player) else Pacing.weight(model,player)
		if encounter_grace>0:
			encounter_grace=maxf(0,encounter_grace-delta)
		elif weight>0:
			grass_distance+=moved*weight
			encounter_walk_time+=delta
	if not Training.needs_rest(saved_player) and grass_distance>=encounter_threshold and encounter_walk_time>=Pacing.MIN_WALK_SECONDS and Pacing.weight(model,player)>0:
		grass_distance=0
		encounter_walk_time=0
		_roll_encounter_distance()
		action_requested.emit("wild")
	elif save_distance>=12 and save_age>=8:
		save_distance=0; save_age=0
		action_requested.emit("autosave")

func interact() -> void:
	if paused or not item_receipt.is_empty() or nearby.is_empty() or not Checkpoint.allowed(nearby,saved_player,area_id): return
	if nearby.type=="piece" and collected_pieces.has(str(int(str(nearby.get("piece_id","0")).to_float()))): return
	if nearby.type=="saida": exit_requested.emit(nearby.duplicate(true)); return
	if nearby.type=="item": action_requested.emit("park-loot:"+str(int(nearby.id))); return
	if nearby.type=="piece" and nearby.get("asset","")=="bau":
		for piece in model.data.pieces:
			if str(piece.id)==str(nearby.piece_id):
				action_requested.emit("chest:"+str(piece.props.bau) if piece.props.has("bau") else "park-loot:piece-"+str(int(piece.id)))
		return
	var action: String = nearby.props.get("acao","")
	if action=="parkTraining":
		action_requested.emit("training:"+str(nearby.props.trainer))
		return
	if nearby.name=="Nina" or action=="veredasNina": action_requested.emit("nina")
	elif action=="parkBoss": action_requested.emit("boss")
	elif action=="veredasTail": action_requested.emit("tail")
	else: action_requested.emit("park-event:"+str(int(nearby.id)))

func celebrate_item(message: String) -> bool:
	if not item_receipt.is_empty(): return false
	path.clear()
	avatar.moving=false
	item_receipt={"time":0.0,"duration":(avatar.item_frames.durationMs+avatar.item_frames.turnMs)/1000.0,"facing":avatar.facing}
	exploration_hud.push_notice(message,"item")
	return true

func _unhandled_input(event: InputEvent) -> void:
	if guardian_focus: return
	if Controls.cancel(event):
		get_viewport().set_input_as_handled()
		menu_requested.emit()
		return
	if paused or not item_receipt.is_empty(): return
	super(event)

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
var mormaco:Node2D
var blue_guide:Node2D
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
	for offset in [Vector2(-.56,.56), Vector2(.56,-.56), Vector2(-.8,0), Vector2(.8,0), Vector2(0,-.8), Vector2(0,.8), Vector2(-.56,-.56), Vector2(.56,.56)]:
		var candidate: Vector2 = player + offset
		if model.clear_segment(candidate, player):
			follower = candidate
			break
	camera.zoom = Vector2.ONE*(1.0 if Checkpoint.is_kronasta(saved_checkpoint.scene) else 1.15)
	if area_id.begins_with("gelo-") or area_id.begins_with("mina-ferro-") or area_id.begins_with("submerso-"):camera.zoom=Vector2.ONE
	_refresh_positions()
	camera.reset_smoothing()
	var partner_id := CompanionFollow.equipped_model(saved_player)
	companion.visible = not partner_id.is_empty()
	if companion.visible and not CompanionFollow.setup_overworld_art(companion, partner_id, avatar.scale.y):
		var atlas: Dictionary = content.combat.get(CompanionFollow.combat_art_id(partner_id), content.combat.rabbito)
		companion.texture = load("res://assets/campaign/" + atlas.image)
		companion_frames = atlas.animations.idle
	CompanionFollow.orient(companion, avatar.facing)
	var ui := CanvasLayer.new()
	add_child(ui)
	exploration_hud = load("res://scripts/campaign/hud_exploration.gd").new()
	exploration_hud.subject = self
	exploration_hud.area_name = model.data.name
	if Checkpoint.region_of(saved_checkpoint.scene)=="palafitas":
		exploration_hud.area_name={"a":"Palafitas · Docas de chegada","b":"Palafitas · Passarelas","c":"Palafitas · Doca de Caio"}.get(saved_checkpoint.scene.right(1),model.data.name)
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
	if saved_checkpoint.scene=="kronasta-pantano-c" and load("res://scripts/campaign/mormaco_story.gd").available(saved_player):
		mormaco=load("res://scripts/campaign/mormaco_overworld.gd").new();add_child(mormaco)
	if saved_checkpoint.scene=="park-trail" and load("res://scripts/campaign/blue_exam_preparation.gd").eligible(saved_player):
		var entry:=Node2D.new();entry.position=model.project(Vector2(34.5,31.5));actors.add_child(entry)
		var arrow:=Line2D.new();arrow.width=3;arrow.default_color=Color("43c5df");arrow.points=PackedVector2Array([Vector2(-14,7),Vector2(14,-7),Vector2(3,-9),Vector2(14,-7),Vector2(9,3)]);entry.add_child(arrow)
		var label:=Label.new();label.text="Pátio da Liga";label.position=Vector2(-45,-32);label.add_theme_font_size_override("font_size",14);label.add_theme_color_override("font_outline_color",Color.BLACK);label.add_theme_constant_override("outline_size",5);entry.add_child(label)
	if saved_checkpoint.scene=="parque-patio-liga":
		follower_root.hide();exploration_hud.show_partner=false;exploration_hud.partner_panel.hide()
		blue_guide=load("res://scripts/campaign/blue_exam_guide.gd").new();add_child(blue_guide)
		var marks=load("res://scripts/campaign/blue_exam.gd")
		exploration_hud.objective.text=marks.objective(saved_player)

func _build_events() -> void:
	if Checkpoint.region_of(saved_checkpoint.scene)=="palafitas":
		for e:Dictionary in Checkpoint.data(saved_checkpoint.scene).events:
			if e.props.get("district","")=="palafitas" and Checkpoint.allowed(e,saved_player,area_id) and not interaction_events.any(func(existing):return int(existing.id)==int(e.id)):
				interaction_events.append(e.duplicate(true))
	if load("res://scripts/campaign/mormaco_story.gd").available(saved_player):
		interaction_events.append_array(load("res://scripts/campaign/mormaco_story.gd").events(saved_checkpoint.scene))
		if saved_checkpoint.scene=="kronasta-pantano-c":
			for e:Dictionary in interaction_events:
				if int(e.id)==7:e.name="Pouso da margem · descansar";e.props.acao="mormacoRest"
	if saved_checkpoint.scene=="parque-patio-liga":
		var start:Vector2=load("res://scripts/campaign/blue_exam.gd").escort_start(saved_player)
		for event:Dictionary in interaction_events:
			if event.props.get("blueAction","")=="escort":event.u=int(start.x);event.v=int(start.y)
	if saved_checkpoint.scene=="park-veredas":interaction_events.append_array(preload("res://scripts/campaign/feira_story.gd").door_events(saved_player))
	if saved_checkpoint.scene=="park-veredas":
		for event:Dictionary in preload("res://scripts/campaign/canal_gate.gd").events(saved_player):
			if Checkpoint.allowed(event,saved_player,area_id):interaction_events.append(event)
	if Checkpoint.region_of(saved_checkpoint.scene)=="montanha":
		for event:Dictionary in Checkpoint.data(saved_checkpoint.scene).events:
			if event.props.get("district","")=="alto-da-serra" and Checkpoint.allowed(event,saved_player,area_id) and not interaction_events.any(func(existing):return int(existing.id)==int(event.id)):
				interaction_events.append(event.duplicate(true))
	var district_region:=Checkpoint.region_of(saved_checkpoint.scene)
	if district_region in ["bambuzal","beira-canal","feira","cais","industrial","palafitas"]:
		var rules=preload("res://scripts/campaign/district_rules.gd")
		var title:Dictionary=rules.entry(saved_player,district_region)
		for event:Dictionary in model.data.events+interaction_events:
			if event.props.get("duel","")==district_region+"-5":event.name=rules.opponent_name(saved_player,district_region) if title.completed and title.champion!="player" else rules.definition(district_region).champion.name
	if district_region=="cais":
		for event:Dictionary in model.data.events+interaction_events:
			if event.props.get("duel","")=="cais-5":
				event.props.storySpritePath="res://assets/npc-ds/cais-v1/"+event.name.to_lower()+".png"
	if district_region=="palafitas":
		for event:Dictionary in interaction_events:
			if event.props.get("duel","")=="palafitas-5":
				var actor_id:String="caio" if event.name=="Caio Garça" else event.name.to_lower()
				event.props.storySpritePath="res://assets/npc-ds/palafitas-v1/"+actor_id+".png"
	if district_region=="industrial":
		for event:Dictionary in model.data.events+interaction_events:
			if event.props.get("duel","")=="industrial-5":
				var actor_id:String=event.name.to_lower().replace(" ","-")
				event.props.storySpritePath="res://assets/npc-ds/vila-operaria-v1/"+actor_id+".png"
	if district_region=="feira":
		for event:Dictionary in model.data.events+interaction_events:
			if event.props.get("duel","")=="feira-5":
				var actor_id:String={"Veyra":"veyra","Orven":"orven","Zafri":"zafri","Nymel":"nymel","Dona Zulmira":"zulmira"}.get(event.name,"zulmira")
				event.props.storySpritePath="res://assets/npc-ds/feira-v1/"+actor_id+".png"
	if model.data.get("forest",{}).get("nativeProps",false):
		for event in Checkpoint.data(saved_checkpoint.scene).events:
			if model.data.events.any(func(existing: Dictionary): return int(existing.id)==int(event.id)): continue
			model.data.events.append(event.duplicate(true))
			interaction_events.append(event.duplicate(true))
	# Dito has no approved overworld sprite in the delivery. Do not duplicate another
	# character or leave an invisible person as an interaction target.
	if Checkpoint.is_bosque(area_id):
		interaction_events=interaction_events.filter(func(event: Dictionary): return event.type!="npc" or event.props.has("npcIdentity") or event.props.has("storySpritePath"))
	if saved_checkpoint.scene=="park-clearing":
		for e:Dictionary in preload("res://scripts/campaign/tyler_clareira.gd").events():
			if not interaction_events.any(func(existing):return int(existing.id)==int(e.id)):interaction_events.append(e)
	if saved_checkpoint.scene=="kronasta-montanha-c":
		interaction_events.append_array(preload("res://scripts/campaign/tufanocorte_story.gd").lesson_events(saved_player))
		interaction_events.append_array(preload("res://scripts/campaign/tufanocorte_story.gd").wind_events(saved_player))
	if saved_checkpoint.scene=="mina-ferro-a":
		interaction_events.append_array(preload("res://scripts/campaign/tufanocorte_story.gd").gallery_events(saved_player))
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
	if saved_checkpoint.get("scene")=="parque-patio-liga":
		var at:Vector2=load("res://scripts/campaign/blue_exam.gd").escort_start(saved_player)
		for event:Dictionary in interaction_events:
			if event.props.get("blueAction","")=="escort":event.u=int(at.x);event.v=int(at.y)
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
		exploration_hud.objective.text = Bosque.objective(saved_player,scene) if Checkpoint.is_kronasta(scene) else Training.objective(saved_player,scene)
		if Checkpoint.is_regional_preview(scene) and not Checkpoint.is_kronasta(scene):exploration_hud.objective.text="Explore os caminhos · M para viajar por Kronasta."
		if scene=="parque-patio-liga":exploration_hud.objective.text=load("res://scripts/campaign/blue_exam.gd").objective(saved_player)
	if is_instance_valid(mormaco):mormaco.refresh()

func toggle_run() -> void:
	if not paused and item_receipt.is_empty():super.toggle_run()

func _physics_process(delta: float) -> void:
	if paused: avatar.moving=false; avatar.running=false; return
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
		var weight: float=0.0 if saved_checkpoint.scene.begins_with("caverna-mural-") or Training.needs_rest(saved_player) or Checkpoint.is_regional_preview(saved_checkpoint.scene) else Pacing.weight(model,player)
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

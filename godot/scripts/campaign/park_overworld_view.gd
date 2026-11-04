extends "res://scripts/overworld/view.gd"
## Campaign adapter over the reviewed renderer/controller, with no preview grants or warps.
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
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
var ending_presented := false

func _process(delta: float) -> void:
	presentation_age+=delta
	var staging := actors.get_node_or_null("EndgameStaging") if is_instance_valid(actors) else null
	if staging != null:
		for sprite in staging.get_children():
			if sprite.has_meta("idle_frames"):
				var frames: Array=sprite.get_meta("idle_frames")
				var frame: Dictionary=frames[int(presentation_age*8)%frames.size()]
				sprite.region_rect=Rect2(frame.x,frame.y,frame.w,frame.h)
			if sprite.has_meta("rest_y") and not reduced_motion:
				sprite.position.y=float(sprite.get_meta("rest_y"))+sin(presentation_age*2.2+sprite.get_index())*2.0
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
	camera.zoom = Vector2.ONE*(1.0 if Checkpoint.is_kronasta(saved_checkpoint.scene) else 1.15)
	if area_id.begins_with("gelo-") or area_id.begins_with("mina-ferro-") or area_id.begins_with("submerso-"):camera.zoom=Vector2.ONE
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
	if Checkpoint.region_of(saved_checkpoint.scene)=="palafitas":
		exploration_hud.area_name={"a":"Palafitas · Docas de chegada","b":"Palafitas · Passarelas","c":"Palafitas · Doca de Caio"}.get(saved_checkpoint.scene.right(1),model.data.name)
	exploration_hud.player_data = saved_player
	ui.add_child(exploration_hud)
	hint = exploration_hud.prompt
	_apply_story_light()
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
	if saved_checkpoint.scene == "kronasta-coracao-d" and saved_player.flags.get("enamorDesperto", false):
		for actor in npc_nodes:
			var event: Dictionary = actor.root.get_meta("event")
			if event.props.get("acao") != "ruinasDuel": continue
			event.name = "Eremor"
			for child in actor.visual.get_children():
				child.hide()
			var sprite := Sprite2D.new()
			sprite.texture = load("res://assets/overworld/kits/camara-do-elo-v1/eremor-overworld-idle.png")
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.offset.y = -sprite.texture.get_height() * .43
			actor.visual.add_child(sprite)
			break
	_roll_encounter_distance()
	encounter_grace=Pacing.walking_grace(saved_player)
	if saved_checkpoint.scene=="kronasta-pantano-c" and load("res://scripts/campaign/mormaco_story.gd").available(saved_player):
		mormaco=load("res://scripts/campaign/mormaco_overworld.gd").new();add_child(mormaco)
	if saved_checkpoint.scene=="park-trail" and load("res://scripts/campaign/blue_exam_preparation.gd").eligible(saved_player):
		var entry:=Node2D.new();entry.position=model.project(Vector2(34.5,31.5));actors.add_child(entry)
		var arrow:=Line2D.new();arrow.width=3;arrow.default_color=Tokens.GUIDE_CYAN;arrow.points=PackedVector2Array([Vector2(-14,7),Vector2(14,-7),Vector2(3,-9),Vector2(14,-7),Vector2(9,3)]);entry.add_child(arrow)
		var label:=Label.new();label.text="Pátio da Liga";label.position=Vector2(-45,-32);label.add_theme_font_size_override("font_size",14);label.add_theme_color_override("font_outline_color",Tokens.NANQUIM);label.add_theme_constant_override("outline_size",5);entry.add_child(label)
	if saved_checkpoint.scene=="parque-patio-liga":
		follower_root.hide();exploration_hud.show_partner=false;exploration_hud.partner_panel.hide()
		blue_guide=load("res://scripts/campaign/blue_exam_guide.gd").new();add_child(blue_guide)
		var marks=load("res://scripts/campaign/blue_exam.gd")
		exploration_hud.objective.text=marks.objective(saved_player)

func _build_events() -> void:
	# Acts 4-6 story steps injected by ParkCheckpoint (endgame_story.gd).
	for e:Dictionary in Checkpoint.data(saved_checkpoint.scene).events:
		if e.props.get("acao","")=="endgameStep" and Checkpoint.allowed(e,saved_player,area_id) and not interaction_events.any(func(existing):return str(existing.id)==str(e.id)):
			interaction_events.append(e.duplicate(true))
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
			ring.default_color=Tokens.alpha(Tokens.SOL,.8)
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
	if nearby.get("type")=="item" and nearby.props.get("visibilidade","")=="escondido":
		hint.text = "Investigar o chão"
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

## Night of the cerol (Centro and Condomínio) and the Trovareta storm (Bosque):
## a veil over the world, under the HUD.
func stage_endgame(id: String) -> void:
	if id not in ["gerador","gollia-arrependimento","reuniao"]:return
	var previous := actors.get_node_or_null("EndgameStaging")
	if previous != null:return
	var staging := Node2D.new()
	staging.name="EndgameStaging"
	staging.y_sort_enabled=true
	staging.z_index=1
	actors.add_child(staging)
	var center := Vector2i(player.floor())
	if id=="reuniao":
		_stage_champions(staging,center)
		return
	if id=="gerador":
		var story=preload("res://scripts/campaign/endgame_story.gd")
		var anchor: Vector2=story.point(area_id,story.STEPS[id].anchor)
		var hidden_points := [anchor]
		for event in interaction_events:
			if event.props.get("acao") in ["tufanocorteStory","learnDig"]:
				hidden_points.append(Vector2(event.u+.5,event.v+.5))
		for npc in npc_nodes:
			if npc.point in hidden_points:
				npc.root.hide()
				staging.tree_exiting.connect(npc.root.show)
	var occupied := {center:true,Vector2i(follower.floor()):true}
	var occupied_screen := [model.project(player),model.project(follower)]
	var offsets := [Vector2i(-4,-1),Vector2i(4,-1),Vector2i(-3,3),Vector2i(3,3)] if id=="gerador" else [Vector2i(-3,-1),Vector2i(3,1)]
	var cast := ["tufanocorte","rabiolava","basic-raio-de-sol","mormaco-normal"] if id=="gerador" else ["capanga-feminina","capanga-masculino"]
	for i in cast.size():
		var desired: Vector2i=center+offsets[i]
		var cell := Vector2i(-1,-1)
		for delta in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN,Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2)]:
			var candidate: Vector2i = desired+delta
			var point := Vector2(candidate)+Vector2(.5,.5)
			var screen: Vector2=model.project(point)
			var separate := true
			for used: Vector2 in occupied_screen:
				if screen.distance_to(used)<80.0:separate=false
			if separate and not occupied.has(candidate) and model.point_walkable(point) and (id=="gerador" or absf(model.height_at(point)-model.height_at(player))<.25):
				cell=candidate
				break
		if cell.x<0:continue
		occupied[cell]=true
		occupied_screen.append(model.project(Vector2(cell)+Vector2(.5,.5)))
		var sprite := Sprite2D.new()
		if cast[i]=="rabiolava":
			sprite.texture=load("res://assets/overworld/kits/aracati-v1/rabiolava.png")
		elif id=="gerador":
			var atlas: Dictionary=content.combat[cast[i]]
			var frame: Dictionary=atlas.animations.idle[0]
			sprite.texture=load("res://assets/campaign/"+atlas.image)
			sprite.region_enabled=true
			var frames: Array=[]
			var source_image: Image=sprite.texture.get_image()
			for raw_frame: Dictionary in atlas.animations.idle:
				var raw_rect:=Rect2i(raw_frame.x,raw_frame.y,raw_frame.w,raw_frame.h)
				var used: Rect2i=source_image.get_region(raw_rect).get_used_rect()
				if not used.has_area():used=Rect2i(Vector2i.ZERO,raw_rect.size)
				frames.append({"x":raw_rect.position.x+used.position.x,"y":raw_rect.position.y+used.position.y,"w":used.size.x,"h":used.size.y})
			frame=frames[0]
			sprite.region_rect=Rect2(frame.x,frame.y,frame.w,frame.h)
			sprite.set_meta("idle_frames",frames)
		else:
			sprite.texture=load("res://assets/overworld/kits/camara-do-elo-v1/"+cast[i]+"-0.png")
		var size: Vector2=sprite.region_rect.size if sprite.region_enabled else sprite.texture.get_size()
		sprite.scale=Vector2.ONE*(96.0/size.y)
		sprite.offset.y=-size.y*.5
		sprite.position=model.project(Vector2(cell)+Vector2(.5,.5))
		sprite.set_meta("rest_y",sprite.position.y)
		sprite.set_meta("ground_point",Vector2(cell)+Vector2(.5,.5))
		staging.add_child(sprite)

## F20: the champions' meeting in the Praça da Matriz, in three small groups with room
## for Kael. Mikka is the event itself; the others come from each district's cast
## (Dona Neve has no art yet).
const CHAMPIONS := [
	{"name":"Lohan","atlas":"res://assets/npc-ds/bambuzal-v1/"},
	{"name":"Kleie","atlas":"res://assets/npc-ds/beira-canal-v1/"},
	{"name":"Dona Zulmira","path":"res://assets/npc-ds/feira-v1/zulmira.png"},
	{"name":"Marisol","path":"res://assets/npc-ds/cais-v1/marisol.png"},
	{"name":"Bruno Solda","path":"res://assets/npc-ds/vila-operaria-v1/bruno-solda.png"},
	{"name":"Caio Garça","path":"res://assets/npc-ds/palafitas-v1/caio.png"},
]
const CHAMPION_SPOTS := [Vector2i(-3,-2),Vector2i(-4,0),Vector2i(-3,2),Vector2i(0,-3),Vector2i(2,-3),Vector2i(4,-1),Vector2i(4,1)]

func _stage_champions(staging: Node2D, center: Vector2i) -> void:
	var occupied := {center:true,Vector2i(follower.floor()):true}
	var occupied_screen := [model.project(player),model.project(follower)]
	for i in CHAMPIONS.size():
		var entry: Dictionary=CHAMPIONS[i]
		var cell := Vector2i(-1,-1)
		for delta in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN,Vector2i(-1,-1),Vector2i(1,1),Vector2i(-2,0),Vector2i(2,0)]:
			var candidate: Vector2i=center+CHAMPION_SPOTS[i]+delta
			var point := Vector2(candidate)+Vector2(.5,.5)
			var screen: Vector2=model.project(point)
			var separate := true
			for used: Vector2 in occupied_screen:
				if screen.distance_to(used)<64.0:separate=false
			if separate and not occupied.has(candidate) and model.point_walkable(point) and absf(model.height_at(point)-model.height_at(player))<.25:
				cell=candidate
				break
		if cell.x<0:continue
		occupied[cell]=true
		occupied_screen.append(model.project(Vector2(cell)+Vector2(.5,.5)))
		var sprite := Sprite2D.new()
		sprite.name=str(entry.name)
		if entry.has("atlas"):
			var atlas: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(str(entry.atlas)+"atlas.json"))
			sprite.texture=load(str(entry.atlas)+"atlas.png")
			for frame: Dictionary in atlas.sprites:
				if frame.name==entry.name and frame.facing=="se":
					sprite.region_enabled=true
					sprite.region_rect=Rect2(frame.bounds[0],frame.bounds[1],frame.bounds[2],frame.bounds[3])
		else:
			sprite.texture=load(str(entry.path))
			if sprite.texture.get_width()>sprite.texture.get_height():
				sprite.region_enabled=true
				sprite.region_rect=Rect2(0,0,64,96)
		var size: Vector2=sprite.region_rect.size if sprite.region_enabled else sprite.texture.get_size()
		sprite.scale=Vector2.ONE*(96.0/size.y)
		sprite.offset.y=-size.y*.5
		sprite.position=model.project(Vector2(cell)+Vector2(.5,.5))
		sprite.set_meta("ground_point",Vector2(cell)+Vector2(.5,.5))
		staging.add_child(sprite)

func animate_gollia_entrance() -> void:
	if reduced_motion:return
	var story=preload("res://scripts/campaign/endgame_story.gd")
	var target: Vector2=story.point(area_id,story.STEPS["gollia-arrependimento"].anchor)
	for npc in npc_nodes:
		if npc.point!=target:continue
		var visual: Node2D=npc.visual
		var origin := target + Vector2(0,-2)
		if not model.clear_segment(origin,target):
			origin=target+Vector2(2,0)
		if not model.clear_segment(origin,target):return
		var rest := visual.position
		visual.position=rest+model.project(origin)-model.project(target)
		var tween := visual.create_tween()
		tween.tween_property(visual,"position",rest,.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tween.finished
		return

func clear_endgame_staging() -> void:
	var staging := actors.get_node_or_null("EndgameStaging")
	if staging != null:staging.queue_free()

func _apply_story_light() -> void:
	var endgame=load("res://scripts/campaign/endgame_story.gd")
	var tint:=Tokens.UNTINTED
	_stage_storm_cast()
	var storm: bool=endgame.storm_active(saved_player) and Checkpoint.is_bosque(saved_checkpoint.scene)
	if endgame.night_active(saved_player) and saved_checkpoint.scene in endgame.NIGHT_SCENES:tint=Tokens.TINTA_3.lightened(.2)
	elif storm:tint=Tokens.TINTA_3.lightened(.32)
	if tint==Tokens.UNTINTED:return
	var layer: Node = exploration_hud.get_parent() if is_instance_valid(exploration_hud) else null
	endgame.veil(layer,tint)
	if storm and layer != null and not layer.has_node("StoryRain"):
		var rain := ColorRect.new()
		rain.name="StoryRain"
		rain.mouse_filter=Control.MOUSE_FILTER_IGNORE
		rain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var surface := ShaderMaterial.new()
		surface.shader=preload("res://shaders/story_storm.gdshader")
		surface.set_shader_parameter("motion",not reduced_motion)
		rain.material=surface
		layer.add_child(rain)
		layer.move_child(rain,1)

## F19: Bosque C during the storm shows the bound Trovareta and the black line from
## Navalha; after her release the Rato watches from the edge until the next story step.
func _stage_storm_cast() -> void:
	if saved_checkpoint.scene!="kronasta-bosque-c" or actors.has_node("StormCast"):return
	var endgame=load("res://scripts/campaign/endgame_story.gd")
	var flags_now: Dictionary=saved_player.get("flags",{})
	var anchor: Vector2i=endgame.STEPS.trovareta.anchor
	var navalha: Vector2=endgame.point(saved_checkpoint.scene,anchor)
	if not navalha.is_finite():return
	var cast := Node2D.new()
	cast.name="StormCast"
	cast.y_sort_enabled=true
	actors.add_child(cast)
	if endgame.storm_active(saved_player):
		var bound: Vector2=endgame.point(saved_checkpoint.scene,anchor+Vector2i(0,-4))
		if not bound.is_finite() or bound.distance_to(navalha)<2.0:return
		var atlas: Dictionary=content.combat["basic-raio-de-sol"]
		var frame: Dictionary=atlas.animations.idle[0]
		var creature := Sprite2D.new()
		creature.name="TrovaretaBound"
		creature.texture=load("res://assets/campaign/"+atlas.image)
		creature.region_enabled=true
		creature.region_rect=Rect2(frame.x,frame.y,frame.w,frame.h)
		creature.scale=Vector2.ONE*(150.0/float(frame.h))
		creature.offset.y=-float(frame.h)*.5
		creature.position=model.project(bound)
		creature.modulate=Tokens.POSSESSED
		cast.add_child(creature)
		var cord := Line2D.new()
		cord.name="CarretelLine"
		cord.width=3.0
		cord.default_color=Tokens.NANQUIM
		cord.z_index=1
		cord.points=PackedVector2Array([model.project(navalha)+Vector2(0,-48),model.project(bound)+Vector2(0,-70)])
		cast.add_child(cord)
	elif flags_now.get("trovaretaLivre",false) and not flags_now.get("reuniaoCampeoes",false):
		var edge: Vector2=endgame.point(saved_checkpoint.scene,anchor+Vector2i(5,-2))
		if not edge.is_finite():return
		var rato := Sprite2D.new()
		rato.name="RatoWatching"
		rato.texture=load("res://assets/overworld/kits/camara-do-elo-v1/rato-0.png")
		rato.offset.y=-48
		rato.position=model.project(edge)
		cast.add_child(rato)

func present_championship_victory() -> void:
	var route: PackedVector2Array=model.path_to(player,Vector2(24.5,14.5))
	for destination: Vector2 in route:
		if reduced_motion:
			player=destination
		else:
			var walk := create_tween()
			avatar.moving=true
			walk.tween_method(func(at: Vector2):
				var movement: Vector2=model.project(at,false)-model.project(player,false)
				avatar.face_motion(movement)
				player=at
				_refresh_positions(),player,destination,.12)
			await walk.finished
	avatar.moving=false
	_refresh_positions()
	var previous := actors.get_node_or_null("ChampionshipVictory")
	if previous != null:return
	var gathering := Node2D.new()
	gathering.name="ChampionshipVictory"
	gathering.y_sort_enabled=true
	gathering.z_index=1
	actors.add_child(gathering)
	var cells := [Vector2i(21,12),Vector2i(27,12),Vector2i(21,16)]
	var identities := ["mae","professor","tyler"]
	for i in identities.size():
		var point := Vector2(cells[i])+Vector2(.5,.5)
		if not model.point_walkable(point):continue
		var holder := Node2D.new()
		holder.position=model.project(point,false)
		gathering.add_child(holder)
		var sprite := Sprite2D.new()
		holder.add_child(sprite)
		if identities[i]=="tyler":
			sprite.texture=load("res://assets/campaign/tyler-clareira-v1/tyler-overworld-idle-eight.png")
			sprite.region_enabled=true
			sprite.region_rect=Rect2(192,96,64,96)
			sprite.scale=Vector2.ONE*.85
			sprite.offset.y=-48
		else:
			preload("res://scripts/npc_pixel_sprite.gd").setup(sprite,identities[i],82.0)
		holder.position.y-=model.height_at(point)*64.0
		if not reduced_motion:
			sprite.modulate.a=0
			var entrance := sprite.create_tween()
			entrance.tween_property(sprite,"modulate:a",1.0,.35)
			for cheer in 2:
				entrance.tween_property(sprite,"position:y",-5.0,.12).set_trans(Tween.TRANS_SINE)
				entrance.tween_property(sprite,"position:y",0.0,.16).set_trans(Tween.TRANS_SINE)
	camera.position_smoothing_enabled=false
	camera.position=model.project(Vector2(24.5,11.5))
	camera.zoom=Vector2.ONE*1.15
	if not reduced_motion:await get_tree().create_timer(.8).timeout
func finish_endgame_scene(id: String) -> void:
	if reduced_motion:return
	if id in ["gollia-arrependimento","reuniao"]:
		var staging := actors.get_node_or_null("EndgameStaging")
		if staging == null:return
		var retreat := create_tween().set_parallel(true)
		for actor: Node2D in staging.get_children():
			var start: Vector2=actor.get_meta("ground_point")
			var destination := start+Vector2(0,2)
			if model.clear_segment(start,destination) and absf(model.height_at(start)-model.height_at(destination))<.25:
				retreat.tween_property(actor,"position",model.project(destination),.7)
			retreat.tween_property(actor,"modulate:a",0.0,.7)
		await retreat.finished
	elif id=="gerador":
		var release := Node2D.new()
		release.name="WindRelease"
		release.z_index=2
		release.position=model.project(player)
		actors.add_child(release)
		var colors: Array = Tokens.WIND_RIBBONS
		for i in 4:
			var ribbon := Line2D.new()
			ribbon.width=3.0
			ribbon.default_color=colors[i]
			for step in 40:
				var angle := float(step)*.12+float(i)*TAU/4.0
				var radius := 26.0+float(step)*3.0
				ribbon.add_point(Vector2(cos(angle)*radius,sin(angle)*radius*.5-float(step)*1.3))
			release.add_child(ribbon)
		var dawn := ColorRect.new()
		dawn.mouse_filter=Control.MOUSE_FILTER_IGNORE
		dawn.color=Tokens.DAWN
		dawn.modulate.a=0.0
		dawn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var material := CanvasItemMaterial.new()
		material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
		dawn.material=material
		var layer := exploration_hud.get_parent()
		layer.add_child(dawn)
		layer.move_child(dawn,0)
		var wind := create_tween().set_parallel(true)
		wind.tween_property(release,"position:y",release.position.y-90.0,1.4)
		wind.tween_property(release,"modulate:a",0.0,1.4)
		wind.tween_property(dawn,"modulate:a",.22,.7)
		await wind.finished
		var clear := create_tween()
		clear.tween_property(dawn,"modulate:a",0.0,.5)
		await clear.finished
		release.queue_free()
		dawn.queue_free()
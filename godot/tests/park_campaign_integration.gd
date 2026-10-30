extends SceneTree
## Real frontend, controller, atomic Store and rules; only fixture state is synthetic.
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const Checkpoint = preload("res://scripts/campaign/park_checkpoint.gd")
var app: Control
var checks := 0
var failures: Array[String] = []
var output: String
var storage: String

func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message); printerr("FAIL ",message)

func freeze(node: Node) -> void:
	if node==app.scene_loading: return
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children(): freeze(child)

func settled() -> void:
	for i in 4: await process_frame
	freeze(app)

func ready_park() -> void:
	# Deferred exits must start before testing whether the old view is ready.
	for i in 2: await process_frame
	for i in 240:
		await process_frame
		if is_instance_valid(app.park) and not is_instance_valid(app.scene_loading) and app.park.get_meta("campaign_scene")==app.session.snapshot().checkpoint.get("scene",""): break
		if i==239:
			check(false,"area transition completes")
			quit(1)
			return
	await settled()
	check(is_instance_valid(app.park),"campaign view constructed")
	if is_instance_valid(app.park): app.park.paused=false

func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await settled()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))

func dialog(node: Node):
	if node.has_signal("confirmed") and node.has_method("popup_centered"): return node
	for child in node.get_children():
		var found = dialog(child)
		if found!=null: return found
	return null

func confirm() -> void:
	var panel = dialog(app)
	check(panel!=null,"campaign dialog available")
	if panel!=null: panel.confirmed.emit()
	await settled()

func walk(point: Vector2) -> bool:
	var park: Node2D = app.park
	var candidates := [point]
	for d in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]: candidates.append(point+d)
	var target := Vector2.INF
	for candidate in candidates:
		if park.model.path_to(park.player,candidate).size()>0: target=candidate; break
	if not check_path(target.is_finite(),"route exists to "+str(point)): return false
	park.paused=false
	park.walk_to(target)
	for tick in 6000:
		if park.player.distance_to(target)<.04: break
		park._physics_process(1.0/60.0)
		if tick==5999: check(false,"walking stalled: "+str(target)); return false
	check(park.player.distance_to(target)<.05,"actual controller reaches "+str(point))
	check(park.camera.position.distance_to(park.model.project(park.player))<.01,"camera follows raised ground")
	return true

func check_path(value: bool, message: String) -> bool:
	check(value,message)
	return value

func event(id: int) -> Dictionary:
	for item in app.park.model.data.events:
		if int(item.id)==id: return item
	return {}

func use_event(id: int) -> void:
	print("INTERACT ",id)
	var item := event(id)
	if not check_path(not item.is_empty(),"event exists: "+str(id)): return
	if not walk(Vector2(item.u+.5,item.v+.5)): return
	app.park.nearby=item
	app.park.interact()
	if item.type=="saida": await ready_park()
	else: await settled()

func run() -> void:
	root.size=Vector2i(1280,720)
	output=ProjectSettings.globalize_path("res://../documentation/overworld/park-campaign-v1")
	storage=ProjectSettings.globalize_path("res://../tmp/park-campaign-"+State.new_id())
	DirAccess.make_dir_recursive_absolute(output)
	app=load("res://tests/fixtures/park_frontend_fixture.gd").new()
	app.session._store=Store.new(storage)
	root.add_child(app)
	check(app.session.start("slot-1").status=="ok","isolated slot created")
	var player: Dictionary=app.session.snapshot().player
	player.partners=[{"id":"test-rabbito","modelId":"rabbito","personalName":"Rabbito","xp":preload("res://scripts/campaign/partner_levels.gd").xp_for_level(8),"craftBonus":0,"condition":{"line":100,"structure":100}}]
	player.equippedPartnerId="test-rabbito"
	player.journey={"phase":"complete","lesson":5}
	# This synchronous controller traversal starts after the introduction.
	# The actual camera/intro branch is exercised by lacertubo_flow_review.gd.
	player.flags.lacertuboIntroduced=true
	player.coins=73
	player.inventory={"linha":2,"rabiola-basica":1}
	player.openedChests=["woodland"]
	player.encounterGraceUntil=Time.get_unix_time_from_system()+3600
	check(app.session.checkpoint({"kind":"world","scene":"park-veredas","position":[1300,154]},player).status=="ok","legacy save accepted")
	app._show_park()
	await ready_park()
	check(app.session.snapshot().checkpoint.space==Checkpoint.SPACE,"legacy position migrates once")
	check(app.session.snapshot().player.coins==73 and app.session.snapshot().player.openedChests==["woodland"],"migration preserves inventory and collected chests")
	check(app.session.snapshot().player.inventory==player.inventory,"migration preserves exact inventory")
	check(app.park.model.walkable(Vector2i(app.park.player.floor())),"legacy load lands on walkable ground")
	# Begin the actual A -> B -> C route from the city entry contract.
	check(app.journey.enter_world("park-trail",Vector2(208,816)).status=="ok","city entry resolves to native Garden")
	app._show_park(); await ready_park()
	await shot("01-jardim")
	await use_event(43); await confirm()
	check(app.session.snapshot().player.flags.get("ninaAccepted",false),"Nina quest starts in Garden through UI")
	await use_event(1002)
	check(app.session.snapshot().player.inventory.get("linha",0)==3,"native item granted")
	check(app.exploration.park_loot("1002",app.park.player).status=="already_applied","item receipt prevents duplicate reward")
	app.park.item_receipt.clear(); app.park.avatar.stop_item()
	await use_event(38)
	check(app.session.snapshot().checkpoint.scene=="park-clearing","Garden -> Clearing")
	await shot("02-clareira")
	# Physically cross both bridges, not just test graph reachability.
	for point in [Vector2(27.5,24.5),Vector2(27.5,34.5),Vector2(32.5,34.5),Vector2(32.5,24.5)]: walk(point)
	await shot("03-pontes")
	await use_event(1201)
	check(app.session.snapshot().checkpoint.scene=="park-veredas" and app.park.player==Vector2(61.5,25.5),"high exit preserves named arrival")
	await shot("04-veredas")
	for id in ["lookout","canal","ridge"]:
		var target := Checkpoint.target("park-veredas","chest:"+id)
		if walk(target):
			check(app.exploration.chest(id,app.park.player).status=="ok","native chest reward: "+id)
	app.park.refresh(app.session.snapshot().player)
	check(app.park.collected_pieces.has("18"),"old woodland chest remains open after migration")
	check(not Checkpoint.allowed(event(1100),app.session.snapshot().player),"shortcut locked before victory")
	check(not Checkpoint.allowed(event(42),app.session.snapshot().player),"quest tail hidden before victory")
	# Resolve an actual boss fight with bounded player inputs, without setting outcome.
	if walk(Checkpoint.target("park-veredas","boss")):
		app._park_action("boss"); await confirm()
		check(is_instance_valid(app.battle),"boss starts through frontend confirmation")
		if is_instance_valid(app.battle):
			var battle: Control=app.battle
			for tick in 9000:
				if not battle.model.outcome.is_empty(): break
				var p: Dictionary=battle.model.p
				var q: Dictionary=battle.model.q
				var crossing:=Vector2(q.anchor,585).lerp(Vector2(q.x,q.y),.6)
				var aim:=Vector2(clampf(p.anchor+(crossing.x-p.anchor)/.7,55,945),clampf(585+(crossing.y-585)/.7,70,480))
				var direction: Vector2=(aim-Vector2(p.x,p.y)).limit_length()
				var contact: Dictionary=battle.model.contact(p,q)
				battle.model.tick(1.0/60.0,{"x":direction.x,"y":direction.y,"cut":contact.get("valid",false) and q.charge<=0,"guard":q.signatureWindup>0 and q.signatureWindup<.3 and p.guardCooldown<=0,"line":p.lineCooldown<=0 and p.energy>60,"signature":p.energy>=100})
			check(battle.model.outcome=="won","actual level-8 fight wins: "+battle.model.outcome)
			print("BOSS actual outcome: ",battle.model.outcome)
			await shot("05-batalha")
			battle.finish_requested.emit()
			await ready_park()
	check(app.session.snapshot().player.flags.get("guardianDefeated",false),"boss victory persists")
	check(not Checkpoint.allowed(event(1100),app.session.snapshot().player),"shortcut stays locked until the quest item is collected")
	await use_event(42)
	check(app.session.snapshot().player.flags.get("ninaTail",false),"tail collected separately after boss")
	app.park.item_receipt.clear(); app.park.avatar.stop_item()
	await use_event(1100)
	check(app.session.snapshot().checkpoint.scene=="park-trail","victory unlocks shortcut to Garden")
	await use_event(43)
	check(app.session.snapshot().player.flags.get("ninaReturned",false),"quest returned to Nina through UI")
	await shot("06-nina-resgatada")
	app._save_park()
	var disk: Dictionary=Store.new(storage).load_slot("slot-1")
	check(disk.status=="ok" and disk.data.checkpoint.space==Checkpoint.SPACE,"fresh Store reloads native checkpoint")
	check(disk.data.player.flags.get("ninaReturned",false),"quest survives disk reload")
	check(disk.data.player.inventory.get("quest-nina-tail",0)==0,"quest item consumed on return")
	# Native wild encounter via actual movement, suspend on disk, then hold to flee.
	app.journey.enter_world("park-clearing",Checkpoint.spawn("park-clearing"),Checkpoint.SPACE)
	app._show_park(); await ready_park()
	var wild_point := Vector2.INF
	for i in app.park.model.data.cells.size():
		if app.park.model.data.cells[i].material=="terra":
			var candidate := Vector2(i%int(app.park.model.data.w)+.5,floori(float(i)/float(app.park.model.data.w))+.5)
			if app.park.model.path_to(app.park.player,candidate).size()>1 and Checkpoint.encounter_weight(app.session.snapshot().checkpoint,candidate)>0 and Checkpoint.encounter_weight(app.session.snapshot().checkpoint,candidate+Vector2.RIGHT)>0 and app.park.model.clear_segment(candidate,candidate+Vector2.RIGHT): wild_point=candidate; break
	check(wild_point.is_finite(),"reachable encounter terrain outside grass exists")
	var wild_player: Dictionary=app.session.snapshot().player
	wild_player.encounterGraceUntil=0
	app.session.checkpoint(Checkpoint.make("park-clearing",wild_point,Checkpoint.SPACE),wild_player)
	app._show_park(); await ready_park()
	var initial_grace: float=app.park.encounter_grace
	for tick in 600: app.park._physics_process(1.0/60.0)
	check(app.park.encounter_grace==initial_grace and app.park.grass_distance==0,"standing still cannot consume grace or trigger battles")
	app.park.encounter_threshold=.01
	var to_right:=true
	app.park.walk_to(wild_point+Vector2.RIGHT)
	for tick in 1200:
		if app.session.snapshot().checkpoint.kind=="encounter": break
		var destination:=wild_point+Vector2.RIGHT if to_right else wild_point
		if app.park.player.distance_to(destination)<.05:
			to_right=not to_right
			app.park.walk_to(wild_point+Vector2.RIGHT if to_right else wild_point)
		app.park._physics_process(1.0/60.0)
	await settled()
	check(app.session.snapshot().checkpoint.kind=="encounter","walking on dirt outside grass starts encounter after grace")
	if app.session.snapshot().checkpoint.kind=="encounter":
		var suspended: Dictionary=Store.new(storage).load_slot("slot-1")
		var return_point: Array=suspended.data.player.encounter.returnPoint
		check(suspended.status=="ok" and suspended.data.player.encounter.space==Checkpoint.SPACE,"native battle can resume from disk")
		var battle: Control=app.battle
		battle.paused=false
		for tick in 250:
			if battle.model.intro<=0: break
			battle.model.tick(1.0/60.0,{})
		battle._step_flee(0)
		battle.flee_pointer=true
		for tick in 65: battle._step_flee(1.0/60.0)
		check(battle.model.outcome=="fled","hold-to-flee works in real encounter")
		battle.finish_requested.emit(); await ready_park()
		var returned: Array=app.session.snapshot().checkpoint.position
		check(app.session.snapshot().checkpoint.space==Checkpoint.SPACE and Vector2(returned[0],returned[1]).is_equal_approx(Vector2(return_point[0],return_point[1])),"flee returns to native position without remigration")
	verify_loss(player)
	var report={"checks":checks,"failures":failures,"isolatedStorage":storage,"scope":"frontend, actual movement, migrated saves, UI quest, bridge crossings and real combat inputs"}
	var file:=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("PARK CAMPAIGN: ",checks," checks; ",failures.size()," failures; ",storage)
	quit(0 if failures.is_empty() else 1)

func verify_loss(base_player: Dictionary) -> void:
	var Session = preload("res://scripts/campaign/session.gd")
	var Encounter = preload("res://scripts/campaign/encounter_model.gd")
	var Encounters = preload("res://scripts/campaign/encounters.gd")
	var session := Session.new()
	session._store=Store.new(storage)
	session.start("slot-2")
	var player: Dictionary=base_player.duplicate(true)
	player.partners[0].xp=0
	player.flags.ninaAccepted=true
	check(session.checkpoint(Checkpoint.make("park-veredas",Checkpoint.target("park-veredas","boss"),Checkpoint.SPACE),player).status=="ok","isolated defeat fixture uses native checkpoint")
	var encounters = Encounters.new(session)
	check(encounters.start_boss(Checkpoint.target("park-veredas","boss")).status=="ok","native loss fixture begins real boss model")
	var model = Encounter.new()
	model.restore(session.snapshot().player.encounter.state)
	for tick in 15000:
		if not model.outcome.is_empty(): break
		model.tick(1.0/60.0,{})
	check(model.outcome=="lost","idle level-1 partner naturally loses boss fight")
	encounters.save_battle(model.snapshot())
	check(encounters.settle().status=="ok","native defeat settles")
	var saved := session.snapshot()
	check(saved.checkpoint.space==Checkpoint.SPACE and Vector2(saved.checkpoint.position[0],saved.checkpoint.position[1])==Checkpoint.spawn("park-veredas"),"loss respawns at native entry")
	check(saved.player.partners.size()==1 and saved.player.partners[0].id==base_player.partners[0].id,"loss preserves partner")
	check(not saved.player.flags.get("guardianDefeated",false),"loss does not unlock boss rewards")
	session.free()

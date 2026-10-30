extends SceneTree
## Campaign controller + isolated disk saves, never the user's progress.
const Store=preload("res://scripts/campaign/save_store.gd")
const State=preload("res://scripts/campaign/state.gd")
const Checkpoint=preload("res://scripts/campaign/park_checkpoint.gd")
const Bosque=preload("res://scripts/campaign/bosque_campaign.gd")
var app: Control
var checks:=0
var failures: Array[String]=[]
var storage: String
var output: String

func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	checks+=1
	if not value: failures.append(message);printerr("FAIL ",message)
func freeze(node: Node) -> void:
	if node==app.scene_loading: return
	node.set_process(false);node.set_physics_process(false)
	for child in node.get_children(): freeze(child)
func settle() -> void:
	for i in 4: await process_frame
	freeze(app)
func ready_park() -> void:
	for i in 2: await process_frame
	for i in 600:
		await process_frame
		if is_instance_valid(app.park) and not is_instance_valid(app.scene_loading) and app.park.get_meta("campaign_scene")==app.session.snapshot().checkpoint.scene: break
		if i==599: check(false,"transition completes");quit(1);return
	await settle()
	app.park.paused=false
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await settle()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(name+".png"))==OK,"capture "+name)
func walk(target: Vector2) -> bool:
	var view=app.park
	var goal:=Vector2.INF
	for candidate in [target,target+Vector2.RIGHT,target+Vector2.LEFT,target+Vector2.UP,target+Vector2.DOWN]:
		if view.model.point_walkable(candidate) and (view.player.distance_to(candidate)<.05 or not view.model.path_to(view.player,candidate).is_empty()): goal=candidate;break
	if not goal.is_finite(): check(false,"route to "+str(target));return false
	view.paused=false
	view.walk_to(goal)
	for tick in 12000:
		if view.player.distance_to(goal)<.05: break
		view._physics_process(1.0/60.0)
		if tick==11999: check(false,"controller reaches "+str(goal));return false
	check(view.model.point_walkable(view.player),"arrival supported")
	check(view.camera.position.distance_to(view.model.project(view.player))<.01,"camera follows elevation")
	return true
func exit_to(destination: String) -> void:
	for event in app.park.model.data.events:
		if event.type!="saida" or event.props.get("destino","")!=destination: continue
		if not walk(Vector2(event.u+.5,event.v+.5)): return
		app.park.nearby=event
		app.park.interact()
		await ready_park()
		check(app.session.snapshot().checkpoint.scene==destination,"exit to "+destination)
		return
	check(false,"exit exists to "+destination)
func run() -> void:
	root.size=Vector2i(1280,720)
	storage=ProjectSettings.globalize_path("res://../tmp/bosque-campaign-"+State.new_id())
	output=ProjectSettings.globalize_path("res://../documentation/overworld/kronasta/integracao-campanha")
	DirAccess.make_dir_recursive_absolute(output)
	app=load("res://tests/fixtures/park_frontend_fixture.gd").new()
	app.session._store=Store.new(storage)
	root.add_child(app)
	check(app.session.start("slot-1").status=="ok","isolated slot")
	var player: Dictionary=app.session.snapshot().player
	player.partners=[{"id":"test-rabbito","modelId":"rabbito","personalName":"Rabbito","xp":0,"craftBonus":0,"condition":{"line":100,"structure":100}}]
	player.equippedPartnerId="test-rabbito"
	player.journey={"phase":"complete","lesson":5}
	player.encounterGraceUntil=Time.get_unix_time_from_system()+3600
	player.cityPosition=[10.5,20.5]
	var coins: int=player.coins
	check(app.session.checkpoint({"kind":"world","scene":"quintal","position":[10.5,20.5],"space":"bairro-inicial-v2"},player).status=="ok","city checkpoint")
	var service=Bosque.new(app.session)
	check(service.travel("park-veredas").status=="wrong_step","arbitrary travel rejected")
	app._show_kronasta()
	await shot("01-acesso-regional")
	app._travel_kronasta("kronasta-bosque-a")
	await ready_park()
	check(app.session.snapshot().player.flags.get("bosqueParteADescoberta",false),"A discovery persisted")
	check(service.collect("944",Vector2.ZERO).status=="wrong_step","remote reward rejected")
	await shot("02-trilha-das-copas")
	var count:=0
	for scene in ["kronasta-bosque-a","kronasta-bosque-b","kronasta-bosque-c"]:
		check(app.session.snapshot().checkpoint.scene==scene,"campaign enters "+scene)
		for event in app.park.model.data.events:
			if event.type!="item": continue
			if not walk(Vector2(event.u+.5,event.v+.5)): continue
			var id:=str(int(event.id))
			check(app.exploration.park_loot(id,app.park.player).status=="ok","collect "+scene+":"+id)
			check(app.exploration.park_loot(id,app.park.player).status=="already_applied","duplicate rejected "+id)
			app.park.refresh(app.session.snapshot().player)
			check(not Checkpoint.allowed(event,app.session.snapshot().player,scene),"collected marker removed")
			count+=1
		if scene.ends_with("a"): await exit_to("kronasta-bosque-b");await shot("03-desvio-do-riacho")
		elif scene.ends_with("b"):
			for point in [Vector2(24.5,25.5),Vector2(24.5,22.5),Vector2(24.5,18.5)]: walk(point)
			await shot("05-ponte-riacho")
			await verify_wild()
			await exit_to("kronasta-bosque-c");await shot("04-clareira-do-marco")
	check(count>=12,"all authored rewards visited")
	check(app.session.snapshot().player.coins==coins+30,"coins match authored amount")
	check(app.session.snapshot().player.inventory.get("pista-caderno-heleana-1",0)==1,"page kept as clue")
	check(app.session.snapshot().player.flags.get("bosqueClareiraDescoberta",false),"shortcut discovered")
	var rests: Array=Bosque.rest_events(app.park.area_id,app.park.model)
	check(not rests.is_empty(),"reachable resting bank")
	if not rests.is_empty():
		var damaged: Dictionary=app.session.snapshot()
		damaged.player.partners[0].condition={"line":13,"structure":27}
		app.session.checkpoint(damaged.checkpoint,damaged.player)
		var rest: Dictionary=rests[0]
		if walk(Vector2(rest.u+.5,rest.v+.5)):
			check(app.exploration.rest(app.park.player).status=="ok","rest through campaign service")
			check(app.session.snapshot().player.partners[0].condition=={"line":100,"structure":100},"team restored")
	await exit_to("kronasta-bosque-b")
	await exit_to("kronasta-bosque-c")
	await exit_to("kronasta-bosque-a")
	check(app._save_park(),"save before closing")
	var before: Dictionary=app.session.snapshot()
	app.session.close_session()
	check(app.session.resume_slot("slot-1").status=="ok","reload disk slot")
	check(app.session.snapshot().player==JSON.parse_string(JSON.stringify(before.player)),"reload preserves rewards and discoveries")
	check(app.session.snapshot().checkpoint==before.checkpoint,"reload preserves native location")
	app._show_park();await ready_park()
	for event in app.park.model.data.events:
		if event.type=="saida" and event.props.get("destino","")=="kronasta":
			if walk(Vector2(event.u+.5,event.v+.5)):
				app.park.nearby=event
				app.park.interact()
				await settle()
				check(not is_instance_valid(app.park),"south exit opens regional travel")
			break
	check(service.travel("quintal").status=="ok","return to city")
	check(app.session.snapshot().checkpoint.position==[10.5,20.5],"return preserves previous city position")
	var report:=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"failures":failures,"rewards":count,"nativeCapture":DisplayServer.get_name()!="headless","scope":"isolated campaign frontend, real controller traversal, collection receipts, rest, battle flee and disk reload"},"  "))
	report.close()
	print("BOSQUE CAMPAIGN: ",checks," checks; failures=",failures.size(),"; rewards=",count)
	app.free()
	quit(0 if failures.is_empty() else 1)

func verify_wild() -> void:
	var point:=Vector2.INF
	for i in app.park.model.data.cells.size():
		var candidate:=Vector2(i%int(app.park.model.data.w)+.5,floori(float(i)/float(app.park.model.data.w))+.5)
		if app.park.model.point_walkable(candidate) and Checkpoint.encounter_weight(app.session.snapshot().checkpoint,candidate)>0 and not app.park.model.path_to(app.park.player,candidate).is_empty(): point=candidate;break
	check(point.is_finite(),"encounter terrain reachable")
	if not point.is_finite() or not walk(point): return
	var saved: Dictionary=app.session.snapshot()
	saved.player.encounterGraceUntil=0
	app.session.checkpoint(Checkpoint.make(saved.checkpoint.scene,app.park.player,Checkpoint.SPACE),saved.player)
	app._park_action("wild")
	await settle()
	check(is_instance_valid(app.battle),"Bosque battle starts through frontend")
	if not is_instance_valid(app.battle): return
	var disk: Dictionary=Store.new(storage).load_slot("slot-1")
	check(disk.status=="ok" and disk.data.player.encounter.space==Checkpoint.SPACE,"battle saved with Bosque coordinates")
	var battle: Control=app.battle
	battle.paused=false
	for tick in 250:
		if battle.model.intro<=0: break
		battle.model.tick(1.0/60.0,{})
	battle._step_flee(0)
	battle.flee_pointer=true
	for tick in 65: battle._step_flee(1.0/60.0)
	check(battle.model.outcome=="fled","real hold-to-flee input")
	battle.finish_requested.emit()
	await ready_park()
	var return_point: Array=disk.data.player.encounter.returnPoint
	check(app.session.snapshot().checkpoint.scene=="kronasta-bosque-b" and app.park.player.is_equal_approx(Vector2(return_point[0],return_point[1])),"flee returns to exact Bosque point")
	saved=app.session.snapshot()
	saved.player.encounterGraceUntil=Time.get_unix_time_from_system()+3600
	app.session.checkpoint(saved.checkpoint,saved.player)
	app.park.refresh(app.session.snapshot().player)

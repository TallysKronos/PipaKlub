extends SceneTree
## Kronasta story spine and the region maps joined to the campaign (Distrito Industrial,
## Pântano, Montanha). Isolated disk saves, never the user's progress.
const Store=preload("res://scripts/campaign/save_store.gd")
const State=preload("res://scripts/campaign/state.gd")
const Checkpoint=preload("res://scripts/campaign/park_checkpoint.gd")
const Bosque=preload("res://scripts/campaign/bosque_campaign.gd")
const Story=preload("res://scripts/campaign/kronasta_story.gd")
const Pacing=preload("res://scripts/campaign/park_pacing.gd")
var app: Control
var checks:=0
var failures: Array[String]=[]
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

func story_rules() -> void:
	var player: Dictionary={"partners":[],"journey":{"phase":"practice"},"flags":{}}
	check(Story.current_beat(player).id=="prologo","fresh save starts at the prologue")
	check(Story.state(player,"bosque")=="fechado","regions closed before the prologue ends")
	player.partners=[{"id":"p"}];player.journey.phase="complete"
	check(Story.current_beat(player).id=="nina","after the prologue: Nina")
	player.flags.ninaAccepted=true
	check(Story.current_beat(player).id=="lacertubo","then the Lacertubo")
	player.flags.guardianDefeated=true
	check(Story.current_beat(player).id=="nina-devolvida","then return the tail")
	player.flags.ninaReturned=true
	check(Story.current_beat(player).id=="mikka","then the Morro do Sol")
	check(Story.neighbourhoods_won(player)==0 and Story.state(player,"morro")=="aberto","Morro open, not won")
	player.morro={"stars":{"morro-5":3}}
	check(Story.neighbourhoods_won(player)==1 and Story.state(player,"morro")=="vencido","Mikka counts as neighbourhood 1")
	check(Story.current_beat(player).id=="bosque","then the Bosque")
	for region in ["industrial","pantano","montanha"]: check(not Story.can_travel(player,region),region+" closed while the act is open")
	player.flags.bosqueClareiraDescoberta=true
	check(Story.current_beat(player).is_empty(),"built act 1 complete")
	for region in ["industrial","pantano","montanha"]: check(Story.can_travel(player,region),region+" preview opens")
	check(Story.state(player,"bambuzal")=="em-breve","unbuilt neighbourhood stays em breve")
	check(not Story.can_travel(player,"bambuzal"),"unbuilt place has no travel")
	check(Story.category(player)=="Rabiola Branca","category waits for its exam")
	check(Story.PLACES.filter(func(p): return p.kind=="bairro").size()==12,"twelve neighbourhoods on the map")
	for entry in Story.PLACES:
		if entry.has("scene") and entry.scene!="quintal": check(Checkpoint.MAPS.has(entry.scene),"travel scene registered: "+entry.scene)
	for region in Checkpoint.REGIONS:
		for part in "abc": check(Checkpoint.region_of("kronasta-%s-%s"%[region,part])==region,"region of %s %s"%[region,part])
	check(Checkpoint.region_of("park-veredas").is_empty(),"park is not a free-roam region")
	check(Pacing.wild_level("kronasta-montanha-c",0)>Pacing.wild_level("kronasta-bosque-a",0),"preview wild levels above the Bosque")

func run() -> void:
	root.size=Vector2i(1280,720)
	output=ProjectSettings.globalize_path("res://../tmp/kronasta-regioes")
	DirAccess.make_dir_recursive_absolute(output)
	story_rules()
	app=load("res://tests/fixtures/park_frontend_fixture.gd").new()
	app.session._store=Store.new(ProjectSettings.globalize_path("res://../tmp/kronasta-regioes-"+State.new_id()))
	root.add_child(app)
	check(app.session.start("slot-1").status=="ok","isolated slot")
	var player: Dictionary=app.session.snapshot().player
	player.partners=[{"id":"test-rabbito","modelId":"rabbito","personalName":"Rabbito","xp":0,"craftBonus":0,"condition":{"line":100,"structure":100}}]
	player.equippedPartnerId="test-rabbito"
	player.journey={"phase":"complete","lesson":5}
	player.encounterGraceUntil=Time.get_unix_time_from_system()+3600
	check(app.session.checkpoint({"kind":"world","scene":"quintal","position":[10.5,20.5],"space":"bairro-inicial-v2"},player).status=="ok","city checkpoint")
	var service=Bosque.new(app.session)
	check(service.travel("kronasta-industrial-a").status=="wrong_step","preview closed before act 1")
	app._show_kronasta()
	await shot("01-kronasta-inicio")
	player=app.session.snapshot().player
	# This fixture resumes after the existing demo-ending presentation was acknowledged.
	player.flags.merge({"ninaAccepted":true,"guardianDefeated":true,"ninaReturned":true,"bosqueClareiraDescoberta":true,"demoEndingSeen":true})
	player.morro=preload("res://scripts/campaign/morro_rules.gd").defaults()
	player.morro.stars={"morro-5":3}
	var progress: Dictionary=app.session.checkpoint(app.session.snapshot().checkpoint,player)
	check(progress.status=="ok","act 1 progress "+str(progress)+" "+str(app.session.snapshot().checkpoint))
	check(service.travel("kronasta-industrial-b").status=="wrong_step","regions are entered by part A")
	app._show_kronasta()
	await shot("02-kronasta-previas")
	for region in ["industrial","pantano","montanha"]:
		app._travel_kronasta("kronasta-%s-a"%region)
		await ready_park()
		if not is_instance_valid(app.park):quit(1);return
		check(app.session.snapshot().player.flags.get(region+"ParteADescoberta",false),region+" A discovered")
		check(not app.park.exploration_hud.objective.text.is_empty(),region+" has an objective")
		await shot("03-"+region+"-a")
		var collected:=0
		for part in ["a","b","c"]:
			var scene:="kronasta-%s-%s"%[region,part]
			check(app.session.snapshot().checkpoint.scene==scene,"in "+scene)
			for event in app.park.model.data.events:
				if event.type!="item" or not walk(Vector2(event.u+.5,event.v+.5)): continue
				if app.exploration.park_loot(str(int(event.id)),app.park.player).status=="ok": collected+=1
			if part!="c": await exit_to("kronasta-%s-%s"%[region,"bc"[ "ab".find(part)]])
		check(collected>=9,region+" authored items collected")
		check(app.session.snapshot().player.flags.get(region+"ParteCDescoberta",false),region+" C discovered")
		await shot("04-"+region+"-c")
		check(app._save_park(),"save in "+region)
		check(service.travel("quintal").status=="ok","back to the city from "+region)
	var report:=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	print("# pass %d"%(checks-failures.size()))
	print("# fail %d"%failures.size())
	quit(1 if not failures.is_empty() else 0)

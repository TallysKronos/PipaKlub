extends SceneTree
const View=preload("res://scripts/campaign/encounter_view.gd")
const TrailView=preload("res://scripts/campaign/morro_battle_view.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
const Trail=preload("res://scripts/campaign/morro_model.gd")
const Panels=preload("res://scripts/ui_mural/battle_hud.gd")
const Crossing=preload("res://scripts/ui_mural/enroscada.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
const EventArt=preload("res://scripts/ui_mural/event_art.gd")
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,note:String) -> void:
	checks+=1
	if not ok:failures.append(note);printerr("FAIL ",note)
func settle() -> void:
	for frame in 5:await process_frame
func key(code:Key) -> void:
	for pressed in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
		Input.parse_input_event(event);await process_frame
func run() -> void:
	root.content_scale_size=Vector2i.ZERO;Controls.install()
	for id in ["boss-warning","boss-status","crossing"]:
		var image:=EventArt.skin(id).texture.get_image()
		var color:=image.get_pixel(image.get_width()/2,image.get_height()/2)
		check(color.r>color.g*1.5 if id=="boss-warning" else color.b>color.r*1.5 if id=="boss-status" else color.g>color.r*1.2,"event has distinct semantic paint: "+id)
	var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	var partner:={"id":"qa","modelId":"rabbito","xp":Model.xp_for_level(8),"personalName":"Rabbito"}
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(1280,800)]:
		root.size=dimensions
		for scale in [1.0,1.5]:
			for mode in ["duelo","boss","campea","tres"]:
				var model=Trail.new(partner,"morro-5" if mode=="campea" else "morro-3") if mode in ["campea","tres"] else Model.new(partner,{"modelId":"basica","level":5}) if mode=="duelo" else Model.new(partner)
				model.intro=2.2 if mode=="campea" else 0
				var view=TrailView.new() if mode in ["campea","tres"] else View.new()
				view.text_scale=scale;view.reduced_motion=true;view.reward_player={"name":"Kael","partners":[partner],"equippedPartnerId":"qa"}
				view.configure(content,model.snapshot());root.add_child(view);view.set_physics_process(false);view.paused=false;view._physics_process(0);await settle()
				var boxes:=Panels.regions(Vector2(dimensions),2 if mode=="tres" else 1,scale)
				for id in ["pilot","partner","clock","weather","rivals"]:check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(boxes[id]),"HUD bounds "+id+str(dimensions)+str(scale)+mode)
				check(not boxes.pilot.intersects(boxes.clock) and not boxes.rivals.intersects(boxes.clock),"top HUD separated")
				for command in view.move_cards:
					check(view.get_global_rect().encloses(command.tile.get_global_rect()),"action fits viewport")
					if command.node.visible:check(not boxes.partner.intersects(command.tile.get_global_rect()),"partner clears action row "+str(dimensions)+str(scale)+mode)
					check(command.tile.mural and command.tile.text_scale==scale,"real actions use Mural/text preference")
				if mode=="campea":
					check(view.champion and view.duel_intro.visible,"Mikka receives champion VS")
					check(view.move_cards.all(func(card):return not card.node.visible),"champion commands hidden")
					var before:Dictionary=view.model.snapshot()
					view.pointer_held={"cut":true};view._physics_process(.05)
					check(view.model.duration==before.duration and view.model.q.hp==before.q.hp,"VS freezes clock and damage")
					view.paused=true;var remaining:float=view.model.intro;view._physics_process(.05)
					check(view.model.intro==remaining and not view.duel_intro.visible,"pause freezes and hides VS")
					view.paused=false;view._physics_process(0)
					Input.action_press("campaign_cut")
					view.duel_intro.skip.grab_focus();await key(KEY_ENTER);view._physics_process(0)
					check(view.model.intro==0 and not view.duel_intro.visible,"native skip ends VS")
					check(view.model.duration==before.duration,"skip does not consume fight time")
					check(view.require_action_release,"skip requires release before combat")
					view.pointer_held={"cut":true};view._physics_process(.01)
					check(view.model.p.attackCooldown==0,"held skip input cannot leak attack")
					Input.action_release("campaign_cut")
				view.free()
	# Real contact fixture, including the counter path; state() must stay pure.
	var model:=Model.new(partner,{"modelId":"basica","level":5});model.intro=0
	model.p.x=750;model.p.y=200;model.p.vx=120;model.q.x=250;model.q.y=200
	var snapshot:=model.snapshot()
	var state:=Crossing.state(model)
	check(not state.is_empty() and state.ready and state.quality.critical,"real critical crossing shown ready")
	check(model.snapshot()==snapshot,"crossing display cannot consume counters, energy or HP")
	model.p.energy=0;check(not Crossing.state(model).ready and "energia" in Crossing.state(model).message,"low energy never promises a cut")
	model.p.energy=model.p.stats.energy;model.p.guardTime=.3;check(not Crossing.state(model).ready,"guard blocks ready cue")
	model.p.guardTime=0;model.p.signatureWindup=.3;check(not Crossing.state(model).ready,"own special blocks ready cue")
	model.p.signatureWindup=0;model.p.attackCooldown=.3;check(not Crossing.state(model).ready,"cooldown blocks ready cue")
	model.p.attackCooldown=0;model.q.signatureWindup=.5;check(Crossing.state(model).is_empty(),"danger takes priority over crossing prompt")
	model.q.signatureWindup=0;model.intro=1;check(Crossing.state(model).is_empty(),"no crossing prompt during intro")
	var revision:="pip-133-v2" if "--revision=2" in OS.get_cmdline_user_args() else "pip-133"
	var file:=FileAccess.open("res://../documentation/hud-v2/"+revision+"/testes.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"input":"Native injected keyboard skip; existing action and boss suites supplement mouse/pad","resolutions":["1280x720","1920x1080","1024x768","1280x800"],"textScales":[1.0,1.5]},"\t"));file.close()
	print("MURAL BATTLE: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

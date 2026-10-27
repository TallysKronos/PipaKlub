extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const Fixtures=preload("res://tools/player_audit_fixtures.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const State=preload("res://scripts/campaign/state.gd")
var count:=0
var failures:Array=[]
var captures:=false
var output:=""
func _initialize() -> void:call_deferred("run")
func check(value:bool,reason:String) -> void:
	count+=1
	if not value:failures.append(reason);printerr("FAIL "+reason)
func settle() -> void:
	for i in 5:await process_frame
func freeze(node:Node) -> void:
	node.set_process(false);node.set_physics_process(false)
	for child in node.get_children():freeze(child)
func save_frame(name:String) -> void:
	if not captures:return
	await settle();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
func run() -> void:
	captures="--capture" in OS.get_cmdline_user_args()
	if captures and DisplayServer.get_name()=="headless":printerr("Renderer required");quit(1);return
	output=ProjectSettings.globalize_path("res://../mockups/revisao/fluxos")
	if captures:DirAccess.make_dir_recursive_absolute(output)
	var front:=Front.new()
	front.session._store=Store.new("user://battle-flow-"+State.new_id())
	front.preferences.storage_path="user://battle-flow-"+State.new_id()+".cfg"
	root.add_child(front)
	for scenario in ["battle","morro-battle","boss-intro","lesson-0"]:
		Fixtures.show(front,scenario);await settle();freeze(front)
		var lesson:bool=scenario.begins_with("lesson")
		var view:Control=front._practice_view() if lesson else front.battle
		view.paused=true
		if not lesson:view.model.intro=0
		view.model.p.attackCooldown=0;view.model.p.energy=100
		view.model.p.evade=0;view.model.p.guardTime=0;view.model.p.lineMove={}
		Input.action_press("campaign_cut")
		var before:Dictionary=view.model.p.duplicate(true)
		if lesson:view._process(.05)
		else:view._physics_process(.05)
		await settle()
		check(view.model.p==before,"paused model unchanged "+scenario)
		if not lesson:
			check(view.resume_button.get_parent()==view.status_row,"resume belongs to pause row")
			for button in view.actions.get_children():
				check(not view.resume_button.get_global_rect().intersects(button.get_global_rect()),"resume never overlaps save or flee")
		view.paused=false
		if lesson:view._process(.05)
		else:view._physics_process(.05)
		check(view.model.p.attackCooldown==0,"held attack cannot cross resume "+scenario)
		Input.action_release("campaign_cut")
		if lesson:view._process(0)
		else:view._physics_process(0)
		Input.action_press("campaign_cut")
		if lesson:view._process(.016)
		else:view._physics_process(.016)
		check(view.model.p.attackCooldown>0,"fresh press works after release "+scenario)
		Input.action_release("campaign_cut")
		# Pause and resume within one frame must also arm the release barrier.
		view.model.p.attackCooldown=0
		Input.action_press("campaign_cut")
		view.suspend_actions();view.paused=false
		if lesson:view._process(.016)
		else:view._physics_process(.016)
		check(view.model.p.attackCooldown==0,"instant pause requires release "+scenario)
		Input.action_release("campaign_cut")
	# Failed storage is also an input barrier, even if an external caller forgot paused=true.
	Fixtures.show(front,"battle");await settle();freeze(front)
	front.battle.blocked=true;front.battle.paused=false
	var state:Dictionary=front.battle.model.snapshot()
	front.battle._physics_process(.05)
	check(front.battle.model.snapshot()==state,"blocked save freezes model independently of pause flag")
	for viewport in [Vector2i(1280,720),Vector2i(1280,800),Vector2i(1920,1080),Vector2i(2560,1080)]:
		root.size=viewport
		for reduced in [false,true]:
			front.preferences.reduced_motion=reduced
			for index in 5:
				Fixtures.show(front,"lesson-"+str(index));await settle();freeze(front)
				var practice:Control=front._practice_view()
				practice._process(0)
				await settle()
				check(practice.reduced_motion==reduced,"lesson receives motion preference")
				check(practice.move_cards.size()==5,"lesson shares five action controls")
				var field_size:Vector2=practice._field_scale()*Vector2(1000,640)
				check(is_equal_approx(field_size.x,practice.size.x),"lesson arena spans viewport width")
				check(field_size.y>practice.size.y*.55,"lesson reserves majority height for arena")
				var point:=Vector2(700,180)
				check((practice._project(point)/practice._field_scale()).distance_to(point)<.01,"pointer and signals share world projection")
				check(not practice.hint.get_global_rect().intersects(practice.move_cards[0].tile.get_global_rect()),"instructions stay separate from commands")
				for command in practice.move_cards:
					check(command.tile.reduced_motion==reduced,"shared tile receives motion preference")
					check(practice.get_global_rect().encloses(command.tile.get_global_rect()),"lesson action inside screen")
				check(practice.get_global_rect().encloses(practice.next_button.get_global_rect()),"advance lesson button visible")
				await save_frame("licao-%d-%s-%dx%d"%[index,"reduzido" if reduced else "normal",viewport.x,viewport.y])
			Fixtures.show(front,"battle");await settle();freeze(front)
			front.battle.model.p.hp=front.battle.model.p.stats.line*.5
			var saved_condition:Dictionary=front.session.snapshot().player.partners[0].condition.duplicate(true)
			front._pause_game();await settle()
			front.battle._physics_process(0)
			await settle()
			check(front.battle.paused and is_instance_valid(front.pause_overlay),"pause overlay stops battle")
			var focus:Control=root.gui_get_focus_owner()
			check(focus!=null and front.pause_overlay.is_ancestor_of(focus),"modal pause retains focus")
			check(front.pause_overlay.battle_paused,"pause summary uses battle context")
			check(is_equal_approx(front.pause_overlay.player.partners[0].condition.line,50),"pause displays current combat condition")
			check(front.session.snapshot().player.partners[0].condition==saved_condition,"pause display never settles damage into save")
			await save_frame("pausa-%s-%dx%d"%["reduzido" if reduced else "normal",viewport.x,viewport.y])
			front._resume_game()
			check(not front.battle.paused,"overlay restores battle state")
	front.free()
	print("BATTLE FLOW: ",count," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
